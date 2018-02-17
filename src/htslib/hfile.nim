# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passL: "-lhts".}
## / @file htslib/hfile.h
## / Buffered low-level input/output streams.
##
##     Copyright (C) 2013-2016 Genome Research Ltd.
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

type
  hFILE_backend* {.importc: "hFILE_backend", header: "htslib/hfile.h", bycopy.} = object


## / Low-level input/output stream handle
## * The fields of this structure are declared here solely for the benefit
## of the hFILE-related inline functions.  They may change in future releases.
## User code should not use them directly; you should imagine that hFILE is an
## opaque incomplete type.
##

type
  hFILE* {.importc: "hFILE", header: "htslib/hfile.h", bycopy.} = object
    buffer* {.importc: "buffer".}: cstring ##  @cond internal
    begin* {.importc: "begin".}: cstring
    `end`* {.importc: "end".}: cstring
    limit* {.importc: "limit".}: cstring
    backend* {.importc: "backend".}: ptr hFILE_backend
    offset* {.importc: "offset".}: off_t
    at_eof* {.importc: "at_eof".} {.bitsize: 1.}: cuint
    mobile* {.importc: "mobile".} {.bitsize: 1.}: cuint
    readonly* {.importc: "readonly".} {.bitsize: 1.}: cuint
    has_errno* {.importc: "has_errno".}: cint ##  @endcond


## / Open the named file or URL as a stream
## * @return An hFILE pointer, or `NULL` (with _errno_ set) if an error occurred.
##
## The usual `fopen(3)` _mode_ letters are supported: one of
## `r` (read), `w` (write), `a` (append), optionally followed by any of
## `+` (update), `e` (close on `exec(2)`), `x` (create exclusively),
## `:` (indicates scheme-specific variable arguments follow).
##

proc hopen*(filename: cstring; mode: cstring): ptr hFILE {.varargs, cdecl,
    importc: "hopen", header: "htslib/hfile.h".}
## / Associate a stream with an existing open file descriptor
## * @return An hFILE pointer, or `NULL` (with _errno_ set) if an error occurred.
##
## Note that the file must be opened in binary mode, or else
## there will be problems on platforms that make a difference
## between text and binary mode.
##
## For socket descriptors (on Windows), _mode_ should contain `s`.
##

proc hdopen*(fd: cint; mode: cstring): ptr hFILE {.cdecl, importc: "hdopen",
    header: "htslib/hfile.h".}
## / Report whether the file name or URL denotes remote storage
## * @return  0 if local, 1 if remote.
##
## "Remote" means involving e.g. explicit network access, with the implication
## that callers may wish to cache such files' contents locally.
##

proc hisremote*(filename: cstring): cint {.cdecl, importc: "hisremote",
                                       header: "htslib/hfile.h".}
## / Flush (for output streams) and close the stream
## * @return  0 if successful, or `EOF` (with _errno_ set) if an error occurred.
##

proc hclose*(fp: ptr hFILE): cint {.cdecl, importc: "hclose", header: "htslib/hfile.h".}
## / Close the stream, without flushing or propagating errors
## * For use while cleaning up after an error only.  Preserves _errno_.
##

proc hclose_abruptly*(fp: ptr hFILE) {.cdecl, importc: "hclose_abruptly",
                                   header: "htslib/hfile.h".}
## / Return the stream's error indicator
## * @return  Non-zero (in fact, an _errno_ value) if an error has occurred.
##
## This would be called `herror()` and return true/false to parallel `ferror(3)`,
## but a networking-related `herror(3)` function already exists.
##

proc herrno*(fp: ptr hFILE): cint {.inline, cdecl.} =
  return fp.has_errno

## / Clear the stream's error indicator

proc hclearerr*(fp: ptr hFILE) {.inline, cdecl.} =
  fp.has_errno = 0

## / Reposition the read/write stream offset
## * @return  The resulting offset within the stream (as per `lseek(2)`),
##     or negative if an error occurred.
##

proc hseek*(fp: ptr hFILE; offset: off_t; whence: cint): off_t {.cdecl, importc: "hseek",
    header: "htslib/hfile.h".}
## / Report the current stream offset
## * @return  The offset within the stream, starting from zero.
##

proc htell*(fp: ptr hFILE): off_t {.inline, cdecl.} =
  return fp.offset + (fp.begin - fp.buffer)

## / Read one character from the stream
## * @return  The character read, or `EOF` on end-of-file or error.
##

proc hgetc*(fp: ptr hFILE): cint {.inline, cdecl.} =
  proc hgetc2(a2: ptr hFILE): cint {.cdecl.}
  return if (fp.`end` > fp.begin): cast[cuchar]((inc(fp.begin))[]) else: hgetc2(fp)

