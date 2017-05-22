# vim: sw=2 ts=2 sts=2 tw=80 et:
##   hts.h -- format-neutral I/O, indexing, and iterator API functions.
##
##     Copyright (C) 2012-2014 Genome Research Ltd.
##     Copyright (C) 2012 Broad Institute.
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

from kstring import kstring_t

type
  cram_fd* {.importc: "struct cram_fd", header: "htslib/hts.h".} = object
  hFILE* {.importc: "struct hFILE", header: "htslib/hts.h".} = object
  BGZF* {.importc: "BGZF", header: "htslib/hts.h".} = object
#[
  kstring_t* {.importc: "kstring_t", header: "htslib/hts.h".} = object
    L* {.importc: "l".}: csize
    m* {.importc: "m".}: csize
    s* {.importc: "s".}: cstring
]#
#[
proc kroundup32*[T](x: var T) =
  dec(x)
  (x) = (x) or (x) shr 1
  (x) = (x) or (x) shr 2
  (x) = (x) or (x) shr 4
  (x) = (x) or (x) shr 8
  (x) = (x) or (x) shr 16
  inc(x)

## *
##  hts_expand()  - expands memory block pointed to by $ptr;
##  hts_expand0()   the latter sets the newly allocated part to 0.
##
##  @param n     requested number of elements of type type_t
##  @param m     size of memory allocated
##

template hts_expand*(type_t, n, m, `ptr`: untyped): void =
  if (n) > (m):
    (m) = (n)
    kroundup32(m)
    (`ptr`) = cast[ptr type_t](realloc((`ptr`), (m) * sizeof((type_t))))

template hts_expand0*(type_t, n, m, `ptr`: untyped): void =
  if (n) > (m):
    var t: cint
    (m) = (n)
    kroundup32(m)
    (`ptr`) = cast[ptr type_t](realloc((`ptr`), (m) * sizeof((type_t))))
    memset((cast[ptr type_t](`ptr`)) + t, 0, sizeof((type_t) * ((m) - t)))
]#


## ***********
##  File I/O *
## **********
##  Add new entries only at the end (but before the *_maximum entry)
##  of these enums, as their numbering is part of the htslib ABI.

type
  htsFormatCategory* {.size: sizeof(cint).} = enum
    unknown_category, sequence_data, ##  Sequence data -- SAM, BAM, CRAM, etc
    variant_data,             ##  Variant calling data -- VCF, BCF, etc
    index_file,               ##  Index file associated with some data file
    region_list,              ##  Coordinate intervals or regions -- BED, etc
    category_maximum = 32767


type
  htsExactFormat* {.size: sizeof(cint).} = enum
    unknown_format, binary_format, text_format, sam, bam, bai, cram, crai, vcf, bcfv1,
    bcf, csi, gzi, tbi, bed, format_maximum = 32767


type
  htsCompression* {.size: sizeof(cint).} = enum
    no_compression, gzip, bgzf, custom, compression_maximum = 32767


type
  htsFormat* {.importc: "htsFormat", header: "htslib/hts.h".} = object
    category* {.importc: "category".}: htsFormatCategory
    format* {.importc: "format".}: htsExactFormat
    compression* {.importc: "compression".}: htsCompression


##  Maintainers note htsFile cannot be an opaque structure because some of its
##  fields are part of libhts.so's ABI (hence these fields must not be moved):
##   - fp is used in the public sam_itr_next()/etc macros
##   - is_bin is used directly in samtools <= 1.1 and bcftools <= 1.1
##   - is_write and is_cram are used directly in samtools <= 1.1
##   - fp is used directly in samtools (up to and including current develop)
##   - line is used directly in bcftools (up to and including current develop)

type
  INNER_C_UNION_2104044963* {.union.} = object
    bgzf* {.importc: "bgzf".}: ptr BGZF
    cram* {.importc: "cram".}: ptr cram_fd
    hfile* {.importc: "hfile".}: ptr hFILE
    voidp* {.importc: "voidp".}: pointer

  htsFile* {.importc: "htsFile", header: "htslib/hts.h", packed.} = object
    is_bin* {.importc: "is_bin", bitsize: 1.}: uint32
    is_write* {.importc: "is_write", bitsize: 1.}: uint32
    is_be* {.importc: "is_be", bitsize: 1.}: uint32
    is_cram* {.importc: "is_cram", bitsize: 1.}: uint32
    dummy* {.importc: "dummy", bitsize: 28.}: uint32
    lineno* {.importc: "lineno".}: int64
    line* {.importc: "line".}: kstring_t
    fn* {.importc: "fn".}: cstring
    fn_aux* {.importc: "fn_aux".}: cstring
    fp* {.importc: "fp".}: INNER_C_UNION_2104044963
    format* {.importc: "format".}: htsFormat


