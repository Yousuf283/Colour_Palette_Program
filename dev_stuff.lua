local FPS = debug.FPS
FPS = -1

local mouse = {0, 0, 0, 0}
local mx, my = mouse[1], mouse[2]
local mxdx, mxdy = mouse[3], mouse[4]

local w, h = love.graphics.getDimensions()

debug_update = function(dt)
  FPS = love.timer.getFPS()
  mx, my = love.mouse.getPosition()
end

debug_draw = function()
  --quit button
  love.graphics.rectangle('fill', w-30, 0, 30, 30)

  --print FPS
  love.graphics.print('FPS: '..FPS, 0, 0)
  --print width/height
  love.graphics.print(w..','..h, 0, 10)
  --print mx, my
  love.graphics.print(mx..','..my, 0, 20)
end
