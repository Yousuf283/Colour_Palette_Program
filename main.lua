local debug = require('dev_stuff')
local colours = require('colours')
local fonts = require('fonts')
local cursor = require('cursor')

local width, height = love.graphics.getDimensions()

love.graphics.setBackgroundColor(colours.primary)
local cross_icon = love.graphics.newImage('images/cross.png')

local calculateDistance = function(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx^2 + dy^2)
    return distance
end

local exporting = false

love.update = function(dt)
  debug_update(dt)
end

love.keypressed = function(k)
  if k == 'escape' then
    love.event.quit()
  end
end

love.mousemoved = function(mx, my, dx, dy)
  debug_mouse_moved(mx, my, dx, dy)
  if not exporting then
    --Quit Button
    if (mx >= width-30) and (mx <= width) and (my >= 0) and (my <= 30) then
      love.mouse.setCursor(cursor.hand)
    --Export Button
    elseif (calculateDistance(mx,my, 75, height-75) <= 25) or (calculateDistance(mx,my, 225, height-75) <= 25) or ( (mx >= 75) and (mx <= 225) and (my >= height-100) and (my <= height-50)) then
      love.mouse.setCursor(cursor.hand)
    else
      love.mouse.setCursor(cursor.default)
    end
  else
    love.mouse.setCursor(cursor.wait)
  end
end

love.mousepressed = function(mx, my, button)
  --Quit Button
  if (mx >= width-30) and (mx <= width) and (my >= 0) and (my <= 30) then
    love.event.quit()
  end
  --Export Button
  if (calculateDistance(mx,my, 75, height-75) <= 25) or (calculateDistance(mx,my, 225, height-75) <= 25) or ( (mx >= 75) and (mx <= 225) and (my >= height-100) and (my <= height-50)) then
    exporting = not exporting
  end
end

love.draw = function()
  --Quit Button
  love.graphics.draw(cross_icon, width-27, 3)
  --GUI Panel
  colours.setColour('secondary')
  love.graphics.rectangle('fill', 0, 0, 300,600)
  --Title
  colours.setColour('tertiary')
  fonts.setFont('twenty five')
  love.graphics.print('Colour Palette Creator', 24, 0)
  love.graphics.line(24, 35, 275, 35)
  --Export Button
  colours.setColour('tertiary')
  love.graphics.rectangle('fill', 50, height-100, 200, 50, 25, 25, 50)
  fonts.setFont('fourty')
  colours.setColour('black')
  love.graphics.print('Export', 90, height-107)
  --Reset Colour
  colours.setColour('white')
  --Debug
  --debug_draw()
end
