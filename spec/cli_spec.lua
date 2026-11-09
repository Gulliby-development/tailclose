local harness = require("spec.harness")

local rows = {
  { {}, "", 2, "", "usage: tailclose close [--fill VALUE]\n       tailclose suffix [--fill VALUE]\n       tailclose path\n       tailclose where\n       tailclose check\n" },
  { { "help" }, "", 0, "usage: tailclose close [--fill VALUE]\n       tailclose suffix [--fill VALUE]\n       tailclose path\n       tailclose where\n       tailclose check\n", "" },
  { { "-h", "extra" }, "", 0, "usage: tailclose close [--fill VALUE]\n       tailclose suffix [--fill VALUE]\n       tailclose path\n       tailclose where\n       tailclose check\n", "" },
  { { "--help", "--bogus" }, "", 0, "usage: tailclose close [--fill VALUE]\n       tailclose suffix [--fill VALUE]\n       tailclose path\n       tailclose where\n       tailclose check\n", "" },
  { { "--version" }, "", 0, "tailclose 0.1.0\n", "" },
  { { "--version", "x" }, "", 0, "tailclose 0.1.0\n", "" },
  { { "frob" }, "", 2, "", "tailclose: unknown command frob\n" },
  { { "" }, "", 2, "", "tailclose: unknown command \n" },
  { { "Close" }, "", 2, "", "tailclose: unknown command Close\n" },
  { { "--fill" }, "", 2, "", "tailclose: unknown command --fill\n" },
  { { "--fill", "0" }, "", 2, "", "tailclose: unknown command --fill\n" },
  { { "help", "close" }, "", 0, "usage: tailclose close [--fill VALUE]\n       tailclose suffix [--fill VALUE]\n       tailclose path\n       tailclose where\n       tailclose check\n", "" },
}

harness.check_rows(rows)
