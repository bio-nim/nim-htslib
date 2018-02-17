# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passL: "-lhts".}
## / @file htslib/hts.h
## / Format-neutral I/O, indexing, and iterator API functions.
##
##     Copyright (C) 2012-2016 Genome Research Ltd.
##     Copyright (C) 2010, 2012 Broad Institute.
##     Portions copyright (C) 2003-2006, 2008-2010 by Heng Li <lh3@live.co.uk>
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

when not defined(HTS_BGZF_TYPEDEF):
  const
    HTS_BGZF_TYPEDEF* = true
type
  cram_fd* {.importc: "cram_fd", header: "htslib/hts.h", bycopy.} = object

  hFILE* {.importc: "hFILE", header: "htslib/hts.h", bycopy.} = object

  hts_tpool* {.importc: "hts_tpool", header: "htslib/hts.h", bycopy.} = object

  kstring_t* {.importc: "kstring_t", header: "htslib/hts.h", bycopy.} = object
    l* {.importc: "l".}: csize
    m* {.importc: "m".}: csize
    s* {.importc: "s".}: cstring


when not defined(kroundup32):
  template kroundup32*(x: untyped): untyped =
    (
      dec((x))
      (x) = (x) or (x) shr 1
      (x) = (x) or (x) shr 2
      (x) = (x) or (x) shr 4
      (x) = (x) or (x) shr 8
      (x) = (x) or (x) shr 16
      inc((x)))

## *
##  @hideinitializer
##  Macro to expand a dynamic array of a given type
##
##  @param         type_t The type of the array elements
##  @param[in]     n      Requested number of elements of type type_t
##  @param[in,out] m      Size of memory allocated
##  @param[in,out] ptr    Pointer to the array
##
##  @discussion
##  The array *ptr will be expanded if necessary so that it can hold @p n
##  or more elements.  If the array is expanded then the new size will be
##  written to @p m and the value in @ptr may change.
##
##  It must be possible to take the address of @p ptr and @p m must be usable
##  as an lvalue.
##
##  @bug
##  If the memory allocation fails, this will call exit(1).  This is
##  not ideal behaviour in a library.
##

template hts_expand*(type_t, n, m, `ptr`: untyped): void =
  while true:
  if (n) > (m):
    proc hts_realloc_or_die(a2: csize; a3: csize; a4: csize; a5: csize; a6: cint;
                           a7: ptr pointer; a8: cstring): csize {.cdecl.}
    (m) = hts_realloc_or_die(if (n) >= 1: (n) else: 1, (m), sizeof((m)), sizeof((type_t)),
                           0, cast[ptr pointer](addr((`ptr`))), __func__)
  if not 0: break

## *
##  @hideinitializer
##  Macro to expand a dynamic array, zeroing any newly-allocated memory
##
##  @param         type_t The type of the array elements
##  @param[in]     n      Requested number of elements of type type_t
##  @param[in,out] m      Size of memory allocated
##  @param[in,out] ptr    Pointer to the array
##
##  @discussion
##  As for hts_expand(), except the bytes that make up the array elements
##  between the old and new values of @p m are set to zero using memset().
##
##  @bug
##  If the memory allocation fails, this will call exit(1).  This is
##  not ideal behaviour in a library.
##

template hts_expand0*(type_t, n, m, `ptr`: untyped): void =
  while true:
  if (n) > (m):
    proc hts_realloc_or_die(a2: csize; a3: csize; a4: csize; a5: csize; a6: cint;
                           a7: ptr pointer; a8: cstring): csize {.cdecl.}
    (m) = hts_realloc_or_die(if (n) >= 1: (n) else: 1, (m), sizeof((m)), sizeof((type_t)),
                           1, cast[ptr pointer](addr((`ptr`))), __func__)
  if not 0: break

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
    unknown_format, binary_format, text_format, sam, bam, bai, cram, crai, vcf, bcf, csi,
    gzi, tbi, bed, htsget, format_maximum = 32767

const
  json = htsget

type
  htsCompression* {.size: sizeof(cint).} = enum
    no_compression, gzip, bgzf, custom, compression_maximum = 32767


