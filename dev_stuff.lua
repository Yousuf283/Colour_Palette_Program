local fonts = require('fonts')
local colours = require('colours')

local scale = 1
local FPS = debug.FPS
FPS = -1

local mouse = {0, 0, 0, 0}
local mx, my = mouse[1], mouse[2]
local mxdx, mxdy = mouse[3], mouse[4]

local w, h = love.graphics.getDimensions()

local calculateDistance = function(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx^2 + dy^2)
    return distance
end


debug_update = function(dt, s)
  FPS = love.timer.getFPS()
  mx, my = love.mouse.getPosition()
  scale = s
end

debug_mouse_moved = function(mx, my, dx, dy)

end

debug_draw = function()
  --print FPS
  fonts.setFont('default')
  love.graphics.print('FPS: '..FPS, 0, h-15)
  --print w/height
  love.graphics.print(w..','..h, 0, h-25)
  --print mx, my
  love.graphics.print(mx..','..my, 0, h-35)
  --print zoom
  love.graphics.print("Scale: ".. scale, 0, h-45)
end