##  REQUIRED_FIELDS

type
  sam_fields* {.size: sizeof(cint).} = enum
    SAM_QNAME = 0x00000001, SAM_FLAG = 0x00000002, SAM_RNAME = 0x00000004,
    SAM_POS = 0x00000008, SAM_MAPQ = 0x00000010, SAM_CIGAR = 0x00000020,
    SAM_RNEXT = 0x00000040, SAM_PNEXT = 0x00000080, SAM_TLEN = 0x00000100,
    SAM_SEQ = 0x00000200, SAM_QUAL = 0x00000400, SAM_AUX = 0x00000800,
    SAM_RGAUX = 0x00001000


type
  cram_option* {.size: sizeof(cint).} = enum
    CRAM_OPT_DECODE_MD, CRAM_OPT_PREFIX, CRAM_OPT_VERBOSITY,
    CRAM_OPT_SEQS_PER_SLICE, CRAM_OPT_SLICES_PER_CONTAINER, CRAM_OPT_RANGE,
    CRAM_OPT_VERSION, CRAM_OPT_EMBED_REF, CRAM_OPT_IGNORE_MD5, CRAM_OPT_REFERENCE,
    CRAM_OPT_MULTI_SEQ_PER_SLICE, CRAM_OPT_NO_REF, CRAM_OPT_USE_BZIP2,
    CRAM_OPT_SHARED_REF, CRAM_OPT_NTHREADS, CRAM_OPT_THREAD_POOL,
    CRAM_OPT_USE_LZMA, CRAM_OPT_USE_RANS, CRAM_OPT_REQUIRED_FIELDS


## *********************
##  Exported functions *
## ********************

var hts_verbose* {.importc: "hts_verbose", header: "htslib/hts.h".}: cint

## ! @abstract Table for converting a nucleotide character to 4-bit encoding.
## The input character may be either an IUPAC ambiguity code, '=' for 0, or
## '0'/'1'/'2'/'3' for a result of 1/2/4/8.  The result is encoded as 1/2/4/8
## for A/C/G/T or combinations of these bits for ambiguous bases.
##

var seq_nt16_table* {.importc: "seq_nt16_table", header: "htslib/hts.h".}: array[256, cuchar]

## ! @abstract Table for converting a 4-bit encoded nucleotide to an IUPAC
## ambiguity code letter (or '=' when given 0).
##

var seq_nt16_str* {.importc: "seq_nt16_str", header: "htslib/hts.h".}: ptr char

## ! @abstract Table for converting a 4-bit encoded nucleotide to about 2 bits.
## Returns 0/1/2/3 for 1/2/4/8 (i.e., A/C/G/T), or 4 otherwise (0 or ambiguous).
##

var seq_nt16_int* {.importc: "seq_nt16_int", header: "htslib/hts.h".}: ptr cint

## !
##   @abstract  Get the htslib version number
##   @return    For released versions, a string like "N.N[.N]"; or git describe
##   output if using a library built within a Git repository.
##

proc hts_version*(): cstring {.cdecl, importc: "hts_version", header: "htslib/hts.h".}
## !
##   @abstract    Determine format by peeking at the start of a file
##   @param fp    File opened for reading, positioned at the beginning
##   @param fmt   Format structure that will be filled out on return
##   @return      0 for success, or negative if an error occurred.
##

proc hts_detect_format*(fp: ptr hFILE; fmt: ptr htsFormat): cint {.cdecl,
    importc: "hts_detect_format", header: "htslib/hts.h".}
## !
##   @abstract    Get a human-readable description of the file format
##

proc hts_format_description*(format: ptr htsFormat): cstring {.cdecl,
    importc: "hts_format_description", header: "htslib/hts.h".}
