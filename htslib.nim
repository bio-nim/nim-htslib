# vim: sw=2 ts=2 sts=2 tw=80 et:
# EXPERIMENTAL - Ignore for now.
{.passC: "-g -Wall -Iinc".}
{.passC: "-L/Users/cdunn2001/repo/gh/pbbam/third-party/htslib/build -lhts".}
#{.compile: "DAZZ_DB/DB.c".}
#{.compile: "DAZZ_DB/QV.c".}

proc bar() =
  echo "BAR"
if isMainModule:
  bar()
