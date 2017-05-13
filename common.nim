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

# For ptr arithmetic
template usePtr*[T] =
  template `+`(p: ptr T, off: Natural): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) +% int(off) * sizeof(p[]))

  template `+=`(p: ptr T, off: Natural) =
    p = p + off

  template `-`(p: ptr T, off: Natural): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) -% int(off) * sizeof(p[]))

  template `-=`(p: ptr T, off: Natural) =
    p = p - int(off)

  template `[]`(p: ptr T, off: Natural): T =
    (p + int(off))[]

  template `[]=`(p: ptr T, off: Natural, val: T) =
    (p + off)[] = val
