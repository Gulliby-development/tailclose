local harness = require("spec.harness")

local rows = {
  { { "where" }, "", 0, "start\n", "" },
  { { "where" }, "  [", 0, "open\n", "" },
  { { "where" }, '{"a', 0, "key\n", "" },
  { { "where" }, '{"a"', 0, "colon\n", "" },
  { { "where" }, '{"a":', 0, "value\n", "" },
  { { "where" }, "[1,", 0, "value\n", "" },
  { { "where" }, '"ab', 0, "string\n", "" },
  { { "where" }, "[12", 0, "number\n", "" },
  { { "where" }, "[nu", 0, "literal\n", "" },
  { { "where" }, "[1 ", 0, "after\n", "" },
  { { "where" }, '{"a":1,', 0, "member\n", "" },
  { { "where" }, '{"a":1}', 0, "done\n", "" },
  { { "where" }, "[,", 1, "", "tailclose: invalid JSON at byte 1: unexpected byte 0x2c\n" },
}

harness.check_rows(rows)
