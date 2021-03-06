# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passL: "-lhts".}
## / @file htslib/sam.h
## / High-level SAM/BAM/CRAM sequence file operations.
##
##     Copyright (C) 2008, 2009, 2013-2017 Genome Research Ltd.
##     Copyright (C) 2010, 2012, 2013 Broad Institute.
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

## *********************
## ** SAM/BAM header ***
## ********************
## ! @typedef
##  @abstract Structure for the alignment header.
##  @field n_targets   number of reference sequences
##  @field l_text      length of the plain text in the header
##  @field target_len  lengths of the reference sequences
##  @field target_name names of the reference sequences
##  @field text        plain text
##  @field sdict       header dictionary
##

type
  bam_hdr_t* {.importc: "bam_hdr_t", header: "htslib/sam.h", bycopy.} = object
    n_targets* {.importc: "n_targets".}: int32_t
    ignore_sam_err* {.importc: "ignore_sam_err".}: int32_t
    l_text* {.importc: "l_text".}: uint32_t
    target_len* {.importc: "target_len".}: ptr uint32_t
    cigar_tab* {.importc: "cigar_tab".}: ptr int8_t
    target_name* {.importc: "target_name".}: cstringArray
    text* {.importc: "text".}: cstring
    sdict* {.importc: "sdict".}: pointer


## ***************************
## ** CIGAR related macros ***
## **************************

const
  BAM_CMATCH* = 0
  BAM_CINS* = 1
  BAM_CDEL* = 2
  BAM_CREF_SKIP* = 3
  BAM_CSOFT_CLIP* = 4
  BAM_CHARD_CLIP* = 5
  BAM_CPAD* = 6
  BAM_CEQUAL* = 7
  BAM_CDIFF* = 8
  BAM_CBACK* = 9
  BAM_CIGAR_STR* = "MIDNSHP=XB"
  BAM_CIGAR_SHIFT* = 4
  BAM_CIGAR_MASK* = 0x0000000F
  BAM_CIGAR_TYPE* = 0x0003C1A7

template bam_cigar_op*(c: untyped): untyped =
  ((c) and BAM_CIGAR_MASK)

template bam_cigar_oplen*(c: untyped): untyped =
  ((c) shr BAM_CIGAR_SHIFT)

##  Note that BAM_CIGAR_STR is padded to length 16 bytes below so that
##  the array look-up will not fall off the end.  '?' is chosen as the
##  padding character so it's easy to spot if one is emitted, and will
##  result in a parsing failure (in sam_parse1(), at least) if read.

template bam_cigar_gen*(l, o: untyped): untyped =
  ((l) shl BAM_CIGAR_SHIFT or (o))

##  bam_cigar_type returns a bit flag with:
##    bit 1 set if the cigar operation consumes the query
##    bit 2 set if the cigar operation consumes the reference
##
##  For reference, the unobfuscated truth table for this function is:
##  BAM_CIGAR_TYPE  QUERY  REFERENCE
##  --------------------------------
##  BAM_CMATCH      1      1
##  BAM_CINS        1      0
##  BAM_CDEL        0      1
##  BAM_CREF_SKIP   0      1
##  BAM_CSOFT_CLIP  1      0
##  BAM_CHARD_CLIP  0      0
##  BAM_CPAD        0      0
##  BAM_CEQUAL      1      1
##  BAM_CDIFF       1      1
##  BAM_CBACK       0      0
##  --------------------------------
##

template bam_cigar_type*(o: untyped): untyped =
  (BAM_CIGAR_TYPE shr ((o) shl 1) and 3) ##  bit 1: consume query; bit 2: consume reference

## ! @abstract the read is paired in sequencing, no matter whether it is mapped in a pair

const
  BAM_FPAIRED* = 1

## ! @abstract the read is mapped in a proper pair

const
  BAM_FPROPER_PAIR* = 2

## ! @abstract the read itself is unmapped; conflictive with BAM_FPROPER_PAIR

const
  BAM_FUNMAP* = 4

## ! @abstract the mate is unmapped

const
  BAM_FMUNMAP* = 8

## ! @abstract the read is mapped to the reverse strand

const
  BAM_FREVERSE* = 16

## ! @abstract the mate is mapped to the reverse strand

const
  BAM_FMREVERSE* = 32

## ! @abstract this is read1

const
  BAM_FREAD1* = 64

