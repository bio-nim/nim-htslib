THISDIR=$(shell pwd)
# TODO: Fix THISDIR
#NIMFLAGS?=--verbosity:2
NIMFLAGS?=--listCmd
#NIMFLAGS+=--d:release
NIMFLAGS+=--d:debug --debugger:native
NIMFLAGS+=--verbosity:2
HTSLIB_ROOT?=../repos/htslib
CFLAGS?=$(shell pkg-config --cflags htslib)
LDLIBS?=$(shell pkg-config --libs htslib)

default: run-main

# test both Nim and C
test: | ../.git/modules/repos/htslib
	${MAKE} nvcftest nhfiletest nsamtest
test-c: | ../.git/modules/repos/htslib
	${MAKE} vcftest hfiletest samtest
../.git/modules/repos/htslib:
	cd ../repos; git submodule update --init
nvcftest: test_vcf_api.exe
	cd ${HTSLIB_ROOT}; ${THISDIR}/test_vcf_api.exe
vcftest: test-vcf-api.exe
	cd ${HTSLIB_ROOT}; ${THISDIR}/test-vcf-api.exe
hfiletest: test-hfile.exe
	cd ${HTSLIB_ROOT}; ${THISDIR}/test-hfile.exe
nhfiletest: test_hfile.exe
	cd ${HTSLIB_ROOT}; ${THISDIR}/test_hfile.exe
samtest: test-sam.exe
	cd ${HTSLIB_ROOT}; ${THISDIR}/test-sam.exe
nsamtest: test_sam.exe
	cd ${HTSLIB_ROOT}; ${THISDIR}/test_sam.exe

run-%: %.exe
	./$*.exe
%.exe: %.nim
	nim c ${NIMFLAGS} --out:$*.exe $*
%.exe: %.c
	${LINK.c} $^ ${LOADLIBES} ${LDLIBS} -o $@
clean:
	rm -f *.exe
	rm -rf nimcache/
