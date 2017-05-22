# vim: sw=2 ts=2 sts=2 tw=80 et:
##  The MIT License
##
##    Copyright (c) 2008 Broad Institute / Massachusetts Institute of Technology
##                  2011, 2012 Attractive Chaos <attractor@live.co.uk>
##    Copyright (C) 2009, 2013, 2014 Genome Research Ltd
##
##    Permission is hereby granted, free of charge, to any person obtaining a copy
##    of this software and associated documentation files (the "Software"), to deal
##    in the Software without restriction, including without limitation the rights
##    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##    copies of the Software, and to permit persons to whom the Software is
##    furnished to do so, subject to the following conditions:
##
##    The above copyright notice and this permission notice shall be included in
##    all copies or substantial portions of the Software.
##
##    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
##    THE SOFTWARE.
##
##  The BGZF library was originally written by Bob Handsaker from the Broad
##  Institute. It was later improved by the SAMtools developers.

const
  BGZF_BLOCK_SIZE* = 0x0000FF00
  BGZF_MAX_BLOCK_SIZE* = 0x00010000
  BGZF_ERR_ZLIB* = 1
  BGZF_ERR_HEADER* = 2
  BGZF_ERR_IO* = 4
  BGZF_ERR_MISUSE* = 8

type
  hFILE* {.importc: "hFILE", header: "htslib/bgzf.h".} = object

  bgzf_mtaux_t* {.importc: "bgzf_mtaux_t", header: "htslib/bgzf.h".} = object

  bgzidx_t* = __bgzidx_t
  BGZF* {.importc: "BGZF", header: "htslib/bgzf.h".} = object
    errcode* {.importc: "errcode".} {.bitsize: 16.}: cint
    is_write* {.importc: "is_write".} {.bitsize: 2.}: cint
    is_be* {.importc: "is_be".} {.bitsize: 2.}: cint
    compress_level* {.importc: "compress_level".} {.bitsize: 9.}: cint
    is_compressed* {.importc: "is_compressed".} {.bitsize: 2.}: cint
    is_gzip* {.importc: "is_gzip".} {.bitsize: 1.}: cint
    cache_size* {.importc: "cache_size".}: cint
    block_length* {.importc: "block_length".}: cint
    block_offset* {.importc: "block_offset".}: cint
    block_address* {.importc: "block_address".}: int64_t
    uncompressed_address* {.importc: "uncompressed_address".}: int64_t
    uncompressed_block* {.importc: "uncompressed_block".}: pointer
    compressed_block* {.importc: "compressed_block".}: pointer
    cache* {.importc: "cache".}: pointer ##  a pointer to a hash table
    fp* {.importc: "fp".}: ptr hFILE ##  actual file handle
    mt* {.importc: "mt".}: ptr bgzf_mtaux_t ##  only used for multi-threading
    idx* {.importc: "idx".}: ptr bgzidx_t ##  BGZF index
    idx_build_otf* {.importc: "idx_build_otf".}: cint ##  build index on the fly, set by bgzf_index_build_init()
    gz_stream* {.importc: "gz_stream".}: ptr z_stream ##  for gzip-compressed files


when not defined(HTS_BGZF_TYPEDEF):
  const
    HTS_BGZF_TYPEDEF* = true
type
  kstring_t* {.importc: "kstring_t", header: "htslib/bgzf.h".} = object
    l* {.importc: "l".}: csize
    m* {.importc: "m".}: csize
    s* {.importc: "s".}: cstring


## *****************
##  Basic routines *
## ****************
## *
##  Open an existing file descriptor for reading or writing.
##
##  @param fd    file descriptor
##  @param mode  mode matching /[rwag][u0-9]+/: 'r' for reading, 'w' for
##               writing, 'a' for appending, 'g' for gzip rather than BGZF
##               compression (with 'w' only), and digit specifies the zlib
##               compression level.
##               Note that there is a distinction between 'u' and '0': the
##               first yields plain uncompressed output whereas the latter
##               outputs uncompressed data wrapped in the zlib format.
##  @return      BGZF file handler; 0 on error
##

proc bgzf_dopen*(fd: cint; mode: cstring): ptr BGZF {.cdecl, importc: "bgzf_dopen",
    header: "htslib/bgzf.h".}

var bgzf_fdopen* = bgzf_dopen
#template bgzf_fdopen*(fd, mode: untyped): untyped =
#  bgzf_dopen((fd), (mode))     ##  for backward compatibility

