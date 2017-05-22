from strutils import `%`

proc capture(command, input="", cache:string =""): string =
    let (stdout, rc) = gorgeEx(command, input, cache)
    if rc != 0:
        let msg = "$# <- $#" % [$rc, command]
        doAssert(false, msg)
    return stdout

let sha1 = gorge("it rev-parse HEAD")
#echo sha1
let passC = capture("pkg-config --cflags htslib", "", sha1)
#echo passC
let passL = capture("pkg-config --libs --static htslib", "", sha1)
#echo passL
let modversion = capture("pkg-config --modversion htslib", "", sha1)
#echo modversion

switch("passC", passC)
switch("passL", passL)
switch("define", "htslib_modversion="&modversion)

hint("XDeclaredButNotUsed", false)
warning("SmallLshouldNotBeUsed", false)
