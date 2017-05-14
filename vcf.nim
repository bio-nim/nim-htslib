##   vcf.h -- VCF/BCF API functions.
## 
##     Copyright (C) 2012, 2013 Broad Institute.
##     Copyright (C) 2012-2014 Genome Research Ltd.
## 
##     Author: Heng Li <lh3@sanger.ac.uk>
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
## 
##     todo:
##         - make the function names consistent
##         - provide calls to abstract away structs as much as possible
## 

from strutils import `%`
import
  hts, kstring, common

## ****************
##  Header struct *
## ***************

const
  BCF_HL_FLT* = 0
  BCF_HL_INFO* = 1
  BCF_HL_FMT* = 2
  BCF_HL_CTG* = 3
  BCF_HL_STR* = 4
  BCF_HL_GEN* = 5
  BCF_HT_FLAG* = 0
  BCF_HT_INT* = 1
  BCF_HT_REAL* = 2
  BCF_HT_STR* = 3
  BCF_VL_FIXED* = 0
  BCF_VL_VAR* = 1
  BCF_VL_A* = 2
  BCF_VL_G* = 3
  BCF_VL_R* = 4

##  === Dictionary ===
## 
##    The header keeps three dictonaries. The first keeps IDs in the
##    "FILTER/INFO/FORMAT" lines, the second keeps the sequence names and lengths
##    in the "contig" lines and the last keeps the sample names. bcf_hdr_t::dict[]
##    is the actual hash table, which is opaque to the end users. In the hash
##    table, the key is the ID or sample name as a C string and the value is a
##    bcf_idinfo_t struct. bcf_hdr_t::id[] points to key-value pairs in the hash
##    table in the order that they appear in the VCF header. bcf_hdr_t::n[] is the
##    size of the hash table or, equivalently, the length of the id[] arrays.
## 

const
  BCF_DT_ID* = 0
  BCF_DT_CTG* = 1
  BCF_DT_SAMPLE* = 2

##  Complete textual representation of a header line

type
  bcf_hrec_t* {.importc: "bcf_hrec_t", header: "vcf.h".} = object
    `type`* {.importc: "type".}: cint ##  One of the BCF_HL_* type
    key* {.importc: "key".}: cstring ##  The part before '=', i.e. FILTER/INFO/FORMAT/contig/fileformat etc.
    value* {.importc: "value".}: cstring ##  Set only for generic lines, NULL for FILTER/INFO, etc.
    nkeys* {.importc: "nkeys".}: cint ##  Number of structured fields
    keys* {.importc: "keys".}: cstringArray
    vals* {.importc: "vals".}: cstringArray ##  The key=value pairs
  
  bcf_idinfo_t* {.importc: "bcf_idinfo_t", header: "vcf.h".} = object
    info* {.importc: "info".}: array[3, uint32] ##  stores Number:20, var:4, Type:4, ColType:4 for BCF_HL_FLT,INFO,FMT
    hrec* {.importc: "hrec".}: array[3, ptr bcf_hrec_t]
    id* {.importc: "id".}: cint

  bcf_idpair_t* {.importc: "bcf_idpair_t", header: "vcf.h".} = object
    key* {.importc: "key".}: cstring
    val* {.importc: "val".}: ptr bcf_idinfo_t

  bcf_hdr_t* {.importc: "bcf_hdr_t", header: "vcf.h".} = object
    n* {.importc: "n".}: array[3, int32]
    id* {.importc: "id".}: array[3, ptr bcf_idpair_t]
    dict* {.importc: "dict".}: array[3, pointer] ##  ID dictionary, contig dict and sample dict
    samples* {.importc: "samples".}: cstringArray
    hrec* {.importc: "hrec".}: ptr ptr bcf_hrec_t
    nhrec* {.importc: "nhrec".}: cint
    dirty* {.importc: "dirty".}: cint
    ntransl* {.importc: "ntransl".}: cint
    transl* {.importc: "transl".}: array[2, ptr cint] ##  for bcf_translate()
    nsamples_ori* {.importc: "nsamples_ori".}: cint ##  for bcf_hdr_set_samples()
    keep_samples* {.importc: "keep_samples".}: ptr uint8
    mem* {.importc: "mem".}: kstring.kstring_t


var bcf_type_shift* {.importc: "bcf_type_shift", header: "vcf.h".}: ptr uint8

## *************
##  VCF record *
## ************

const
  BCF_BT_NULL* = 0
  BCF_BT_INT8* = 1
  BCF_BT_INT16* = 2
  BCF_BT_INT32* = 3
  BCF_BT_FLOAT* = 5
  BCF_BT_CHAR* = 7
  VCF_REF* = 0
  VCF_SNP* = 1
  VCF_MNP* = 2
  VCF_INDEL* = 4
  VCF_OTHER* = 8

type
  INNER_C_UNION_988133268* {.importc: "no_name", header: "vcf.h".} = object {.union.}
    i* {.importc: "i".}: int32 ##  integer value
    f* {.importc: "f".}: cfloat  ##  float value
  
  variant_t* {.importc: "variant_t", header: "vcf.h".} = object
    `type`* {.importc: "type".}: cint
    n* {.importc: "n".}: cint    ##  variant type and the number of bases affected, negative for deletions
  
  bcf_fmt_t* {.importc: "bcf_fmt_t", header: "vcf.h".} = object
    id* {.importc: "id".}: cint  ##  id: numeric tag id, the corresponding string is bcf_hdr_t::id[BCF_DT_ID][$id].key
    n* {.importc: "n".}: cint
    size* {.importc: "size".}: cint
    `type`* {.importc: "type".}: cint ##  n: number of values per-sample; size: number of bytes per-sample; type: one of BCF_BT_* types
    p* {.importc: "p".}: ptr uint8 ##  same as vptr and vptr_* in bcf_info_t below
    p_len* {.importc: "p_len".}: uint32
    p_off* {.importc: "p_off", bitsize: 31.}: uint32
    p_free* {.importc: "p_free", bitsize: 1.}: uint32

  bcf_info_t* {.importc: "bcf_info_t", header: "vcf.h".} = object
    key* {.importc: "key".}: cint ##  key: numeric tag id, the corresponding string is bcf_hdr_t::id[BCF_DT_ID][$key].key
    `type`* {.importc: "type".}: cint
    len* {.importc: "len".}: cint ##  type: one of BCF_BT_* types; len: vector length, 1 for scalars
    v1* {.importc: "v1".}: INNER_C_UNION_988133268 ##  only set if $len==1; for easier access
    vptr* {.importc: "vptr".}: ptr uint8 ##  pointer to data array in bcf1_t->shared.s, excluding the size+type and tag id bytes
    vptr_len* {.importc: "vptr_len".}: uint32 ##  length of the vptr block or, when set, of the vptr_mod block, excluding offset
    vptr_off* {.importc: "vptr_off", bitsize: 31.}: uint32 ##  vptr offset, i.e., the size of the INFO key plus size+type bytes
    vptr_free* {.importc: "vptr_free", bitsize: 1.}: uint32 ##  indicates that vptr-vptr_off must be freed; set only when modified and the new
                                                           ##     data block is bigger than the original
  

