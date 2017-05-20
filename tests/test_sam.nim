##   test/sam.c -- SAM/BAM/CRAM API test cases.
##
##     Copyright (C) 2014-2017 Genome Research Ltd.
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
## #include <config.h>

##  Suppress message for faidx_fetch_nseq(), which we're intentionally testing

#import htslib/hts_defs

#template HTS_DEPRECATED*(message: untyped): void = nil

from strutils import `%`
from hts import nil
from os import nil
import
  sam, faidx, kstring

var status*: cint

proc fail*(fmt: string, vals: varargs[string, `$`]) =
  echo fmt
  status = QuitFailure

proc arr2(tag: cstring): array[2, char] =
  var tg: array[2, char]
  tg[0] = tag[0]
  tg[1] = tag[1]
  return tg

proc check_bam_aux_get*(aln: ptr bam1_t; tag: cstring; `type`: char): ptr uint8 =
  var p: ptr uint8 = bam_aux_get(aln, arr2(tag))
  if p != nil:
    if p[] == `type`.uint8: return p
    else: fail("%s field of type \'%c\', expected \'%c\'\x0A", tag, p[], `type`)
  else:
    fail("can\'t find %s field\x0A", tag)
  return nil

#[
# bam_auxB stuff is in a later version of htslib
proc check_int_B_array*(aln: ptr bam1_t; tag: cstring; nvals: uint32;
                       vals: ptr int64) =
  var p: ptr uint8
  p = check_bam_aux_get(aln, arr2(tag), 'B')
  if p != nil:
    var i: uint32
    if bam_auxB_len(p) != nvals:
      fail("Wrong length reported for %s field, got %u, expected %u\x0A", tag,
           bam_auxB_len(p), nvals)
    i = 0
    while i < nvals:
      if bam_auxB2i(p, i) != vals[i]:
        fail("Wrong value from bam_auxB2i for %s field index %u, got %", PRId64,
             " expected %", PRId64, "\x0A", tag, i, bam_auxB2i(p, i), vals[i])
      if bam_auxB2f(p, i) != cast[cdouble](vals[i]):
        fail("Wrong value from bam_auxB2f for %s field index %u, got %f expected %f\x0A",
             tag, i, bam_auxB2f(p, i), cast[cdouble](vals[i]))
      inc(i)
]#

const
  PI* = 3.141592653589793
  E* = 2.718281828459045
  HELLO* = "Hello, world!"
  NEW_HELLO* = "Yo, dude"
  BEEF* = "DEADBEEF"

proc strcmp(a: cstring, b:string): int =
  ## Only return 0 and 42
  if $a == b: return 0
  else: return 42

from common import nil
common.usePtr[uint8]()

proc memcmp(a: ptr uint8, b: string, num: int): int =
  ## Only return 0 and 42
  for i in 0..<num:
    if a[i].char != b[i]: return 42
  return 0