## ! @abstract this is read2

const
  BAM_FREAD2* = 128

## ! @abstract not primary alignment

const
  BAM_FSECONDARY* = 256

## ! @abstract QC failure

const
  BAM_FQCFAIL* = 512

## ! @abstract optical or PCR duplicate

const
  BAM_FDUP* = 1024

## ! @abstract supplementary alignment

const
  BAM_FSUPPLEMENTARY* = 2048

## ************************
## ** Alignment records ***
## ***********************
## ! @typedef
##  @abstract Structure for core alignment information.
##  @field  tid     chromosome ID, defined by bam_hdr_t
##  @field  pos     0-based leftmost coordinate
##  @field  bin     bin calculated by bam_reg2bin()
##  @field  qual    mapping quality
##  @field  l_qname length of the query name
##  @field  flag    bitwise flag
##  @field  l_extranul length of extra NULs between qname & cigar (for alignment)
##  @field  n_cigar number of CIGAR operations
##  @field  l_qseq  length of the query sequence (read)
##  @field  mtid    chromosome ID of next read in template, defined by bam_hdr_t
##  @field  mpos    0-based leftmost coordinate of next read in template
##

type
  bam1_core_t* {.importc: "bam1_core_t", header: "htslib/sam.h", bycopy.} = object
    tid* {.importc: "tid".}: int32_t
    pos* {.importc: "pos".}: int32_t
    bin* {.importc: "bin".}: uint16_t
    qual* {.importc: "qual".}: uint8_t
    l_qname* {.importc: "l_qname".}: uint8_t
    flag* {.importc: "flag".}: uint16_t
    unused1* {.importc: "unused1".}: uint8_t
    l_extranul* {.importc: "l_extranul".}: uint8_t
    n_cigar* {.importc: "n_cigar".}: uint32_t
    l_qseq* {.importc: "l_qseq".}: int32_t
    mtid* {.importc: "mtid".}: int32_t
    mpos* {.importc: "mpos".}: int32_t
    isize* {.importc: "isize".}: int32_t


## ! @typedef
##  @abstract Structure for one alignment.
##  @field  core       core information about the alignment
##  @field  l_data     current length of bam1_t::data
##  @field  m_data     maximum length of bam1_t::data
##  @field  data       all variable-length data, concatenated; structure: qname-cigar-seq-qual-aux
##
##  @discussion Notes:
##
##  1. qname is terminated by one to four NULs, so that the following
##  cigar data is 32-bit aligned; core.l_qname includes these trailing NULs,
##  while core.l_extranul counts the excess NULs (so 0 <= l_extranul <= 3).
##  2. l_qseq is calculated from the total length of an alignment block
##  on reading or from CIGAR.
##  3. cigar data is encoded 4 bytes per CIGAR operation.
##  4. seq is nybble-encoded according to bam_nt16_table.
##

type
  bam1_t* {.importc: "bam1_t", header: "htslib/sam.h", bycopy.} = object
    core* {.importc: "core".}: bam1_core_t
    l_data* {.importc: "l_data".}: cint
    m_data* {.importc: "m_data".}: uint32_t
    data* {.importc: "data".}: ptr uint8_t ## #ifndef BAM_NO_ID
    id* {.importc: "id".}: uint64_t ## #endif


## ! @function
##  @abstract  Get whether the query is on the reverse strand
##  @param  b  pointer to an alignment
##  @return    boolean true if query is on the reverse strand
##

template bam_is_rev*(b: untyped): untyped =
  (((b).core.flag and BAM_FREVERSE) != 0)

## ! @function
##  @abstract  Get whether the query's mate is on the reverse strand
##  @param  b  pointer to an alignment
##  @return    boolean true if query's mate on the reverse strand
##

template bam_is_mrev*(b: untyped): untyped =
  (((b).core.flag and BAM_FMREVERSE) != 0)

## ! @function
##  @abstract  Get the name of the query
##  @param  b  pointer to an alignment
##  @return    pointer to the name string, null terminated
##

template bam_get_qname*(b: untyped): untyped =
  (cast[cstring]((b).data))

## ! @function
##  @abstract  Get the CIGAR array
##  @param  b  pointer to an alignment
##  @return    pointer to the CIGAR array
##
##  @discussion In the CIGAR array, each element is a 32-bit integer. The
##  lower 4 bits gives a CIGAR operation and the higher 28 bits keep the
##  length of a CIGAR.
##

