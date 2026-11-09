local repair = require("tailclose.repair")
local scan = require("tailclose.scan")

local M = {}

function M.check_command(_, input)
  local state, diagnostic = scan.scan(input)
  if not state then
    if diagnostic.kind == "too_long" then
      error({ status = 1, message = diagnostic.reason }, 0)
    end
    return {
      status = 1,
      out = string.format("invalid at byte %d: %s\n", diagnostic.offset, diagnostic.reason),
      err = "",
    }
  end

  local suffix = repair.suffix(state, "null")
  local completion = suffix == "" and "complete" or ("partial " .. #suffix)
  return {
    status = 0,
    out = string.format("%s\ndepth %d bytes %d\n", completion, #state.frames, state.bytes),
    err = "",
  }
end

return M