## *
##  Open the specified file for reading or writing.
##

proc bgzf_open*(path: cstring; mode: cstring): ptr BGZF {.cdecl, importc: "bgzf_open",
    header: "htslib/bgzf.h".}
## *
##  Open an existing hFILE stream for reading or writing.
##

proc bgzf_hopen*(fp: ptr hFILE; mode: cstring): ptr BGZF {.cdecl, importc: "bgzf_hopen",
    header: "htslib/bgzf.h".}
## *
##  Close the BGZF and free all associated resources.
##
##  @param fp    BGZF file handler
##  @return      0 on success and -1 on error
##

proc bgzf_close*(fp: ptr BGZF): cint {.cdecl, importc: "bgzf_close", header: "htslib/bgzf.h".}
## *
##  Read up to _length_ bytes from the file storing into _data_.
##
##  @param fp     BGZF file handler
##  @param data   data array to read into
##  @param length size of data to read
##  @return       number of bytes actually read; 0 on end-of-file and -1 on error
##

proc bgzf_read*(fp: ptr BGZF; data: pointer; length: csize): ssize_t {.cdecl,
    importc: "bgzf_read", header: "htslib/bgzf.h".}
## *
##  Write _length_ bytes from _data_ to the file.  If no I/O errors occur,
##  the complete _length_ bytes will be written (or queued for writing).
##
##  @param fp     BGZF file handler
##  @param data   data array to write
##  @param length size of data to write
##  @return       number of bytes written (i.e., _length_); negative on error
##

proc bgzf_write*(fp: ptr BGZF; data: pointer; length: csize): ssize_t {.cdecl,
    importc: "bgzf_write", header: "htslib/bgzf.h".}
## *
##  Read up to _length_ bytes directly from the underlying stream without
##  decompressing.  Bypasses BGZF blocking, so must be used with care in
##  specialised circumstances only.
##
##  @param fp     BGZF file handler
##  @param data   data array to read into
##  @param length number of raw bytes to read
##  @return       number of bytes actually read; 0 on end-of-file and -1 on error
##

proc bgzf_raw_read*(fp: ptr BGZF; data: pointer; length: csize): ssize_t {.cdecl,
    importc: "bgzf_raw_read", header: "htslib/bgzf.h".}
## *
##  Write _length_ bytes directly to the underlying stream without
##  compressing.  Bypasses BGZF blocking, so must be used with care
##  in specialised circumstances only.
##
##  @param fp     BGZF file handler
##  @param data   data array to write
##  @param length number of raw bytes to write
##  @return       number of bytes actually written; -1 on error
##

proc bgzf_raw_write*(fp: ptr BGZF; data: pointer; length: csize): ssize_t {.cdecl,
    importc: "bgzf_raw_write", header: "htslib/bgzf.h".}
## *
##  Write the data in the buffer to the file.
##

proc bgzf_flush*(fp: ptr BGZF): cint {.cdecl, importc: "bgzf_flush", header: "htslib/bgzf.h".}
## *
##  Return a virtual file pointer to the current location in the file.
##  No interpetation of the value should be made, other than a subsequent
##  call to bgzf_seek can be used to position the file at the same point.
##  Return value is non-negative on success.
##

template bgzf_tell*(fp: untyped): untyped =
  (((fp).block_address shl 16) or ((fp).block_offset and 0x0000FFFF))

## *
##  Set the file to read from the location specified by _pos_.
##
##  @param fp     BGZF file handler
##  @param pos    virtual file offset returned by bgzf_tell()
##  @param whence must be SEEK_SET
##  @return       0 on success and -1 on error
##

proc bgzf_seek*(fp: ptr BGZF; pos: int64_t; whence: cint): int64_t {.cdecl,
    importc: "bgzf_seek", header: "htslib/bgzf.h".}
## *
##  Check if the BGZF end-of-file (EOF) marker is present
##
##  @param fp    BGZF file handler opened for reading
##  @return      1 if the EOF marker is present and correct;
##               2 if it can't be checked, e.g., because fp isn't seekable;
##               0 if the EOF marker is absent;
##               -1 (with errno set) on error
##

proc bgzf_check_EOF*(fp: ptr BGZF): cint {.cdecl, importc: "bgzf_check_EOF",
                                      header: "htslib/bgzf.h".}
## *
##  Check if a file is in the BGZF format
##
##  @param fn    file name
##  @return      1 if _fn_ is BGZF; 0 if not or on I/O error
##