type
  INNER_C_STRUCT_1586747630* {.importc: "no_name", header: "htslib/hts.h", bycopy.} = object
    major* {.importc: "major".}: cshort
    minor* {.importc: "minor".}: cshort

  htsFormat* {.importc: "htsFormat", header: "htslib/hts.h", bycopy.} = object
    category* {.importc: "category".}: htsFormatCategory
    format* {.importc: "format".}: htsExactFormat
    version* {.importc: "version".}: INNER_C_STRUCT_1586747630
    compression* {.importc: "compression".}: htsCompression
    compression_level* {.importc: "compression_level".}: cshort ##  currently unused
    specific* {.importc: "specific".}: pointer ##  format specific options; see struct hts_opt.


##  Maintainers note htsFile cannot be an opaque structure because some of its
##  fields are part of libhts.so's ABI (hence these fields must not be moved):
##   - fp is used in the public sam_itr_next()/etc macros
##   - is_bin is used directly in samtools <= 1.1 and bcftools <= 1.1
##   - is_write and is_cram are used directly in samtools <= 1.1
##   - fp is used directly in samtools (up to and including current develop)
##   - line is used directly in bcftools (up to and including current develop)

type
  INNER_C_UNION_3085289003* {.importc: "no_name", header: "htslib/hts.h", bycopy.} = object {.
      union.}
    bgzf* {.importc: "bgzf".}: ptr BGZF
    cram* {.importc: "cram".}: ptr cram_fd
    hfile* {.importc: "hfile".}: ptr hFILE

  htsFile* {.importc: "htsFile", header: "htslib/hts.h", bycopy.} = object
    is_bin* {.importc: "is_bin".} {.bitsize: 1.}: uint32_t
    is_write* {.importc: "is_write".} {.bitsize: 1.}: uint32_t
    is_be* {.importc: "is_be".} {.bitsize: 1.}: uint32_t
    is_cram* {.importc: "is_cram".} {.bitsize: 1.}: uint32_t
    is_bgzf* {.importc: "is_bgzf".} {.bitsize: 1.}: uint32_t
    dummy* {.importc: "dummy".} {.bitsize: 27.}: uint32_t
    lineno* {.importc: "lineno".}: int64_t
    line* {.importc: "line".}: kstring_t
    fn* {.importc: "fn".}: cstring
    fn_aux* {.importc: "fn_aux".}: cstring
    fp* {.importc: "fp".}: INNER_C_UNION_3085289003
    format* {.importc: "format".}: htsFormat


##  A combined thread pool and queue allocation size.
##  The pool should already be defined, but qsize may be zero to
##  indicate an appropriate queue size is taken from the pool.
##
##  Reasons for explicitly setting it could be where many more file
##  descriptors are in use than threads, so keeping memory low is
##  important.

type
  htsThreadPool* {.importc: "htsThreadPool", header: "htslib/hts.h", bycopy.} = object
    pool* {.importc: "pool".}: ptr hts_tpool ##  The shared thread pool itself
    qsize* {.importc: "qsize".}: cint ##  Size of I/O queue to use for this fp


##  REQUIRED_FIELDS

type
  sam_fields* {.size: sizeof(cint).} = enum
    SAM_QNAME = 0x00000001, SAM_FLAG = 0x00000002, SAM_RNAME = 0x00000004,
    SAM_POS = 0x00000008, SAM_MAPQ = 0x00000010, SAM_CIGAR = 0x00000020,
    SAM_RNEXT = 0x00000040, SAM_PNEXT = 0x00000080, SAM_TLEN = 0x00000100,
    SAM_SEQ = 0x00000200, SAM_QUAL = 0x00000400, SAM_AUX = 0x00000800,
    SAM_RGAUX = 0x00001000


##  Mostly CRAM only, but this could also include other format options

type
  hts_fmt_option* {.size: sizeof(cint).} = enum ##  CRAM specific
    CRAM_OPT_DECODE_MD, CRAM_OPT_PREFIX, CRAM_OPT_VERBOSITY, ##  obsolete, use hts_set_log_level() instead
    CRAM_OPT_SEQS_PER_SLICE, CRAM_OPT_SLICES_PER_CONTAINER, CRAM_OPT_RANGE, CRAM_OPT_VERSION, ##  rename to cram_version?
    CRAM_OPT_EMBED_REF, CRAM_OPT_IGNORE_MD5, CRAM_OPT_REFERENCE, ##  make general
    CRAM_OPT_MULTI_SEQ_PER_SLICE, CRAM_OPT_NO_REF, CRAM_OPT_USE_BZIP2,
    CRAM_OPT_SHARED_REF, CRAM_OPT_NTHREADS, ##  deprecated, use HTS_OPT_NTHREADS
    CRAM_OPT_THREAD_POOL,     ##  make general
    CRAM_OPT_USE_LZMA, CRAM_OPT_USE_RANS, CRAM_OPT_REQUIRED_FIELDS,
    CRAM_OPT_LOSSY_NAMES, CRAM_OPT_BASES_PER_SLICE, ##  General purpose
    HTS_OPT_COMPRESSION_LEVEL = 100, HTS_OPT_NTHREADS, HTS_OPT_THREAD_POOL,
    HTS_OPT_CACHE_SIZE, HTS_OPT_BLOCK_SIZE


