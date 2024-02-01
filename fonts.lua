local fonts = {}

fonts.default = love.graphics.getFont()
fonts.kanit = love.graphics.newFont('fonts/Kanit/Kanit-Regular.ttf')

fonts.setFont = function(font)
  if font == 'default' then
    love.graphics.setFont(fonts.default)
  elseif font == 'kanit' then
    love.graphics.setFont(fonts.kanit)
  end
end

fonts.getDimensions = function(font, msg)
  local result = {}
  if font == 'default' then
    result[1] = fonts.default:getWidth(msg)
    result[2] = fonts.default:getHeight(msg)
    return result
  elseif font == 'kanit' then
    result[1] = fonts.kanit:getWidth(msg)
    result[2] = fonts.kanit:getHeight(msg)
    return result
  end
end

return fonts