const
  BCF1_DIRTY_ID* = 1
  BCF1_DIRTY_ALS* = 2
  BCF1_DIRTY_FLT* = 4
  BCF1_DIRTY_INF* = 8

type
  bcf_dec_t* {.importc: "bcf_dec_t", header: "vcf.h".} = object
    m_fmt* {.importc: "m_fmt".}: cint
    m_info* {.importc: "m_info".}: cint
    m_id* {.importc: "m_id".}: cint
    m_als* {.importc: "m_als".}: cint
    m_allele* {.importc: "m_allele".}: cint
    m_flt* {.importc: "m_flt".}: cint ##  allocated size (high-water mark); do not change
    n_flt* {.importc: "n_flt".}: cint ##  Number of FILTER fields
    flt* {.importc: "flt".}: ptr cint ##  FILTER keys in the dictionary
    id* {.importc: "id".}: cstring
    als* {.importc: "als".}: cstring ##  ID and REF+ALT block (\0-seperated)
    allele* {.importc: "allele".}: cstringArray ##  allele[0] is the REF (allele[] pointers to the als block); all null terminated
    info* {.importc: "info".}: ptr bcf_info_t ##  INFO
    fmt* {.importc: "fmt".}: ptr bcf_fmt_t ##  FORMAT and individual sample
    `var`* {.importc: "var".}: ptr variant_t ##  $var and $var_type set only when set_variant_types called
    n_var* {.importc: "n_var".}: cint
    var_type* {.importc: "var_type".}: cint
    shared_dirty* {.importc: "shared_dirty".}: cint ##  if set, shared.s must be recreated on BCF output
    indiv_dirty* {.importc: "indiv_dirty".}: cint ##  if set, indiv.s must be recreated on BCF output
  

const
  BCF_ERR_CTG_UNDEF* = 1
  BCF_ERR_TAG_UNDEF* = 2
  BCF_ERR_NCOLS* = 4

## 
##     The bcf1_t structure corresponds to one VCF/BCF line. Reading from VCF file
##     is slower because the string is first to be parsed, packed into BCF line
##     (done in vcf_parse), then unpacked into internal bcf1_t structure. If it
##     is known in advance that some of the fields will not be required (notably
##     the sample columns), parsing of these can be skipped by setting max_unpack
##     appropriately.
##     Similarly, it is fast to output a BCF line because the columns (kept in
##     shared.s, indiv.s, etc.) are written directly by bcf_write, whereas a VCF
##     line must be formatted in vcf_format.
## 

type
  bcf1_t* {.importc: "bcf1_t", header: "vcf.h".} = object
    rid* {.importc: "rid".}: int32 ##  CHROM
    pos* {.importc: "pos".}: int32 ##  POS
    rlen* {.importc: "rlen".}: int32 ##  length of REF
    qual* {.importc: "qual".}: cfloat ##  QUAL
    n_info* {.importc: "n_info", bitsize: 16.}: uint32
    n_allele* {.importc: "n_allele", bitsize: 16.}: uint32
    n_fmt* {.importc: "n_fmt", bitsize: 8.}: uint32
    n_sample* {.importc: "n_sample", bitsize: 24.}: uint32
    shared* {.importc: "shared".}: kstring.kstring_t
    indiv* {.importc: "indiv".}: kstring.kstring_t
    d* {.importc: "d".}: bcf_dec_t ##  lazy evaluation: $d is not generated by bcf_read(), but by explicitly calling bcf_unpack()
    max_unpack* {.importc: "max_unpack".}: cint ##  Set to BCF_UN_STR, BCF_UN_FLT, or BCF_UN_INFO to boost performance of vcf_parse when some of the fields won't be needed
    unpacked* {.importc: "unpacked".}: cint ##  remember what has been unpacked to allow calling bcf_unpack() repeatedly without redoing the work
    unpack_size* {.importc: "unpack_size".}: array[3, cint] ##  the original block size of ID, REF+ALT and FILTER
    errcode* {.importc: "errcode".}: cint ##  one of BCF_ERR_* codes

{.push hint[XDeclaredButNotUsed]: off.}
usePtr[bcf_idpair_t]()
usePtr[int8]()
usePtr[int16]()
usePtr[int32]()
usePtr[uint8]()
#usePtr[uint16]()
#usePtr[uint32]()
{.pop.}

## ******
##  API *
## *****

## **********************************************************************
##   BCF and VCF I/O
## 
##   A note about naming conventions: htslib internally represents VCF
##   records as bcf1_t data structures, therefore most functions are
##   prefixed with bcf_. There are a few exceptions where the functions must
##   be aware of both BCF and VCF worlds, such as bcf_parse vs vcf_parse. In
##   these cases, functions prefixed with bcf_ are more general and work
##   with both BCF and VCF.
## 
## *********************************************************************
## * These macros are defined only for consistency with other parts of htslib

template bcf_init1*(): untyped =
  bcf_init()

template bcf_read1*(fp, h, v: untyped): untyped =
  bcf_read((fp), (h), (v))

template vcf_read1*(fp, h, v: untyped): untyped =
  vcf_read((fp), (h), (v))

template bcf_write1*(fp, h, v: untyped): untyped =
  bcf_write((fp), (h), (v))

template vcf_write1*(fp, h, v: untyped): untyped =
  vcf_write((fp), (h), (v))

template bcf_destroy1*(v: untyped): untyped =
  bcf_destroy(v)

template vcf_parse1*(s, h, v: untyped): untyped =
  vcf_parse((s), (h), (v))

template bcf_clear1*(v: untyped): untyped =
  bcf_clear(v)

template vcf_format1*(h, v, s: untyped): untyped =
  vcf_format((h), (v), (s))

## *
##   bcf_hdr_init() - create an empty BCF header.
##   @param mode    "r" or "w"
## 
##   When opened for writing, the mandatory fileFormat and
##   FILTER=PASS lines are added automatically.
## 

proc bcf_hdr_init*(mode: cstring): ptr bcf_hdr_t {.cdecl, importc: "bcf_hdr_init",
    header: "vcf.h".}
## * Destroy a BCF header struct

proc bcf_hdr_destroy*(h: ptr bcf_hdr_t) {.cdecl, importc: "bcf_hdr_destroy",
                                      header: "vcf.h".}
## * Initialize a bcf1_t object; equivalent to calloc(1, sizeof(bcf1_t))

proc bcf_init*(): ptr bcf1_t {.cdecl, importc: "bcf_init", header: "vcf.h".}
## * Deallocate a bcf1_t object