##  For backwards compatibility

const
  cram_option* = hts_fmt_option

type
  INNER_C_UNION_427159264* {.importc: "no_name", header: "htslib/hts.h", bycopy.} = object {.
      union.}
    i* {.importc: "i".}: cint    ##  ... and value
    s* {.importc: "s".}: cstring

  hts_opt* {.importc: "hts_opt", header: "htslib/hts.h", bycopy.} = object
    arg* {.importc: "arg".}: cstring ##  string form, strdup()ed
    opt* {.importc: "opt".}: hts_fmt_option ##  tokenised key
    val* {.importc: "val".}: INNER_C_UNION_427159264
    next* {.importc: "next".}: ptr hts_opt


## *********************
##  Exported functions *
## ********************
##
##  Parses arg and appends it to the option list.
##
##  Returns 0 on success;
##         -1 on failure.
##

proc hts_opt_add*(opts: ptr ptr hts_opt; c_arg: cstring): cint {.cdecl,
    importc: "hts_opt_add", header: "htslib/hts.h".}
##
##  Applies an hts_opt option list to a given htsFile.
##
##  Returns 0 on success
##         -1 on failure
##

proc hts_opt_apply*(fp: ptr htsFile; opts: ptr hts_opt): cint {.cdecl,
    importc: "hts_opt_apply", header: "htslib/hts.h".}
##
##  Frees an hts_opt list.
##

proc hts_opt_free*(opts: ptr hts_opt) {.cdecl, importc: "hts_opt_free", header: "htslib/hts.h".}
##
##  Accepts a string file format (sam, bam, cram, vcf, bam) optionally
##  followed by a comma separated list of key=value options and splits
##  these up into the fields of htsFormat struct.
##
##  Returns 0 on success
##         -1 on failure.
##

proc hts_parse_format*(opt: ptr htsFormat; str: cstring): cint {.cdecl,
    importc: "hts_parse_format", header: "htslib/hts.h".}
##
##  Tokenise options as (key(=value)?,)*(key(=value)?)?
##  NB: No provision for ',' appearing in the value!
##  Add backslashing rules?
##
##  This could be used as part of a general command line option parser or
##  as a string concatenated onto the file open mode.
##
##  Returns 0 on success
##         -1 on failure.
##

proc hts_parse_opt_list*(opt: ptr htsFormat; str: cstring): cint {.cdecl,
    importc: "hts_parse_opt_list", header: "htslib/hts.h".}
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
##   @param fmt   Format structure holding type, version, compression, etc.
##   @return      Description string, to be freed by the caller after use.
##

proc hts_format_description*(format: ptr htsFormat): cstring {.cdecl,
    importc: "hts_format_description", header: "htslib/hts.h".}
## !
##   @abstract       Open a SAM/BAM/CRAM/VCF/BCF/etc file
##   @param fn       The file name or "-" for stdin/stdout
##   @param mode     Mode matching / [rwa][bceguxz0-9]* /
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
##       and with non-format option letters (for any of 'r'/'w'/'a'):
##         e  close the file on exec(2) (opens with O_CLOEXEC, where supported)
##         x  create the file exclusively (opens with O_EXCL, where supported)
##       Note that there is a distinction between 'u' and '0': the first yields
##       plain uncompressed output whereas the latter outputs uncompressed data
##       wrapped in the zlib format.
##   @example
##       [rw]b  .. compressed BCF, BAM, FAI
##       [rw]bu .. uncompressed BCF
##       [rw]z  .. compressed VCF
##       [rw]   .. uncompressed VCF
##

proc hts_open*(fn: cstring; mode: cstring): ptr htsFile {.cdecl, importc: "hts_open",
    header: "htslib/hts.h".}
