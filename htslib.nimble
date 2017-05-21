# Package

version       = "0.1.0"
author        = "Christopher Dunn"
description   = "Nim wrapper for htslib (and maybe someday samtools)"
license       = "MIT"
bin = @["main"]
srcDir        = "src"

# Dependencies

requires "nim >= 0.17.0"

#--passC:"-DHELLO"
var cflags = staticExec("pkg-config --cflags htslib")
var ldflags = staticExec("pkg-config --libs htslib")
echo cflags, ldflags

from strutils import `%`
task test, "Runs the test suite":
  #exec "nim c --listCmd -r tests/main.nim"
  exec "nim c --passC:$# --passL:$# -r tests/main.nim" % [repr(cflags), repr(ldflags)]
