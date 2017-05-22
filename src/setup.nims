# vim: sw=2 ts=2 sts=2 tw=80 et:
from strutils import `%`

proc capture(command, input="", cache:string =""): string =
    let (stdout, rc) = gorgeEx(command, input, cache)
    if rc != 0:
        let msg = "$# <- $#" % [$rc, command]
        doAssert(false, msg)
    return stdout

let sha1 = gorge("git rev-parse HEAD")
#echo sha1
var
    modversion, passC, passL: string
try:
    modversion = capture("pkg-config --modversion htslib", "", sha1)
    passC = capture("pkg-config --cflags htslib", "", sha1)
    passL = capture("pkg-config --libs --static htslib", "", sha1)
except:
    modversion = getEnv("HTSLIB_VERSION")
    if modversion == "":
        modversion = getEnv("HTS_VERSION")
    passC = getEnv("CFLAGS")
    passL = getEnv("LDFLAGS")

#echo modversion
#echo passC
#echo passL
switch("passC", passC)
switch("passL", passL)
switch("define", "htslib_modversion="&modversion)

hint("XDeclaredButNotUsed", false)
warning("SmallLshouldNotBeUsed", false)