proc bcf_destroy*(v: ptr bcf1_t) {.cdecl, importc: "bcf_destroy", header: "vcf.h".}
## *
##   Same as bcf_destroy() but frees only the memory allocated by bcf1_t,
##   not the bcf1_t object itself.
## 

proc bcf_empty*(v: ptr bcf1_t) {.cdecl, importc: "bcf_empty", header: "vcf.h".}
## *
##   Make the bcf1_t object ready for next read. Intended mostly for
##   internal use, the user should rarely need to call this function
##   directly.
## 

proc bcf_clear*(v: ptr bcf1_t) {.cdecl, importc: "bcf_clear", header: "vcf.h".}
## * bcf_open and vcf_open mode: please see hts_open() in hts.h

type
  vcfFile* = htsFile

template bcf_open*(fn, mode: untyped): untyped =
  hts_open((fn), (mode))

template vcf_open*(fn, mode: untyped): untyped =
  hts_open((fn), (mode))

template bcf_close*(fp: untyped): untyped =
  hts_close(fp)

template vcf_close*(fp: untyped): untyped =
  hts_close(fp)

## * Reads VCF or BCF header

proc bcf_hdr_read*(fp: ptr htsFile): ptr bcf_hdr_t {.cdecl, importc: "bcf_hdr_read",
    header: "vcf.h".}
## *
##   bcf_hdr_set_samples() - for more efficient VCF parsing when only one/few samples are needed
##   @samples: samples to include or exclude from file or as a comma-separated string.
##               LIST|FILE   .. select samples in list/file
##               ^LIST|FILE  .. exclude samples from list/file
##               -           .. include all samples
##               NULL        .. exclude all samples
##   @is_file: @samples is a file (1) or a comma-separated list (1)
## 
##   The bottleneck of VCF reading is parsing of genotype fields. If the
##   reader knows in advance that only subset of samples is needed (possibly
##   no samples at all), the performance of bcf_read() can be significantly
##   improved by calling bcf_hdr_set_samples after bcf_hdr_read().
##   The function bcf_read() will subset the VCF/BCF records automatically
##   with the notable exception when reading records via bcf_itr_next().
##   In this case, bcf_subset_format() must be called explicitly, because
##   bcf_readrec() does not see the header.
## 
##   Returns 0 on success, -1 on error or a positive integer if the list
##   contains samples not present in the VCF header. In such a case, the
##   return value is the index of the offending sample.
## 

proc bcf_hdr_set_samples*(hdr: ptr bcf_hdr_t; samples: cstring; is_file: cint): cint {.
    cdecl, importc: "bcf_hdr_set_samples", header: "vcf.h".}
proc bcf_subset_format*(hdr: ptr bcf_hdr_t; rec: ptr bcf1_t): cint {.cdecl,
    importc: "bcf_subset_format", header: "vcf.h".}
## * Writes VCF or BCF header

proc bcf_hdr_write*(fp: ptr htsFile; h: ptr bcf_hdr_t): cint {.cdecl,
    importc: "bcf_hdr_write", header: "vcf.h", discardable.}
## * Parse VCF line contained in kstring and populate the bcf1_t struct

proc vcf_parse*(s: ptr kstring.kstring_t; h: ptr bcf_hdr_t; v: ptr bcf1_t): cint {.cdecl,
    importc: "vcf_parse", header: "vcf.h".}
## * The opposite of vcf_parse. It should rarely be called directly, see vcf_write

proc vcf_format*(h: ptr bcf_hdr_t; v: ptr bcf1_t; s: ptr kstring.kstring_t): cint {.cdecl,
    importc: "vcf_format", header: "vcf.h".}
## *
##   bcf_read() - read next VCF or BCF record
## 
##   Returns -1 on critical errors, 0 otherwise. On errors which are not
##   critical for reading, such as missing header definitions, v->errcode is
##   set to one of BCF_ERR* code and must be checked before calling
##   vcf_write().
## 

proc bcf_read*(fp: ptr htsFile; h: ptr bcf_hdr_t; v: ptr bcf1_t): cint {.cdecl,
    importc: "bcf_read", header: "vcf.h".}
## *
##   bcf_unpack() - unpack/decode a BCF record (fills the bcf1_t::d field)
## 
##   Note that bcf_unpack() must be called even when reading VCF. It is safe
##   to call the function repeatedly, it will not unpack the same field
##   twice.
## 

const
  BCF_UN_STR* = 1
  BCF_UN_FLT* = 2
  BCF_UN_INFO* = 4
  BCF_UN_SHR* = (BCF_UN_STR or BCF_UN_FLT or BCF_UN_INFO) ##  all shared information
  BCF_UN_FMT* = 8
  BCF_UN_IND* = BCF_UN_FMT
  BCF_UN_ALL* = (BCF_UN_SHR or BCF_UN_FMT) ##  everything

proc bcf_unpack*(b: ptr bcf1_t; which: cint): cint {.cdecl, importc: "bcf_unpack",
    header: "vcf.h", discardable.}
## 
##   bcf_dup() - create a copy of BCF record.
## 
##   Note that bcf_unpack() must be called on the returned copy as if it was
##   obtained from bcf_read(). Also note that bcf_dup() calls bcf_sync1(src)
##   internally to reflect any changes made by bcf_update_* functions.
## 

proc bcf_dup*(src: ptr bcf1_t): ptr bcf1_t {.cdecl, importc: "bcf_dup", header: "vcf.h".}
proc bcf_copy*(dst: ptr bcf1_t; src: ptr bcf1_t): ptr bcf1_t {.cdecl, importc: "bcf_copy",
    header: "vcf.h".}
## *
##   bcf_write() - write one VCF or BCF record. The type is determined at the open() call.
## 

proc bcf_write*(fp: ptr htsFile; h: ptr bcf_hdr_t; v: ptr bcf1_t): cint {.cdecl,
    importc: "bcf_write", header: "vcf.h", discardable.}
## *
##   The following functions work only with VCFs and should rarely be called
##   directly. Usually one wants to use their bcf_* alternatives, which work
##   transparently with both VCFs and BCFs.
## 

proc vcf_hdr_read*(fp: ptr htsFile): ptr bcf_hdr_t {.cdecl, importc: "vcf_hdr_read",
    header: "vcf.h".}
proc vcf_hdr_write*(fp: ptr htsFile; h: ptr bcf_hdr_t): cint {.cdecl,
    importc: "vcf_hdr_write", header: "vcf.h".}
proc vcf_read*(fp: ptr htsFile; h: ptr bcf_hdr_t; v: ptr bcf1_t): cint {.cdecl,
    importc: "vcf_read", header: "vcf.h".}