## !
##   @abstract       Open a SAM/BAM/CRAM/VCF/BCF/etc file
##   @param fn       The file name or "-" for stdin/stdout
##   @param mode     Open mode, as per hts_open()
##   @param fmt      Optional format specific parameters
##   @discussion
##       See hts_open() for description of fn and mode.
##       // TODO Update documentation for s/opts/fmt/
##       Opts contains a format string (sam, bam, cram, vcf, bcf) which will,
##       if defined, override mode.  Opts also contains a linked list of hts_opt
##       structures to apply to the open file handle.  These can contain things
##       like pointers to the reference or information on compression levels,
##       block sizes, etc.
##

proc hts_open_format*(fn: cstring; mode: cstring; fmt: ptr htsFormat): ptr htsFile {.
    cdecl, importc: "hts_open_format", header: "htslib/hts.h".}
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
##   @ abstract      Returns a string containing the file format extension.
##   @ param format  Format structure containing the file type.
##   @ return        A string ("sam", "bam", etc) or "?" for unknown formats.
##

proc hts_format_file_extension*(format: ptr htsFormat): cstring {.cdecl,
    importc: "hts_format_file_extension", header: "htslib/hts.h".}
## !
##   @abstract  Sets a specified CRAM option on the open file handle.
##   @param fp  The file handle open the open file.
##   @param opt The CRAM_OPT_* option.
##   @param ... Optional arguments, dependent on the option used.
##   @return    0 for success, or negative if an error occurred.
##

proc hts_set_opt*(fp: ptr htsFile; opt: hts_fmt_option): cint {.varargs, cdecl,
    importc: "hts_set_opt", header: "htslib/hts.h".}
proc hts_getline*(fp: ptr htsFile; delimiter: cint; str: ptr kstring_t): cint {.cdecl,
    importc: "hts_getline", header: "htslib/hts.h".}
proc hts_readlines*(fn: cstring; _n: ptr cint): cstringArray {.cdecl,
    importc: "hts_readlines", header: "htslib/hts.h".}
## !
##     @abstract       Parse comma-separated list or read list from a file
##     @param list     File name or comma-separated list
##     @param is_file
##     @param _n       Size of the output array (number of items read)
##     @return         NULL on failure or pointer to newly allocated array of
##                     strings
##

proc hts_readlist*(fn: cstring; is_file: cint; _n: ptr cint): cstringArray {.cdecl,
    importc: "hts_readlist", header: "htslib/hts.h".}
## !
##   @abstract  Create extra threads to aid compress/decompression for this file
##   @param fp  The file handle
##   @param n   The number of worker threads to create
##   @return    0 for success, or negative if an error occurred.
##   @notes     This function creates non-shared threads for use solely by fp.
##              The hts_set_thread_pool function is the recommended alternative.
##

proc hts_set_threads*(fp: ptr htsFile; n: cint): cint {.cdecl,
    importc: "hts_set_threads", header: "htslib/hts.h".}
## !
##   @abstract  Create extra threads to aid compress/decompression for this file
##   @param fp  The file handle
##   @param p   A pool of worker threads, previously allocated by hts_create_threads().
##   @return    0 for success, or negative if an error occurred.
##

proc hts_set_thread_pool*(fp: ptr htsFile; p: ptr htsThreadPool): cint {.cdecl,
    importc: "hts_set_thread_pool", header: "htslib/hts.h".}
## !
##   @abstract  Adds a cache of decompressed blocks, potentially speeding up seeks.
##              This may not work for all file types (currently it is bgzf only).
##   @param fp  The file handle
##   @param n   The size of cache, in bytes
##

proc hts_set_cache_size*(fp: ptr htsFile; n: cint) {.cdecl,
    importc: "hts_set_cache_size", header: "htslib/hts.h".}
## !
##   @abstract  Set .fai filename for a file opened for reading
##   @return    0 for success, negative on failure
##   @discussion
##       Called before *_hdr_read(), this provides the name of a .fai file
##       used to provide a reference list if the htsFile contains no @SQ headers.
##

proc hts_set_fai_filename*(fp: ptr htsFile; fn_aux: cstring): cint {.cdecl,
    importc: "hts_set_fai_filename", header: "htslib/hts.h".}
