-- The usage text, the limits and the command table. Verbatim from the brief.
local M = {}

M.VERSION = "0.1.0"
M.MAX_INPUT = 100
M.MAX_DEPTH = 8

M.USAGE = "usage: tailclose close [--fill VALUE]\n" .. "       tailclose suffix [--fill VALUE]\n" .. "       tailclose path\n" .. "       tailclose where\n" .. "       tailclose check\n"

-- The values that --fill takes, exactly as the command line gives them.
M.FILLS = { "null", "0", '""', "false", "[]", "{}" }

-- name: the command word; fill: whether --fill is one of its options;
-- module and handler: where the function that runs it lives.
M.COMMANDS = {
  { name = "close", fill = true, module = "tailclose.cmd_close", handler = "close_command" },
  { name = "suffix", fill = true, module = "tailclose.cmd_close", handler = "suffix_command" },
  { name = "path", fill = false, module = "tailclose.cmd_path", handler = "path_command" },
  { name = "where", fill = false, module = "tailclose.cmd_path", handler = "where_command" },
  { name = "check", fill = false, module = "tailclose.cmd_check", handler = "check_command" },
}

return M
