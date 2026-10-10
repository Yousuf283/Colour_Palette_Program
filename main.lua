-- main.lua
-- Palette maker: pick or type colours, build a palette, name and export it,
-- and search/load previously saved palettes from the panel on the right.

local cursor = require('cursor')
local colours = require('colours')
local palette = require('palette')

local W, H
local font, smallFont

local selected = nil
local status = { text = '', timer = 0 }
local currentCursor = nil
local blink = 0

---------------------------------------------------------------------------
-- Text fields
---------------------------------------------------------------------------

local fields = {
  hex    = { x = 20,  y = 20, w = 160, h = 40, text = '', max = 7,  allowed = '[%x#]',    upper = true, placeholder = '#BF6136' },
  name   = { x = 470, y = 20, w = 180, h = 40, text = '', max = 32, allowed = '[%w%-_ ]',               placeholder = 'Palette name' },
  search = { x = 0,   y = 120, w = 0,  h = 32, text = '', max = 32, allowed = '[%w%-_ ]',               placeholder = 'Search...' },
}
local fieldOrder = { 'hex', 'name', 'search' }
local focused = 'hex'

---------------------------------------------------------------------------
-- Colour picker state (h, s, v all 0-1)
---------------------------------------------------------------------------

local picker = {
  h = 0, s = 1, v = 1,
  x = 20, y = 100, size = 200,   -- saturation/value square
  hueX = 232, hueW = 24,         -- hue bar (same y and height as the square)
  dragging = nil,                -- 'sv', 'hue' or nil
}
local svShader, hueImage, pixelImage
local lastHex = ''

---------------------------------------------------------------------------
-- Saved palettes panel
---------------------------------------------------------------------------

local PANEL_W, ITEM_H, ITEM_GAP = 240, 52, 6
local panel = { x = 0, listY = 165, scroll = 0 }
local savedList = {}
local thumbs = {}
local pendingDelete = nil -- file awaiting a second "confirm" click

-- Swatch grid layout (between the picker and the panel)
local SWATCH, GAP, TOP, GRID_LEFT, LABEL_H = 64, 12, 100, 280, 18

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function pointInRect(px, py, x, y, w, h)
  return px >= x and px <= x + w and py >= y and py <= y + h
end

local function clamp(x, lo, hi)
  return math.max(lo, math.min(hi, x))
end

local function setStatus(msg)
  status.text = msg
  status.timer = 5
end

local function layout()
  W, H = love.graphics.getDimensions()
  panel.x = W - PANEL_W
  fields.search.x = panel.x + 15
  fields.search.w = PANEL_W - 30
end

-- Accepts "#RRGGBB", "RRGGBB", "#RGB" or "RGB". Returns r, g, b (0-1) or nil.
local function hexToRGB(hex)
  hex = hex:gsub('#', '')
  if #hex == 3 then
    hex = hex:gsub('.', '%0%0')
  end
  if not hex:match('^%x%x%x%x%x%x$') then
    return nil
  end
  return love.math.colorFromBytes(
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16)
  )
end

local function rgbToHex(c)
  return string.format('#%02X%02X%02X', love.math.colorToBytes(c[1], c[2], c[3]))
end

local function hsvToRgb(h, s, v)
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
  i = i % 6
  if i == 0 then return v, t, p
  elseif i == 1 then return q, v, p
  elseif i == 2 then return p, v, t
  elseif i == 3 then return p, q, v
  elseif i == 4 then return t, p, v
  else return v, p, q end
end

local function rgbToHsv(r, g, b)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local d = max - min
  local h = 0
  if d > 0 then
    if max == r then h = ((g - b) / d) % 6
    elseif max == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    h = h / 6
  end
  local s = (max == 0) and 0 or d / max
  return h, s, max
end

local function fieldAt(px, py)
  for _, key in ipairs(fieldOrder) do
    local f = fields[key]
    if pointInRect(px, py, f.x, f.y, f.w, f.h) then
      return key
    end
  end
  return nil
end

