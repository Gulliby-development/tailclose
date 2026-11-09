local M = {}

function M.suffix(state, fill)
  if fill == nil then
    fill = "null"
  end

  local repair = ""
  local where = state.where
  if where == "start" or where == "value" then
    repair = fill
  elseif where == "member" then
    repair = '"":' .. fill
  elseif where == "colon" then
    repair = ":" .. fill
  elseif where == "string" or where == "key" then
    local token = state.string
    if token.escape == "backslash" then
      repair = "\\"
    elseif token.escape == "unicode" then
      repair = string.rep("0", 4 - token.hexDigits)
    end
    repair = repair .. '"'
    if where == "key" then
      repair = repair .. ":" .. fill
    end
  elseif where == "number" then
    local phase = state.number.phase
    if phase == "sign" or phase == "dot" or phase == "exponent" or phase == "exponent_sign" then
      repair = "0"
    end
  elseif where == "literal" then
    local token = state.literal
    repair = token.word:sub(token.matched + 1)
  end

  local closers = {}
  for i = #state.frames, 1, -1 do
    local frame = state.frames[i]
    closers[#closers + 1] = frame.kind == "object" and "}" or "]"
  end
  local closing = table.concat(closers)
  return repair .. closing, closing
end

return M
