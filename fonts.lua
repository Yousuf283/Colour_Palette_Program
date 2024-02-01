local fonts = {}

fonts.default = love.graphics.getFont()
fonts.kanit = love.graphics.newFont('fonts/Kanit/Kanit-Regular.ttf', 40)

fonts.setFont = function(font)
  if font == 'default' then
    love.graphics.setFont(fonts.default)
  elseif font == 'kanit' then
    love.graphics.setFont(fonts.kanit)
  end
end

fonts.getDimensions = function(font, msg)
  local output = {-1, -1}
  local current_font = love.graphics.getFont()
  output[1] = current_font:getWidth(msg)
  output[2] = current_font:getHeight(msg)
  return output
end

return fonts
