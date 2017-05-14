# vim: sw=2 ts=2 sts=2 tw=80 et:
{.experimental.}
from common import nil
from hts import nil
from strutils import `%`

type
  PHtsFile = ptr hts.htsfile
  XHtsFile = object
    fname: string
    cptr*: ptr hts.htsFile

converter toPHtsFile(x: XHtsFile): ptr hts.htsFile = x.cptr

proc newXHtsFile*(fname: string, mode: string): ref XHtsFile =
  new(result)
  result.fname = fname
  result.cptr = hts.hts_open(fname, mode)
  if result.cptr.isnil:
    let msg = "Could not hts_open($1, $2)" % [repr(fname), repr(mode)]
    common.throw(msg)

proc close*(x: var XHtsFile) =
  let ret = hts.hts_close(x.cptr)
  x.cptr = nil
  if ret != 0:
    let msg = "hts_close($1): non-zero status $2" % [$x.fname, $ret]
    common.throw(msg)

proc `=destroy`*(x: var XHtsFile) =
  if not x.cptr.isnil:
    x.close()
