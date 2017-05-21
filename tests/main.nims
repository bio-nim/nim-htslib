echo "hi"

include "../src/setup.nims"

task build, "default build is via the C backend":
  echo "where"
  setCommand "dump"