## !
##   @abstract       Open a SAM/BAM/CRAM/VCF/BCF/etc file
##   @param fn       The file name or "-" for stdin/stdout
##   @param mode     Mode matching /[rwa][bcuz0-9]+/
##   @discussion
##       With 'r' opens for reading; any further format mode letters are ignored
##       as the format is detected by checking the first few bytes or BGZF blocks
##       of the file.  With 'w' or 'a' opens for writing or appending, with format
##       specifier letters:
##         b  binary format (BAM, BCF, etc) rather than text (SAM, VCF, etc)
##         c  CRAM format
##         g  gzip compressed
##         u  uncompressed
##         z  bgzf compressed
##         [0-9]  zlib compression level
##       Note that there is a distinction between 'u' and '0': the first yields
##       plain uncompressed output whereas the latter outputs uncompressed data
##       wrapped in the zlib format.
##   @example
##       [rw]b .. compressed BCF, BAM, FAI
##       [rw]u .. uncompressed BCF
##       [rw]z .. compressed VCF
##       [rw]  .. uncompressed VCF
##

proc hts_open*(fn: cstring; mode: cstring): ptr htsFile {.cdecl, importc: "hts_open",
    header: "htslib/hts.h".}
## !
##   @abstract       Open an existing stream as a SAM/BAM/CRAM/VCF/BCF/etc file
##   @param fn       The already-open file handle
##   @param mode     Open mode, as per hts_open()
##

proc hts_hopen*(fp: ptr hFILE; fn: cstring; mode: cstring): ptr htsFile {.cdecl,
    importc: "hts_hopen", header: "htslib/hts.h".}
## !
##   @abstract  Close a file handle, flushing buffered data for output streams
##   @param fp  The file handle to be closed
##   @return    0 for success, or negative if an error occurred.
##

proc hts_close*(fp: ptr htsFile): cint {.cdecl, importc: "hts_close", header: "htslib/hts.h".}
## !
##   @abstract  Returns the file's format information
##   @param fp  The file handle
##   @return    Read-only pointer to the file's htsFormat.
##

proc hts_get_format*(fp: ptr htsFile): ptr htsFormat {.cdecl,
    importc: "hts_get_format", header: "htslib/hts.h".}
## !
##   @abstract  Sets a specified CRAM option on the open file handle.
##   @param fp  The file handle open the open file.
##   @param opt The CRAM_OPT_* option.
##   @param ... Optional arguments, dependent on the option used.
##   @return    0 for success, or negative if an error occurred.
##

proc hts_set_opt*(fp: ptr htsFile; opt: cram_option): cint {.varargs, cdecl,
    importc: "hts_set_opt", header: "htslib/hts.h".}
proc hts_getline*(fp: ptr htsFile; delimiter: cint; str: ptr kstring_t): cint {.cdecl,
    importc: "hts_getline", header: "htslib/hts.h".}
proc hts_readlines*(fn: cstring; n: ptr cint): cstringArray {.cdecl,
    importc: "hts_readlines", header: "htslib/hts.h".}
## !
##     @abstract       Parse comma-separated list or read list from a file
##     @param list     File name or comma-separated list
##     @param is_file
##     @param _n       Size of the output array (number of items read)
##     @return         NULL on failure or pointer to newly allocated array of
##                     strings
##

proc hts_readlist*(fn: cstring; is_file: cint; n: ptr cint): cstringArray {.cdecl,
    importc: "hts_readlist", header: "htslib/hts.h".}
## !
##   @abstract  Create extra threads to aid compress/decompression for this file
##   @param fp  The file handle
##   @param n   The number of worker threads to create
##   @return    0 for success, or negative if an error occurred.
##   @notes     THIS THREADING API IS LIKELY TO CHANGE IN FUTURE.
##

proc hts_set_threads*(fp: ptr htsFile; n: cint): cint {.cdecl,
    importc: "hts_set_threads", header: "htslib/hts.h".}
## !
##   @abstract  Set .fai filename for a file opened for reading
##   @return    0 for success, negative on failure
##   @discussion
##       Called before *_hdr_read(), this provides the name of a .fai file
##       used to provide a reference list if the htsFile contains no @SQ headers.
##

proc hts_set_fai_filename*(fp: ptr htsFile; fn_aux: cstring): cint {.cdecl,
    importc: "hts_set_fai_filename", header: "htslib/hts.h".}
## ***********
##  Indexing *
## **********
## !
## These HTS_IDX_* macros are used as special tid values for hts_itr_query()/etc,
## producing iterators operating as follows:
##  - HTS_IDX_NOCOOR iterates over unmapped reads sorted at the end of the file
##  - HTS_IDX_START  iterates over the entire file
##  - HTS_IDX_REST   iterates from the current position to the end of the file
##  - HTS_IDX_NONE   always returns "no more alignment records"
## When one of these special tid values is used, beg and end are ignored.
## When REST or NONE is used, idx is also ignored and may be NULL.
##

