-- Byte-oriented JSON prefix scanner shared by completion and inspection.
-- Successful states expose bytes, where, outermost-first frames, and only the
-- active string/number/literal token. Frame keys preserve their raw JSON bytes.
local registry = require("tailclose.registry")
local M = {}

local function invalid(offset, byte)
  return { kind = "invalid", offset = offset, reason = string.format("unexpected byte 0x%02x", byte) }
end

local function whitespace(byte)
  return byte == 0x20 or byte == 0x09 or byte == 0x0a or byte == 0x0d
end

local function hex(byte)
  return (byte >= 0x30 and byte <= 0x39) or (byte >= 0x41 and byte <= 0x46) or (byte >= 0x61 and byte <= 0x66)
end

local function digit(byte)
  return byte >= 0x30 and byte <= 0x39
end

local function complete_value(state)
  state.string, state.number, state.literal = nil, nil, nil
  local frame = state.frames[#state.frames]
  state.where = frame and "after" or "done"
end

local function can_start_value(state)
  local where = state.where
  if where == "start" then
    return true
  end
  if where == "value" then
    return true
  end
  if where == "open" then
    local frame = state.frames[#state.frames]
    return frame and frame.kind == "array"
  end
  return false
end

local function begin_string(state, role)
  state.string = { role = role, raw = "", escape = "none", hexDigits = 0 }
  state.where = role == "key" and "key" or "string"
end

local function begin_value(state, byte, offset)
  if byte == 0x7b or byte == 0x5b then
    if #state.frames >= registry.MAX_DEPTH then
      return { kind = "invalid", offset = offset, reason = "nesting too deep (max 8)" }
    end
    state.frames[#state.frames + 1] = {
      kind = byte == 0x7b and "object" or "array",
      commas = 0,
      key = nil,
    }
    state.where = "open"
  elseif byte == 0x22 then
    begin_string(state, "value")
  elseif byte == 0x2d or digit(byte) then
    local phase = byte == 0x2d and "sign" or (byte == 0x30 and "zero" or "integer")
    state.number = { raw = string.char(byte), phase = phase }
    state.where = "number"
  elseif byte == 0x74 or byte == 0x66 or byte == 0x6e then
    local word = byte == 0x74 and "true" or (byte == 0x66 and "false" or "null")
    state.literal = { word = word, matched = 1 }
    state.where = "literal"
  else
    return invalid(offset, byte)
  end
end

local function consume_number(state, byte, offset)
  local token = state.number
  local phase = token.phase
  local next_phase
  if phase == "sign" then
    if byte == 0x30 then
      next_phase = "zero"
    elseif byte >= 0x31 and byte <= 0x39 then
      next_phase = "integer"
    end
  elseif phase == "zero" then
    if byte == 0x2e then
      next_phase = "dot"
    elseif byte == 0x65 or byte == 0x45 then
      next_phase = "exponent"
    end
  elseif phase == "integer" then
    if digit(byte) then
      next_phase = "integer"
    elseif byte == 0x2e then
      next_phase = "dot"
    elseif byte == 0x65 or byte == 0x45 then
      next_phase = "exponent"
    end
  elseif phase == "dot" then
    if digit(byte) then
      next_phase = "fraction"
    end
  elseif phase == "fraction" then
    if digit(byte) then
      next_phase = "fraction"
    elseif byte == 0x65 or byte == 0x45 then
      next_phase = "exponent"
    end
  elseif phase == "exponent" then
    if byte == 0x2b or byte == 0x2d then
      next_phase = "exponent_sign"
    elseif digit(byte) then
      next_phase = "exponent_digits"
    end
  elseif phase == "exponent_sign" then
    if digit(byte) then
      next_phase = "exponent_digits"
    end
  elseif phase == "exponent_digits" and digit(byte) then
    next_phase = "exponent_digits"
  end
  if next_phase then
    if phase == "zero" and digit(byte) then
      return invalid(offset, byte), false
    end
    token.raw = token.raw .. string.char(byte)
    token.phase = next_phase
    return nil, true
  end
  if phase == "sign" or phase == "dot" or phase == "exponent" or phase == "exponent_sign" then
    return invalid(offset, byte), false
  end
  complete_value(state)
  return nil, false
end

function M.scan(text)
  if #text > registry.MAX_INPUT then
    return nil, { kind = "too_long", reason = "input is too long (max 100 bytes)" }
  end

  local state = { bytes = #text, where = "start", frames = {} }
  local i = 1
  while i <= #text do
    local byte = text:byte(i)
    local again = false
    if state.string then
      local token = state.string
      if token.escape == "backslash" then
        if byte == 0x75 then
          token.raw = token.raw .. string.char(byte)
          token.escape, token.hexDigits = "unicode", 0
        elseif byte == 0x22 or byte == 0x5c or byte == 0x2f or byte == 0x62 or byte == 0x66 or byte == 0x6e or byte == 0x72 or byte == 0x74 then
          token.raw = token.raw .. string.char(byte)
          token.escape = "none"
        else
          return nil, invalid(i - 1, byte)
        end
      elseif token.escape == "unicode" then
        if not hex(byte) then
          return nil, invalid(i - 1, byte)
        end
        token.raw = token.raw .. string.char(byte)
        token.hexDigits = token.hexDigits + 1
        if token.hexDigits == 4 then
          token.escape, token.hexDigits = "none", 0
        end
      elseif byte == 0x5c then
        token.raw, token.escape = token.raw .. string.char(byte), "backslash"
      elseif byte == 0x22 then
        local role = token.role
        state.string = nil
        if role == "key" then
          state.frames[#state.frames].key = token.raw
          state.where = "colon"
        else
          complete_value(state)
        end
      elseif byte < 0x20 then
        return nil, invalid(i - 1, byte)
      else
        token.raw = token.raw .. string.char(byte)
      end
    elseif state.number then
      local diagnostic, consumed = consume_number(state, byte, i - 1)
      if diagnostic then
        return nil, diagnostic
      end
      again = not consumed
    elseif state.literal then
      local token = state.literal
      local expected = token.word:byte(token.matched + 1)
      if byte ~= expected then
        return nil, invalid(i - 1, byte)
      end
      token.matched = token.matched + 1
      if token.matched == #token.word then
        complete_value(state)
      end
    elseif whitespace(byte) then
      -- Whitespace does not change the structural position.
      again = false
    else
      local where = state.where
      local frame = state.frames[#state.frames]
      if (where == "open" and frame.kind == "object" and byte ~= 0x7d) or where == "member" then
        if byte ~= 0x22 then
          return nil, invalid(i - 1, byte)
        end
        begin_string(state, "key")
      elseif where == "colon" then
        if byte ~= 0x3a then
          return nil, invalid(i - 1, byte)
        end
        state.where = "value"
      elseif where == "after" then
        if byte == 0x2c then
          frame.commas = frame.commas + 1
          frame.key = nil
          state.where = frame.kind == "object" and "member" or "value"
        elseif (byte == 0x7d and frame.kind == "object") or (byte == 0x5d and frame.kind == "array") then
          state.frames[#state.frames] = nil
          state.where = #state.frames > 0 and "after" or "done"
        else
          return nil, invalid(i - 1, byte)
        end
      elseif where == "open" or where == "value" or where == "start" then
        if byte == 0x7d or byte == 0x5d then
          if where == "open" and ((byte == 0x7d and frame.kind == "object") or (byte == 0x5d and frame.kind == "array")) then
            state.frames[#state.frames] = nil
            state.where = #state.frames > 0 and "after" or "done"
          else
            return nil, invalid(i - 1, byte)
          end
        elseif can_start_value(state) then
          local diagnostic = begin_value(state, byte, i - 1)
          if diagnostic then
            return nil, diagnostic
          end
        else
          return nil, invalid(i - 1, byte)
        end
      elseif where == "done" then
        return nil, invalid(i - 1, byte)
      else
        return nil, invalid(i - 1, byte)
      end
    end
    if not again then
      i = i + 1
    end
  end
  return state
end

function M.read(input)
  local state, diagnostic = M.scan(input)
  if state then
    return state
  end
  if diagnostic.kind == "too_long" then
    error({ status = 1, message = diagnostic.reason }, 0)
  end
  error({
    status = 1,
    message = string.format("invalid JSON at byte %d: %s", diagnostic.offset, diagnostic.reason),
  }, 0)
end

return M
