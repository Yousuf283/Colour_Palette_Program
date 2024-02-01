local debug = require('dev_stuff')
local colours = require('colours')

local width, height = love.graphics.getDimensions()
local cross_icon

love.load = function()
  love.graphics.setBackgroundColor(colours.primary)
  cross_icon = love.graphics.newImage('images/cross.png')
end

love.update = function(dt)
  debug_update(dt)
end

love.keypressed = function(k)
  if k == 'escape' then
    love.event.quit()
  end
end

love.mousepressed = function(mx, my, button)
  --Quit Button
  if (mx >= width-30) and (mx <= width) and (my >= 0) and (my <= 30) then
    love.event.quit()
  end
end

love.draw = function()
  --Quit Button
  love.graphics.draw(cross_icon, width-27, 3)
  --GUI Panel
  colours.setColour('secondary')
  love.graphics.rectangle('fill', 0, 0, 300,600)
  --Export Button
  colours.setColour('tertiary')
  love.graphics.rectangle('fill', 50, height-100, 200, 50, 25, 25, 50)
  --Reset Colour
  colours.setColour('white')
  --Debug
  debug_draw()
end