proc bgzf_is_bgzf*(fn: cstring): cint {.cdecl, importc: "bgzf_is_bgzf",
                                    header: "htslib/bgzf.h".}
## ********************
##  Advanced routines *
## *******************
## *
##  Set the cache size. Only effective when compiled with -DBGZF_CACHE.
##
##  @param fp    BGZF file handler
##  @param size  size of cache in bytes; 0 to disable caching (default)
##

proc bgzf_set_cache_size*(fp: ptr BGZF; size: cint) {.cdecl,
    importc: "bgzf_set_cache_size", header: "htslib/bgzf.h".}
## *
##  Flush the file if the remaining buffer size is smaller than _size_
##  @return      0 if flushing succeeded or was not needed; negative on error
##

proc bgzf_flush_try*(fp: ptr BGZF; size: ssize_t): cint {.cdecl,
    importc: "bgzf_flush_try", header: "htslib/bgzf.h".}
## *
##  Read one byte from a BGZF file. It is faster than bgzf_read()
##  @param fp     BGZF file handler
##  @return       byte read; -1 on end-of-file or error
##

proc bgzf_getc*(fp: ptr BGZF): cint {.cdecl, importc: "bgzf_getc", header: "htslib/bgzf.h".}
## *
##  Read one line from a BGZF file. It is faster than bgzf_getc()
##
##  @param fp     BGZF file handler
##  @param delim  delimitor
##  @param str    string to write to; must be initialized
##  @return       length of the string; 0 on end-of-file; negative on error
##

proc bgzf_getline*(fp: ptr BGZF; delim: cint; str: ptr kstring_t): cint {.cdecl,
    importc: "bgzf_getline", header: "htslib/bgzf.h".}
## *
##  Read the next BGZF block.
##

proc bgzf_read_block*(fp: ptr BGZF): cint {.cdecl, importc: "bgzf_read_block",
                                       header: "htslib/bgzf.h".}
## *
##  Enable multi-threading (only effective on writing and when the
##  library was compiled with -DBGZF_MT)
##
##  @param fp          BGZF file handler; must be opened for writing
##  @param n_threads   #threads used for writing
##  @param n_sub_blks  #blocks processed by each thread; a value 64-256 is recommended
##

proc bgzf_mt*(fp: ptr BGZF; n_threads: cint; n_sub_blks: cint): cint {.cdecl,
    importc: "bgzf_mt", header: "htslib/bgzf.h".}
## ******************
##  bgzidx routines *
## *****************
## *
##   Position BGZF at the uncompressed offset
##
##   @param fp           BGZF file handler; must be opened for reading
##   @param uoffset      file offset in the uncompressed data
##   @param where        SEEK_SET supported atm
##
##   Returns 0 on success and -1 on error.
##

proc bgzf_useek*(fp: ptr BGZF; uoffset: clong; where: cint): cint {.cdecl,
    importc: "bgzf_useek", header: "htslib/bgzf.h".}
## *
##   Position in uncompressed BGZF
##
##   @param fp           BGZF file handler; must be opened for reading
##
##   Returns the current offset on success and -1 on error.
##

proc bgzf_utell*(fp: ptr BGZF): clong {.cdecl, importc: "bgzf_utell", header: "htslib/bgzf.h".}
## *
##  Tell BGZF to build index while compressing.
##
##  @param fp          BGZF file handler; can be opened for reading or writing.
##
##  Returns 0 on success and -1 on error.
##

proc bgzf_index_build_init*(fp: ptr BGZF): cint {.cdecl,
    importc: "bgzf_index_build_init", header: "htslib/bgzf.h".}
## *
##  Load BGZF index
##
##  @param fp          BGZF file handler
##  @param bname       base name
##  @param suffix      suffix to add to bname (can be NULL)
##
##  Returns 0 on success and -1 on error.
##

proc bgzf_index_load*(fp: ptr BGZF; bname: cstring; suffix: cstring): cint {.cdecl,
    importc: "bgzf_index_load", header: "htslib/bgzf.h".}
## *
##  Save BGZF index
##
##  @param fp          BGZF file handler
##  @param bname       base name
##  @param suffix      suffix to add to bname (can be NULL)
##
##  Returns 0 on success and -1 on error.
##

proc bgzf_index_dump*(fp: ptr BGZF; bname: cstring; suffix: cstring): cint {.cdecl,
    importc: "bgzf_index_dump", header: "htslib/bgzf.h".}
