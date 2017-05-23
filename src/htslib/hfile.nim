# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passL: "-lhts".}
##   hfile.h -- buffered low-level input/output streams.
##
##     Copyright (C) 2013-2014 Genome Research Ltd.
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

##  These fields are declared here solely for the benefit of the inline functions
##    below.  They may change in future releases.  User code should not use them
##    directly; you should imagine that hFILE is an opaque incomplete type.

type
  off_t* = int
  hFILE_backend* {.importc: "hFILE_backend", header: "htslib/hfile.h".} = object

  hFILE* {.importc: "hFILE", header: "htslib/hfile.h".} = object
    buffer* {.importc: "buffer".}: ptr char
    begin* {.importc: "begin".}: ptr char
    `end`* {.importc: "end".}: ptr char
    limit* {.importc: "limit".}: ptr char
    backend* {.importc: "backend".}: ptr hFILE_backend
    offset* {.importc: "offset".}: off_t
    at_eof* {.importc: "at_eof", bitsize: 1.}: cint
    has_errno* {.importc: "has_errno".}: cint

from common import nil
common.usePtr[char]()
#common.usePtr[hFile]()

## !
##   @abstract  Open the named file or URL as a stream
##   @return    An hFILE pointer, or NULL (with errno set) if an error occurred.
##
proc hopen*(filename: cstring; mode: cstring): ptr hFILE {.cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Associate a stream with an existing open file descriptor
##   @return    An hFILE pointer, or NULL (with errno set) if an error occurred.
##   @notes     For socket descriptors (on Windows), mode should contain 's'.
##
proc hdopen*(fd: cint; mode: cstring): ptr hFILE {.cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Flush (for output streams) and close the stream
##   @return    0 if successful, or EOF (with errno set) if an error occurred.
##
proc hclose*(fp: ptr hFILE): cint {.cdecl, importc: "hclose", header: "htslib/hfile.h".}

## !
##   @abstract  Close the stream, without flushing or propagating errors
##   @notes     For use while cleaning up after an error only.  Preserves errno.
##
proc hclose_abruptly*(fp: ptr hFILE) {.cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Return the stream's error indicator
##   @return    Non-zero (in fact, an errno value) if an error has occurred.
##   @notes     This would be called herror() and return true/false to parallel
##     ferror(3), but a networking-related herror(3) function already exists.
proc herrno*(fp: ptr hFILE): cint {.inline, cdecl.} =
  return fp.has_errno

## !
##   @abstract  Clear the stream's error indicator
##
proc hclearerr*(fp: ptr hFILE) {.inline, cdecl.} =
  fp.has_errno = 0

## !
##   @abstract  Reposition the read/write stream offset
##   @return    The resulting offset within the stream (as per lseek(2)),
##     or negative if an error occurred.
##
proc hseek*(fp: ptr hFILE; offset: off_t; whence: cint): off_t {.cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Report the current stream offset
##   @return    The offset within the stream, starting from zero.
##

proc htell*(fp: ptr hFILE): off_t {.inline, cdecl.} =
  return fp.offset + (fp.begin - fp.buffer)

## !
##   @abstract  Read one character from the stream
##   @return    The character read, or EOF on end-of-file or error
##

proc hgetc*(fp: ptr hFILE): cint {.inline, cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Peek at characters to be read without removing them from buffers
##   @param fp      The file stream
##   @param buffer  The buffer to which the peeked bytes will be written
##   @param nbytes  The number of bytes to peek at; limited by the size of the
##     internal buffer, which could be as small as 4K.
##   @return    The number of bytes peeked, which may be less than nbytes if EOF
##     is encountered; or negative, if there was an I/O error.
##   @notes  The characters peeked at remain in the stream's internal buffer,
##     and will be returned by later hread() etc calls.
##
proc hpeek*(fp: ptr hFILE; buffer: pointer; nbytes: csize): csize {.cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Read a block of characters from the file
##   @return    The number of bytes read, or negative if an error occurred.
##   @notes     The full nbytes requested will be returned, except as limited
##     by EOF or I/O errors.
##
proc hread*(fp: ptr hFILE; buffer: pointer; nbytes: csize): cint {.cdecl, inline, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Write a character to the stream
##   @return    The character written, or EOF if an error occurred.
##
proc hputc*(c: cint; fp: ptr hFILE): cint {.inline, cdecl, importc, header:"htslib/hfile.h".}

## !
##   @abstract  Write a string to the stream
##   @return    0 if successful, or EOF if an error occurred.
##
proc hputs*(text: cstring; fp: ptr hFILE): cint {.inline, cdecl, importc, header:"htslib/hfile.h".}

## ! This is in newer versions of htslib.
##
proc hgets*(buffer: pointer, size: csize, fp: ptr hFILE): ptr char {.cdecl, importc, header: "htslib/hfile.h".}

## !
##   @abstract  Write a block of characters to the file
##   @return    Either nbytes, or negative if an error occurred.
##   @notes     In the absence of I/O errors, the full nbytes will be written.
##
proc hwrite*(fp: ptr hFILE; buffer: pointer; nbytes: csize): cint {.cdecl, inline, importc, header: "htslib/hfile.h".}

## !
##   @abstract  For writing streams, flush buffered output to the underlying stream
##   @return    0 if successful, or EOF if an error occurred.
##
proc hflush*(fp: ptr hFILE): cint {.cdecl, importc, header: "htslib/hfile.h".}