## !
##   @abstract  Determine whether a given htsFile contains a valid EOF block
##   @return    3 for a non-EOF checkable filetype;
##              2 for an unseekable file type where EOF cannot be checked;
##              1 for a valid EOF block;
##              0 for if the EOF marker is absent when it should be present;
##             -1 (with errno set) on failure
##   @discussion
##       Check if the BGZF end-of-file (EOF) marker is present
##

proc hts_check_EOF*(fp: ptr htsFile): cint {.cdecl, importc: "hts_check_EOF",
                                        header: "htslib/hts.h".}
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
  HTS_IDX_NOCOOR* = (-2)
  HTS_IDX_START* = (-3)
  HTS_IDX_REST* = (-4)
  HTS_IDX_NONE* = (-5)
  HTS_FMT_CSI* = 0
  HTS_FMT_BAI* = 1
  HTS_FMT_TBI* = 2
  HTS_FMT_CRAI* = 3

type
  __hts_idx_t* {.importc: "__hts_idx_t", header: "htslib/hts.h", bycopy.} = object

  INNER_C_STRUCT_436670879* {.importc: "no_name", header: "htslib/hts.h", bycopy.} = object
    n* {.importc: "n".}: cint
    m* {.importc: "m".}: cint
    a* {.importc: "a".}: ptr cint

  hts_idx_t* = __hts_idx_t
  hts_pair64_t* {.importc: "hts_pair64_t", header: "htslib/hts.h", bycopy.} = object
    u* {.importc: "u".}: uint64_t
    v* {.importc: "v".}: uint64_t

  hts_readrec_func* = proc (fp: ptr BGZF; data: pointer; r: pointer; tid: ptr cint;
                         beg: ptr cint; `end`: ptr cint): cint {.cdecl.}
  hts_itr_t* {.importc: "hts_itr_t", header: "htslib/hts.h", bycopy.} = object
    read_rest* {.importc: "read_rest".} {.bitsize: 1.}: uint32_t
    finished* {.importc: "finished".} {.bitsize: 1.}: uint32_t
    is_cram* {.importc: "is_cram".} {.bitsize: 1.}: uint32_t
    dummy* {.importc: "dummy".} {.bitsize: 29.}: uint32_t
    tid* {.importc: "tid".}: cint
    beg* {.importc: "beg".}: cint
    `end`* {.importc: "end".}: cint
    n_off* {.importc: "n_off".}: cint
    i* {.importc: "i".}: cint
    curr_tid* {.importc: "curr_tid".}: cint
    curr_beg* {.importc: "curr_beg".}: cint
    curr_end* {.importc: "curr_end".}: cint
    curr_off* {.importc: "curr_off".}: uint64_t
    off* {.importc: "off".}: ptr hts_pair64_t
    readrec* {.importc: "readrec".}: ptr hts_readrec_func
    bins* {.importc: "bins".}: INNER_C_STRUCT_436670879


template hts_bin_first*(l: untyped): untyped =
  (((1 shl (((l) shl 1) + (l))) - 1) div 7)

template hts_bin_parent*(l: untyped): untyped =
  (((l) - 1) shr 3)

proc hts_idx_init*(n: cint; fmt: cint; offset0: uint64_t; min_shift: cint; n_lvls: cint): ptr hts_idx_t {.
    cdecl, importc: "hts_idx_init", header: "htslib/hts.h".}
proc hts_idx_destroy*(idx: ptr hts_idx_t) {.cdecl, importc: "hts_idx_destroy",
                                        header: "htslib/hts.h".}
proc hts_idx_push*(idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint;
                  offset: uint64_t; is_mapped: cint): cint {.cdecl,
    importc: "hts_idx_push", header: "htslib/hts.h".}
proc hts_idx_finish*(idx: ptr hts_idx_t; final_offset: uint64_t) {.cdecl,
    importc: "hts_idx_finish", header: "htslib/hts.h".}
## / Save an index to a file
## * @param idx  Index to be written
##     @param fn   Input BAM/BCF/etc filename, to which .bai/.csi/etc will be added
##     @param fmt  One of the HTS_FMT_* index formats
##     @return  0 if successful, or negative if an error occurred.
##

proc hts_idx_save*(idx: ptr hts_idx_t; fn: cstring; fmt: cint): cint {.cdecl,
    importc: "hts_idx_save", header: "htslib/hts.h".}
