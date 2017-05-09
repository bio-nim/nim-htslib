# nim-htslib
Nim wrapper for htslib

For now, this is just a simple example of faidx.
We still need to clean up the c2nim-generated modules.

## Run example

	make submodule
	make build-htslib
	make
	MY_FASTA=foo.fasta make

## Requirements
See REQ.md

## Components
**pbbam** uses the following htslib headers:
```c
#include <htslib/bgzf.h>
#include <htslib/faidx.h>
#include <htslib/hfile.h>
#include <htslib/hts.h>
#include <htslib/kstring.h>
#include <htslib/sam.h>
```
We have run **c2nim** on those, but our wrappers still need some work.
Note that some CPP macros have become templates, and some
static-inline functions have been translated into Nim procedures.
