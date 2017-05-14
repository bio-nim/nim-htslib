proc throw*(msg: string) =
    raise newException(Exception, msg)

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