## / Save an index to a specific file
## * @param idx    Index to be written
##     @param fn     Input BAM/BCF/etc filename
##     @param fnidx  Output filename, or NULL to add .bai/.csi/etc to @a fn
##     @param fmt    One of the HTS_FMT_* index formats
##     @return  0 if successful, or negative if an error occurred.
##

proc hts_idx_save_as*(idx: ptr hts_idx_t; fn: cstring; fnidx: cstring; fmt: cint): cint {.
    cdecl, importc: "hts_idx_save_as", header: "htslib/hts.h".}
## / Load an index file
## * @param fn   BAM/BCF/etc filename, to which .bai/.csi/etc will be added or
##                 the extension substituted, to search for an existing index file
##     @param fmt  One of the HTS_FMT_* index formats
##     @return  The index, or NULL if an error occurred.
##

proc hts_idx_load*(fn: cstring; fmt: cint): ptr hts_idx_t {.cdecl,
    importc: "hts_idx_load", header: "htslib/hts.h".}
## / Load a specific index file
## * @param fn     Input BAM/BCF/etc filename
##     @param fnidx  The input index filename
##     @return  The index, or NULL if an error occurred.
##

proc hts_idx_load2*(fn: cstring; fnidx: cstring): ptr hts_idx_t {.cdecl,
    importc: "hts_idx_load2", header: "htslib/hts.h".}
## / Get extra index meta-data
## * @param idx    The index
##     @param l_meta Pointer to where the length of the extra data is stored
##     @return Pointer to the extra data if present; NULL otherwise
##
##     Indexes (both .tbi and .csi) made by tabix include extra data about
##     the indexed file.  The returns a pointer to this data.  Note that the
##     data is stored exactly as it is in the index.  Callers need to interpret
##     the results themselves, including knowing what sort of data to expect;
##     byte swapping etc.
##

proc hts_idx_get_meta*(idx: ptr hts_idx_t; l_meta: ptr uint32_t): ptr uint8_t {.cdecl,
    importc: "hts_idx_get_meta", header: "htslib/hts.h".}
## / Set extra index meta-data
## * @param idx     The index
##     @param l_meta  Length of data
##     @param meta    Pointer to the extra data
##     @param is_copy If not zero, a copy of the data is taken
##     @return 0 on success; -1 on failure (out of memory).
##
##     Sets the data that is returned by hts_idx_get_meta().
##
##     If is_copy != 0, a copy of the input data is taken.  If not, ownership of
##     the data pointed to by *meta passes to the index.
##

proc hts_idx_set_meta*(idx: ptr hts_idx_t; l_meta: uint32_t; meta: ptr uint8_t;
                      is_copy: cint): cint {.cdecl, importc: "hts_idx_set_meta",
    header: "htslib/hts.h".}
proc hts_idx_get_stat*(idx: ptr hts_idx_t; tid: cint; mapped: ptr uint64_t;
                      unmapped: ptr uint64_t): cint {.cdecl,
    importc: "hts_idx_get_stat", header: "htslib/hts.h".}
proc hts_idx_get_n_no_coor*(idx: ptr hts_idx_t): uint64_t {.cdecl,
    importc: "hts_idx_get_n_no_coor", header: "htslib/hts.h".}
const
  HTS_PARSE_THOUSANDS_SEP* = 1

## / Parse a numeric string
## * The number may be expressed in scientific notation, and optionally may
##     contain commas in the integer part (before any decimal point or E notation).
##     @param str     String to be parsed
##     @param strend  If non-NULL, set on return to point to the first character
##                    in @a str after those forming the parsed number
##     @param flags   Or'ed-together combination of HTS_PARSE_* flags
##     @return  Converted value of the parsed number.
##
##     When @a strend is NULL, a warning will be printed (if hts_verbose is HTS_LOG_WARNING
##     or more) if there are any trailing characters after the number.
##

proc hts_parse_decimal*(str: cstring; strend: cstringArray; flags: cint): clonglong {.
    cdecl, importc: "hts_parse_decimal", header: "htslib/hts.h".}
## / Parse a "CHR:START-END"-style region string
## * @param str  String to be parsed
##     @param beg  Set on return to the 0-based start of the region
##     @param end  Set on return to the 1-based end of the region
##     @return  Pointer to the colon or '\0' after the reference sequence name,
##              or NULL if @a str could not be parsed.
##