const
  HTS_IDX_NOCOOR* = (- 2)
  HTS_IDX_START* = (- 3)
  HTS_IDX_REST* = (- 4)
  HTS_IDX_NONE* = (- 5)
  HTS_FMT_CSI* = 0
  HTS_FMT_BAI* = 1
  HTS_FMT_TBI* = 2
  HTS_FMT_CRAI* = 3

type
  hts_idx_t* {.importc: "struct __hts_idx_t", header: "htslib/hts.h".} = object

  INNER_C_STRUCT_3954569502* {.importc: "no_name", header: "htslib/hts.h".} = object
    n* {.importc: "n".}: cint
    m* {.importc: "m".}: cint
    a* {.importc: "a".}: ptr cint

  hts_pair64_t* {.importc: "hts_pair64_t", header: "htslib/hts.h".} = object
    u* {.importc: "u".}: uint64
    v* {.importc: "v".}: uint64

  hts_readrec_func* = proc (fp: ptr BGZF; data: pointer; r: pointer; tid: ptr cint;
                         beg: ptr cint; `end`: ptr cint): cint {.cdecl.}
  hts_itr_t* {.importc: "hts_itr_t", header: "htslib/hts.h".} = object
    read_rest* {.importc: "read_rest", bitsize: 1.}: uint32
    finished* {.importc: "finished", bitsize: 1.}: uint32
    dummy* {.importc: "dummy", bitsize: 29.}: uint32
    tid* {.importc: "tid".}: cint
    beg* {.importc: "beg".}: cint
    `end`* {.importc: "end".}: cint
    n_off* {.importc: "n_off".}: cint
    i* {.importc: "i".}: cint
    curr_off* {.importc: "curr_off".}: uint64
    off* {.importc: "off".}: ptr hts_pair64_t
    readrec* {.importc: "readrec".}: ptr hts_readrec_func
    bins* {.importc: "bins".}: INNER_C_STRUCT_3954569502


template hts_bin_first*(v: untyped): untyped =
  (((1 shl (((v) shl 1) + (v))) - 1) div 7)

template hts_bin_parent*(v: untyped): untyped =
  (((v) - 1) shr 3)

proc hts_idx_init*(n: cint; fmt: cint; offset0: uint64; min_shift: cint; n_lvls: cint): ptr hts_idx_t {.
    cdecl, importc: "hts_idx_init", header: "htslib/hts.h".}
proc hts_idx_destroy*(idx: ptr hts_idx_t) {.cdecl, importc: "hts_idx_destroy",
                                        header: "htslib/hts.h".}
proc hts_idx_push*(idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint;
                  offset: uint64; is_mapped: cint): cint {.cdecl,
    importc: "hts_idx_push", header: "htslib/hts.h".}
proc hts_idx_finish*(idx: ptr hts_idx_t; final_offset: uint64) {.cdecl,
    importc: "hts_idx_finish", header: "htslib/hts.h".}
proc hts_idx_save*(idx: ptr hts_idx_t; fn: cstring; fmt: cint) {.cdecl,
    importc: "hts_idx_save", header: "htslib/hts.h".}
proc hts_idx_load*(fn: cstring; fmt: cint): ptr hts_idx_t {.cdecl,
    importc: "hts_idx_load", header: "htslib/hts.h".}
proc hts_idx_get_meta*(idx: ptr hts_idx_t; l_meta: ptr cint): ptr uint8 {.cdecl,
    importc: "hts_idx_get_meta", header: "htslib/hts.h".}
proc hts_idx_set_meta*(idx: ptr hts_idx_t; l_meta: cint; meta: ptr uint8; is_copy: cint) {.
    cdecl, importc: "hts_idx_set_meta", header: "htslib/hts.h".}
proc hts_idx_get_stat*(idx: ptr hts_idx_t; tid: cint; mapped: ptr uint64;
                      unmapped: ptr uint64): cint {.cdecl,
    importc: "hts_idx_get_stat", header: "htslib/hts.h".}
proc hts_idx_get_n_no_coor*(idx: ptr hts_idx_t): uint64 {.cdecl,
    importc: "hts_idx_get_n_no_coor", header: "htslib/hts.h".}
