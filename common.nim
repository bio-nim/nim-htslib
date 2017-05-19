import math

proc throw*(msg: string) =
    raise newException(Exception, msg)

# https://akehrer.github.io/nim/2015/01/14/getting-started-with-nim-pt2.html
#const
#  Nan = 0.0/0.0 # floating point not a number (NaN)

proc cIsNaN(x: float): cint {.importc: "isnan", header: "<math.h>".}
  ## returns non-zero if x is not a number

proc cIsInf(x: float): cint {.importc: "isinf", header: "<math.h>".}
  ## returns non-zero if x is infinity

proc isNaN*(x: float): bool =
  ## converts the integer result from cIsNaN to a boolean
  if cIsNaN(x) != 0.cint:
    true
  else:
    false

proc isInf*(x: float): bool =
  ## converts the integer result from cIsInf to a boolean
  if cIsInf(x) != 0.cint:
    true
  else:
    false

# For ptr arithmetic: https://forum.nim-lang.org/t/1188#7366
template usePtr*[T] =
  template `+`(p: ptr T, off: SomeInteger): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) +% int(off) * sizeof(p[]))

  template `+=`(p: ptr T, off: SomeInteger) =
    p = p + off

  template `-`(p: ptr T, off: SomeInteger): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) -% int(off) * sizeof(p[]))

  template `-`(p: ptr T, off: ptr T): ByteAddress =
    (cast[ByteAddress](p) -% cast[ByteAddress](off))

  template `-=`(p: ptr T, off: SomeInteger) =
    p = p - int(off)

  template `[]`(p: ptr T, off: SomeInteger): T =
    (p + int(off))[]

  template `[]=`(p: ptr T, off: SomeInteger, val: T) =
    (p + off)[] = val

# https://forum.nim-lang.org/t/2943
template asarray*[T](p: pointer): auto =
  type A {.unchecked.} = array[0..0, T]
  cast[ptr A](p)
