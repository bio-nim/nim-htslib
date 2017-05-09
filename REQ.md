## Nim
* https://nim-lang.org/install.html

## htslib
We provide an older htslib via the pbbam submodule.
It is easy to build htslib locally.

	make build-htslib

I do not know how to install htslib given our cmakefiles,
but that is not necessary.

But in theory, we can build our Nim code
against an already installed version
of htslib. We only need to pass the right `-I/-L` flags to cc
via Nim somehow.

In theory, we can build our Nim code against a more recent
version of htslib, since the older parts are usually not
modified. We do not yet support compile-time modifications
like `BAM_NO_ID`, so there could be some minor problems to work out.
