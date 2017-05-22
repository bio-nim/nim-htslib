# Package

version       = "0.1.0"
author        = "Christopher Dunn"
description   = "Nim wrapper for htslib (and maybe someday samtools)"
license       = "MIT"
#bin = @["main"]
srcDir        = "src"

# Dependencies

requires "nim >= 0.17.0"

task test, "Runs the test suite":
  #exec "nim c --listCmd -r tests/main.nim"
  exec "make -C tests/ run-main test"