proc hts_parse_reg*(str: cstring; beg: ptr cint; `end`: ptr cint): cstring {.cdecl,
    importc: "hts_parse_reg", header: "htslib/hts.h".}
proc hts_itr_query*(idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint;
                   readrec: ptr hts_readrec_func): ptr hts_itr_t {.cdecl,
    importc: "hts_itr_query", header: "htslib/hts.h".}
proc hts_itr_destroy*(iter: ptr hts_itr_t) {.cdecl, importc: "hts_itr_destroy",
    header: "htslib/hts.h".}
type
  hts_name2id_f* = proc (a2: pointer; a3: cstring): cint {.cdecl.}
  hts_id2name_f* = proc (a2: pointer; a3: cint): cstring {.cdecl.}
  hts_itr_query_func* = proc (idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint;
                           readrec: ptr hts_readrec_func): ptr hts_itr_t {.cdecl.}

proc hts_itr_querys*(idx: ptr hts_idx_t; reg: cstring; getid: hts_name2id_f;
                    hdr: pointer; itr_query: ptr hts_itr_query_func;
                    readrec: ptr hts_readrec_func): ptr hts_itr_t {.cdecl,
    importc: "hts_itr_querys", header: "htslib/hts.h".}
proc hts_itr_next*(fp: ptr BGZF; iter: ptr hts_itr_t; r: pointer; data: pointer): cint {.
    cdecl, importc: "hts_itr_next", header: "htslib/hts.h".}
proc hts_idx_seqnames*(idx: ptr hts_idx_t; n: ptr cint; getid: hts_id2name_f;
                      hdr: pointer): cstringArray {.cdecl,
    importc: "hts_idx_seqnames", header: "htslib/hts.h".}
##  free only the array, not the values
## *
##  hts_file_type() - Convenience function to determine file type
##  DEPRECATED:  This function has been replaced by hts_detect_format().
##  It and these FT_* macros will be removed in a future HTSlib release.
##

const
  FT_UNKN* = 0
  FT_GZ* = 1
  FT_VCF* = 2
  FT_VCF_GZ* = (FT_GZ or FT_VCF)
  FT_BCF* = (1 shl 2)
  FT_BCF_GZ* = (FT_GZ or FT_BCF)
  FT_STDIN* = (1 shl 3)

proc hts_file_type*(fname: cstring): cint {.cdecl, importc: "hts_file_type",
                                        header: "htslib/hts.h".}
## **************************
##  Revised MAQ error model *
## *************************

type
  errmod_t* {.importc: "errmod_t", header: "htslib/hts.h", bycopy.} = object


proc errmod_init*(depcorr: cdouble): ptr errmod_t {.cdecl, importc: "errmod_init",
    header: "htslib/hts.h".}
proc errmod_destroy*(em: ptr errmod_t) {.cdecl, importc: "errmod_destroy",
                                     header: "htslib/hts.h".}
##
##     n: number of bases
##     m: maximum base
##     bases[i]: qual:6, strand:1, base:4
##     q[i*m+j]: phred-scaled likelihood of (i,j)
##

proc errmod_cal*(em: ptr errmod_t; n: cint; m: cint; bases: ptr uint16_t; q: ptr cfloat): cint {.
    cdecl, importc: "errmod_cal", header: "htslib/hts.h".}
## ****************************************
##  Probabilistic banded glocal alignment *
## ***************************************

type
  probaln_par_t* {.importc: "probaln_par_t", header: "htslib/hts.h", bycopy.} = object
    d* {.importc: "d".}: cfloat
    e* {.importc: "e".}: cfloat
    bw* {.importc: "bw".}: cint


proc probaln_glocal*(`ref`: ptr uint8_t; l_ref: cint; query: ptr uint8_t; l_query: cint;
                    iqual: ptr uint8_t; c: ptr probaln_par_t; state: ptr cint;
                    q: ptr uint8_t): cint {.cdecl, importc: "probaln_glocal",
                                        header: "htslib/hts.h".}
## *********************
##  MD5 implementation *
## ********************

type
  hts_md5_context* {.importc: "hts_md5_context", header: "htslib/hts.h", bycopy.} = object