-- Insert text into a field, keeping only allowed characters
local function typeInto(f, text)
  for ch in text:gmatch('.') do
    if #f.text >= f.max then break end
    if ch:match('^' .. f.allowed .. '$') then
      f.text = f.text .. (f.upper and ch:upper() or ch)
    end
  end
end

---------------------------------------------------------------------------
-- Picker sync
---------------------------------------------------------------------------

-- Picker -> hex box
local function updateHexFromPicker()
  local r, g, b = hsvToRgb(picker.h, picker.s, picker.v)
  fields.hex.text = rgbToHex({r, g, b})
  lastHex = fields.hex.text -- don't sync straight back (keeps hue stable on greys)
end

-- Hex box -> picker
local function updatePickerFromHex()
  local r, g, b = hexToRGB(fields.hex.text)
  if not r then return end
  local h, s, v = rgbToHsv(r, g, b)
  if s > 0 and v > 0 then picker.h = h end -- hue is meaningless for greys
  if v > 0 then picker.s = s end
  picker.v = v
end

local function updatePickerDrag(mx, my)
  if picker.dragging == 'sv' then
    picker.s = clamp((mx - picker.x) / picker.size, 0, 1)
    picker.v = 1 - clamp((my - picker.y) / picker.size, 0, 1)
    updateHexFromPicker()
  elseif picker.dragging == 'hue' then
    picker.h = clamp((my - picker.y) / picker.size, 0, 1)
    updateHexFromPicker()
  end
end

local function overSV(x, y)
  return pointInRect(x, y, picker.x, picker.y, picker.size, picker.size)
end

local function overHue(x, y)
  return pointInRect(x, y, picker.hueX, picker.y, picker.hueW, picker.size)
end

---------------------------------------------------------------------------
-- Swatch grid
---------------------------------------------------------------------------

local function swatchRect(i)
  local gridW = W - GRID_LEFT - PANEL_W - 20
  local cols = math.max(1, math.floor((gridW + GAP) / (SWATCH + GAP)))
  local col = (i - 1) % cols
  local row = math.floor((i - 1) / cols)
  return GRID_LEFT + col * (SWATCH + GAP), TOP + row * (SWATCH + GAP + LABEL_H), SWATCH, SWATCH
end

local function swatchAt(px, py)
  for i = 1, #palette.colours do
    if pointInRect(px, py, swatchRect(i)) then
      return i
    end
  end
  return nil
end

---------------------------------------------------------------------------
-- Saved palettes list
---------------------------------------------------------------------------

local function refreshSaved()
  savedList = palette.list()
  thumbs = {}
end

local function filteredSaved()
  local query = fields.search.text:lower()
  if query == '' then
    return savedList
  end
  local out = {}
  for _, item in ipairs(savedList) do
    if item.name:lower():find(query, 1, true) then
      table.insert(out, item)
    end
  end
  return out
end

local function getThumb(item)
  if thumbs[item.file] == nil then
    local ok, img = pcall(love.graphics.newImage, item.file)
    if ok then
      img:setFilter('nearest', 'nearest')
      thumbs[item.file] = img
    else
      thumbs[item.file] = false
    end
  end
  return thumbs[item.file] or nil
end

local function listViewHeight()
  return H - panel.listY - 10
end

local function maxScroll(count)
  return math.max(0, count * (ITEM_H + ITEM_GAP) - listViewHeight())
end

local function listItemRect(i)
  return panel.x + 10, panel.listY + (i - 1) * (ITEM_H + ITEM_GAP) - panel.scroll, PANEL_W - 20, ITEM_H
end

-- Small delete button in the top-right of a list item (wider while confirming)
local function deleteButtonRect(i, item)
  local x, y, w = listItemRect(i)
  local bw = (pendingDelete == item.file) and 64 or 22
  return x + w - bw - 6, y + 5, bw, 20
end

local function listItemAt(px, py, items)
  if not pointInRect(px, py, panel.x, panel.listY, PANEL_W, listViewHeight()) then
    return nil
  end
  for i = 1, #items do
    if pointInRect(px, py, listItemRect(i)) then
      return i
    end
  end
  return nil
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------