template bam_get_cigar*(b: untyped): untyped =
  (cast[ptr uint32_t](((b).data + (b).core.l_qname)))

## ! @function
##  @abstract  Get query sequence
##  @param  b  pointer to an alignment
##  @return    pointer to sequence
##
##  @discussion Each base is encoded in 4 bits: 1 for A, 2 for C, 4 for G,
##  8 for T and 15 for N. Two bases are packed in one byte with the base
##  at the higher 4 bits having smaller coordinate on the read. It is
##  recommended to use bam_seqi() macro to get the base.
##

template bam_get_seq*(b: untyped): untyped =
  ((b).data + ((b).core.n_cigar shl 2) + (b).core.l_qname)

## ! @function
##  @abstract  Get query quality
##  @param  b  pointer to an alignment
##  @return    pointer to quality string
##

template bam_get_qual*(b: untyped): untyped =
  ((b).data + ((b).core.n_cigar shl 2) + (b).core.l_qname +
      (((b).core.l_qseq + 1) shr 1))

## ! @function
##  @abstract  Get auxiliary data
##  @param  b  pointer to an alignment
##  @return    pointer to the concatenated auxiliary data
##

template bam_get_aux*(b: untyped): untyped =
  ((b).data + ((b).core.n_cigar shl 2) + (b).core.l_qname +
      (((b).core.l_qseq + 1) shr 1) + (b).core.l_qseq)

## ! @function
##  @abstract  Get length of auxiliary data
##  @param  b  pointer to an alignment
##  @return    length of the concatenated auxiliary data
##

template bam_get_l_aux*(b: untyped): untyped =
  ((b).l_data - ((b).core.n_cigar shl 2) - (b).core.l_qname - (b).core.l_qseq -
      (((b).core.l_qseq + 1) shr 1))

## ! @function
##  @abstract  Get a base on read
##  @param  s  Query sequence returned by bam_get_seq()
##  @param  i  The i-th position, 0-based
##  @return    4-bit integer representing the base.
##

template bam_seqi*(s, i: untyped): untyped =
  ((s)[(i) shr 1] shr ((not (i) and 1) shl 2) and 0x0000000F)

## *************************
## ** Exported functions ***
## ************************
## **************
## ** BAM I/O ***
## *************

proc bam_hdr_init*(): ptr bam_hdr_t {.cdecl, importc: "bam_hdr_init", header: "htslib/sam.h".}
proc bam_hdr_read*(fp: ptr BGZF): ptr bam_hdr_t {.cdecl, importc: "bam_hdr_read",
    header: "htslib/sam.h".}
proc bam_hdr_write*(fp: ptr BGZF; h: ptr bam_hdr_t): cint {.cdecl,
    importc: "bam_hdr_write", header: "htslib/sam.h".}
proc bam_hdr_destroy*(h: ptr bam_hdr_t) {.cdecl, importc: "bam_hdr_destroy",
                                      header: "htslib/sam.h".}
proc bam_name2id*(h: ptr bam_hdr_t; `ref`: cstring): cint {.cdecl,
    importc: "bam_name2id", header: "htslib/sam.h".}
proc bam_hdr_dup*(h0: ptr bam_hdr_t): ptr bam_hdr_t {.cdecl, importc: "bam_hdr_dup",
    header: "htslib/sam.h".}
proc bam_init1*(): ptr bam1_t {.cdecl, importc: "bam_init1", header: "htslib/sam.h".}
proc bam_destroy1*(b: ptr bam1_t) {.cdecl, importc: "bam_destroy1", header: "htslib/sam.h".}
proc bam_read1*(fp: ptr BGZF; b: ptr bam1_t): cint {.cdecl, importc: "bam_read1",
    header: "htslib/sam.h".}
proc bam_write1*(fp: ptr BGZF; b: ptr bam1_t): cint {.cdecl, importc: "bam_write1",
    header: "htslib/sam.h".}
proc bam_copy1*(bdst: ptr bam1_t; bsrc: ptr bam1_t): ptr bam1_t {.cdecl,
    importc: "bam_copy1", header: "htslib/sam.h".}
proc bam_dup1*(bsrc: ptr bam1_t): ptr bam1_t {.cdecl, importc: "bam_dup1",
    header: "htslib/sam.h".}
