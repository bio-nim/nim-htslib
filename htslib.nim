# vim: sw=2 ts=2 sts=2 tw=80 et:
# EXPERIMENTAL - Ignore for now.
#{.compile: "DAZZ_DB/DB.c".}
#{.compile: "DAZZ_DB/QV.c".}

proc bar() =
  echo "BAR"
if isMainModule:
  bar()
