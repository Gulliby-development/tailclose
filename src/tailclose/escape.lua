local M = {}

function M.show(text)
  return (text:gsub("[%z\1-\255]", function(byte)
    local value = byte:byte()
    if value == 92 then
      return "\\\\"
    end
    if value == 10 then
      return "\\n"
    end
    if value == 13 then
      return "\\r"
    end
    if value == 9 then
      return "\\t"
    end
    if value < 32 or value > 126 then
      return string.format("\\x%02x", value)
    end
    return byte
  end))
end

return M
