local debug = require('dev_stuff')
local colours = require('colours')

local width, height = love.graphics.getDimensions()

love.load = function()
  love.graphics.setBackgroundColor(colours.primary)
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

  debug_draw()
end