## / Read from the stream until the delimiter, up to a maximum length
## * @param buffer  The buffer into which bytes will be written
##     @param size    The size of the buffer
##     @param delim   The delimiter (interpreted as an `unsigned char`)
##     @param fp      The file stream
##     @return  The number of bytes read, or negative on error.
##     @since   1.4
##
## Bytes will be read into the buffer up to and including a delimiter, until
## EOF is reached, or _size-1_ bytes have been written, whichever comes first.
## The string will then be terminated with a NUL byte (`\0`).
##

proc hgetdelim*(buffer: cstring; size: csize; delim: cint; fp: ptr hFILE): ssize_t {.cdecl,
    importc: "hgetdelim", header: "htslib/hfile.h".}
## / Read a line from the stream, up to a maximum length
## * @param buffer  The buffer into which bytes will be written
##     @param size    The size of the buffer
##     @param fp      The file stream
##     @return  The number of bytes read, or negative on error.
##     @since   1.4
##
## Specialization of hgetdelim() for a `\n` delimiter.
##

proc hgetln*(buffer: cstring; size: csize; fp: ptr hFILE): ssize_t {.inline, cdecl.} =
  return hgetdelim(buffer, size, '\x0A', fp)

## / Read a line from the stream, up to a maximum length
## * @param buffer  The buffer into which bytes will be written
##     @param size    The size of the buffer (must be > 1 to be useful)
##     @param fp      The file stream
##     @return  _buffer_ on success, or `NULL` if an error occurred.
##     @since   1.4
##
## This function can be used as a replacement for `fgets(3)`, or together with
## kstring's `kgetline()` to read arbitrarily-long lines into a _kstring_t_.
##

proc hgets*(buffer: cstring; size: cint; fp: ptr hFILE): cstring {.cdecl,
    importc: "hgets", header: "htslib/hfile.h".}
## / Peek at characters to be read without removing them from buffers
## * @param fp      The file stream
##     @param buffer  The buffer to which the peeked bytes will be written
##     @param nbytes  The number of bytes to peek at; limited by the size of the
##                    internal buffer, which could be as small as 4K.
##     @return  The number of bytes peeked, which may be less than _nbytes_
##              if EOF is encountered; or negative, if there was an I/O error.
##
## The characters peeked at remain in the stream's internal buffer, and will be
## returned by later hread() etc calls.
##

proc hpeek*(fp: ptr hFILE; buffer: pointer; nbytes: csize): ssize_t {.cdecl,
    importc: "hpeek", header: "htslib/hfile.h".}
## / Read a block of characters from the file
## * @return  The number of bytes read, or negative if an error occurred.
##
## The full _nbytes_ requested will be returned, except as limited by EOF
## or I/O errors.
##

proc hread*(fp: ptr hFILE; buffer: pointer; nbytes: csize): ssize_t {.inline, cdecl.} =
  proc hread2(a2: ptr hFILE; a3: pointer; a4: csize; a5: csize): ssize_t {.cdecl.}
  var n: csize
  if n > nbytes: n = nbytes
  copyMem(buffer, fp.begin, n)
  inc(fp.begin, n)
  return if (n == nbytes): cast[ssize_t](n) else: hread2(fp, buffer, nbytes, n)

## / Write a character to the stream
## * @return  The character written, or `EOF` if an error occurred.
##

proc hputc*(c: cint; fp: ptr hFILE): cint {.inline, cdecl.} =
  proc hputc2(a2: cint; a3: ptr hFILE): cint {.cdecl.}
  if fp.begin < fp.limit: (inc(fp.begin))[] = c
  else: c = hputc2(c, fp)
  return c

## / Write a string to the stream
## * @return  0 if successful, or `EOF` if an error occurred.
##

proc hputs*(text: cstring; fp: ptr hFILE): cint {.inline, cdecl.} =
  proc hputs2(a2: cstring; a3: csize; a4: csize; a5: ptr hFILE): cint {.cdecl.}
  var
    nbytes: csize
    n: csize
  if n > nbytes: n = nbytes
  copyMem(fp.begin, text, n)
  inc(fp.begin, n)
  return if (n == nbytes): 0 else: hputs2(text, nbytes, n, fp)

## / Write a block of characters to the file
## * @return  Either _nbytes_, or negative if an error occurred.
##
## In the absence of I/O errors, the full _nbytes_ will be written.
##

proc hwrite*(fp: ptr hFILE; buffer: pointer; nbytes: csize): ssize_t {.inline, cdecl.} =
  proc hwrite2(a2: ptr hFILE; a3: pointer; a4: csize; a5: csize): ssize_t {.cdecl.}
  var n: csize
  if n > nbytes: n = nbytes
  copyMem(fp.begin, buffer, n)
  inc(fp.begin, n)
  return if (n == nbytes): cast[ssize_t](n) else: hwrite2(fp, buffer, nbytes, n)

## / For writing streams, flush buffered output to the underlying stream
## * @return  0 if successful, or `EOF` if an error occurred.
##
## This includes low-level flushing such as via `fdatasync(2)`.
##

proc hflush*(fp: ptr hFILE): cint {.cdecl, importc: "hflush", header: "htslib/hfile.h".}
