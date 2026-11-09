local harness = require("spec.harness")

local rows = {
  { { "close" }, "", 0, "null\n", "" },
  { { "close" }, " \n", 0, " \\nnull\n", "" },
  { { "close" }, '{"a":1}', 0, '{"a":1}\n', "" },
  { { "close" }, "[1,", 0, "[1,null]\n", "" },
  { { "close" }, '{"a":', 0, '{"a":null}\n', "" },
  { { "close" }, '{"a"', 0, '{"a":null}\n', "" },
  { { "close" }, '{"a":"x', 0, '{"a":"x"}\n', "" },
  { { "close" }, '{"a":"x\\', 0, '{"a":"x\\\\\\\\"}\n', "" },
  { { "close" }, '["\\u00', 0, '["\\\\u0000"]\n', "" },
  { { "close" }, "[tru", 0, "[true]\n", "" },
  { { "close" }, "[-", 0, "[-0]\n", "" },
  { { "close" }, "[1.", 0, "[1.0]\n", "" },
  { { "close" }, '{"a":[1,{"b":tr', 0, '{"a":[1,{"b":true}]}\n', "" },
  { { "close" }, '{"a":1,', 0, '{"a":1,"":null}\n', "" },
  { { "close" }, "[1,2", 0, "[1,2]\n", "" },
  { { "close" }, '{"a":[{"b":[', 0, '{"a":[{"b":[]}]}\n', "" },
  { { "close" }, "[1,\n\t", 0, "[1,\\n\\tnull]\n", "" },
  { { "close" }, "[1}", 1, "", "tailclose: invalid JSON at byte 2: unexpected byte 0x7d\n" },
}

harness.check_rows(rows)
