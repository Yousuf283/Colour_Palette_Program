-- palette.lua
-- Stores the palette's colours, exports them to PNG and reads saved palettes back.

local palette = {}

palette.colours = {}
palette.max = 64
palette.dir = 'palettes' -- inside LÖVE's save directory

-- Add a colour (components in the 0-1 range). Returns true on success.
function palette.add(r, g, b)
  if #palette.colours >= palette.max then
    return false
  end
  table.insert(palette.colours, {r, g, b, 1})
  return true
end

-- Remove the colour at index i. Returns true on success.
function palette.remove(i)
  if palette.colours[i] then
    table.remove(palette.colours, i)
    return true
  end
  return false
end

-- Export the palette as a horizontal strip of square swatches to palettes/<name>.png.
-- Returns true, full path, and whether an existing file was overwritten,
-- or false and an error message.
function palette.export(name, size)
  size = size or 32
  local count = #palette.colours
  if count == 0 then
    return false, 'Palette is empty - add some colours first'
  end

  local data = love.image.newImageData(count * size, size)
  data:mapPixel(function(x, y)
    local c = palette.colours[math.floor(x / size) + 1]
    return c[1], c[2], c[3], 1
  end)

  love.filesystem.createDirectory(palette.dir)
  local file = palette.dir .. '/' .. name .. '.png'
  local existed = love.filesystem.getInfo(file) ~= nil
  data:encode('png', file)
  return true, love.filesystem.getSaveDirectory() .. '/' .. file, existed
end

-- List saved palettes, newest first: { {name=, file=, modtime=}, ... }
function palette.list()
  love.filesystem.createDirectory(palette.dir)
  local out = {}
  for _, f in ipairs(love.filesystem.getDirectoryItems(palette.dir)) do
    local name = f:match('^(.*)%.png$')
    if name then
      local file = palette.dir .. '/' .. f
      local info = love.filesystem.getInfo(file)
      table.insert(out, { name = name, file = file, modtime = info and info.modtime or 0 })
    end
  end
  table.sort(out, function(a, b) return a.modtime > b.modtime end)
  return out
end

-- Read the colours back out of a saved palette PNG.
-- Swatches are square, so the image height is the swatch size.
function palette.readColours(file)
  local ok, data = pcall(love.image.newImageData, file)
  if not ok then
    return nil
  end
  local size = data:getHeight()
  local count = math.floor(data:getWidth() / size)
  local cols = {}
  for i = 0, count - 1 do
    local r, g, b = data:getPixel(i * size + math.floor(size / 2), math.floor(size / 2))
    table.insert(cols, {r, g, b, 1})
  end
  return cols
end

-- Permanently delete a saved palette file. Returns true on success.
function palette.delete(file)
  return love.filesystem.remove(file)
end

-- Replace the current palette with a saved one. Returns true on success.
function palette.load(file)
  local cols = palette.readColours(file)
  if not cols then
    return false
  end
  palette.colours = cols
  return true
end

return palette