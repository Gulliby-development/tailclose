local harness = require("spec.harness")

local rows = {
  { { "check" }, "", 0, "partial 4\ndepth 0 bytes 0\n", "" },
  { { "check" }, '{"a":1}', 0, "complete\ndepth 0 bytes 7\n", "" },
  { { "check" }, "[[1,2],[3", 0, "partial 2\ndepth 2 bytes 9\n", "" },
  { { "check" }, "12", 0, "complete\ndepth 0 bytes 2\n", "" },
  { { "check" }, '"x', 0, "partial 1\ndepth 0 bytes 2\n", "" },
  { { "check" }, "[1,]", 1, "invalid at byte 3: unexpected byte 0x5d\n", "" },
  { { "check" }, '{"a":1,}', 1, "invalid at byte 7: unexpected byte 0x7d\n", "" },
  { { "check" }, "{a", 1, "invalid at byte 1: unexpected byte 0x61\n", "" },
  { { "check" }, "[01]", 1, "invalid at byte 2: unexpected byte 0x31\n", "" },
  { { "check" }, "[1 2]", 1, "invalid at byte 3: unexpected byte 0x32\n", "" },
  { { "check" }, '"a\\q"', 1, "invalid at byte 3: unexpected byte 0x71\n", "" },
  { { "check" }, '"\\u12g4', 1, "invalid at byte 5: unexpected byte 0x67\n", "" },
  { { "check" }, '"a\tb"', 1, "invalid at byte 2: unexpected byte 0x09\n", "" },
  { { "check" }, "[[[[[[[[[", 1, "invalid at byte 8: nesting too deep (max 8)\n", "" },
  { { "check" }, "[[[[[[[[", 0, "partial 8\ndepth 8 bytes 8\n", "" },
  { { "check" }, "[1,[2,{}]", 0, "partial 1\ndepth 1 bytes 9\n", "" },
  { { "check" }, "{} x", 1, "invalid at byte 3: unexpected byte 0x78\n", "" },
  { { "check" }, '["01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 0, "partial 2\ndepth 1 bytes 100\n", "" },
  { { "check" }, '["012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678', 1, "", "tailclose: input is too long (max 100 bytes)\n" },
}

harness.check_rows(rows)
