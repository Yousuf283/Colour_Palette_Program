local debug = require('dev_stuff')
local colours = require('colours')
local fonts = require('fonts')
local cursor = require('cursor')
local slab = require('libs.slab')
local gamera = require('libs.gamera')

local width, height = love.graphics.getDimensions()
love.graphics.setBackgroundColor(colours.primary)
slab.Initialize(args)
local cam = gamera.new(0,0,5000,5000)
cam:setWindow(200,0,700,600)
cam:setPosition(2500,2500)

local dx = 0
local dy = 0

local scale = 1.0
local isDragging = false
local AmountOfColours = 1

love.update = function(dt)
  slab.Update(dt)
  slab.BeginWindow('GUI', {
    --Title = "Colour Palette Creator",
    X = 0,
    Y = 0,
    W = 200,
    H = 600,
    ContentW = 200,
    ContentH = 600,
    AllowMove = false,
    AllowResize = false,
    Border = 2,
    NoOutline = true,
    AutoSizeWindow = false,
    ShowMinimize = false,
    ShowScrollbarY = false;
  })
  slab.Text("Amount Of Colours")
  if slab.Input('AmountOfColours', {
    Text = tostring(AmountOfColours),
    Tooltip = "Amount Of Colours For The Colour Palette",
    Align = "center",
    W = 75,
    H = 20,
    MinNumber = 1,
    MultiLine = false,
    NoDrag = true,
    UseSlider = false,
    ReturnOnText = false,
    NumbersOnly = true
  }) then
	   AmountOfColours = slab.GetInputNumber()
  end
  slab.Separator()
  if slab.Button("Export") then
	   exporting = true
  end
  slab.EndWindow()
  --Debug
  debug_update(dt, scale)
end

love.draw = function()
  slab.Draw()
  cam:draw(function()
    love.graphics.rectangle("fill", 2495, 2495, 10, 10)
  end)
  --Reset Colour
  colours.setColour('white')
  --Debug
  debug_draw()
end

love.keypressed = function(k, scancode, isRepeat)
  if k == 'escape' then
    love.event.quit()
  end
end

love.mousemoved = function(mx, my, dx, dy)
  if isDragging then
    local x, y = cam:getPosition()
    cam:setPosition(x - dx / scale, y - dy / scale)
  end
  debug_mouse_moved(mx, my, dx, dy)
end

love.mousepressed = function(mx, my, button, pressCount)
  if button == 2 and mx > 200 then
    isDragging = true
  end
end

love.mousereleased = function(mx, my, button)
  if button == 2 then
    isDragging = false
  end
end

love.wheelmoved = function(dx, dy)
  if dy > 0 then
    if scale < 4 then
      scale = scale + (dy * 0.1)
    else
      scale = 4
    end
  else
    if scale > 0.1 then
      scale = scale - (dy * -0.1)
    else
      scale = 0.1
    end
  end
  cam:setScale(scale)
end

local coordsToScreen = function(x,y)
  return cam:toScreen(x,y)
end

local coordsToWorld = function(x,y)
  return cam:toWorld(x,y)
end