proc vcf_write*(fp: ptr htsFile; h: ptr bcf_hdr_t; v: ptr bcf1_t): cint {.cdecl,
    importc: "vcf_write", header: "vcf.h".}
## * Helper function for the bcf_itr_next() macro; internal use, ignore it

proc bcf_readrec*(fp: ptr hts.BGZF; null: pointer; v: pointer; tid: ptr cint; beg: ptr cint;
                 `end`: ptr cint): cint {.cdecl, importc: "bcf_readrec",
                                      header: "vcf.h".}
#var p_bcf_readrec: hts_readrec_func = bcf_readrec

## *************************************************************************
##   Header querying and manipulation routines
## ************************************************************************
## * Create a new header using the supplied template

proc bcf_hdr_dup*(hdr: ptr bcf_hdr_t): ptr bcf_hdr_t {.cdecl, importc: "bcf_hdr_dup",
    header: "vcf.h".}
## *
##   Copy header lines from src to dst if not already present in dst. See also bcf_translate().
##   Returns 0 on success or sets a bit on error:
##       1 .. conflicting definitions of tag length
##       // todo
## 

proc bcf_hdr_combine*(dst: ptr bcf_hdr_t; src: ptr bcf_hdr_t): cint {.cdecl,
    importc: "bcf_hdr_combine", header: "vcf.h".}
## *
##   bcf_hdr_add_sample() - add a new sample.
##   @param sample:  sample name to be added
## 

proc bcf_hdr_add_sample*(hdr: ptr bcf_hdr_t; sample: cstring): cint {.cdecl,
    importc: "bcf_hdr_add_sample", header: "vcf.h", discardable.}
## * Read VCF header from a file and update the header

proc bcf_hdr_set*(hdr: ptr bcf_hdr_t; fname: cstring): cint {.cdecl,
    importc: "bcf_hdr_set", header: "vcf.h".}
## * Returns formatted header (newly allocated string) and its length,
##   excluding the terminating \0. If is_bcf parameter is unset, IDX
##   fields are discarded.
## 

proc bcf_hdr_fmt_text*(hdr: ptr bcf_hdr_t; is_bcf: cint; len: ptr cint): cstring {.cdecl,
    importc: "bcf_hdr_fmt_text", header: "vcf.h".}
## * Append new VCF header line, returns 0 on success

proc bcf_hdr_append*(h: ptr bcf_hdr_t; line: cstring): cint {.cdecl,
    importc: "bcf_hdr_append", header: "vcf.h", discardable.}
proc bcf_hdr_printf*(h: ptr bcf_hdr_t; format: cstring): cint {.varargs, cdecl,
    importc: "bcf_hdr_printf", header: "vcf.h".}
proc bcf_hdr_get_version*(hdr: ptr bcf_hdr_t): cstring {.cdecl,
    importc: "bcf_hdr_get_version", header: "vcf.h".}
proc bcf_hdr_set_version*(hdr: ptr bcf_hdr_t; version: cstring) {.cdecl,
    importc: "bcf_hdr_set_version", header: "vcf.h".}
## *
##   bcf_hdr_remove() - remove VCF header tag
##   @param type:      one of BCF_HL_*
##   @param key:       tag name
## 

proc bcf_hdr_remove*(h: ptr bcf_hdr_t; `type`: cint; key: cstring) {.cdecl,
    importc: "bcf_hdr_remove", header: "vcf.h".}
## *
##   bcf_hdr_subset() - creates a new copy of the header removing unwanted samples
##   @param n:        number of samples to keep
##   @param samples:  names of the samples to keep
##   @param imap:     mapping from index in @samples to the sample index in the original file
## 
##   Sample names not present in h0 are ignored. The number of unmatched samples can be checked
##   by comparing n and bcf_hdr_nsamples(out_hdr).
##   This function can be used to reorder samples.
##   See also bcf_subset() which subsets individual records.
## 

proc bcf_hdr_subset*(h0: ptr bcf_hdr_t; n: cint; samples: cstringArray; imap: ptr cint): ptr bcf_hdr_t {.
    cdecl, importc: "bcf_hdr_subset", header: "vcf.h".}
## * Creates a list of sequence names. It is up to the caller to free the list (but not the sequence names)

proc bcf_hdr_seqnames*(h: ptr bcf_hdr_t; nseqs: ptr cint): cstringArray {.cdecl,
    importc: "bcf_hdr_seqnames", header: "vcf.h".}
## * Get number of samples

template bcf_hdr_nsamples*(hdr: untyped): untyped =
  (hdr).n[BCF_DT_SAMPLE]

## * The following functions are for internal use and should rarely be called directly

proc bcf_hdr_parse*(hdr: ptr bcf_hdr_t; htxt: cstring): cint {.cdecl,
    importc: "bcf_hdr_parse", header: "vcf.h".}
proc bcf_hdr_sync*(h: ptr bcf_hdr_t): cint {.cdecl, importc: "bcf_hdr_sync",
                                        header: "vcf.h".}
proc bcf_hdr_parse_line*(h: ptr bcf_hdr_t; line: cstring; len: ptr cint): ptr bcf_hrec_t {.
    cdecl, importc: "bcf_hdr_parse_line", header: "vcf.h".}
proc bcf_hrec_format*(hrec: ptr bcf_hrec_t; str: ptr kstring.kstring_t) {.cdecl,
    importc: "bcf_hrec_format", header: "vcf.h".}
proc bcf_hdr_add_hrec*(hdr: ptr bcf_hdr_t; hrec: ptr bcf_hrec_t): cint {.cdecl,
    importc: "bcf_hdr_add_hrec", header: "vcf.h".}
## *
##   bcf_hdr_get_hrec() - get header line info
##   @param type:  one of the BCF_HL_* types: FLT,INFO,FMT,CTG,STR,GEN
##   @param key:   the header key for generic lines (e.g. "fileformat"), any field
##                   for structured lines, typically "ID".
##   @param value: the value which pairs with key. Can be be NULL for BCF_HL_GEN
##   @param str_class: the class of BCF_HL_STR line (e.g. "ALT" or "SAMPLE"), otherwise NULL
## 

proc bcf_hdr_get_hrec*(hdr: ptr bcf_hdr_t; `type`: cint; key: cstring; value: cstring;
                      str_class: cstring): ptr bcf_hrec_t {.cdecl,
    importc: "bcf_hdr_get_hrec", header: "vcf.h".}
proc bcf_hrec_dup*(hrec: ptr bcf_hrec_t): ptr bcf_hrec_t {.cdecl,
    importc: "bcf_hrec_dup", header: "vcf.h".}
proc bcf_hrec_add_key*(hrec: ptr bcf_hrec_t; str: cstring; len: cint) {.cdecl,
    importc: "bcf_hrec_add_key", header: "vcf.h".}