local function addColour()
  local r, g, b = hexToRGB(fields.hex.text)
  if not r then
    setStatus('Pick a colour or enter a valid hex code, e.g. #BF6136')
    return
  end
  if palette.add(r, g, b) then
    selected = #palette.colours
    setStatus('Added ' .. rgbToHex(palette.colours[selected]))
  else
    setStatus('Palette is full (' .. palette.max .. ' colours)')
  end
end

local function removeColour(i)
  i = i or selected
  if not i or not palette.colours[i] then
    setStatus('Click a colour to select it first')
    return
  end
  local hex = rgbToHex(palette.colours[i])
  palette.remove(i)
  local n = #palette.colours
  if n == 0 then
    selected = nil
  elseif selected and selected > n then
    selected = n
  end
  setStatus('Removed ' .. hex)
end

local function exportPalette()
  local name = fields.name.text:match('^%s*(.-)%s*$')
  if name == '' then
    name = 'palette_' .. os.date('%Y%m%d_%H%M%S')
    fields.name.text = name
  end

  local ok, result, existed = palette.export(name, 32)
  if ok then
    love.system.setClipboardText(result)
    setStatus((existed and 'Updated ' or 'Saved ') .. result .. '  (path copied to clipboard)')
    fields.name.text = ''
    refreshSaved()
  else
    setStatus(result)
  end
end

