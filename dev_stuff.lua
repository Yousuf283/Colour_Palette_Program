local fonts = require('fonts')
local colours = require('colours')
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


debug_update = function(dt)
  FPS = love.timer.getFPS()
  mx, my = love.mouse.getPosition()
end

debug_mouse_moved = function(mx, my, dx, dy)
  --Quit Hitbox
  if (mx >= w-30) and (mx <= w) and (my >= 0) and (my <= 30) then
    print('Quit')
  end
  --Export Hitbox
  if (calculateDistance(mx,my, 75, h-75) <= 25) or (calculateDistance(mx,my, 225, h-75) <= 25) or ( (mx >= 75) and (mx <= 225) and (my >= h-100) and (my <= h-50)) then
    print('Export')
  end
end

debug_draw = function()
  --[[
  --quit button hitbox
  love.graphics.rectangle('fill', w-30, 0, 30, 30)
  ]]
  --[[
  --export button hitbox
  colours.setColour('black')
  love.graphics.rectangle('line', 50, h-100, 200, 50)
  love.graphics.line(75, h-100, 75, h-50)
  love.graphics.line(225, h-100, 225, h-50)
  love.graphics.circle('line', 75, h-75, 25)
  love.graphics.circle('line', 225, h-75, 25)
  ]]
  --reset colours
  colours.setColour('white')
  --print FPS
  fonts.setFont('default')
  love.graphics.print('FPS: '..FPS, 0, 0)
  --print w/height
  love.graphics.print(w..','..h, 0, 10)
  --print mx, my
  love.graphics.print(mx..','..my, 0, 20)
end