proc bam_cigar2qlen*(n_cigar: cint; cigar: ptr uint32_t): cint {.cdecl,
    importc: "bam_cigar2qlen", header: "htslib/sam.h".}
proc bam_cigar2rlen*(n_cigar: cint; cigar: ptr uint32_t): cint {.cdecl,
    importc: "bam_cigar2rlen", header: "htslib/sam.h".}
## !
##       @abstract Calculate the rightmost base position of an alignment on the
##       reference genome.
##
##       @param  b  pointer to an alignment
##       @return    the coordinate of the first base after the alignment, 0-based
##
##       @discussion For a mapped read, this is just b->core.pos + bam_cigar2rlen.
##       For an unmapped read (either according to its flags or if it has no cigar
##       string), we return b->core.pos + 1 by convention.
##

proc bam_endpos*(b: ptr bam1_t): int32_t {.cdecl, importc: "bam_endpos", header: "htslib/sam.h".}
proc bam_str2flag*(str: cstring): cint {.cdecl, importc: "bam_str2flag",
                                     header: "htslib/sam.h".}
## * returns negative value on error

proc bam_flag2str*(flag: cint): cstring {.cdecl, importc: "bam_flag2str",
                                      header: "htslib/sam.h".}
## * The string must be freed by the user
## ************************
## ** BAM/CRAM indexing ***
## ***********************
##  These BAM iterator functions work only on BAM files.  To work with either
##  BAM or CRAM files use the sam_index_load() & sam_itr_*() functions.

template bam_itr_destroy*(iter: untyped): untyped =
  hts_itr_destroy(iter)

template bam_itr_queryi*(idx, tid, beg, `end`: untyped): untyped =
  sam_itr_queryi(idx, tid, beg, `end`)

template bam_itr_querys*(idx, hdr, region: untyped): untyped =
  sam_itr_querys(idx, hdr, region)

template bam_itr_next*(htsfp, itr, r: untyped): untyped =
  hts_itr_next((htsfp).fp.bgzf, (itr), (r), 0)

##  Load/build .csi or .bai BAM index file.  Does not work with CRAM.
##  It is recommended to use the sam_index_* functions below instead.

template bam_index_load*(fn: untyped): untyped =
  hts_idx_load((fn), HTS_FMT_BAI)

template bam_index_build*(fn, min_shift: untyped): untyped =
  (sam_index_build((fn), (min_shift)))

## / Load a BAM (.csi or .bai) or CRAM (.crai) index file
## * @param fp  File handle of the data file whose index is being opened
##     @param fn  BAM/CRAM/etc filename to search alongside for the index file
##     @return  The index, or NULL if an error occurred.
##

proc sam_index_load*(fp: ptr htsFile; fn: cstring): ptr hts_idx_t {.cdecl,
    importc: "sam_index_load", header: "htslib/sam.h".}
## / Load a specific BAM (.csi or .bai) or CRAM (.crai) index file
## * @param fp     File handle of the data file whose index is being opened
##     @param fn     BAM/CRAM/etc data file filename
##     @param fnidx  Index filename, or NULL to search alongside @a fn
##     @return  The index, or NULL if an error occurred.
##

proc sam_index_load2*(fp: ptr htsFile; fn: cstring; fnidx: cstring): ptr hts_idx_t {.
    cdecl, importc: "sam_index_load2", header: "htslib/sam.h".}
## / Generate and save an index file
## * @param fn        Input BAM/etc filename, to which .csi/etc will be added
##     @param min_shift Positive to generate CSI, or 0 to generate BAI
##     @return  0 if successful, or negative if an error occurred (usually -1; or
##              -2: opening fn failed; -3: format not indexable; -4:
##              failed to create and/or save the index)
##

proc sam_index_build*(fn: cstring; min_shift: cint): cint {.cdecl,
    importc: "sam_index_build", header: "htslib/sam.h".}
## / Generate and save an index to a specific file
## * @param fn        Input BAM/CRAM/etc filename
##     @param fnidx     Output filename, or NULL to add .bai/.csi/etc to @a fn
##     @param min_shift Positive to generate CSI, or 0 to generate BAI
##     @return  0 if successful, or negative if an error occurred (see
##              sam_index_build for error codes)
##

proc sam_index_build2*(fn: cstring; fnidx: cstring; min_shift: cint): cint {.cdecl,
    importc: "sam_index_build2", header: "htslib/sam.h".}
