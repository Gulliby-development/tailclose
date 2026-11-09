local harness = require("spec.harness")

local rows = {
  { { "help" }, "", 0, "", "" },
  { { "-h" }, "", 0, "", "" },
  { {}, "", 0, "", "" },
  { { "frob" }, "", 0, "", "" },
  { { "close" }, "", 1, "", "" },
  { { "close", "--fill", "0" }, "", 1, "", "" },
  { { "path", "x" }, "", 0, "", "" },
  { { "check" }, "", 1, "", "" },
  { { "check", "--fill", "0" }, "", 0, "", "" },
  { { "where" }, "", 1, "", "" },
  { { "suffix", "--fill", '""' }, "", 1, "", "" },
  { { "--version" }, "", 0, "", "" },
}

harness.check_reads(rows)
