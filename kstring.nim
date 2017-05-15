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

const
  KS_SEP_SPACE* = 0 # isspace(): \t, \n, \v, \f, \r
  KS_SEP_TAB*   = 1 # isspace() && !' '
  KS_SEP_LINE*  = 2 # line separator: "\n" (Unix) or "\r\n" (Windows)
  KS_SEP_MAX*   = 2

type
  kstring_t* {.importc: "kstring_t", header: "kstring.h".} = object
    L* {.importc: "l".}: csize
    m* {.importc: "m".}: csize
    s* {.importc: "s".}: cstring

  ks_tokaux_t* {.importc: "ks_tokaux_t", header: "kstring.h".} = object
    tab* {.importc: "tab".}: array[4, uint64]
    sep* {.importc: "sep".}: cint
    finished* {.importc: "finished".}: cint
    p* {.importc: "p".}: cstring ##  end of the current token

proc kroundup32*[T](x: var T) =
  dec(x)
  (x) = (x) or (x) shr 1
  (x) = (x) or (x) shr 2
  (x) = (x) or (x) shr 4
  (x) = (x) or (x) shr 8
  (x) = (x) or (x) shr 16
  inc(x)

#proc kvsprintf*(s: ptr kstring_t; fmt: cstring; ap: va_list): cint {.cdecl,
#    importc: "kvsprintf", header: "kstring.h".}
proc ksprintf*(s: ptr kstring_t; fmt: cstring): cint {.varargs, cdecl,
    importc: "ksprintf", header: "kstring.h".}
proc ksplit_core*(s: cstring; delimiter: cint; max: ptr cint; offsets: ptr ptr cint): cint {.
    cdecl, importc: "ksplit_core", header: "kstring.h".}
proc kstrstr*(str: cstring; pat: cstring; prep: ptr ptr cint): cstring {.cdecl,
    importc: "kstrstr", header: "kstring.h".}
proc kstrnstr*(str: cstring; pat: cstring; n: cint; prep: ptr ptr cint): cstring {.cdecl,
    importc: "kstrnstr", header: "kstring.h".}
proc kmemmem*(str: pointer; n: cint; pat: pointer; m: cint; prep: ptr ptr cint): pointer {.
    cdecl, importc: "kmemmem", header: "kstring.h".}
##  kstrtok() is similar to strtok_r() except that str is not
##  modified and both str and sep can be NULL. For efficiency, it is
##  actually recommended to set both to NULL in the subsequent calls
##  if sep is not changed.

proc kstrtok*(str: cstring; sep: cstring; aux: ptr ks_tokaux_t): cstring {.cdecl,
    importc: "kstrtok", header: "kstring.h".}
proc ks_resize*(s: ptr kstring_t; size: csize): cint {.inline, cdecl.} =
  if s.m < size:
    var tmp: cstring
    s.m = size
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return - 1
  return 0

proc ks_str*(s: ptr kstring_t): cstring {.inline, cdecl.} =
  return s.s

proc ks_len*(s: ptr kstring_t): csize {.inline, cdecl.} =
  return s.L

##  Give ownership of the underlying buffer away to something else (making
##  that something else responsible for freeing it), leaving the kstring_t
##  empty and ready to be used again, or ready to go out of scope without
##  needing  free(str.s)  to prevent a memory leak.

proc ks_release*(s: ptr kstring_t): cstring {.inline, cdecl.} =
  var ss: cstring = s.s
  s.L = 0
  s.m = 0
  s.s = nil
  return ss

proc kputsn*(p: cstring; l: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if s.L + l + 1 >= s.m:
    var tmp: cstring
    s.m = s.L + l + 2
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  copyMem(cast[pointer](cast[ByteAddress](s.s) + s.L), cast[pointer](p), l)
  inc(s.L, l)
  s.s[s.L] = '\0'
  return l

proc kputs*(p: cstring; s: ptr kstring_t): cint {.inline, cdecl.} =
  return kputsn(p, len(p).cint, s)

proc kputc*(c: cint; s: ptr kstring_t): cint {.inline, cdecl, discardable.} =
  if s.L + 1 >= s.m:
    var tmp: cstring
    s.m = s.L + 2
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  s.s[s.L] = c.char
  inc(s.L)
  s.s[s.L] = '\0'
  return c

proc kputc_z*(c: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if s.L + 1 > s.m:
    var tmp: cstring
    s.m = s.L + 1
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  s.s[s.L] = c.char
  inc(s.L)
  return 1

#proc kputc*(c: char; s: ptr kstring_t): cint {.inline, discardable.} =
#  return kputc(c.cint, s)

proc kputsn_z*(p: pointer; l: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  if s.L + l > s.m:
    var tmp: cstring
    s.m = s.L + l
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  copyMem(cast[pointer](cast[ByteAddress](s.s) + s.L), cast[pointer](p), l)
  inc(s.L, l)
  return l

proc kputw*(c: cint; s: ptr kstring_t): cint {.inline, cdecl.} =
  var buf: array[16, char]
  var
    i: cint
    l: cint
    x: cuint
  if c < 0:
    x = cuint(-c)
  else:
    x = cuint(c)
  while true:
    buf[l] = (x mod 10 + '0'.int).char
    inc(l)
    x = x div 10
    if not (x > 0'u): break
  if c < 0:
    buf[l] = '-'
    inc(l)
  if s.L + l + 1 >= s.m:
    var tmp: cstring
    s.m = s.L + l + 2
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  i = l - 1
  while i >= 0:
    s.s[s.L] = buf[i]
    inc(s.L)
    dec(i)
  s.s[s.L] = '\0'
  return 0

proc kputuw*(c: cuint; s: ptr kstring_t): cint {.inline, cdecl.} =
  var buf: array[16, char]
  var
    l: cint
    i: cint
    x: cuint
  if c == 0: return kputc('0'.cint, s)
  l = 0
  x = c
  while x > 0'u:
    buf[l] = (x mod 10 + '0'.int).char
    inc(l)
    x = x div 10
  if s.L + l + 1 >= s.m:
    var tmp: cstring
    s.m = s.L + l + 2
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  i = l - 1
  while i >= 0:
    s.s[s.L] = buf[i]
    inc(s.L)
    dec(i)
  s.s[s.L] = '\0'
  return 0

proc kputl*(c: clong; s: ptr kstring_t): cint {.inline, cdecl.} =
  var buf: array[32, char]
  var
    i: cint
    l: cint
    x: culong
  if c < 0: x = (-c).culong
  else: x = c.culong
  while true:
    buf[l] = (x mod 10 + '0'.culong).char
    inc(l)
    x = x div 10
    if not (x > 0'u): break
  if c < 0:
    buf[l] = '-'
    inc(l)
  if s.L + l + 1 >= s.m:
    var tmp: cstring
    s.m = s.L + l + 2
    kroundup32(s.m)
    tmp = cast[cstring](realloc(s.s, s.m))
    if (tmp != nil): s.s = tmp
    else: return -1 # EOF
  i = l - 1
  while i >= 0:
    s.s[s.L] = buf[i]
    inc(s.L)
    dec(i)
  s.s[s.L] = '\0'
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
