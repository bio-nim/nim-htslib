# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passL: "-lhts".}
##  The MIT License
##
##    Copyright (C) 2011 by Attractive Chaos <attractor@live.co.uk>
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

##  kstring_t is a simple non-opaque type whose fields are likely to be
##  used directly by user code (but see also ks_str() and ks_len() below).
##  A kstring_t object is initialised by either of
##        kstring_t str = { 0, 0, NULL };
##        kstring_t str; ...; str.l = str.m = 0; str.s = NULL;
##  and either ownership of the underlying buffer should be given away before
##  the object disappears (see ks_release() below) or the kstring_t should be
##  destroyed with  free(str.s);

type
  kstring_t* {.importc: "kstring_t", header: "htslib/kstring.h", bycopy.} = object
    l* {.importc: "l".}: csize
    m* {.importc: "m".}: csize
    s* {.importc: "s".}: cstring

  ks_tokaux_t* {.importc: "ks_tokaux_t", header: "htslib/kstring.h", bycopy.} = object
    tab* {.importc: "tab".}: array[4, uint64_t]
    sep* {.importc: "sep".}: cint
    finished* {.importc: "finished".}: cint
    p* {.importc: "p".}: cstring ##  end of the current token


proc kvsprintf*(s: ptr kstring_t; fmt: cstring; ap: va_list): cint {.cdecl,
    importc: "kvsprintf", header: "htslib/kstring.h".}
proc ksprintf*(s: ptr kstring_t; fmt: cstring): cint {.varargs, cdecl,
    importc: "ksprintf", header: "htslib/kstring.h".}
proc kputd*(d: cdouble; s: ptr kstring_t): cint {.cdecl, importc: "kputd",
    header: "htslib/kstring.h".}
##  custom %g only handler

proc ksplit_core*(s: cstring; delimiter: cint; _max: ptr cint; _offsets: ptr ptr cint): cint {.
    cdecl, importc: "ksplit_core", header: "htslib/kstring.h".}
proc kstrstr*(str: cstring; pat: cstring; _prep: ptr ptr cint): cstring {.cdecl,
    importc: "kstrstr", header: "htslib/kstring.h".}
proc kstrnstr*(str: cstring; pat: cstring; n: cint; _prep: ptr ptr cint): cstring {.cdecl,
    importc: "kstrnstr", header: "htslib/kstring.h".}
proc kmemmem*(_str: pointer; n: cint; _pat: pointer; m: cint; _prep: ptr ptr cint): pointer {.
    cdecl, importc: "kmemmem", header: "htslib/kstring.h".}
##  kstrtok() is similar to strtok_r() except that str is not
##  modified and both str and sep can be NULL. For efficiency, it is
##  actually recommended to set both to NULL in the subsequent calls
##  if sep is not changed.

proc kstrtok*(str: cstring; sep: cstring; aux: ptr ks_tokaux_t): cstring {.cdecl,
    importc: "kstrtok", header: "htslib/kstring.h".}
##  kgetline() uses the supplied fgets()-like function to read a "\n"-
##  or "\r\n"-terminated line from fp.  The line read is appended to the
##  kstring without its terminator and 0 is returned; EOF is returned at
##  EOF or on error (determined by querying fp, as per fgets()).

type
  kgets_func* = proc (a2: cstring; a3: cint; a4: pointer): cstring {.cdecl.}

proc kgetline*(s: ptr kstring_t; fgets: ptr kgets_func; fp: pointer): cint {.cdecl,
    importc: "kgetline", header: "htslib/kstring.h".}
proc ks_resize*(s: ptr kstring_t; size: csize): cint {.inline, cdecl.} =
  if s.m < size:
    var tmp: cstring
    kroundup_size_t(size)
    tmp = cast[cstring](realloc(s.s, size))
    if not tmp: return -1
    s.s = tmp
    s.m = size

  return 0

proc ks_str*(s: ptr kstring_t): cstring {.inline, cdecl.} =
  return s.s

proc ks_len*(s: ptr kstring_t): csize {.inline, cdecl.} =
  return s.l

##  Give ownership of the underlying buffer away to something else (making
##  that something else responsible for freeing it), leaving the kstring_t
##  empty and ready to be used again, or ready to go out of scope without
##  needing  free(str.s)  to prevent a memory leak.

proc ks_release*(s: ptr kstring_t): cstring {.inline, cdecl.} =
  var ss: cstring
  s.l = s.m = 0
  s.s = nil
  return ss

proc kputsn*(p: cstring; l: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if ks_resize(s, s.l + l + 2) < 0: return EOF
  copyMem(s.s + s.l, p, l)
  inc(s.l, l)
  s.s[s.l] = 0
  return l

proc kputs*(p: cstring; s: ptr kstring_t): cint {.inline, cdecl.} =
  return kputsn(p, strlen(p), s)

proc kputc*(c: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if ks_resize(s, s.l + 2) < 0: return EOF
  s.s[inc(s.l)] = c
  s.s[s.l] = 0
  return c

proc kputc_*(c: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if ks_resize(s, s.l + 1) < 0: return EOF
  s.s[inc(s.l)] = c
  return 1

proc kputsn_*(p: pointer; l: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if ks_resize(s, s.l + l) < 0: return EOF
  copyMem(s.s + s.l, p, l)
  inc(s.l, l)
  return l

proc kputw*(c: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  var buf: array[16, char]
  var
    i: cint
    l: cint
  var x: cuint
  if c < 0: x = -x
  while true:
    buf[inc(l)] = x mod 10 + '0'
    x = x / 10
    if not (x > 0): break
  if c < 0: buf[inc(l)] = '-'
  if ks_resize(s, s.l + l + 2) < 0: return EOF
  i = l - 1
  while i >= 0:
    s.s[inc(s.l)] = buf[i]
    dec(i)
  s.s[s.l] = 0
  return 0

proc kputuw*(c: cuint; s: ptr kstring_t): cint {.inline, cdecl.} =
  var buf: array[16, char]
  var
    l: cint
    i: cint
  var x: cuint
  if c == 0: return kputc('0', s)
  l = 0
  x = c
  while x > 0:
    buf[inc(l)] = x mod 10 + '0'
    x = x / 10
  if ks_resize(s, s.l + l + 2) < 0: return EOF
  i = l - 1
  while i >= 0:
    s.s[inc(s.l)] = buf[i]
    dec(i)
  s.s[s.l] = 0
  return 0

proc kputl*(c: clong; s: ptr kstring_t): cint {.inline, cdecl.} =
  var buf: array[32, char]
  var
    i: cint
    l: cint
  var x: culong
  if c < 0: x = -x
  while true:
    buf[inc(l)] = x mod 10 + '0'
    x = x / 10
    if not (x > 0): break
  if c < 0: buf[inc(l)] = '-'
  if ks_resize(s, s.l + l + 2) < 0: return EOF
  i = l - 1
  while i >= 0:
    s.s[inc(s.l)] = buf[i]
    dec(i)
  s.s[s.l] = 0
  return 0

##
##  Returns 's' split by delimiter, with *n being the number of components;
##          NULL on failue.
##

proc ksplit*(s: ptr kstring_t; delimiter: cint; n: ptr cint): ptr cint {.inline, cdecl.} =
  var
    max: cint
    offsets: ptr cint
  n[] = ksplit_core(s.s, delimiter, addr(max), addr(offsets))
  return offsets

