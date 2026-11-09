local harness = require("spec.harness")

local rows = {
  { { "suffix" }, '{"a":1}', 0, "\n", "" },
  { { "suffix" }, "", 0, "null\n", "" },
  { { "suffix", "--fill", "0" }, "[1,", 0, "0]\n", "" },
  { { "suffix", "--fill", '""' }, "[1,", 0, '""]\n', "" },
  { { "suffix", "--fill", "false" }, "[1,", 0, "false]\n", "" },
  { { "suffix", "--fill", "[]" }, "[1,", 0, "[]]\n", "" },
  { { "suffix", "--fill", "{}" }, "[1,", 0, "{}]\n", "" },
  { { "suffix", "--fill", "{}" }, '{"a"', 0, ":{}}\n", "" },
  { { "suffix", "--fill", "[]" }, '{"a":1,', 0, '"":[]}\n', "" },
  { { "suffix", "--fill", '""' }, '{"k', 0, '":""}\n', "" },
  { { "suffix" }, '"\\u0', 0, '000"\n', "" },
  { { "suffix" }, '"x\\', 0, '\\\\"\n', "" },
  { { "suffix" }, "-", 0, "0\n", "" },
  { { "suffix" }, "[01]", 1, "", "tailclose: invalid JSON at byte 2: unexpected byte 0x31\n" },
}

harness.check_rows(rows)