local function deleteSaved(item)
  pendingDelete = nil
  if palette.delete(item.file) then
    setStatus('Deleted "' .. item.name .. '"')
  else
    setStatus('Could not delete ' .. item.file)
  end
  refreshSaved()
  panel.scroll = clamp(panel.scroll, 0, maxScroll(#filteredSaved()))
end

local function loadSaved(item)
  if palette.load(item.file) then
    selected = nil
    fields.name.text = item.name
    setStatus('Loaded "' .. item.name .. '" (' .. #palette.colours .. ' colours)')
  else
    setStatus('Could not read ' .. item.file)
  end
end

local buttons = {
  { label = 'Add',    x = 250, y = 20, w = 90,  h = 40, action = addColour },
  { label = 'Remove', x = 350, y = 20, w = 100, h = 40, action = function() removeColour() end },
  { label = 'Export', x = 660, y = 20, w = 100, h = 40, action = exportPalette },
}

local function buttonAt(px, py)
  for _, b in ipairs(buttons) do
    if pointInRect(px, py, b.x, b.y, b.w, b.h) then
      return b
    end
  end
  return nil
end

---------------------------------------------------------------------------
-- LÖVE callbacks
---------------------------------------------------------------------------

function love.load()
  love.filesystem.setIdentity('palette-maker')
  love.window.setTitle('Palette Maker')
  love.window.setMode(1040, 640, { resizable = true, minwidth = 800, minheight = 360 })
  love.keyboard.setKeyRepeat(true)

  layout()
  font = love.graphics.newFont(16)
  smallFont = love.graphics.newFont(12)

  -- Shader that draws the saturation (x) / value (y) square for the current hue
  svShader = love.graphics.newShader([[
    extern number hue;
    vec3 hsv2rgb(vec3 c) {
      vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
      vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      return vec4(hsv2rgb(vec3(hue, tc.x, 1.0 - tc.y)), 1.0);
    }
  ]])

  -- 1x1 white image: drawn scaled up so the shader gets 0-1 texture coords
  pixelImage = love.graphics.newImage(love.image.newImageData(1, 1, 'rgba8', string.char(255, 255, 255, 255)))

  -- Hue bar: a 1px-wide gradient stretched to size
  local hueData = love.image.newImageData(1, 256)
  for y = 0, 255 do
    local r, g, b = hsvToRgb(y / 255, 1, 1)
    hueData:setPixel(0, y, r, g, b, 1)
  end
  hueImage = love.graphics.newImage(hueData)
  hueImage:setFilter('linear', 'linear')

  updateHexFromPicker()
  refreshSaved()
end

function love.resize()
  layout()
  panel.scroll = clamp(panel.scroll, 0, maxScroll(#filteredSaved()))
end

function love.update(dt)
  blink = (blink + dt) % 1
  if status.timer > 0 then
    status.timer = status.timer - dt
  end

  -- Keep the picker in sync when the hex box is edited
  if fields.hex.text ~= lastHex then
    lastHex = fields.hex.text
    updatePickerFromHex()
  end

  local mx, my = love.mouse.getPosition()
  if picker.dragging then
    updatePickerDrag(mx, my)
  end

  -- Pick the cursor for whatever the mouse is over
  local want = cursor.default
  if picker.dragging or overSV(mx, my) or overHue(mx, my) then
    want = cursor.crosshair or cursor.hand
  elseif fieldAt(mx, my) then
    want = cursor.ibeam
  elseif buttonAt(mx, my) or swatchAt(mx, my) or listItemAt(mx, my, filteredSaved()) then
    want = cursor.hand
  end
  if want ~= currentCursor then
    love.mouse.setCursor(want)
    currentCursor = want
  end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function drawField(key)
  local f = fields[key]
  local isFocused = (focused == key)

  love.graphics.setFont(font)
  colours.setColour('primary')
  love.graphics.rectangle('fill', f.x, f.y, f.w, f.h, 4)
  colours.setColour(isFocused and 'tertiary' or 'white')
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', f.x, f.y, f.w, f.h, 4)
  love.graphics.setLineWidth(1)

  local textY = f.y + (f.h - font:getHeight()) / 2
  love.graphics.setScissor(f.x + 4, f.y, f.w - 8, f.h)
  if f.text == '' and not isFocused then
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.print(f.placeholder, f.x + 10, textY)
  else
    -- Scroll long text so the end (and caret) stays visible
    local textW = font:getWidth(f.text)
    local offset = math.max(0, textW - (f.w - 24))
    colours.setColour('white')
    love.graphics.print(f.text, f.x + 10 - offset, textY)
    if isFocused and blink < 0.5 then
      local caretX = f.x + 10 + textW - offset + 1
      love.graphics.line(caretX, textY, caretX, textY + font:getHeight())
    end
  end
  love.graphics.setScissor()
end

local function drawPicker()
  local p = picker

  -- Saturation/value square
  svShader:send('hue', p.h)
  love.graphics.setShader(svShader)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(pixelImage, p.x, p.y, 0, p.size, p.size)
  love.graphics.setShader()

  -- Hue bar
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(hueImage, p.hueX, p.y, 0, p.hueW, p.size / 256)

  -- Borders
  colours.setColour('secondary')
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', p.x, p.y, p.size, p.size)
  love.graphics.rectangle('line', p.hueX, p.y, p.hueW, p.size)

  -- SV marker
  local sx, sy = p.x + p.s * p.size, p.y + (1 - p.v) * p.size
  colours.setColour('black')
  love.graphics.circle('line', sx, sy, 7)
  colours.setColour('white')
  love.graphics.circle('line', sx, sy, 5)

  -- Hue marker
  local hy = p.y + p.h * p.size
  colours.setColour('white')
  love.graphics.rectangle('line', p.hueX - 3, hy - 3, p.hueW + 6, 6, 2)
  love.graphics.setLineWidth(1)

  -- Current colour readout
  love.graphics.setFont(smallFont)
  local r, g, b = hsvToRgb(p.h, p.s, p.v)
  local R, G, B = love.math.colorToBytes(r, g, b)
  colours.setColour('white')
  love.graphics.print(string.format('R %d  G %d  B %d', R, G, B), p.x, p.y + p.size + 10)
  love.graphics.print(string.format('H %d°  S %d%%  V %d%%',
    math.floor(p.h * 360 + 0.5), math.floor(p.s * 100 + 0.5), math.floor(p.v * 100 + 0.5)),
    p.x, p.y + p.size + 28)
end

local function drawPanel(mx, my)
  colours.setColour('secondary')
  love.graphics.rectangle('fill', panel.x, 80, PANEL_W, H - 80)

  love.graphics.setFont(font)
  colours.setColour('white')
  love.graphics.print('Saved palettes', panel.x + 15, 92)

  drawField('search')

  local items = filteredSaved()
  local viewH = listViewHeight()
  panel.scroll = clamp(panel.scroll, 0, maxScroll(#items))

  love.graphics.setFont(smallFont)
  if #items == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
    local msg = (#savedList == 0) and 'No saved palettes yet.\nName your palette and press Export.'
      or 'No palettes match your search.'
    love.graphics.printf(msg, panel.x + 15, panel.listY, PANEL_W - 30, 'left')
    return
  end

  local hovered = listItemAt(mx, my, items)
  love.graphics.setScissor(panel.x, panel.listY, PANEL_W, viewH)
  for i, item in ipairs(items) do
    local x, y, w, h = listItemRect(i)
    if y + h >= panel.listY and y <= panel.listY + viewH then
      colours.setColour(i == hovered and 'tertiary' or 'primary')
      love.graphics.rectangle('fill', x, y, w, h, 4)

      -- Name, clipped so it doesn't run under the delete button
      local bx, by, bw, bh = deleteButtonRect(i, item)
      love.graphics.intersectScissor(x, y, bx - x - 4, h)
      colours.setColour('white')
      love.graphics.print(item.name, x + 10, y + 7)
      love.graphics.setScissor(panel.x, panel.listY, PANEL_W, viewH)

      -- Delete button
      local confirming = (pendingDelete == item.file)
      local overDelete = pointInRect(mx, my, bx, by, bw, bh)
      if confirming then
        love.graphics.setColor(0.75, 0.2, 0.2, 1)
      elseif overDelete then
        colours.setColour('secondary')
      else
        love.graphics.setColor(0, 0, 0, 0)
      end
      love.graphics.rectangle('fill', bx, by, bw, bh, 3)
      colours.setColour('white')
      love.graphics.printf(confirming and 'Delete?' or 'x', bx, by + (bh - smallFont:getHeight()) / 2, bw, 'center')

      local img = getThumb(item)
      if img then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, x + 10, y + 28, 0, (w - 20) / img:getWidth(), 16 / img:getHeight())
      end
    end
  end
  love.graphics.setScissor()

  -- Scrollbar
  local total = #items * (ITEM_H + ITEM_GAP)
  if total > viewH then
    local barH = math.max(20, viewH * viewH / total)
    local barY = panel.listY + (viewH - barH) * (panel.scroll / maxScroll(#items))
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle('fill', panel.x + PANEL_W - 6, barY, 3, barH, 2)
  end
end

function love.draw()
  local mx, my = love.mouse.getPosition()

  -- Background and top bar
  colours.setColour('primary')
  love.graphics.rectangle('fill', 0, 0, W, H)
  colours.setColour('secondary')
  love.graphics.rectangle('fill', 0, 0, W, 80)

  drawField('hex')
  drawField('name')

  -- Live preview of the current colour
  local r, g, b = hexToRGB(fields.hex.text)
  if r then
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle('fill', 190, 20, 40, 40, 4)
  end
  colours.setColour('white')
  love.graphics.rectangle('line', 190, 20, 40, 40, 4)

  -- Buttons
  love.graphics.setFont(font)
  for _, btn in ipairs(buttons) do
    local hovered = pointInRect(mx, my, btn.x, btn.y, btn.w, btn.h)
    colours.setColour(hovered and 'tertiary' or 'primary')
    love.graphics.rectangle('fill', btn.x, btn.y, btn.w, btn.h, 4)
    colours.setColour('white')
    love.graphics.printf(btn.label, btn.x, btn.y + (btn.h - font:getHeight()) / 2, btn.w, 'center')
  end

  drawPicker()

  -- Swatches
  love.graphics.setFont(smallFont)
  if #palette.colours == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.printf('No colours yet - pick one on the left (or type a hex code) and press Add.',
      GRID_LEFT, TOP, W - GRID_LEFT - PANEL_W - 20, 'left')
  end
  for i, c in ipairs(palette.colours) do
    local x, y, w, h = swatchRect(i)
    love.graphics.setColor(c)
    love.graphics.rectangle('fill', x, y, w, h, 4)

    if i == selected then
      colours.setColour('tertiary')
      love.graphics.setLineWidth(3)
      love.graphics.rectangle('line', x - 3, y - 3, w + 6, h + 6, 6)
      love.graphics.setLineWidth(1)
    end

    colours.setColour('white')
    love.graphics.printf(rgbToHex(c), x - 6, y + h + 3, w + 12, 'center')
  end

  drawPanel(mx, my)

  -- Status / help line
  love.graphics.setFont(smallFont)
  local statusW = W - PANEL_W - 40
  if status.timer > 0 then
    colours.setColour('white')
    love.graphics.printf(status.text, 20, H - 40, statusW, 'left')
  else
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.printf('Enter to add  |  Click to select  |  Right-click or Delete to remove  |  Ctrl+S to export',
      20, H - 28, statusW, 'left')
  end
end

---------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------

function love.mousepressed(x, y, button)
  if button == 1 then
    -- Any click that isn't on the confirming delete button cancels the confirm
    local items = filteredSaved()
    local li = listItemAt(x, y, items)
    if pendingDelete and not (li and items[li].file == pendingDelete
        and pointInRect(x, y, deleteButtonRect(li, items[li]))) then
      pendingDelete = nil
    end

    focused = fieldAt(x, y)
    if focused then return end

    if overSV(x, y) then
      picker.dragging = 'sv'
      updatePickerDrag(x, y)
      return
    elseif overHue(x, y) then
      picker.dragging = 'hue'
      updatePickerDrag(x, y)
      return
    end

    local btn = buttonAt(x, y)
    if btn then
      btn.action()
      return
    end

    local items = filteredSaved()
    local li = listItemAt(x, y, items)
    if li then
      local item = items[li]
      if pointInRect(x, y, deleteButtonRect(li, item)) then
        if pendingDelete == item.file then
          deleteSaved(item)
        else
          pendingDelete = item.file
          setStatus('Click "Delete?" again to permanently delete "' .. item.name .. '"')
        end
      else
        pendingDelete = nil
        loadSaved(item)
      end
      return
    end

    local i = swatchAt(x, y)
    if i then
      selected = i
      -- Load the selected colour into the hex box and picker
      fields.hex.text = rgbToHex(palette.colours[i])
    end
  elseif button == 2 then
    local i = swatchAt(x, y)
    if i then
      selected = i
      removeColour(i)
    end
  end
end

function love.mousereleased(x, y, button)
  if button == 1 then
    picker.dragging = nil
  end
end

function love.wheelmoved(dx, dy)
  local mx, my = love.mouse.getPosition()
  if mx >= panel.x then
    panel.scroll = clamp(panel.scroll - dy * 30, 0, maxScroll(#filteredSaved()))
  end
end

function love.textinput(t)
  if focused then
    typeInto(fields[focused], t)
    if focused == 'search' then panel.scroll = 0 end
  end
end

function love.keypressed(key)
  local ctrl = love.keyboard.isDown('lctrl', 'rctrl', 'lgui', 'rgui')

  if ctrl and key == 's' then
    exportPalette()
    return
  end

  if focused then
    local f = fields[focused]
    if key == 'backspace' then
      f.text = f.text:sub(1, -2)
      if focused == 'search' then panel.scroll = 0 end
    elseif key == 'escape' then
      focused = nil
    elseif key == 'tab' then
      -- Cycle through the text fields
      for i, k in ipairs(fieldOrder) do
        if k == focused then
          focused = fieldOrder[i % #fieldOrder + 1]
          break
        end
      end
    elseif ctrl and key == 'v' then
      if focused == 'hex' then f.text = '' end
      typeInto(f, (love.system.getClipboardText() or ''):gsub('%s', focused == 'hex' and '' or ' '))
    elseif key == 'return' or key == 'kpenter' then
      if focused == 'name' then
        exportPalette()
      elseif focused == 'hex' then
        addColour()
      end
    end
  else
    if key == 'return' or key == 'kpenter' then
      addColour()
    elseif key == 'delete' or key == 'backspace' then
      removeColour()
    elseif key == 'escape' then
      selected = nil
      pendingDelete = nil
    end
  end
end