proc bcf_hrec_set_val*(hrec: ptr bcf_hrec_t; i: cint; str: cstring; len: cint;
                      is_quoted: cint) {.cdecl, importc: "bcf_hrec_set_val",
                                       header: "vcf.h".}
proc bcf_hrec_find_key*(hrec: ptr bcf_hrec_t; key: cstring): cint {.cdecl,
    importc: "bcf_hrec_find_key", header: "vcf.h".}
proc hrec_add_idx*(hrec: ptr bcf_hrec_t; idx: cint) {.cdecl, importc: "hrec_add_idx",
    header: "vcf.h".}
proc bcf_hrec_destroy*(hrec: ptr bcf_hrec_t) {.cdecl, importc: "bcf_hrec_destroy",
    header: "vcf.h".}
## *************************************************************************
##   Individual record querying and manipulation routines
## ************************************************************************
## * See the description of bcf_hdr_subset()

proc bcf_subset*(h: ptr bcf_hdr_t; v: ptr bcf1_t; n: cint; imap: ptr cint): cint {.cdecl,
    importc: "bcf_subset", header: "vcf.h".}
## *
##   bcf_translate() - translate tags ids to be consistent with different header. This function
##                     is useful when lines from multiple VCF need to be combined.
##   @dst_hdr:   the destination header, to be used in bcf_write(), see also bcf_hdr_combine()
##   @src_hdr:   the source header, used in bcf_read()
##   @src_line:  line obtained by bcf_read()
## 

proc bcf_translate*(dst_hdr: ptr bcf_hdr_t; src_hdr: ptr bcf_hdr_t;
                   src_line: ptr bcf1_t): cint {.cdecl, importc: "bcf_translate",
    header: "vcf.h".}
## *
##   bcf_get_variant_type[s]()  - returns one of VCF_REF, VCF_SNP, etc
## 

proc bcf_get_variant_types*(rec: ptr bcf1_t): cint {.cdecl,
    importc: "bcf_get_variant_types", header: "vcf.h".}
proc bcf_get_variant_type*(rec: ptr bcf1_t; ith_allele: cint): cint {.cdecl,
    importc: "bcf_get_variant_type", header: "vcf.h".}
proc bcf_is_snp*(v: ptr bcf1_t): cint {.cdecl, importc: "bcf_is_snp", header: "vcf.h".}
## *
##   bcf_update_filter() - sets the FILTER column
##   @flt_ids:  The filter IDs to set, numeric IDs returned by bcf_id2int(hdr, BCF_DT_ID, "PASS")
##   @n:        Number of filters. If n==0, all filters are removed
## 

proc bcf_update_filter*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; flt_ids: ptr cint; n: cint): cint {.
    cdecl, importc: "bcf_update_filter", header: "vcf.h", discardable.}
## *
##   bcf_add_filter() - adds to the FILTER column
##   @flt_id:   filter ID to add, numeric ID returned by bcf_id2int(hdr, BCF_DT_ID, "PASS")
## 
##   If flt_id is PASS, all existing filters are removed first. If other than PASS, existing PASS is removed.
## 

proc bcf_add_filter*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; flt_id: cint): cint {.cdecl,
    importc: "bcf_add_filter", header: "vcf.h".}
## *
##   bcf_remove_filter() - removes from the FILTER column
##   @flt_id:   filter ID to remove, numeric ID returned by bcf_id2int(hdr, BCF_DT_ID, "PASS")
##   @pass:     when set to 1 and no filters are present, set to PASS
## 

proc bcf_remove_filter*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; flt_id: cint; pass: cint): cint {.
    cdecl, importc: "bcf_remove_filter", header: "vcf.h".}
## *
##   Returns 1 if present, 0 if absent, or -1 if filter does not exist. "PASS" and "." can be used interchangeably.
## 

proc bcf_has_filter*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; filter: cstring): cint {.cdecl,
    importc: "bcf_has_filter", header: "vcf.h".}
## *
##   bcf_update_alleles() and bcf_update_alleles_str() - update REF and ALLT column
##   @alleles:           Array of alleles
##   @nals:              Number of alleles
##   @alleles_string:    Comma-separated alleles, starting with the REF allele
## 
##   Not that in order for indexing to work correctly in presence of INFO/END tag,
##   the length of reference allele (line->rlen) must be set explicitly by the caller,
##   or otherwise, if rlen is zero, strlen(line->d.allele[0]) is used to set the length
##   on bcf_write().
## 

proc bcf_update_alleles*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; alleles: cstringArray;
                        nals: cint): cint {.cdecl, importc: "bcf_update_alleles",
    header: "vcf.h".}
proc bcf_update_alleles_str*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t;
                            alleles_string: cstring): cint {.cdecl,
    importc: "bcf_update_alleles_str", header: "vcf.h", discardable.}
proc bcf_update_id*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; id: cstring): cint {.cdecl,
    importc: "bcf_update_id", header: "vcf.h", discardable.}
## 
##   bcf_update_info_*() - functions for updating INFO fields
##   @hdr:       the BCF header
##   @line:      VCF line to be edited
##   @key:       the INFO tag to be updated
##   @values:    pointer to the array of values. Pass NULL to remove the tag.
##   @n:         number of values in the array. When set to 0, the INFO tag is removed
## 
##   The @string in bcf_update_info_flag() is optional, @n indicates whether
##   the flag is set or removed.
## 
##   Returns 0 on success or negative value on error.
## 

template bcf_update_info_int32*(hdr, line, key, values, n: untyped): untyped =
  bcf_update_info((hdr), (line), (key), (values), (n), BCF_HT_INT)

template bcf_update_info_float*(hdr, line, key, values, n: untyped): untyped =
  bcf_update_info((hdr), (line), (key), (values), (n), BCF_HT_REAL)

template bcf_update_info_flag*(hdr, line, key, values, n: untyped): untyped =
  bcf_update_info((hdr), (line), (key), (values), (n.cint), BCF_HT_FLAG.cint)

template bcf_update_info_string*(hdr, line, key, values: untyped): untyped =
  bcf_update_info((hdr), (line), (key), (values), 1.cint, BCF_HT_STR.cint)

proc bcf_update_info*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; key: cstring;
                     values: pointer; n: cint; `type`: cint): cint {.cdecl,
    importc: "bcf_update_info", header: "vcf.h", discardable.}
## 
##   bcf_update_format_*() - functions for updating FORMAT fields
##   @values:    pointer to the array of values, the same number of elements
##               is expected for each sample. Missing values must be padded
##               with bcf_*_missing or bcf_*_vector_end values.
##   @n:         number of values in the array. If n==0, existing tag is removed.
## 
##   The function bcf_update_format_string() is a higher-level (slower) variant of
##   bcf_update_format_char(). The former accepts array of \0-terminated strings
##   whereas the latter requires that the strings are collapsed into a single array
##   of fixed-length strings. In case of strings with variable length, shorter strings
##   can be \0-padded. Note that the collapsed strings passed to bcf_update_format_char()
##   are not \0-terminated.
## 
##   Returns 0 on success or negative value on error.
## 