proc sam_index_build3*(fn: cstring; fnidx: cstring; min_shift: cint; nthreads: cint): cint {.
    cdecl, importc: "sam_index_build3", header: "htslib/sam.h".}
template sam_itr_destroy*(iter: untyped): untyped =
  hts_itr_destroy(iter)

proc sam_itr_queryi*(idx: ptr hts_idx_t; tid: cint; beg: cint; `end`: cint): ptr hts_itr_t {.
    cdecl, importc: "sam_itr_queryi", header: "htslib/sam.h".}
proc sam_itr_querys*(idx: ptr hts_idx_t; hdr: ptr bam_hdr_t; region: cstring): ptr hts_itr_t {.
    cdecl, importc: "sam_itr_querys", header: "htslib/sam.h".}
template sam_itr_next*(htsfp, itr, r: untyped): untyped =
  hts_itr_next((htsfp).fp.bgzf, (itr), (r), (htsfp))

## **************
## ** SAM I/O ***
## *************

template sam_open*(fn, mode: untyped): untyped =
  (hts_open((fn), (mode)))

template sam_open_format*(fn, mode, fmt: untyped): untyped =
  (hts_open_format((fn), (mode), (fmt)))

template sam_close*(fp: untyped): untyped =
  hts_close(fp)

proc sam_open_mode*(mode: cstring; fn: cstring; format: cstring): cint {.cdecl,
    importc: "sam_open_mode", header: "htslib/sam.h".}
##  A version of sam_open_mode that can handle ,key=value options.
##  The format string is allocated and returned, to be freed by the caller.
##  Prefix should be "r" or "w",

proc sam_open_mode_opts*(fn: cstring; mode: cstring; format: cstring): cstring {.cdecl,
    importc: "sam_open_mode_opts", header: "htslib/sam.h".}
type
  samFile* = htsFile

proc sam_hdr_parse*(l_text: cint; text: cstring): ptr bam_hdr_t {.cdecl,
    importc: "sam_hdr_parse", header: "htslib/sam.h".}
proc sam_hdr_read*(fp: ptr samFile): ptr bam_hdr_t {.cdecl, importc: "sam_hdr_read",
    header: "htslib/sam.h".}
proc sam_hdr_write*(fp: ptr samFile; h: ptr bam_hdr_t): cint {.cdecl,
    importc: "sam_hdr_write", header: "htslib/sam.h".}
proc sam_parse1*(s: ptr kstring_t; h: ptr bam_hdr_t; b: ptr bam1_t): cint {.cdecl,
    importc: "sam_parse1", header: "htslib/sam.h".}
proc sam_format1*(h: ptr bam_hdr_t; b: ptr bam1_t; str: ptr kstring_t): cint {.cdecl,
    importc: "sam_format1", header: "htslib/sam.h".}
## !
##   @return >= 0 on successfully reading a new record, -1 on end of stream, < -1 on error
##

proc sam_read1*(fp: ptr samFile; h: ptr bam_hdr_t; b: ptr bam1_t): cint {.cdecl,
    importc: "sam_read1", header: "htslib/sam.h".}
proc sam_write1*(fp: ptr samFile; h: ptr bam_hdr_t; b: ptr bam1_t): cint {.cdecl,
    importc: "sam_write1", header: "htslib/sam.h".}
## ************************************
## ** Manipulating auxiliary fields ***
## ***********************************
## / Return a pointer to an aux record
## * @param b   Pointer to the bam record
##     @param tag Desired aux tag
##     @return Pointer to the tag data, or NULL if tag is not present or on error
##     If the tag is not present, this function returns NULL and sets errno to
##     ENOENT.  If the bam record's aux data is corrupt (either a tag has an
##     invalid type, or the last record is incomplete) then errno is set to
##     EINVAL and NULL is returned.
##

proc bam_aux_get*(b: ptr bam1_t; tag: array[2, char]): ptr uint8_t {.cdecl,
    importc: "bam_aux_get", header: "htslib/sam.h".}
## / Get an integer aux value
## * @param s Pointer to the tag data, as returned by bam_aux_get()
##     @return The value, or 0 if the tag was not an integer type
##     If the tag is not an integer type, errno is set to EINVAL.  This function
##     will not return the value of floating-point tags.
##

