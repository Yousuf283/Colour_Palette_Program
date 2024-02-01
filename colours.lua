local colours = {}

colours.white = {1,1,1,1}
colours.black = {0,0,0,1}
colours.primary = {love.math.colorFromBytes(47, 54, 66, 255)}
colours.secondary = {love.math.colorFromBytes(33, 37, 43, 255)}
colours.tertiary = {love.math.colorFromBytes(191, 97, 54, 255)}

colours.setColour = function(colour)
  if colour == 'white' then
    love.graphics.setColor(colours.white)
  elseif colour == 'black' then
    love.graphics.setColor(colours.black)
  elseif colour == 'primary' then
    love.graphics.setColor(colours.primary)
  elseif colour == 'secondary' then
    love.graphics.setColor(colours.secondary)
  elseif colour == 'tertiary' then
    love.graphics.setColor(colours.tertiary)
  end
end

return colours