## ! @abstract   Intialises an MD5 context.
##   @discussion
##     The expected use is to allocate an hts_md5_context using
##     hts_md5_init().  This pointer is then passed into one or more calls
##     of hts_md5_update() to compute successive internal portions of the
##     MD5 sum, which can then be externalised as a full 16-byte MD5sum
##     calculation by calling hts_md5_final().  This can then be turned
##     into ASCII via hts_md5_hex().
##
##     To dealloate any resources created by hts_md5_init() call the
##     hts_md5_destroy() function.
##
##   @return     hts_md5_context pointer on success, NULL otherwise.
##

proc hts_md5_init*(): ptr hts_md5_context {.cdecl, importc: "hts_md5_init",
                                        header: "htslib/hts.h".}
## ! @abstract Updates the context with the MD5 of the data.

proc hts_md5_update*(ctx: ptr hts_md5_context; data: pointer; size: culong) {.cdecl,
    importc: "hts_md5_update", header: "htslib/hts.h".}
## ! @abstract Computes the final 128-bit MD5 hash from the given context

proc hts_md5_final*(digest: ptr cuchar; ctx: ptr hts_md5_context) {.cdecl,
    importc: "hts_md5_final", header: "htslib/hts.h".}
## ! @abstract Resets an md5_context to the initial state, as returned
##             by hts_md5_init().
##

proc hts_md5_reset*(ctx: ptr hts_md5_context) {.cdecl, importc: "hts_md5_reset",
    header: "htslib/hts.h".}
## ! @abstract Converts a 128-bit MD5 hash into a 33-byte nul-termninated
##             hex string.
##

proc hts_md5_hex*(hex: cstring; digest: ptr cuchar) {.cdecl, importc: "hts_md5_hex",
    header: "htslib/hts.h".}
## ! @abstract Deallocates any memory allocated by hts_md5_init.

proc hts_md5_destroy*(ctx: ptr hts_md5_context) {.cdecl, importc: "hts_md5_destroy",
    header: "htslib/hts.h".}
proc hts_reg2bin*(beg: int64_t; `end`: int64_t; min_shift: cint; n_lvls: cint): cint {.
    inline, cdecl.} =
  var
    l: cint
    s: cint
    t: cint
  dec(`end`)
  l = n_lvls
  while l > 0:
    if beg shr s == `end` shr s: return t + (beg shr s)
    dec(l)
    inc(s, 3)
    dec(t, 1 shl ((l shl 1) + l))
  return 0

proc hts_bin_bot*(bin: cint; n_lvls: cint): cint {.inline, cdecl.} =
  var
    l: cint
    b: cint
  l = 0
  b = bin
  while b:
    ##  compute the level of bin
    inc(l)
    b = hts_bin_parent(b)
  return (bin - hts_bin_first(l)) shl (n_lvls - l) * 3

## *************
##  Endianness *
## ************

proc ed_is_big*(): cint {.inline, cdecl.} =
  var one: clong
  return not ((cast[cstring]((addr(one))))[])

proc ed_swap_2*(v: uint16_t): uint16_t {.inline, cdecl.} =
  return (uint16_t)(((v and 0x00FF00FF) shl 8) or ((v and 0xFF00FF00) shr 8))

proc ed_swap_2p*(x: pointer): pointer {.inline, cdecl.} =
  cast[ptr uint16_t](x)[] = ed_swap_2(cast[ptr uint16_t](x)[])
  return x

proc ed_swap_4*(v: uint32_t): uint32_t {.inline, cdecl.} =
  v = ((v and 0x0000FFFF) shl 16) or (v shr 16)
  return ((v and 0x00FF00FF) shl 8) or ((v and 0xFF00FF00) shr 8)

proc ed_swap_4p*(x: pointer): pointer {.inline, cdecl.} =
  cast[ptr uint32_t](x)[] = ed_swap_4(cast[ptr uint32_t](x)[])
  return x

proc ed_swap_8*(v: uint64_t): uint64_t {.inline, cdecl.} =
  v = ((v and 0x00000000FFFFFFFF'i64) shl 32) or (v shr 32)
  v = ((v and 0x0000FFFF0000FFFF'i64) shl 16) or
      ((v and 0xFFFF0000FFFF0000'i64) shr 16)
  return ((v and 0x00FF00FF00FF00FF'i64) shl 8) or
      ((v and 0xFF00FF00FF00FF00'i64) shr 8)

proc ed_swap_8p*(x: pointer): pointer {.inline, cdecl.} =
  cast[ptr uint64_t](x)[] = ed_swap_8(cast[ptr uint64_t](x)[])
  return x

