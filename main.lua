local debug = require('dev_stuff')
local colours = require('colours')
local fonts = require('fonts')
local cursor = require('cursor')
local slab = require('libs.slab')
local gamera = require('libs.gamera')

local width, height = love.graphics.getDimensions()
love.graphics.setBackgroundColor(colours.primary)
slab.Initialize(args)
local cam = gamera.new(0,0,1000,1000)
cam:setWindow(200,0,600,600)
scale = 1.0

local AmountOfColours = 0

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
  debug_update(dt)
end

love.keypressed = function(k, scancode, isRepeat)
  if k == 'escape' then
    love.event.quit()
  end
end

love.textinput = function(text)
end

love.mousemoved = function(mx, my, dx, dy)
  debug_mouse_moved(mx, my, dx, dy)
end

love.mousepressed = function(mx, my, button, pressCount)
end

love.mousereleased = function(mx, my, button)
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
end

love.draw = function()
  slab.Draw()
  --[[GUI Panel
  colours.setColour('secondary')
  love.graphics.rectangle('fill', 0, 0, 300,600)]]
  --[[Title
  colours.setColour('tertiary')
  fonts.setFont('twenty five')
  love.graphics.print('Colour Palette Creator', 24, 0)
  love.graphics.line(24, 35, 275, 35)]]

  --Colour Slots
  for i = 1, AmountOfColours, 1 do
    --love.graphics.rectangle("fill")
  end
  for i = 1, AmountOfColours, 1 do
    --love.graphics.rectangle("line")
  end
  --Reset Colour
  colours.setColour('white')
  --Debug
  love.graphics.print("scale: ".. scale, 0, height-45)
  debug_draw()
end