template bcf_update_format_int32*(hdr, line, key, values, n: untyped): untyped =
  bcf_update_format((hdr), (line), (key), (values), (n), BCF_HT_INT)

template bcf_update_format_float*(hdr, line, key, values, n: untyped): untyped =
  bcf_update_format((hdr), (line), (key), (values), (n), BCF_HT_REAL)

template bcf_update_format_char*(hdr, line, key, values, n: untyped): untyped =
  bcf_update_format((hdr), (line), (key), (values), (n), BCF_HT_STR)

template bcf_update_genotypes*(hdr, line, gts, n: untyped): untyped =
  bcf_update_format((hdr), (line), "GT", (gts), (n), BCF_HT_INT) ##  See bcf_gt_ macros below
  
proc bcf_update_format_string*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; key: cstring;
                              values: cstringArray; n: cint): cint {.cdecl,
    importc: "bcf_update_format_string", header: "vcf.h", discardable.}
proc bcf_update_format*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; key: cstring;
                       values: pointer; n: cint; `type`: cint): cint {.cdecl,
    importc: "bcf_update_format", header: "vcf.h", discardable.}
##  Macros for setting genotypes correctly, for use with bcf_update_genotypes only; idx corresponds
##  to VCF's GT (1-based index to ALT or 0 for the reference allele) and val is the opposite, obtained
##  from bcf_get_genotypes() below.

template bcf_gt_phased*(idx: untyped): untyped =
  ((idx + 1) shl 1 or 1)

template bcf_gt_unphased*(idx: untyped): untyped =
  ((idx + 1) shl 1)

const
  bcf_gt_missing* = 0

template bcf_gt_is_missing*(val: untyped): untyped =
  (if (val) shr 1: 0 else: 1)

template bcf_gt_is_phased*(idx: untyped): untyped =
  ((idx) and 1)

template bcf_gt_allele*(val: untyped): untyped =
  (((val) shr 1) - 1)

## * Conversion between alleles indexes to Number=G genotype index (assuming diploid, all 0-based)

template bcf_alleles2gt*(a, b: untyped): untyped =
  (if (a) > (b): ((a) * ((a) + 1) div 2 + (b)) else: ((b) * ((b) + 1) div 2 + (a)))

proc bcf_gt2alleles*(igt: cint; a: ptr cint; b: ptr cint) {.inline, cdecl.} =
  var
    k: cint
    dk: cint
  while k < igt:
    inc(dk)
    inc(k, dk)
  b[] = dk - 1
  a[] = igt - k + b[]

## *
##  bcf_get_fmt() - returns pointer to FORMAT's field data
##  @header: for access to BCF_DT_ID dictionary
##  @line:   VCF line obtained from vcf_parse1
##  @fmt:    one of GT,PL,...
## 
##  Returns bcf_fmt_t* if the call succeeded, or returns NULL when the field
##  is not available.
## 

proc bcf_get_fmt*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; key: cstring): ptr bcf_fmt_t {.
    cdecl, importc: "bcf_get_fmt", header: "vcf.h".}
proc bcf_get_info*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; key: cstring): ptr bcf_info_t {.
    cdecl, importc: "bcf_get_info", header: "vcf.h".}
## *
##  bcf_get_*_id() - returns pointer to FORMAT/INFO field data given the header index instead of the string ID
##  @line: VCF line obtained from vcf_parse1
##  @id:  The header index for the tag, obtained from bcf_hdr_id2int()
##  
##  Returns bcf_fmt_t* / bcf_info_t*. These functions do not check if the index is valid 
##  as their goal is to avoid the header lookup.
## 

proc bcf_get_fmt_id*(line: ptr bcf1_t; id: cint): ptr bcf_fmt_t {.cdecl,
    importc: "bcf_get_fmt_id", header: "vcf.h".}
proc bcf_get_info_id*(line: ptr bcf1_t; id: cint): ptr bcf_info_t {.cdecl,
    importc: "bcf_get_info_id", header: "vcf.h".}
## *
##   bcf_get_info_*() - get INFO values, integers or floats
##   @hdr:       BCF header
##   @line:      BCF record
##   @tag:       INFO tag to retrieve
##   @dst:       *dst is pointer to a memory location, can point to NULL
##   @ndst:      pointer to the size of allocated memory
## 
##   Returns negative value on error or the number of written values on
##   success. bcf_get_info_string() returns on success the number of
##   characters written excluding the null-terminating byte. bcf_get_info_flag()
##   returns 1 when flag is set or 0 if not.
## 
##   List of return codes:
##       -1 .. no such INFO tag defined in the header
##       -2 .. clash between types defined in the header and encountered in the VCF record
##       -3 .. tag is not present in the VCF record
## 

template bcf_get_info_int32*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_info_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_INT)

template bcf_get_info_float*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_info_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_REAL)

template bcf_get_info_string*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_info_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_STR)

template bcf_get_info_flag*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_info_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_FLAG)

proc bcf_get_info_values*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; tag: cstring;
                         dst: ptr pointer; ndst: ptr cint; `type`: cint): cint {.cdecl,
    importc: "bcf_get_info_values", header: "vcf.h".}
## *
##   bcf_get_format_*() - same as bcf_get_info*() above
## 
##   The function bcf_get_format_string() is a higher-level (slower) variant of bcf_get_format_char().
##   see the description of bcf_update_format_string() and bcf_update_format_char() above.
##   Unlike other bcf_get_format__*() functions, bcf_get_format_string() allocates two arrays:
##   a single block of \0-terminated strings collapsed into a single array and an array of pointers
##   to these strings. Both arrays must be cleaned by the user.
## 
##   Returns negative value on error or the number of written values on success.
## 
##   Example:
##       int ndst = 0; char **dst = NULL;
##       if ( bcf_get_format_string(hdr, line, "XX", &dst, &ndst) > 0 )
##           for (i=0; i<bcf_hdr_nsamples(hdr); i++) printf("%s\n", dst[i]);
##       free(dst[0]); free(dst);
## 
##   Example:
##       int ngt, *gt_arr = NULL, ngt_arr = 0;
##       ngt = bcf_get_genotypes(hdr, line, &gt_arr, &ngt_arr);
## 

template bcf_get_format_int32*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_format_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_INT)

template bcf_get_format_float*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_format_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_REAL)

template bcf_get_format_char*(hdr, line, tag, dst, ndst: untyped): untyped =
  bcf_get_format_values(hdr, line, tag, cast[ptr pointer]((dst)), ndst, BCF_HT_STR)

