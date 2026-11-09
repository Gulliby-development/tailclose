local escape = require("tailclose.escape")
local repair = require("tailclose.repair")
local scan = require("tailclose.scan")

local M = {}

function M.close_command(options, input)
  local state = scan.read(input)
  local suffix = repair.suffix(state, options.fill)
  return { status = 0, out = escape.show(input .. suffix) .. "\n", err = "" }
end

function M.suffix_command(options, input)
  local state = scan.read(input)
  local suffix = repair.suffix(state, options.fill)
  return { status = 0, out = escape.show(suffix) .. "\n", err = "" }
end

return M
