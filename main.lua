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
  if (mx >= width-30) and (mx <= width) and (my >= 0) and (my <= 30) then
    love.event.quit()
  end
end

love.draw = function()
  --debug
  debug_draw()
  --Quit Button
  love.graphics.draw(cross_icon, width-27, 3)
  --GUI Panel
  love.graphics.setColor(colours.secondary)
  love.graphics.rectangle('fill', 0, 0, 300,600)
  --
  love.graphics.setColor(colours.default)
end
