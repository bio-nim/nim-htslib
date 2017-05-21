# vim: sw=2 ts=2 sts=2 tw=0 et:
##   test/hfile.c -- Test cases for low-level input/output streams.
##
##     Copyright (C) 2013-2014, 2016 Genome Research Ltd.
##
##     Author: John Marshall <jm18@sanger.ac.uk>
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
## THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
## DEALINGS IN THE SOFTWARE.

import
  htslib/hfile #, htslib/hts_defs
from os import nil
from posix import nil
from strutils import `%`, toHex

const
  EOF = -1

proc strlen*(s: ptr char): cint {.importc, header:"string.h", cdecl.}
proc strcmp*(s, t: ptr char): cint {.importc, header:"string.h", cdecl.}

proc fail*(format: string, msg: varargs[string, `$`]) =
  var fullmsg: string = format % msg
  var err: cint = posix.errno
  if err != 0:
    fullmsg = fullmsg & ": " & os.osErrorMsg()
  os.raiseOSError(fullmsg)

proc check_offset*(f: ptr hFILE; off: off_t; message: cstring) =
  var ret: off_t = htell(f)
  if ret < 0: fail("htell($#)", message)
  if ret == off: return
  fail("$# offset incorrect: expected $# but got $#\L", message,
          cast[clong](off), cast[clong](ret))

proc slurp*(filename: string): cstring =
  return system.readFile(filename).string.cstring

var fin*: ptr hFILE = nil

var fout*: ptr hFILE = nil

var arbitrary_existing_fn*: string = "/Users/cdunn2001/repo/gh/htslib/vcf.c"

proc reopen*(infname: string; outfname: string) =
  if nil != fin:
    if hclose(fin) != 0: fail("hclose(input)")
  if nil != fout:
    if hclose(fout) != 0: fail("hclose(output)")
  #echo "reopen($#, $#)" % [infname, outfname]
  fin = hopen(infname, "r")
  if fin == nil: fail("hopen(\"$#\", \'r\')", infname)
  fout = hopen(outfname, "w")
  if fout == nil: fail("hopen(\"$#\", \'w\')", outfname)
 
