local debug = require('stats')
local colours = require('colours')

love.load = function()
  love.graphics.setBackgroundColor(colours.background)
end

love.update = function(dt)
  debug_update(dt)
end

love.keypressed = function(k)
  if k == 'escape' then
    love.event.quit()
  end
end

love.draw = function()
  debug_draw()
end
