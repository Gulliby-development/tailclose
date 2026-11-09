local escape = require("tailclose.escape")
local scan = require("tailclose.scan")

local M = {}

function M.path_command(_, input)
  local state = scan.read(input)
  local path = { "$" }
  for _, frame in ipairs(state.frames) do
    if frame.kind == "array" then
      path[#path + 1] = "[" .. frame.commas .. "]"
    elseif frame.key ~= nil then
      if frame.key:match("^[A-Za-z_][A-Za-z0-9_]*$") then
        path[#path + 1] = "." .. escape.show(frame.key)
      else
        path[#path + 1] = '["' .. escape.show(frame.key) .. '"]'
      end
    end
  end
  return { status = 0, out = table.concat(path) .. "\n", err = "" }
end

function M.where_command(_, input)
  local state = scan.read(input)
  return { status = 0, out = state.where .. "\n", err = "" }
end

return M
