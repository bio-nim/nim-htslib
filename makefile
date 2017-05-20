THISDIR=$(shell pwd)
# TODO: Fix THISDIR
NIMFLAGS?=--verbosity:2
HEADERS=bgzf.h faidx.h hfile.h hts.h kstring.h sam.h vcf.h
MY_FASTA?=data/p_ctg.fa
#LDFLAGS+=-Lpbbam/third-party/htslib/build/ -lhts -lz
#CFLAGS+=-g -Wall -Ipbbam/third-party/htslib/htslib
LDLIBS=-lhts -lz
CFLAGS+=-g -Wall
export LDFLAGS CFLAGS MY_FASTA

default: run-main
# test both Nim and C
test: vcftest nvcftest hfiletest nhfiletest samtest nsamtest
submodule:
	git submodule update --init
build-htslib:
	mkdir -p pbbam/third-party/htslib/build
	(cd pbbam/third-party/htslib/build; cmake -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_INSTALL_PREFIX=$(shell pwd)/DESTDIR ..; make VERBOSE=1)
run-%: %.exe
	./$*.exe
%.exe: %.nim
	nim ${NIMFLAGS} --out:$*.exe c $<
%.exe: %.c
	${LINK.c} $^ ${LOADLIBES} ${LDLIBS} -o $@
nvcftest: run-test_vcf_api
vcftest: test-vcf-api.exe
	./test-vcf-api.exe
hfiletest: test-hfile.exe
	cd ../htslib; ${THISDIR}/test-hfile.exe
nhfiletest: test_hfile.exe
	cd ../htslib; ${THISDIR}/test_hfile.exe
samtest: test-sam.exe
	cd ../htslib; ${THISDIR}/test-sam.exe
nsamtest: test_sam.exe
	cd ../htslib; ${THISDIR}/test_sam.exe
# We are gradually wrapping the headers we actually use.
# Someday we might actually convert the underlying C code too.
cp:
	for i in ${HEADERS}; do cp pbbam/third-party/htslib/htslib/htslib/$$i inc/; done
header-%:
	c2nim --header --cdecl inc/$*.h --out:$*.nim
full-%:
	c2nim inc/$*.h --out:$*.nim
clean:
	rm -rf pbbam/third-party/htslib/build/
	git clean -Xdf .
distclean: clean
	git clean -df .
	git submodule deinit --all
