# vim: sw=2 ts=2 sts=2 tw=80 et:
#{.passC: "-g -Wall -I./inc".}
#{.passL: "-Lpbbam/third-party/htslib/build/ -lhts -lz".}
##   test/test-vcf-api.c -- VCF test harness.
## 
##     Copyright (C) 2013, 2014 Genome Research Ltd.
## 
##     Author: Petr Danecek <pd3@sanger.ac.uk>
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
from strutils import `%`
from kstring import nil
import wrap, common, hts, vcf
import os

usePtr[int32]()
usePtr[cfloat]()

proc free*(p: pointer) {.cdecl,
    importc: "free", header: "stdlib.h".}

proc write_bcf*(fname: cstring) =
  ##  Init
  var xfp = wrap.initXHtsFile($fname, "wb")
  var fp: ptr htsFile = xfp.cptr #hts_open(fname, "wb")
  var hdr: ptr bcf_hdr_t = bcf_hdr_init("w")
  assert(not hdr.isnil)
  var rec: ptr bcf1_t = bcf_init1()
  ##  Create VCF header
  #var str: kstring_t = kstring_t(L:0, m:0, s:nil)
  bcf_hdr_append(hdr, "##fileDate=20090805")
  bcf_hdr_append(hdr, "##FORMAT=<ID=UF,Number=1,Type=Integer,Description=\"Unused FORMAT\">")
  bcf_hdr_append(hdr, "##INFO=<ID=UI,Number=1,Type=Integer,Description=\"Unused INFO\">")
  bcf_hdr_append(hdr, "##FILTER=<ID=Flt,Description=\"Unused FILTER\">")
  bcf_hdr_append(hdr, "##unused=<XX=AA,Description=\"Unused generic\">")
  bcf_hdr_append(hdr, "##unused=unformatted text 1")
  bcf_hdr_append(hdr, "##unused=unformatted text 2")
  bcf_hdr_append(hdr, "##contig=<ID=Unused,length=62435964>")
  bcf_hdr_append(hdr, "##source=myImputationProgramV3.1")
  bcf_hdr_append(hdr, "##reference=file:///seq/references/1000GenomesPilot-NCBI36.fasta")
  bcf_hdr_append(hdr, "##contig=<ID=20,length=62435964,assembly=B36,md5=f126cdf8a6e0c7f379d618ff66beb2da,species=\"Homo sapiens\",taxonomy=x>")
  bcf_hdr_append(hdr, "##phasing=partial")
  bcf_hdr_append(hdr, "##INFO=<ID=NS,Number=1,Type=Integer,Description=\"Number of Samples With Data\">")
  bcf_hdr_append(hdr, "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">")
  bcf_hdr_append(hdr, "##INFO=<ID=AF,Number=A,Type=Float,Description=\"Allele Frequency\">")
  bcf_hdr_append(hdr, "##INFO=<ID=AA,Number=1,Type=String,Description=\"Ancestral Allele\">")
  bcf_hdr_append(hdr, "##INFO=<ID=DB,Number=0,Type=Flag,Description=\"dbSNP membership, build 129\">")
  bcf_hdr_append(hdr, "##INFO=<ID=H2,Number=0,Type=Flag,Description=\"HapMap2 membership\">")
  bcf_hdr_append(hdr, "##FILTER=<ID=q10,Description=\"Quality below 10\">")
  bcf_hdr_append(hdr, "##FILTER=<ID=s50,Description=\"Less than 50% of samples have data\">")
  bcf_hdr_append(hdr, "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">")
  bcf_hdr_append(hdr, "##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"Genotype Quality\">")
  bcf_hdr_append(hdr, "##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read Depth\">")
  bcf_hdr_append(hdr, "##FORMAT=<ID=HQ,Number=2,Type=Integer,Description=\"Haplotype Quality\">")
  bcf_hdr_append(hdr, "##FORMAT=<ID=TS,Number=1,Type=String,Description=\"Test String\">")
  bcf_hdr_add_sample(hdr, "NA00001")
  bcf_hdr_add_sample(hdr, "NA00002")
  bcf_hdr_add_sample(hdr, "NA00003")
  bcf_hdr_add_sample(hdr, nil)
  ##  to update internal structures
  bcf_hdr_write(fp, hdr)
  ##  Add a record
  ##  20     14370   rs6054257 G      A       29   PASS   NS=3;DP=14;AF=0.5;DB;H2           GT:GQ:DP:HQ 0|0:48:1:51,51 1|0:48:8:51,51 1/1:43:5:.,.
  ##  .. CHROM
  rec.rid = bcf_hdr_name2id(hdr, "20")
  ##  .. POS
  rec.pos = 14369
  ##  .. ID
  bcf_update_id(hdr, rec, "rs6054257")
  ##  .. REF and ALT
  bcf_update_alleles_str(hdr, rec, "G,A")
  ##  .. QUAL
  rec.qual = 29
  ##  .. FILTER
  var tmpi: int32 = bcf_hdr_id2int(hdr, BCF_DT_ID, "PASS")
  bcf_update_filter(hdr, rec, addr(tmpi), 1)
  ##  .. INFO
  tmpi = 3
  bcf_update_info_int32(hdr, rec, "NS", addr(tmpi), 1)
  tmpi = 14
  bcf_update_info_int32(hdr, rec, "DP", addr(tmpi), 1)
  var tmpf: cfloat = 0.5
  bcf_update_info_float(hdr, rec, "AF", addr(tmpf), 1)
  bcf_update_info_flag(hdr, rec, "DB", nil, 1)
  bcf_update_info_flag(hdr, rec, "H2", nil, 1)
  ##  .. FORMAT
  var tmpia: ptr int32 = cast[ptr cint](alloc(
      bcf_hdr_nsamples(hdr) * 2 * sizeof((int))))
  tmpia[0] = bcf_gt_phased(0)
  tmpia[1] = bcf_gt_phased(0)
  tmpia[2] = bcf_gt_phased(1)
  tmpia[3] = bcf_gt_phased(0)
  tmpia[4] = bcf_gt_unphased(1)
  tmpia[5] = bcf_gt_unphased(1)
  bcf_update_genotypes(hdr, rec, tmpia, bcf_hdr_nsamples(hdr) * 2)
  tmpia[0] = 48
  tmpia[1] = 48
  tmpia[2] = 43
  bcf_update_format_int32(hdr, rec, "GQ", tmpia, bcf_hdr_nsamples(hdr))
  tmpia[0] = 1
  tmpia[1] = 8
  tmpia[2] = 5
  bcf_update_format_int32(hdr, rec, "DP", tmpia, bcf_hdr_nsamples(hdr))
  tmpia[0] = 51
  tmpia[1] = 51
  tmpia[2] = 51
  tmpia[3] = 51
  tmpia[4] = bcf_int32_missing
  tmpia[5] = bcf_int32_missing
  bcf_update_format_int32(hdr, rec, "HQ", tmpia, bcf_hdr_nsamples(hdr) * 2)
  var tmp_str = ["String1", "SomeOtherString2", "YetAnotherString3"]
  var c_tmp_str = allocCStringArray(tmp_str)
  bcf_update_format_string(hdr, rec, "TS", c_tmp_str, 3)
  deallocCStringArray(c_tmp_str)
  bcf_write1(fp, hdr, rec)
  ##  20     1110696 . A      G,T     67   .   NS=2;DP=10;AF=0.333,.;AA=T;DB GT 2 1   ./.
  bcf_clear1(rec)
  rec.rid = bcf_hdr_name2id(hdr, "20")
  rec.pos = 1110695
  bcf_update_alleles_str(hdr, rec, "A,G,T")
  rec.qual = 67
  tmpi = 2
  bcf_update_info_int32(hdr, rec, "NS", addr(tmpi), 1)
  tmpi = 10
  bcf_update_info_int32(hdr, rec, "DP", addr(tmpi), 1)
  var tmpfa: ptr cfloat = cast[ptr cfloat](alloc(2 * sizeof((float))))
  tmpfa[0] = 0.333
  bcf_float_set_missing(tmpfa[1])
  bcf_update_info_float(hdr, rec, "AF", tmpfa, 2)
  bcf_update_info_string(hdr, rec, "AA", "T".cstring)
  bcf_update_info_flag(hdr, rec, "DB", nil, 1)
  tmpia[0] = bcf_gt_phased(2)
  tmpia[1] = bcf_int32_vector_end
  tmpia[2] = bcf_gt_phased(1)
  tmpia[3] = bcf_int32_vector_end
  tmpia[4] = bcf_gt_missing
  tmpia[5] = bcf_gt_missing
  bcf_update_genotypes(hdr, rec, tmpia, bcf_hdr_nsamples(hdr) * 2)
  bcf_write1(fp, hdr, rec)
  dealloc(tmpia)
  dealloc(tmpfa)
  ##  Clean
  #free(str.s)
  bcf_destroy1(rec)
  bcf_hdr_destroy(hdr)

proc bcf_to_vcf*(fname: cstring) =
  var xfp = wrap.initXHtsFile($fname, "rb")
  var fp: ptr htsFile = xfp.cptr #hts_open(fname, "rb")
  var hdr: ptr bcf_hdr_t = bcf_hdr_read(fp)
  assert(not hdr.isnil)
  var rec: ptr bcf1_t = bcf_init1()
  var str_gz_fname = $fname & ".gz"
  var gz_fname = str_gz_fname.cstring
  var xout = wrap.initXHtsFile(str_gz_fname, "wg")
  var `out`: ptr htsFile = xout.cptr #hts_open(gz_name, "wg")
  var hdr_out: ptr bcf_hdr_t = bcf_hdr_dup(hdr)
  bcf_hdr_remove(hdr_out, BCF_HL_STR, "unused")
  bcf_hdr_remove(hdr_out, BCF_HL_GEN, "unused")
  bcf_hdr_remove(hdr_out, BCF_HL_FLT, "Flt")
  bcf_hdr_remove(hdr_out, BCF_HL_INFO, "UI")
  bcf_hdr_remove(hdr_out, BCF_HL_FMT, "UF")
  bcf_hdr_remove(hdr_out, BCF_HL_CTG, "Unused")
  bcf_hdr_write(`out`, hdr_out)
  while bcf_read1(fp, hdr, rec) >= 0:
    bcf_write1(`out`, hdr_out, rec)
    ##  Test problems caused by bcf1_sync: the data block
    ##  may be realloced, also the unpacked structures must
    ##  get updated.
    bcf_unpack(rec, BCF_UN_STR)
    bcf_update_id(hdr, rec, nil)
    bcf_update_format_int32(hdr, rec, "GQ", nil, 0)
    var dup: ptr bcf1_t = bcf_dup(rec)
    ##  force bcf1_sync call
    bcf_write1(`out`, hdr_out, dup)
    bcf_destroy1(dup)
    bcf_update_alleles_str(hdr_out, rec, "G,A")
    var tmpi: int32 = 99
    bcf_update_info_int32(hdr_out, rec, "DP", addr(tmpi), 1)
    var tmpia = [9'i32, 9'i32, 9'i32]
    bcf_update_format_int32(hdr_out, rec, "DP".cstring, cast[ptr int32](addr tmpia[0]), 3.cint)
    bcf_write1(`out`, hdr_out, rec)
  bcf_destroy1(rec)
  bcf_hdr_destroy(hdr)
  bcf_hdr_destroy(hdr_out)
  xout.close()
  var xgz_in = wrap.initXHtsFile(str_gz_fname, "r")
  var gz_in: ptr htsFile = xgz_in.cptr #hts_open(gz_fname, "r")
  var line: kstring.kstring_t = kstring.kstring_t(L:0, m:0, s:nil)
  while hts_getline(gz_in, kstring.KS_SEP_LINE, addr(line)) > 0:
    discard kstring.kputc('\x0A'.cint, addr(line))
    stdout.write(line.s, line.L)
  free(line.s)
  #dealloc(gz_fname)

proc `iterator`*(fname: cstring) =
  var xfp = wrap.initXHtsFile($fname, "r")
  var fp: ptr htsFile = xfp.cptr #hts_open(fname, "r")
  var hdr: ptr bcf_hdr_t = bcf_hdr_read(fp)
  var idx: ptr hts_idx_t
  var iter: ptr hts_itr_t
  bcf_index_build(fname, 0)
  idx = bcf_index_load(fname)
  iter = bcf_itr_queryi(idx, bcf_hdr_name2id(hdr, "20"), 1110600.cint, 1110800.cint)
  #iter = hts.hts_itr_query(idx, bcf_hdr_name2id(hdr, "20"), 1110600.cint, 1110800.cint, vcf.bcf_readrec)
  bcf_itr_destroy(iter)
  iter = bcf_itr_querys(idx, hdr, "20:1110600-1110800".cstring)
  bcf_itr_destroy(iter)
  hts_idx_destroy(idx)
  bcf_hdr_destroy(hdr)

proc test_get_info_values*(fname: cstring) =
  var xfp = wrap.initXHtsFile($fname, "r")
  var fp: ptr htsFile = xfp.cptr #hts_open(fname, "r")
  var hdr: ptr bcf_hdr_t = bcf_hdr_read(fp)
  var line: ptr bcf1_t = bcf_init()
  while bcf_read(fp, hdr, line) == 0:
    var afs: ptr cfloat = nil
    var count: cint = 0
    var ret: cint = bcf_get_info_float(hdr, line, "AF", addr(afs), addr(count))
    if line.pos == 14369:
      assert ret == 1
      assert afs[0] == 0.5
    else:
      assert ret == 2
      let myval: cfloat = 0.333
      assert afs[0] == myval
      assert bcf_float_is_missing(afs[1])
    free(afs) # actually, an array
  bcf_destroy(line)
  bcf_hdr_destroy(hdr)

proc write_format_values*(fname: cstring) =
  ##  Init
  var xfp = wrap.initXHtsFile($fname, "wb")
  var fp: ptr htsFile = xfp.cptr #hts_open(fname, "wb")
  var hdr: ptr bcf_hdr_t = bcf_hdr_init("w")
  var rec: ptr bcf1_t = bcf_init1()
  ##  Create VCF header
  bcf_hdr_append(hdr, "##contig=<ID=1>")
  bcf_hdr_append(hdr, "##FORMAT=<ID=TF,Number=1,Type=Float,Description=\"Test Float\">")
  bcf_hdr_add_sample(hdr, "S")
  bcf_hdr_add_sample(hdr, nil)
  ##  to update internal structures
  bcf_hdr_write(fp, hdr)
  ##  Add a record
  ##  .. FORMAT
  var test: array[4, cfloat]
  bcf_float_set_missing(test[0])
  assert common.isNan(cast[cfloat](0x7F800001))
  assert common.isNan(test[0])
  assert cast[uint32](test[0]) == 0x7F800001
  test[1] = 47.11
  bcf_float_set_vector_end(test[2])
  bcf_update_format_float(hdr, rec, "TF".cstring, test, 4)
  assert bcf_float_is_missing(test[0])
  let myval: cfloat = 47.11
  assert test[1] == myval
  assert bcf_float_is_vector_end(test[2])
  #assert bcf_float_is_vector_end(test[3])
  bcf_write1(xfp.cptr, hdr, rec)
  bcf_destroy1(rec)
  bcf_hdr_destroy(hdr)

proc check_format_values*(fname: cstring) =
  var xfp = wrap.initXHtsFile($fname, "r")
  var fp: ptr htsFile = xfp.cptr #hts_open(fname, "r")
  var hdr: ptr bcf_hdr_t = bcf_hdr_read(fp)
  var line: ptr bcf1_t = bcf_init()
  while bcf_read(fp, hdr, line) == 0:
    var values: ptr cfloat = nil
    var count: cint = 0
    var ret: cint = bcf_get_format_float(hdr, line, "TF", addr(values), addr(count))
    ##  NOTE the return value from bcf_get_format_float is different from
    ##  bcf_get_info_float in the sense that vector-end markers also count.
    assert (not values.isnil)
    assert ret == 4
    assert count >= ret
    assert bcf_float_is_missing(values[0])
    let myval: cfloat = 47.11
    assert values[1] == myval
    assert bcf_float_is_vector_end(values[2])
    assert bcf_float_is_vector_end(values[3])
    if ret != 4 or count < ret or not bcf_float_is_missing(values[0]) or
        values[1] != myval or not bcf_float_is_vector_end(values[2]) or
        not bcf_float_is_vector_end(values[3]):
      common.throw("bcf_get_format_float didn't produce the expected output.")
    free(values)
  bcf_destroy(line)
  bcf_hdr_destroy(hdr)

proc test_get_format_values*(fname: cstring) =
  write_format_values(fname)
  check_format_values(fname)

proc main*(args: seq[TaintedString]): int =
  var fname: cstring
  if args.len > 0:
    fname = args[0].string.cstring
  else:
    fname = "rmme.bcf"
  echo "fname=", fname
  ##  format test. quiet unless there's a failure
  test_get_format_values(fname)
  ##  main test. writes to stdout
  write_bcf(fname)
  bcf_to_vcf(fname)
  `iterator`(fname)
  ##  additional tests. quiet unless there's a failure.
  test_get_info_values(fname)
  return 0

if isMainModule:
  programResult = main(os.commandLineParams())
