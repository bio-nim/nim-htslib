# Easy integration
If you have nim and htslib installed in your standard system directories,
things are easy. We make some assumptions (htslib >= 1.4.0),
and everything should Just Work.

    nimble test
    nimble install

Enjoy!

# With GNU modules

    module load nim
    module load htslib
    nimble test

# Harder integration
We take advantage of **pkg-config** or some environment variables,
so most systems are supported, sometimes with effort.

1. Install dependencies.
1. Run tests.
1. Build your own executable.

## Install dependencies

You need:

* htslib, which needs:
  * libz
  * others?
* nim (includes `nim` compiler and `nimble` build-tool)

## Run tests

    nimble test
    # or
    make test

However, to build executables for the tests,
you need to tell **nim** how to find your C headers/libs.

### pkg-config
If you have **pkg-config**, with `htslib.pc` in your `PKG_CONFIG_PATH`,
the tests should simply pass. To find out:

    pkg-config --cflags htslib
    pkg-config --libs htslib

In my case, I get:
```
$ pkg-config --cflags htslib
-I/mnt/software/h/htslib/1.3.1/include
$ pkg-config --libs htslib
-L/mnt/software/h/htslib/1.3.1/lib -lhts
$ pkg-config --libs --static htslib
-L/mnt/software/h/htslib/1.3.1/lib -lhts -lm -lpthread -lz
$ pkg-config --modversion htslib
1.3.1
```

(For now, we always build static binaries. Someday, we may provide a setting to use dynamic libs,
but you would then need to set `LD_LIBRARY_PATH` or `DYLD_LIBRARY_PATH`.)

### GNU modules
If you have GNU modules, you can probably run this:

    module load git
    module load nim
    module load htslib

Within PacBio, that will set-up **pkg-config**, and all should work.

### Other ways
You could try building htslib from the pbbam repository, or some other means.

If you do not build **pkg-config** `.pc` files, then you can set flags
more directly via `CFLAGS` and `LDFLAGS` in your shell-environment. E.g.

    export CFLAGS="-I/my/include"
    export LDFLAGS="-L/my/lib -lhtslib -lz"
    export HTSLIB_VERSION="1.6"

Note that you need to specify the `-l` flags according to which libraries
were available and used when you built **htslib**. (With dynamic linking,
`htslib.so` already knows its own dependencies.)


## Build your own executable
The simplest way is with **nimble**. But you still need to tell **nim** how
to find the C headers/libs. I suggest looking in `./tests/*.nims`. (Yes,
`.nims`, for **nimscripts files.) For a main-program `foo.nim`, create `foo.nims`,
and add a line
```nim
include "setup.nims"
```
TODO: What is actual include path?

Then,

    nim c foo

Our `setup.nims` will pass along the cflags and ldflags for you.

## Version
This wrapper will work will all known versions of htslib.
Of course, it is only a subset of the API.
In order to wrap different versions differently, you must
provide the version at build-time. This is trivial with
**pkg-config**, but otherwise you must set `HTSLIB_VERSION`.
(That is for cmake, within pbbam.)
