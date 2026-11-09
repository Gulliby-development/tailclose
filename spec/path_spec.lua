local harness = require("spec.harness")

local rows = {
  { { "path" }, "", 0, "$\n", "" },
  { { "path" }, "[", 0, "$[0]\n", "" },
  { { "path" }, "[1,2,", 0, "$[2]\n", "" },
  { { "path" }, '{"a":', 0, "$.a\n", "" },
  { { "path" }, '{"a":[1,{"b":', 0, "$.a[1].b\n", "" },
  { { "path" }, '{"a":1,"b', 0, "$\n", "" },
  { { "path" }, '{"a b":[', 0, '$["a b"][0]\n', "" },
  { { "path" }, '{"":1', 0, '$[""]\n', "" },
  { { "path" }, '{"1a":tr', 0, '$["1a"]\n', "" },
  { { "path" }, '{"_x1"', 0, "$._x1\n", "" },
  { { "path" }, '{"a":{"b":1},', 0, "$\n", "" },
  { { "path" }, '{"k\\"q":', 0, '$["k\\\\"q"]\n', "" },
  { { "path" }, '{"a":01', 1, "", "tailclose: invalid JSON at byte 6: unexpected byte 0x31\n" },
}

harness.check_rows(rows)
