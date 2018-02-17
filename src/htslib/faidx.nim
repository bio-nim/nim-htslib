# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passL: "-lhts".}
## / @file htslib/faidx.h
## / FASTA random access.
##
##    Copyright (C) 2008, 2009, 2013, 2014, 2016, 2017 Genome Research Ltd.
##
##    Author: Heng Li <lh3@sanger.ac.uk>
##
##    Permission is hereby granted, free of charge, to any person obtaining
##    a copy of this software and associated documentation files (the
##    "Software"), to deal in the Software without restriction, including
##    without limitation the rights to use, copy, modify, merge, publish,
##    distribute, sublicense, and/or sell copies of the Software, and to
##    permit persons to whom the Software is furnished to do so, subject to
##    the following conditions:
##
##    The above copyright notice and this permission notice shall be
##    included in all copies or substantial portions of the Software.
##
##    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
##    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
##    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
##    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
##    BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
##    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
##    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##    SOFTWARE.
##

## * @file
##
##   Index FASTA files and extract subsequence.
##
##   The fai file index columns are:
##     - chromosome name
##     - chromosome length: number of bases
##     - offset: number of bytes to skip to get to the first base
##         from the beginning of the file, including the length
##         of the sequence description string (`>chr ..\n`)
##     - line length: number of bases per line (excluding `\n`)
##     - binary line length: number of bytes, including `\n`
##

type
  struct_faidx_t* {.importc: "struct __faidx_t", header: "htslib/faidx.h", bycopy.} = object


## / Opaque structure representing FASTA index

type
  faidx_t* = struct_faidx_t

## / Build index for a FASTA or bgzip-compressed FASTA file.
## *  @param  fn  FASTA file name
##      @param  fnfai Name of .fai file to build.
##      @param  fngzi Name of .gzi file to build (if fn is bgzip-compressed).
##      @return     0 on success; or -1 on failure
##
## If fnfai is NULL, ".fai" will be appended to fn to make the FAI file name.
## If fngzi is NULL, ".gzi" will be appended to fn for the GZI file.  The GZI
## file will only be built if fn is bgzip-compressed.
##

proc fai_build3*(fn: cstring; fnfai: cstring; fngzi: cstring): cint {.cdecl,
    importc: "fai_build3", header: "htslib/faidx.h".}
## / Build index for a FASTA or bgzip-compressed FASTA file.
## * @param  fn  FASTA file name
##     @return     0 on success; or -1 on failure
##
## File "fn.fai" will be generated.  This function is equivalent to
## fai_build3(fn, NULL, NULL);
##

proc fai_build*(fn: cstring): cint {.cdecl, importc: "fai_build", header: "htslib/faidx.h".}
## / Destroy a faidx_t struct

proc fai_destroy*(fai: ptr faidx_t) {.cdecl, importc: "fai_destroy", header: "htslib/faidx.h".}
type
  fai_load_options* {.size: sizeof(cint).} = enum
    FAI_CREATE = 0x00000001


## / Load FASTA indexes.
## * @param  fn  File name of the FASTA file (can be compressed with bgzip).
##     @param  fnfai File name of the FASTA index.
##     @param  fngzi File name of the bgzip index.
##     @param  flags Option flags to control index file caching and creation.
##     @return Pointer to a faidx_t struct on success, NULL on failure.
##
## If fnfai is NULL, ".fai" will be appended to fn to make the FAI file name.
## If fngzi is NULL, ".gzi" will be appended to fn for the bgzip index name.
## The bgzip index is only needed if fn is compressed.
##
## If (flags & FAI_CREATE) is true, the index files will be built using
## fai_build3() if they are not already present.
##

proc fai_load3*(fn: cstring; fnfai: cstring; fngzi: cstring; flags: cint): ptr faidx_t {.
    cdecl, importc: "fai_load3", header: "htslib/faidx.h".}
## / Load index from "fn.fai".
## * @param  fn  File name of the FASTA file
##     @return Pointer to a faidx_t struct on success, NULL on failure.
##
## This function is equivalent to fai_load3(fn, NULL, NULL, FAI_CREATE|FAI_CACHE);
##

proc fai_load*(fn: cstring): ptr faidx_t {.cdecl, importc: "fai_load", header: "htslib/faidx.h".}
## / Fetch the sequence in a region
## * @param  fai  Pointer to the faidx_t struct
##     @param  reg  Region in the format "chr2:20,000-30,000"
##     @param  len  Length of the region; -2 if seq not present, -1 general error
##     @return      Pointer to the sequence; `NULL` on failure
##
## The returned sequence is allocated by `malloc()` family and should be destroyed
## by end users by calling `free()` on it.
##

proc fai_fetch*(fai: ptr faidx_t; reg: cstring; len: ptr cint): cstring {.cdecl,
    importc: "fai_fetch", header: "htslib/faidx.h".}
## / Fetch the number of sequences
## * @param  fai  Pointer to the faidx_t struct
##     @return      The number of sequences
##

proc faidx_fetch_nseq*(fai: ptr faidx_t): cint {.cdecl, importc: "faidx_fetch_nseq",
    header: "htslib/faidx.h".}
## / Fetch the sequence in a region
## * @param  fai  Pointer to the faidx_t struct
##     @param  c_name Region name
##     @param  p_beg_i  Beginning position number (zero-based)
##     @param  p_end_i  End position number (zero-based)
##     @param  len  Length of the region; -2 if c_name not present, -1 general error
##     @return      Pointer to the sequence; null on failure
##
## The returned sequence is allocated by `malloc()` family and should be destroyed
## by end users by calling `free()` on it.
##

proc faidx_fetch_seq*(fai: ptr faidx_t; c_name: cstring; p_beg_i: cint; p_end_i: cint;
                     len: ptr cint): cstring {.cdecl, importc: "faidx_fetch_seq",
    header: "htslib/faidx.h".}
## / Query if sequence is present
## *   @param  fai  Pointer to the faidx_t struct
##       @param  seq  Sequence name
##       @return      1 if present or 0 if absent
##

proc faidx_has_seq*(fai: ptr faidx_t; seq: cstring): cint {.cdecl,
    importc: "faidx_has_seq", header: "htslib/faidx.h".}
## / Return number of sequences in fai index

proc faidx_nseq*(fai: ptr faidx_t): cint {.cdecl, importc: "faidx_nseq",
                                      header: "htslib/faidx.h".}
## / Return name of i-th sequence

proc faidx_iseq*(fai: ptr faidx_t; i: cint): cstring {.cdecl, importc: "faidx_iseq",
    header: "htslib/faidx.h".}
## / Return sequence length, -1 if not present

proc faidx_seq_len*(fai: ptr faidx_t; seq: cstring): cint {.cdecl,
    importc: "faidx_seq_len", header: "htslib/faidx.h".}