proc main*(): cint =
  var size = [1, 13, 403, 999, 30000]
  var buffer: array[40000, char]
  var
    c: cint
    i: cint
  var n: csize
  var off: off_t
  reopen(arbitrary_existing_fn, "test/hfile1.tmp")
  while true:
    c = hgetc(fin)
    if c == EOF: break
    if hputc(c, fout) == EOF: fail("hputc")
  if 0 != herrno(fin):
    posix.errno = herrno(fin)
    fail("hgetc")
  reopen("test/hfile1.tmp", "test/hfile2.tmp")
  if hpeek(fin, addr buffer[0], 50) < 0: fail("hpeek")
  var total = 0
  while true:
    n = hread(fin, addr buffer[0], 17)
    if n <= 0: break
    total += n
    if hwrite(fout, addr buffer[0], n) != n: fail("hwrite")
  if n < 0: fail("hread")
  reopen("test/hfile2.tmp", "test/hfile3.tmp")
  while true:
    n = hread(fin, addr buffer[0], sizeof(buffer).csize)
    if n <= 0: break
    if hwrite(fout, addr buffer[0], n) != n: fail("hwrite")
    if hpeek(fin, addr buffer[0], 700) < 0: fail("hpeek")
  if n < 0: fail("hread")
  reopen("test/hfile3.tmp", "test/hfile4.tmp")
  i = 0
  off = 0
  while true:
    n = hread(fin, addr buffer[0], size[i mod 5])
    inc(i)
    if n <= 0: break
    inc(off, n)
    buffer[n] = '\0'
    check_offset(fin, off, "pre-peek")
    if hputs(addr buffer[0], fout) == EOF: fail("hputs")
    n = hpeek(fin, addr buffer[0], size[(i + 3) mod 5])
    if n < 0: fail("hpeek")
    check_offset(fin, off, "post-peek")
  if n < 0: fail("hread")
  #[
  reopen("test/hfile4.tmp", "test/hfile5.tmp")
  while hgets(addr buffer[0], 80, fin) != nil:
    var slen: csize = strlen(addr buffer[0])
    if slen > 79: fail("hgets read $# bytes, should be < 80", slen)
    if hwrite(fout, addr buffer[0], slen) != slen: fail("hwrite")
  if herrno(fin) != 0: fail("hgets")
  ]#
  reopen("test/hfile4.tmp", "test/hfile6.tmp")
  n = hread(fin, addr buffer[0], 200)
  if n < 0: fail("hread")
  elif n != 200: fail("hread only got $#", n)
  if hwrite(fout, addr buffer[0], 1000) != 1000: fail("hwrite")
  check_offset(fin, 200, "input/first200")
  check_offset(fout, 1000, "output/first200")
  if hseek(fin, 800, posix.SEEK_CUR) < 0: fail("hseek/cur")
  check_offset(fin, 1000, "input/seek")
  off = 1000
  while true:
    n = hread(fin, addr buffer[0], sizeof(buffer))
    if n <= 0: break
    if hwrite(fout, addr buffer[0], n) != n: fail("hwrite")
    inc(off, n)
  if n < 0: fail("hread")
  check_offset(fin, off, "input/eof")
  check_offset(fout, off, "output/eof")
  if hseek(fin, 200, posix.SEEK_SET) < 0: fail("hseek/set")
  if hseek(fout, 200, posix.SEEK_SET) < 0: fail("hseek(output)")
  check_offset(fin, 200, "input/backto200")
  check_offset(fout, 200, "output/backto200")
  n = hread(fin, addr buffer[0], 800)
  if n < 0: fail("hread")
  elif n != 800: fail("hread only got $#", n)
  if hwrite(fout, addr buffer[0], 800) != 800: fail("hwrite")
  check_offset(fin, 1000, "input/wrote800")
  check_offset(fout, 1000, "output/wrote800")
  if hflush(fout) == EOF: fail("hflush")
  let original = slurp(arbitrary_existing_fn)
  i = 0
  while true:
    inc(i)
    if i > 6: break
    if i == 5: continue
    let fn = "test/hfile$#.tmp" % [$i]
    let text = slurp(fn)
    if text != original:
      fail("$# differs from $#\L", fn, arbitrary_existing_fn)
  if hclose(fin) != 0: fail("hclose(input)")
  if hclose(fout) != 0: fail("hclose(output)")
  fout = hopen("test/hfile_chars.tmp", "w")
  if fout == nil: fail("hopen(\"test/hfile_chars.tmp\")")
  i = 0
  while i < 256:
    if hputc(i, fout) != i: fail("chars: hputc (%d)", i)
    inc(i)
  if hclose(fout) != 0: fail("hclose(test/hfile_chars.tmp)")
  fin = hopen("test/hfile_chars.tmp", "r")
  if fin == nil: fail("hopen(\"test/hfile_chars.tmp\") for reading")
  i = 0
  while i < 256:
    c = hgetc(fin)
    if c != i:
      fail("chars: hgetc ($# = 0x$#) returned $# = 0x$#",
        i, toHex(i), c, toHex(c))
    inc(i)
  c = hgetc(fin)
  if c != EOF: fail("chars: hgetc (EOF) returned $#", c)
  if hclose(fin) != 0: fail("hclose(test/hfile_chars.tmp) for reading")
  fin = hopen("data:,hello, world!%0A", "r")
  if fin == nil: fail("hopen(\"data:...\")")
  n = hread(fin, addr buffer[0], 300)
  if n < 0: fail("hread")
  buffer[n] = '\0'
  var expected = "hello, world!\x0A".cstring
  if strcmp(addr buffer[0], addr expected[0]) != 0: fail("hread result")
  if hclose(fin) != 0: fail("hclose(\"data:...\")")
  fin = hopen("test/xx#blank.sam", "r")
  if fin == nil: fail("hopen(\"test/xx#blank.sam\") for reading")
  if hread(fin, addr buffer[0], 100) != 0: fail("test/xx#blank.sam is non-empty")
  if hclose(fin) != 0: fail("hclose(\"test/xx#blank.sam\") for reading")
  fin = hopen("data:,", "r")
  if fin == nil: fail("hopen(\"data:\") for reading")
  if hread(fin, addr buffer[0], 100) != 0: fail("empty data: URL is non-empty")
  if hclose(fin) != 0: fail("hclose(\"data:\") for reading")
  fin = hopen("data:;base64,TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=",
            "r")
  if fin == nil: fail("hopen(\"data:;base64,...\")")
  n = hread(fin, addr buffer[0], 300)
  if n < 0: fail("hread for base64")
  buffer[n] = '\0'
  var expected1 = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.".cstring
  if strcmp(addr buffer[0], addr expected1[0]) != 0:
    fail("hread result for base64")
  if hclose(fin) != 0: fail("hclose(\"data:;base64,...\")")
  return QuitSuccess

when isMainModule:
  programResult = main()
