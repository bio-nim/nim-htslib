# nim-htslib
Nim wrapper for htslib

* https://github.com/bio-nim/nim-htslib/wiki

# Getting started
Assuming you have **nim** but not **htslib**:

    nim --version
    cmake --version
    make submodule
    make build-htslib
    make test
    make

To try your own input:

    MY_FASTA=foo.fasta make