proc bam_aux2i*(s: ptr uint8_t): int64_t {.cdecl, importc: "bam_aux2i", header: "htslib/sam.h".}
## / Get an integer aux value
## * @param s Pointer to the tag data, as returned by bam_aux_get()
##     @return The value, or 0 if the tag was not an integer type
##     If the tag is not an numeric type, errno is set to EINVAL.  The value of
##     integer flags will be returned cast to a double.
##

proc bam_aux2f*(s: ptr uint8_t): cdouble {.cdecl, importc: "bam_aux2f", header: "htslib/sam.h".}
## / Get a character aux value
## * @param s Pointer to the tag data, as returned by bam_aux_get().
##     @return The value, or 0 if the tag was not a character ('A') type
##     If the tag is not a character type, errno is set to EINVAL.
##

proc bam_aux2A*(s: ptr uint8_t): char {.cdecl, importc: "bam_aux2A", header: "htslib/sam.h".}
## / Get a string aux value
## * @param s Pointer to the tag data, as returned by bam_aux_get().
##     @return Pointer to the string, or NULL if the tag was not a string type
##     If the tag is not a string type ('Z' or 'H'), errno is set to EINVAL.
##

proc bam_aux2Z*(s: ptr uint8_t): cstring {.cdecl, importc: "bam_aux2Z", header: "htslib/sam.h".}
## / Get the length of an array-type ('B') tag
## * @param s Pointer to the tag data, as returned by bam_aux_get().
##     @return The length of the array, or 0 if the tag is not an array type.
##     If the tag is not an array type, errno is set to EINVAL.
##

proc bam_auxB_len*(s: ptr uint8_t): uint32_t {.cdecl, importc: "bam_auxB_len",
    header: "htslib/sam.h".}
## / Get an integer value from an array-type tag
## * @param s   Pointer to the tag data, as returned by bam_aux_get().
##     @param idx 0-based Index into the array
##     @return The idx'th value, or 0 on error.
##     If the array is not an integer type, errno is set to EINVAL.  If idx
##     is greater than or equal to  the value returned by bam_auxB_len(s),
##     errno is set to ERANGE.  In both cases, 0 will be returned.
##

proc bam_auxB2i*(s: ptr uint8_t; idx: uint32_t): int64_t {.cdecl, importc: "bam_auxB2i",
    header: "htslib/sam.h".}
## / Get a floating-point value from an array-type tag
## * @param s   Pointer to the tag data, as returned by bam_aux_get().
##     @param idx 0-based Index into the array
##     @return The idx'th value, or 0.0 on error.
##     If the array is not a numeric type, errno is set to EINVAL.  This can
##     only actually happen if the input record has an invalid type field.  If
##     idx is greater than or equal to  the value returned by bam_auxB_len(s),
##     errno is set to ERANGE.  In both cases, 0.0 will be returned.
##

proc bam_auxB2f*(s: ptr uint8_t; idx: uint32_t): cdouble {.cdecl, importc: "bam_auxB2f",
    header: "htslib/sam.h".}
## / Append tag data to a bam record
##  @param b    The bam record to append to.
##    @param tag  Tag identifier
##    @param type Tag data type
##    @param len  Length of the data in bytes
##    @param data The data to append
##    @return 0 on success; -1 on failure.
## If there is not enough space to store the additional tag, errno is set to
## ENOMEM.  If the type is invalid, errno may be set to EINVAL.  errno is
## also set to EINVAL if the bam record's aux data is corrupt.
##

proc bam_aux_append*(b: ptr bam1_t; tag: array[2, char]; `type`: char; len: cint;
                    data: ptr uint8_t): cint {.cdecl, importc: "bam_aux_append",
    header: "htslib/sam.h".}
## / Delete tag data from a bam record
##  @param b The bam record to update
##    @param s Pointer to the tag to delete, as returned by bam_aux_get().
##    @return 0 on success; -1 on failure
##    If the bam record's aux data is corrupt, errno is set to EINVAL and this
##    function returns -1;
##

proc bam_aux_del*(b: ptr bam1_t; s: ptr uint8_t): cint {.cdecl, importc: "bam_aux_del",
    header: "htslib/sam.h".}
## / Update a string-type tag
##  @param b    The bam record to update
##    @param tag  Tag identifier
##    @param len  The length of the new string
##    @param data The new string
##    @return 0 on success, -1 on failure
##