proc hts_parse_reg*(s: cstring; beg: ptr cint; `end`: ptr cint): cstring {.cdecl,
    importc: "hts_parse_reg", header: "htslib/hts.h".}
proc hts_itr_query*(idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint;
                   readrec: hts_readrec_func): ptr hts_itr_t {.cdecl,
    importc: "hts_itr_query", header: "htslib/hts.h".}
proc hts_itr_destroy*(iter: ptr hts_itr_t) {.cdecl, importc: "hts_itr_destroy",
    header: "htslib/hts.h".}
type
  hts_name2id_f* = proc (a2: pointer; a3: cstring): cint {.cdecl.}
  hts_id2name_f* = proc (a2: pointer; a3: cint): cstring {.cdecl.}
  hts_itr_query_func* = proc (idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint;
                           readrec: ptr hts_readrec_func): ptr hts_itr_t {.cdecl.}

proc hts_itr_querys*(idx: ptr hts_idx_t; reg: cstring; getid: hts_name2id_f;
                    hdr: pointer; itr_query: hts_itr_query_func;
                    readrec: hts_readrec_func): ptr hts_itr_t {.cdecl,
    importc: "hts_itr_querys", header: "htslib/hts.h".}
proc hts_itr_next*(fp: ptr BGZF; iter: ptr hts_itr_t; r: pointer; data: pointer): cint {.cdecl, importc: "hts_itr_next", header: "htslib/hts.h".}
proc hts_idx_seqnames*(idx: ptr hts_idx_t; n: ptr cint; getid: hts_id2name_f;
                      hdr: pointer): cstringArray {.cdecl,
    importc: "hts_idx_seqnames", header: "htslib/hts.h".}
##  free only the array, not the values

proc hts_reg2bin*(beg: int64; `end`: int64; min_shift: cint; n_lvls: cint): cint {.inline, cdecl.} =
  var
    L: cint = n_lvls
    s: cint = min_shift
    t: cint = (((1 shl ((n_lvls shl 1) + n_lvls)) - 1) div 7).cint
  var fin = `end`
  dec(fin)
  while L > 0:
    if beg shr s == fin shr s: return t + (beg shr s).cint
    dec(L)
    inc(s, 3)
    dec(t, 1 shl ((L shl 1) + L))
  return 0

proc hts_bin_bot*(bin: cint; n_lvls: cint): cint {.inline, cdecl.} =
  var
    L: cint = 0
    b: cint = bin
  while b != 0:
    ##  compute the level of bin
    inc(L)
    b = hts_bin_parent(b)
  return ((bin - hts_bin_first(L)) shl (n_lvls - L) * 3).cint

## *************
##  Endianness *
## ************

proc ed_is_big*(): bool {.inline, cdecl.} =
  var one: clong
  return '\0' == ((cast[ptr char]((addr(one))))[])

proc ed_swap_2*(v: uint16): uint16 {.inline, cdecl.} =
  return (((v.uint32 and 0x00FF00FF'u32) shl 8) or ((v.uint32 and 0xFF00FF00'u32) shr 8)).uint16

proc ed_swap_2p*(x: pointer): pointer {.inline, cdecl.} =
  cast[ptr uint16](x)[] = ed_swap_2(cast[ptr uint16](x)[])
  return x

proc ed_swap_4*(vv: uint32): uint32 {.inline, cdecl.} =
  var v = vv
  v = ((v and 0x0000FFFF'u32) shl 16) or (v shr 16)
  return ((v and 0x00FF00FF'u32) shl 8) or ((v and 0xFF00FF00'u32) shr 8)

proc ed_swap_4p*(x: pointer): pointer {.inline, cdecl.} =
  cast[ptr uint32](x)[] = ed_swap_4(cast[ptr uint32](x)[])
  return x

proc ed_swap_8*(vv: uint64): uint64 {.inline, cdecl.} =
  var v = vv
  v = ((v and 0x00000000FFFFFFFF'u64) shl 32) or (v shr 32)
  v = ((v and 0x0000FFFF0000FFFF'u64) shl 16) or
      ((v and 0xFFFF0000FFFF0000'u64) shr 16)
  return ((v and 0x00FF00FF00FF00FF'u64) shl 8) or
      ((v and 0xFF00FF00FF00FF00'u64) shr 8)

proc ed_swap_8p*(x: pointer): pointer {.inline, cdecl.} =
  cast[ptr uint64](x)[] = ed_swap_8(cast[ptr uint64](x)[])
  return x