template bcf_get_genotypes*(hdr, line, dst, ndst: untyped): untyped =
  bcf_get_format_values(hdr, line, "GT", cast[ptr pointer]((dst)), ndst, BCF_HT_INT)

proc bcf_get_format_string*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; tag: cstring;
                           dst: ptr cstringArray; ndst: ptr cint): cint {.cdecl,
    importc: "bcf_get_format_string", header: "vcf.h".}
proc bcf_get_format_values*(hdr: ptr bcf_hdr_t; line: ptr bcf1_t; tag: cstring;
                           dst: ptr pointer; ndst: ptr cint; `type`: cint): cint {.cdecl,
    importc: "bcf_get_format_values", header: "vcf.h".}
## *************************************************************************
##   Helper functions
## ************************************************************************
## *
##   bcf_hdr_id2int() - Translates string into numeric ID
##   bcf_hdr_int2id() - Translates numeric ID into string
##   @type:     one of BCF_DT_ID, BCF_DT_CTG, BCF_DT_SAMPLE
##   @id:       tag name, such as: PL, DP, GT, etc.
## 
##   Returns -1 if string is not in dictionary, otherwise numeric ID which identifies
##   fields in BCF records.
## 

proc bcf_hdr_id2int*(hdr: ptr bcf_hdr_t; `type`: cint; id: cstring): cint {.cdecl,
    importc: "bcf_hdr_id2int", header: "vcf.h".}
template bcf_hdr_int2id*(hdr, `type`, int_id: untyped): untyped =
  ((hdr).id[`type`][int_id].key)

## *
##   bcf_hdr_name2id() - Translates sequence names (chromosomes) into numeric ID
##   bcf_hdr_id2name() - Translates numeric ID to sequence name
## 

proc bcf_hdr_name2id*(hdr: ptr bcf_hdr_t; id: cstring): cint {.inline, cdecl.} =
  return bcf_hdr_id2int(hdr, BCF_DT_CTG, id)
proc bcf_hdr_name2id_raw*(hdr: pointer; id: cstring): cint {.inline, cdecl.} =
  return bcf_hdr_name2id(cast[ptr bcf_hdr_t](hdr), id)

proc bcf_hdr_id2name*(hdr: ptr bcf_hdr_t; rid: cint): cstring {.inline, cdecl.} =
  return hdr.id[BCF_DT_CTG][rid].key

proc bcf_seqname*(hdr: ptr bcf_hdr_t; rec: ptr bcf1_t): cstring {.inline, cdecl.} =
  return hdr.id[BCF_DT_CTG][rec.rid].key

## *
##   bcf_hdr_id2*() - Macros for accessing bcf_idinfo_t
##   @type:      one of BCF_HL_FLT, BCF_HL_INFO, BCF_HL_FMT
##   @int_id:    return value of bcf_id2int, must be >=0
## 
##   The returned values are:
##      bcf_hdr_id2length   ..  whether the number of values is fixed or variable, one of BCF_VL_*
##      bcf_hdr_id2number   ..  the number of values, 0xfffff for variable length fields
##      bcf_hdr_id2type     ..  the field type, one of BCF_HT_*
##      bcf_hdr_id2coltype  ..  the column type, one of BCF_HL_*
## 
##   Notes: Prior to using the macros, the presence of the info should be
##   tested with bcf_hdr_idinfo_exists().
## 

template bcf_hdr_id2length*(hdr, `type`, int_id: untyped): untyped =
  ((hdr).id[BCF_DT_ID][int_id].val.info[`type`] shr 8 and 0x0000000F)

template bcf_hdr_id2number*(hdr, `type`, int_id: untyped): untyped =
  ((hdr).id[BCF_DT_ID][int_id].val.info[`type`] shr 12)

template bcf_hdr_id2type*(hdr, `type`, int_id: untyped): untyped =
  ((hdr).id[BCF_DT_ID][int_id].val.info[`type`] shr 4 and 0x0000000F)

template bcf_hdr_id2coltype*(hdr, `type`, int_id: untyped): untyped =
  ((hdr).id[BCF_DT_ID][int_id].val.info[`type`] and 0x0000000F)

template bcf_hdr_idinfo_exists*(hdr, `type`, int_id: untyped): untyped =
  (if (int_id < 0 or bcf_hdr_id2coltype(hdr, `type`, int_id) == 0x0000000F): 0 else: 1)

template bcf_hdr_id2hrec*(hdr, dict_type, col_type, int_id: untyped): untyped =
  ((hdr).id[if (dict_type) == BCF_DT_CTG: BCF_DT_CTG else: BCF_DT_ID][int_id].val.hrec[
      if (dict_type) == BCF_DT_CTG: 0 else: (col_type)])

proc bcf_fmt_array*(s: ptr kstring.kstring_t; n: cint; `type`: cint; data: pointer) {.cdecl,
    importc: "bcf_fmt_array", header: "vcf.h".}
proc bcf_fmt_sized_array*(s: ptr kstring.kstring_t; `ptr`: ptr uint8): ptr uint8 {.cdecl,
    importc: "bcf_fmt_sized_array", header: "vcf.h".}
proc bcf_enc_vchar*(s: ptr kstring.kstring_t; l: cint; a: cstring) {.cdecl,
    importc: "bcf_enc_vchar", header: "vcf.h".}
proc bcf_enc_vint*(s: ptr kstring.kstring_t; n: cint; a: ptr int32; wsize: cint) {.cdecl,
    importc: "bcf_enc_vint", header: "vcf.h".}
proc bcf_enc_vfloat*(s: ptr kstring.kstring_t; n: cint; a: ptr cfloat) {.cdecl,
    importc: "bcf_enc_vfloat", header: "vcf.h".}
## *************************************************************************
##   BCF index
## 
##   Note that these functions work with BCFs only. See synced_bcf_reader.h
##   which provides (amongst other things) an API to work transparently with
##   both indexed BCFs and VCFs.
## ************************************************************************

template bcf_itr_destroy*(iter: untyped): untyped =
  hts_itr_destroy(iter)

template bcf_itr_queryi*(idx, tid, beg, `end`: untyped): untyped =
  hts_itr_query((idx), (tid), (beg), (`end`), bcf_readrec)

template bcf_itr_querys*(idx, hdr, s: untyped): untyped =
  hts_itr_querys((idx), (s), (hts_name2id_f)(bcf_hdr_name2id_raw), (hdr), cast[hts_itr_query_func](hts_itr_query),
                 bcf_readrec)

template bcf_itr_next*(htsfp, itr, r: untyped): untyped =
  hts_itr_next((htsfp).fp.bgzf, (itr), (r), 0)

template bcf_index_load*(fn: untyped): untyped =
  hts_idx_load(fn, HTS_FMT_CSI)

template bcf_index_seqnames*(idx, hdr, nptr: untyped): untyped =
  hts_idx_seqnames((idx), (nptr), (hts_id2name_f)(bcf_hdr_id2name), (hdr))

