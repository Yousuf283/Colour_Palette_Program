local fonts = {}

fonts.default = love.graphics.newFont('fonts/Kanit/Kanit-Regular.ttf')
fonts.fourty = love.graphics.newFont('fonts/Kanit/Kanit-Regular.ttf', 40)
fonts.twenty_five = love.graphics.newFont('fonts/Kanit/Kanit-Regular.ttf', 25)

fonts.setFont = function(font)
  if font == 'default' then
    love.graphics.setFont(fonts.default)
  elseif font == 'fourty' then
    love.graphics.setFont(fonts.fourty)
  elseif font == 'twenty five' then
    love.graphics.setFont(fonts.twenty_five)
  end
end

fonts.getDimensions = function(msg)
  local output = {-1, -1}
  local current_font = love.graphics.getFont()
  output[1] = current_font:getWidth(msg)
  output[2] = current_font:getHeight(msg)
  return output
end

return fonts
