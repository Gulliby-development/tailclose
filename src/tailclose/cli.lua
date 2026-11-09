local registry = require("tailclose.registry")

local M = {}

local function reply(status, out, err)
  return { status = status, out = out, err = err }
end

local function error_reply(message)
  return reply(2, "", "tailclose: " .. message .. "\n")
end

local function parse(args)
  local first = args[1]
  if first == "help" or first == "-h" or first == "--help" then
    return nil, nil, reply(0, registry.USAGE, "")
  end
  if first == "--version" then
    return nil, nil, reply(0, "tailclose " .. registry.VERSION .. "\n", "")
  end
  if first == nil then
    return nil, nil, reply(2, "", registry.USAGE)
  end

  local command
  for _, candidate in ipairs(registry.COMMANDS) do
    if candidate.name == first then
      command = candidate
      break
    end
  end
  if not command then
    return nil, nil, error_reply("unknown command " .. first)
  end

  local options = {}
  local has_fill = false
  local i = 2
  while i <= #args do
    local word = args[i]
    if word == "--fill" and command.fill then
      if has_fill then
        return nil, nil, error_reply("given twice: --fill")
      end
      if i == #args then
        return nil, nil, error_reply("missing value for --fill")
      end
      local value = args[i + 1]
      local valid = false
      for _, fill in ipairs(registry.FILLS) do
        if value == fill then
          valid = true
          break
        end
      end
      if not valid then
        return nil, nil, error_reply("bad value for --fill")
      end
      options.fill = value
      has_fill = true
      i = i + 2
    else
      if word == "" or word == "-" or word:sub(1, 1) ~= "-" then
        return nil, nil, error_reply("unexpected argument " .. word)
      end
      return nil, nil, error_reply("unknown option " .. word)
    end
  end
  return command, options, nil
end

function M.reads_stdin(args)
  local command = parse(args)
  return command ~= nil
end

function M.run(args, input)
  local command, options, immediate = parse(args)
  if immediate then
    return immediate
  end

  local ok, result = pcall(function()
    local module = require(command.module)
    return module[command.handler](options, input)
  end)
  if ok then
    return result
  end
  if type(result) == "table" and result.status ~= nil and result.message ~= nil then
    return reply(result.status, "", "tailclose: " .. result.message .. "\n")
  end
  error(result, 0)
end

return M