proc bcf_index_build*(fn: cstring; min_shift: cint): cint {.cdecl,
    importc: "bcf_index_build", header: "vcf.h", discardable.}
## ******************
##  Typed value I/O *
## *****************
## 
##     Note that in contrast with BCFv2.1 specification, HTSlib implementation
##     allows missing values in vectors. For integer types, the values 0x80,
##     0x8000, 0x80000000 are interpreted as missing values and 0x81, 0x8001,
##     0x80000001 as end-of-vector indicators.  Similarly for floats, the value of
##     0x7F800001 is interpreted as a missing value and 0x7F800002 as an
##     end-of-vector indicator.
##     Note that the end-of-vector byte is not part of the vector.
## 
##     This trial BCF version (v2.2) is compatible with the VCF specification and
##     enables to handle correctly vectors with different ploidy in presence of
##     missing values.
## 

const
  INT8_MIN = int8.low
  INT16_MIN = int16.low
  INT32_MIN = int32.low
  INT8_MAX = int8.high
  INT16_MAX = int16.high
  #INT32_MAX = int32.high
  bcf_int8_vector_end* = (INT8_MIN + 1)
  bcf_int16_vector_end* = (INT16_MIN + 1)
  bcf_int32_vector_end* = (INT32_MIN + 1)
  bcf_str_vector_end* = 0
  bcf_int8_missing* = INT8_MIN
  bcf_int16_missing* = INT16_MIN
  bcf_int32_missing* = INT32_MIN
  bcf_str_missing* = 0x00000007

var bcf_float_vector_end* {.importc: "bcf_float_vector_end", header: "vcf.h".}: uint32

var bcf_float_missing* {.importc: "bcf_float_missing", header: "vcf.h".}: uint32

proc bcf_float_set*(`ptr`: ptr cfloat; value: uint32) {.inline, cdecl.} =
  `ptr`[] = cast[cfloat](value)

template bcf_float_set_vector_end*(x: untyped): untyped =
  bcf_float_set(addr((x)), bcf_float_vector_end)

template bcf_float_set_missing*(x: untyped) =
  bcf_float_set(addr(x), bcf_float_missing)

proc bcf_float_is_missing*(f: cfloat): bool {.inline.} =
  return cast[uint32](f) == bcf_float_missing

proc bcf_float_is_vector_end*(f: cfloat): bool {.inline.} =
  return cast[uint32](f) == bcf_float_vector_end

proc bcf_format_gt*(fmt: ptr bcf_fmt_t; isample: cint; str: ptr kstring.kstring_t) {.inline, cdecl.} =
  template BRANCH(type_t, missing, vector_end: untyped): void =
    var p_val: ptr type_t
    var i: cint
    i = 0
    while i < fmt.n and p_val[i] != vector_end:
      if i != 0: discard kputc("/|"[p_val[i] and 1].cint, str)
      if 0 == (p_val[i] shr 1): discard kputc('.'.cint, str)
      else: discard kputw((p_val[i] shr 1) - 1, str)
      inc(i)
    if i == 0: discard kputc('.'.cint, str)

  case fmt.`type`
  of BCF_BT_INT8:
    BRANCH(int8, bcf_int8_missing, bcf_int8_vector_end)
  of BCF_BT_INT16:
    BRANCH(int16, bcf_int16_missing, bcf_int16_vector_end)
  of BCF_BT_INT32:
    BRANCH(int32, bcf_int32_missing, bcf_int32_vector_end)
  else:
    let msg = "FIXME: type $1 in bcf_format_gt?" % repr(fmt.`type`)
    raise newException(OSError, msg) # or abort()

proc bcf_enc_size*(s: ptr kstring.kstring_t; size: cint; `type`: cint) {.inline, cdecl.} =
  if size >= 15:
    discard kputc(15 shl 4 or `type`, s)
    if size >= 128:
      if size >= 32768:
        var x: int32
        discard kputc(1 shl 4 or BCF_BT_INT32, s)
        discard kputsn(cast[cstring](addr(x)), 4, s)
      else:
        var x: int16
        discard kputc(1 shl 4 or BCF_BT_INT16, s)
        discard kputsn(cast[cstring](addr(x)), 2, s)
    else:
      discard kputc(1 shl 4 or BCF_BT_INT8, s)
      discard kputc(size, s)
  else:
    discard kputc(size shl 4 or `type`, s)
  
proc bcf_enc_inttype*(x: clong): cint {.inline, cdecl.} =
  if x <= INT8_MAX and x > bcf_int8_missing: return BCF_BT_INT8
  if x <= INT16_MAX and x > bcf_int16_missing: return BCF_BT_INT16
  return BCF_BT_INT32

proc bcf_enc_int1*(s: ptr kstring.kstring_t; x: int32) {.inline, cdecl.} =
  if x == bcf_int32_vector_end:
    bcf_enc_size(s, 1, BCF_BT_INT8)
    discard kputc(bcf_int8_vector_end, s)
  elif x == bcf_int32_missing:
    bcf_enc_size(s, 1, BCF_BT_INT8)
    discard kputc(bcf_int8_missing, s)
  elif x <= INT8_MAX and x > bcf_int8_missing:
    bcf_enc_size(s, 1, BCF_BT_INT8)
    discard kputc(x, s)
  elif x <= INT16_MAX and x > bcf_int16_missing:
    var z: int16
    bcf_enc_size(s, 1, BCF_BT_INT16)
    discard kputsn(cast[cstring](addr(z)), 2, s)
  else:
    var z: int32
    bcf_enc_size(s, 1, BCF_BT_INT32)
    discard kputsn(cast[cstring](addr(z)), 4, s)

proc bcf_dec_int1*(p: ptr uint8; `type`: cint; q: ptr ptr uint8): int32 {.inline,
    cdecl.} =
  if `type` == BCF_BT_INT8:
    q[] = cast[ptr uint8](p) + 1
    return cast[ptr int8](p)[]
  elif `type` == BCF_BT_INT16:
    q[] = cast[ptr uint8](p) + 2
    return cast[ptr int16](p)[]
  else:
    q[] = cast[ptr uint8](p) + 4
    return cast[ptr int32](p)[]

proc bcf_dec_typed_int1*(p: ptr uint8; q: ptr ptr uint8): int32 {.inline, cdecl.} =
  return bcf_dec_int1(p + 1, p[] and 0x0000000F, q)

proc bcf_dec_size*(p: ptr uint8; q: ptr ptr uint8; `type`: ptr cint): int32 {.inline,
    cdecl.} =
  `type`[] = p[] and 0x0000000F
  if p[] shr 4 != 15:
    q[] = cast[ptr uint8](p) + 1
    return (p[] shr 4).int32
  else:
    return bcf_dec_typed_int1(p + 1, q)