proc bam_aux_update_str*(b: ptr bam1_t; tag: array[2, char]; len: cint; data: cstring): cint {.
    cdecl, importc: "bam_aux_update_str", header: "htslib/sam.h".}
## *************************
## ** Pileup and Mpileup ***
## ************************

when not defined(BAM_NO_PILEUP):
  ## ! @typedef
  ##  @abstract Generic pileup 'client data'.
  ##
  ##  @discussion The pileup iterator allows setting a constructor and
  ##  destructor function, which will be called every time a sequence is
  ##  fetched and discarded.  This permits caching of per-sequence data in
  ##  a tidy manner during the pileup process.  This union is the cached
  ##  data to be manipulated by the "client" (the caller of pileup).
  ##
  type
    bam_pileup_cd* {.importc: "bam_pileup_cd", header: "htslib/sam.h", bycopy.} = object {.
        union.}
      p* {.importc: "p".}: pointer
      i* {.importc: "i".}: int64_t
      f* {.importc: "f".}: cdouble



  ## ! @typedef
  ##  @abstract Structure for one alignment covering the pileup position.
  ##  @field  b          pointer to the alignment
  ##  @field  qpos       position of the read base at the pileup site, 0-based
  ##  @field  indel      indel length; 0 for no indel, positive for ins and negative for del
  ##  @field  level      the level of the read in the "viewer" mode
  ##  @field  is_del     1 iff the base on the padded read is a deletion
  ##  @field  is_head    ???
  ##  @field  is_tail    ???
  ##  @field  is_refskip ???
  ##  @field  aux        ???
  ##
  ##  @discussion See also bam_plbuf_push() and bam_lplbuf_push(). The
  ##  difference between the two functions is that the former does not
  ##  set bam_pileup1_t::level, while the later does. Level helps the
  ##  implementation of alignment viewers, but calculating this has some
  ##  overhead.
  ##
  type
    bam_pileup1_t* {.importc: "bam_pileup1_t", header: "htslib/sam.h", bycopy.} = object
      b* {.importc: "b".}: ptr bam1_t
      qpos* {.importc: "qpos".}: int32_t
      indel* {.importc: "indel".}: cint
      level* {.importc: "level".}: cint
      is_del* {.importc: "is_del".} {.bitsize: 1.}: uint32_t
      is_head* {.importc: "is_head".} {.bitsize: 1.}: uint32_t
      is_tail* {.importc: "is_tail".} {.bitsize: 1.}: uint32_t
      is_refskip* {.importc: "is_refskip".} {.bitsize: 1.}: uint32_t
      aux* {.importc: "aux".} {.bitsize: 28.}: uint32_t
      cd* {.importc: "cd".}: bam_pileup_cd ##  generic per-struct data, owned by caller.

    bam_plp_auto_f* = proc (data: pointer; b: ptr bam1_t): cint {.cdecl.}
  type
    __bam_plp_t* {.importc: "__bam_plp_t", header: "htslib/sam.h", bycopy.} = object

  type
    bam_plp_t* = ptr __bam_plp_t
  type
    __bam_mplp_t* {.importc: "__bam_mplp_t", header: "htslib/sam.h", bycopy.} = object

  type
    bam_mplp_t* = ptr __bam_mplp_t


  ## *
  ##   bam_plp_init() - sets an iterator over multiple
  ##   @func:      see mplp_func in bam_plcmd.c in samtools for an example. Expected return
  ##               status: 0 on success, -1 on end, < -1 on non-recoverable errors
  ##   @data:      user data to pass to @func
  ##
  proc bam_plp_init*(`func`: bam_plp_auto_f; data: pointer): bam_plp_t {.cdecl,
      importc: "bam_plp_init", header: "htslib/sam.h".}
  proc bam_plp_destroy*(iter: bam_plp_t) {.cdecl, importc: "bam_plp_destroy",
                                        header: "htslib/sam.h".}
  proc bam_plp_push*(iter: bam_plp_t; b: ptr bam1_t): cint {.cdecl,
      importc: "bam_plp_push", header: "htslib/sam.h".}
  proc bam_plp_next*(iter: bam_plp_t; _tid: ptr cint; _pos: ptr cint; _n_plp: ptr cint): ptr bam_pileup1_t {.
      cdecl, importc: "bam_plp_next", header: "htslib/sam.h".}
  proc bam_plp_auto*(iter: bam_plp_t; _tid: ptr cint; _pos: ptr cint; _n_plp: ptr cint): ptr bam_pileup1_t {.
      cdecl, importc: "bam_plp_auto", header: "htslib/sam.h".}
  proc bam_plp_set_maxcnt*(iter: bam_plp_t; maxcnt: cint) {.cdecl,
      importc: "bam_plp_set_maxcnt", header: "htslib/sam.h".}
  proc bam_plp_reset*(iter: bam_plp_t) {.cdecl, importc: "bam_plp_reset",
                                      header: "htslib/sam.h".}
  ## *
  ##   bam_plp_constructor() - sets a callback to initialise any per-pileup1_t fields.
  ##   @plp:       The bam_plp_t initialised using bam_plp_init.
  ##   @func:      The callback function itself.  When called, it is given the
  ##               data argument (specified in bam_plp_init), the bam structure and
  ##               a pointer to a locally allocated bam_pileup_cd union.  This union
  ##               will also be present in each bam_pileup1_t created.
  ##
  proc bam_plp_constructor*(plp: bam_plp_t; `func`: proc (data: pointer; b: ptr bam1_t;
      cd: ptr bam_pileup_cd): cint {.cdecl.}) {.cdecl, importc: "bam_plp_constructor",
      header: "htslib/sam.h".}
  proc bam_plp_destructor*(plp: bam_plp_t; `func`: proc (data: pointer; b: ptr bam1_t;
      cd: ptr bam_pileup_cd): cint {.cdecl.}) {.cdecl, importc: "bam_plp_destructor",
      header: "htslib/sam.h".}
  proc bam_mplp_init*(n: cint; `func`: bam_plp_auto_f; data: ptr pointer): bam_mplp_t {.
      cdecl, importc: "bam_mplp_init", header: "htslib/sam.h".}
  ## *
  ##   bam_mplp_init_overlaps() - if called, mpileup will detect overlapping
  ##   read pairs and for each base pair set the base quality of the
  ##   lower-quality base to zero, thus effectively discarding it from
  ##   calling. If the two bases are identical, the quality of the other base
  ##   is increased to the sum of their qualities (capped at 200), otherwise
  ##   it is multiplied by 0.8.
  ##
  proc bam_mplp_init_overlaps*(iter: bam_mplp_t) {.cdecl,
      importc: "bam_mplp_init_overlaps", header: "htslib/sam.h".}
  proc bam_mplp_destroy*(iter: bam_mplp_t) {.cdecl, importc: "bam_mplp_destroy",
      header: "htslib/sam.h".}
  proc bam_mplp_set_maxcnt*(iter: bam_mplp_t; maxcnt: cint) {.cdecl,
      importc: "bam_mplp_set_maxcnt", header: "htslib/sam.h".}
  proc bam_mplp_auto*(iter: bam_mplp_t; _tid: ptr cint; _pos: ptr cint; n_plp: ptr cint;
                     plp: ptr ptr bam_pileup1_t): cint {.cdecl,
      importc: "bam_mplp_auto", header: "htslib/sam.h".}
  proc bam_mplp_reset*(iter: bam_mplp_t) {.cdecl, importc: "bam_mplp_reset",
                                        header: "htslib/sam.h".}
  proc bam_mplp_constructor*(iter: bam_mplp_t; `func`: proc (data: pointer;
      b: ptr bam1_t; cd: ptr bam_pileup_cd): cint {.cdecl.}) {.cdecl,
      importc: "bam_mplp_constructor", header: "htslib/sam.h".}
  proc bam_mplp_destructor*(iter: bam_mplp_t; `func`: proc (data: pointer;
      b: ptr bam1_t; cd: ptr bam_pileup_cd): cint {.cdecl.}) {.cdecl,
      importc: "bam_mplp_destructor", header: "htslib/sam.h".}
## **********************************
##  BAQ calculation and realignment *
## *********************************

proc sam_cap_mapq*(b: ptr bam1_t; `ref`: cstring; ref_len: cint; thres: cint): cint {.
    cdecl, importc: "sam_cap_mapq", header: "htslib/sam.h".}
proc sam_prob_realn*(b: ptr bam1_t; `ref`: cstring; ref_len: cint; flag: cint): cint {.
    cdecl, importc: "sam_prob_realn", header: "htslib/sam.h".}