proc aux_fields1*(): cint =
  var sam = "data:,@SQ\x09SN:one\x09LN:1000\x0A@SQ\x09SN:two\x09LN:500\x0Ar1\x090\x09one\x09500\x0920\x098M\x09*\x090\x090\x09ATGCATGC\x09qqqqqqqq\x09XA:A:k\x09Xi:i:37\x09Xf:f:3.141592653589793\x09Xd:d:2.718281828459045\x09XZ:Z:Hello, world!\x09XH:H:DEADBEEF\x09XB:B:c,-2,0,+2\x09B0:B:i,-2147483648,-1,0,1,2147483647\x09B1:B:I,0,1,2147483648,4294967295\x09B2:B:s,-32768,-1,0,1,32767\x09B3:B:S,0,1,32768,65535\x09B4:B:c,-128,-1,0,1,127\x09B5:B:C,0,1,127,255\x09Bf:B:f,-3.14159,2.71828\x09ZZ:i:1000000\x09Y1:i:-2147483648\x09Y2:i:-2147483647\x09Y3:i:-1\x09Y4:i:0\x09Y5:i:1\x09Y6:i:2147483647\x09Y7:i:2147483648\x09Y8:i:4294967295\x0A"
  ##  Canonical form of the alignment record above, as output by sam_format1()
  var r1 = "r1\x090\x09one\x09500\x0920\x098M\x09*\x090\x090\x09ATGCATGC\x09qqqqqqqq\x09Xi:i:37\x09Xf:f:3.14159\x09Xd:d:2.71828\x09XZ:Z:Yo, dude\x09XH:H:DEADBEEF\x09XB:B:c,-2,0,2\x09B0:B:i,-2147483648,-1,0,1,2147483647\x09B1:B:I,0,1,2147483648,4294967295\x09B2:B:s,-32768,-1,0,1,32767\x09B3:B:S,0,1,32768,65535\x09B4:B:c,-128,-1,0,1,127\x09B5:B:C,0,1,127,255\x09Bf:B:f,-3.14159,2.71828\x09ZZ:i:1000000\x09Y1:i:-2147483648\x09Y2:i:-2147483647\x09Y3:i:-1\x09Y4:i:0\x09Y5:i:1\x09Y6:i:2147483647\x09Y7:i:2147483648\x09Y8:i:4294967295\x09N0:i:-1234\x09N1:i:1234"
  # Or without the NEW_HELLO sub
  var r0 = "r1\x090\x09one\x09500\x0920\x098M\x09*\x090\x090\x09ATGCATGC\x09qqqqqqqq\x09Xi:i:37\x09Xf:f:3.14159\x09Xd:d:2.71828\x09XZ:Z:Hello, world!\x09XH:H:DEADBEEF\x09XB:B:c,-2,0,2\x09B0:B:i,-2147483648,-1,0,1,2147483647\x09B1:B:I,0,1,2147483648,4294967295\x09B2:B:s,-32768,-1,0,1,32767\x09B3:B:S,0,1,32768,65535\x09B4:B:c,-128,-1,0,1,127\x09B5:B:C,0,1,127,255\x09Bf:B:f,-3.14159,2.71828\x09ZZ:i:1000000\x09Y1:i:-2147483648\x09Y2:i:-2147483647\x09Y3:i:-1\x09Y4:i:0\x09Y5:i:1\x09Y6:i:2147483647\x09Y7:i:2147483648\x09Y8:i:4294967295\x09N0:i:-1234\x09N1:i:1234"
  var `in`: ptr samFile = sam_open(sam, "r")
  var header: ptr bam_hdr_t = sam_hdr_read(`in`)
  var aln: ptr bam1_t = bam_init1()
  var p: ptr uint8
  var ks = kstring_t(L:0, m:0, s:nil)
  var b0vals: array[5, int64] = [- 2147483648'i64, - 1, 0, 1, 2147483647]
  ##  i
  var b1vals: array[4, int64] = [0'i64, 1, 2147483648, 4294967295]
  ##  I
  var b2vals: array[5, int64] = [- 32768'i64, - 1, 0, 1, 32767]
  ##  s
  var b3vals: array[4, int64] = [0'i64, 1, 32768, 65535]
  ##  S
  var b4vals: array[5, int64] = [- 128'i64, - 1, 0, 1, 127]
  ##  c
  var b5vals: array[4, int64] = [0'i64, 1, 127, 255]
  ##  C
  ##  NB: Floats not doubles below!
  ##  See https://randomascii.wordpress.com/2012/06/26/doubles-are-not-floats-so-dont-compare-them/
  var bfvals: array[2, cfloat] = [- 3.14159.cfloat, 2.71828]
  var ival: int32 = - 1234
  var uval: uint32 = 1234
  var
    nvals: csize = 2
    #i: csize
  if sam_read1(`in`, header, aln) >= 0:
    p = check_bam_aux_get(aln, "XA", 'A')
    if (p != nil) and bam_aux2A(p) != 'k':
      fail("XA field is \'%c\', expected \'k\'", bam_aux2A(p))
    discard bam_aux_del(aln, p)
    if bam_aux_get(aln, arr2("XA")) != nil: fail("XA field was not deleted")
    p = check_bam_aux_get(aln, "Xi", 'C')
    if (p != nil) and bam_aux2i(p) != 37:
      fail("Xi field is $#, expected 37" % $bam_aux2i(p))
    p = check_bam_aux_get(aln, "Xf", 'f')
    if (p != nil) and abs(bam_aux2f(p) - PI) > 1e-06:
      fail("Xf field is %.12f, expected pi", bam_aux2f(p))
    p = check_bam_aux_get(aln, "Xd", 'd')
    if (p != nil) and abs(bam_aux2f(p) - E) > 1e-06:
      fail("Xf field is %.12f, expected e", bam_aux2f(p))
    p = check_bam_aux_get(aln, "XZ", 'Z')
    if (p != nil) and strcmp(bam_aux2Z(p), HELLO) != 0:
      fail("XZ field is \"%s\", expected \"%s\"", bam_aux2Z(p), HELLO)
    ###bam_aux_update_str(aln, "XZ", strlen(NEW_HELLO) + 1, NEW_HELLO)
    ###p = check_bam_aux_get(aln, "XZ", 'Z')
    ###if (p != nil) and
    ###    strcmp(bam_aux2Z(p), NEW_HELLO) != 0:
    ###  fail("XZ field is \"%s\", expected \"%s\"", bam_aux2Z(p), NEW_HELLO)
    p = check_bam_aux_get(aln, "XH", 'H')
    if (p != nil) and strcmp(bam_aux2Z(p), BEEF) != 0:
      fail("XH field is \"%s\", expected \"%s\"", bam_aux2Z(p), BEEF)
    p = check_bam_aux_get(aln, "XB", 'B')
    if (p != nil) and
        not (memcmp(p, "Bc", 2) == 0 and
        memcmp(p + 2, "\x03\0\0\0\xFE\0\x02", 7) == 0):
      fail("XB field is %c,..., expected c,-2,0,+2", p[1])
    #[
    check_int_B_array(aln, "B0", sizeof((b0vals) div sizeof((b0vals[0]))), b0vals)
    check_int_B_array(aln, "B1", sizeof((b1vals) div sizeof((b1vals[0]))), b1vals)
    check_int_B_array(aln, "B2", sizeof((b2vals) div sizeof((b2vals[0]))), b2vals)
    check_int_B_array(aln, "B3", sizeof((b3vals) div sizeof((b3vals[0]))), b3vals)
    check_int_B_array(aln, "B4", sizeof((b4vals) div sizeof((b4vals[0]))), b4vals)
    check_int_B_array(aln, "B5", sizeof((b5vals) div sizeof((b5vals[0]))), b5vals)
    p = check_bam_aux_get(aln, "Bf", 'B')
    if p != nil:
      if bam_auxB_len(p) != nvals:
        fail("Wrong length reported for Bf field, got %d, expected %zd\x0A",
             bam_auxB_len(p), nvals)
      i = 0
      while i < nvals:
        if bam_auxB2f(p, i) != bfvals[i]:
          fail("Wrong value from bam_auxB2f for Bf field index %zd, got %f expected %f\x0A",
               i, bam_auxB2f(p, i), bfvals[i])
        inc(i)
]#
    p = check_bam_aux_get(aln, "ZZ", 'I')
    if (p != nil) and bam_aux2i(p) != 1000000:
      fail("ZZ field is $#, expected 1000000" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y1"))
    if (p != nil) and bam_aux2i(p) != - 2147483647 - 1:
      fail("Y1 field is $#, expected -2^31" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y2"))
    if (p != nil) and bam_aux2i(p) != - 2147483647:
      fail("Y2 field is $#, expected -2^31+1" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y3"))
    if (p != nil) and bam_aux2i(p) != - 1:
      fail("Y3 field is $#, expected -1" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y4"))
    if (p != nil) and bam_aux2i(p) != 0:
      fail("Y4 field is $#, expected 0" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y5"))
    if (p != nil) and bam_aux2i(p) != 1:
      fail("Y5 field is $#, expected 1" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y6"))
    if (p != nil) and bam_aux2i(p) != 2147483647:
      fail("Y6 field is $#, expected 2^31-1" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y7"))
    if (p != nil) and cast[uint32](bam_aux2i(p)).int64 != 2147483648'i64:
      fail("Y7 field is $#, expected 2^31" % $bam_aux2i(p))
    p = bam_aux_get(aln, arr2("Y8"))
    if (p != nil) and cast[uint32](bam_aux2i(p)).int64 != 4294967295'i64:
      fail("Y8 field is $#, expected 2^32-1" % $bam_aux2i(p))
    if bam_aux_append(aln, arr2("N0"), 'i', sizeof((ival)).cint, cast[ptr uint8](addr(ival))) !=
        0:
      fail("Failed to append N0:i tag")
    p = bam_aux_get(aln, arr2("N0"))
    if (p != nil) and bam_aux2i(p) != ival:
      fail("N0 field is $#, expected %d" % $bam_aux2i(p), ival)
    if bam_aux_append(aln, arr2("N1"), 'I', sizeof((uval)).cint, cast[ptr uint8](addr(uval))) !=
        0:
      fail("failed to append N1:I tag")
    p = bam_aux_get(aln, arr2("N1"))
    if (p != nil) and bam_aux2i(p).uint32 != uval:
      fail("N1 field is $#, expected %u" % $bam_aux2i(p), uval)
    if sam_format1(header, aln, addr(ks)) < 0: fail("can\'t format record")
    if strcmp(ks.s, r0) != 0: fail("record formatted incorrectly:\L$#\L$#\n" % [$ks.s, r0]) # or r1 if updated
    #free(ks.s)
  else:
    fail("can\'t read record")
  bam_destroy1(aln)
  bam_hdr_destroy(header)
  discard sam_close(`in`)
  return 1

proc iterators1*() =
  hts.hts_itr_destroy(sam_itr_queryi(nil, hts.HTS_IDX_REST, 0, 0))
  hts.hts_itr_destroy(sam_itr_queryi(nil, hts.HTS_IDX_NONE, 0, 0))

proc copy_check_alignment*(infname: cstring; informat: cstring; outfname: cstring;
                          outmode: cstring; outref: cstring) =
  var `in`: ptr samFile = sam_open(infname, "r")
  var `out`: ptr samFile = sam_open(outfname, outmode)
  var aln: ptr bam1_t = bam_init1()
  var header: ptr bam_hdr_t
  if not outref.isnil:
    if hts.hts_set_opt(`out`, hts.CRAM_OPT_REFERENCE, outref) < 0:
      fail("setting reference %s for %s", outref, outfname)
  header = sam_hdr_read(`in`)
  if sam_hdr_write(`out`, header) < 0: fail("writing headers to %s", outfname)
  while sam_read1(`in`, header, aln) >= 0:
    var mod4: cint = (cast[ByteAddress](sam.bam_get_cigar(aln))) mod 4
    if mod4 != 0:
      fail("%s CIGAR not 4-byte aligned; offset is 4k+%d for \"%s\"", informat,
           mod4, bam_get_qname(aln))
    if sam_write1(`out`, header, aln) < 0: fail("writing to %s", outfname)
  bam_destroy1(aln)
  bam_hdr_destroy(header)
  discard sam_close(`in`)
  discard sam_close(`out`)

proc samrecord_layout*() =
  var qnames = "data:,@SQ\x09SN:CHROMOSOME_II\x09LN:5000\x0Aa\x090\x09CHROMOSOME_II\x09100\x0910\x094M\x09*\x090\x090\x09ATGC\x09qqqq\x0Abc\x090\x09CHROMOSOME_II\x09200\x0910\x094M\x09*\x090\x090\x09ATGC\x09qqqq\x0Adef\x090\x09CHROMOSOME_II\x09300\x0910\x094M\x09*\x090\x090\x09ATGC\x09qqqq\x0Aghij\x090\x09CHROMOSOME_II\x09400\x0910\x094M\x09*\x090\x090\x09ATGC\x09qqqq\x0Aklmno\x090\x09CHROMOSOME_II\x09500\x0910\x094M\x09*\x090\x090\x09ATGC\x09qqqq\x0A"
  var
    bam1_t_size: csize
    bam1_t_size2: csize
  bam1_t_size = 36 + sizeof((int)) + 4 + sizeof(cstring)
  when not defined(BAM_NO_ID):
    inc(bam1_t_size, 8)
  bam1_t_size2 = bam1_t_size + 4
  ##  Account for padding on some platforms
  if sizeof((bam1_core_t)) != 36:
    fail("sizeof bam1_core_t is %zu, expected 36", sizeof((bam1_core_t)))
  if sizeof((bam1_t)) != bam1_t_size and sizeof((bam1_t)) != bam1_t_size2:
    fail("sizeof bam1_t is %zu, expected either %zu or %zu", sizeof((bam1_t)),
         bam1_t_size, bam1_t_size2)
  copy_check_alignment(qnames, "SAM", "test/sam_alignment.tmp.bam", "wb", nil)
  copy_check_alignment("test/sam_alignment.tmp.bam", "BAM",
                       "test/sam_alignment.tmp.cram", "wc", "test/ce.fa")
  copy_check_alignment("test/sam_alignment.tmp.cram", "CRAM",
                       "test/sam_alignment.tmp.sam_", "w", nil)

proc faidx1*(filename: string) =
  var
    n: cint
    n_exp: cint = 0
    tmpfilename: string
  #var
  #  line: array[500, char]
  block:
    var
      fin: File
      fout: File
    if not fin.open(filename):
      fail("can\'t open %s\x0A", filename)
    tmpfilename = "{}.tmp" % filename
    if not fout.open(tmpfilename, fmWrite):
      fail("can\'t create temporary %s\x0A", tmpfilename)
    for line in fin.lines():
      if line[0] == '>': inc(n_exp)
      fout.writeLine(line)
    fin.close()
    fout.close()
  if fai_build(tmpfilename) < 0: fail("can\'t index %s", tmpfilename)
  var fai: ptr faidx_t
  fai = fai_load(tmpfilename)
  if fai == nil: fail("can\'t load faidx file %s", tmpfilename)
  n = faidx_fetch_nseq(fai)
  if n != n_exp:
    fail("%s: faidx_fetch_nseq returned %d, expected %d", filename, n, n_exp)
  n = faidx_nseq(fai)
  if n != n_exp:
    fail("%s: faidx_nseq returned %d, expected %d", filename, n, n_exp)
  fai_destroy(fai)

proc check_enum1*() =
  ##  bgzf_compression() returns int, but enjoys this correspondence
  if hts.no_compression.int != 0: fail("no_compression is %d", hts.no_compression)
  if hts.gzip.int != 1: fail("gzip is %d", hts.gzip)
  if hts.bgzf.int != 2: fail("bgzf is %d", hts.bgzf)

proc main*(args: seq[string]): cint =
  status = QuitSuccess
  discard aux_fields1()
  iterators1()
  samrecord_layout()
  check_enum1()
  for arg in args:
    faidx1(arg)
  return status

when isMainModule:
  programResult = main(os.commandLineParams())
