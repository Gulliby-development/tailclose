local harness = require("spec.harness")

local rows = {
  { { "close", "x" }, "", 2, "", "tailclose: unexpected argument x\n" },
  { { "close", "" }, "", 2, "", "tailclose: unexpected argument \n" },
  { { "path", "x" }, "", 2, "", "tailclose: unexpected argument x\n" },
  { { "where", "y", "z" }, "", 2, "", "tailclose: unexpected argument y\n" },
  { { "check", "--nope" }, "", 2, "", "tailclose: unknown option --nope\n" },
  { { "close", "--nope", "x" }, "", 2, "", "tailclose: unknown option --nope\n" },
  { { "close", "x", "--nope" }, "", 2, "", "tailclose: unexpected argument x\n" },
  { { "check", "--fill", "0" }, "", 2, "", "tailclose: unknown option --fill\n" },
  { { "where", "--fill" }, "", 2, "", "tailclose: unknown option --fill\n" },
  { { "close", "--fill" }, "", 2, "", "tailclose: missing value for --fill\n" },
  { { "close", "--fill", "x" }, "", 2, "", "tailclose: bad value for --fill\n" },
  { { "close", "--fill", "NULL" }, "", 2, "", "tailclose: bad value for --fill\n" },
  { { "suffix", "--fill", "" }, "", 2, "", "tailclose: bad value for --fill\n" },
  { { "close", "--fill", "--fill" }, "", 2, "", "tailclose: bad value for --fill\n" },
  { { "close", "--fill", "0", "--fill", "x" }, "", 2, "", "tailclose: given twice: --fill\n" },
  { { "suffix", "--fill", '""' }, '{"a":', 0, '""}\n', "" },
}

harness.check_rows(rows)
