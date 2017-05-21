THISDIR=$(shell pwd)
# TODO: Fix THISDIR
#NIMFLAGS?=--verbosity:2
NIMFLAGS?=--listCmd

default: run-main

# test both Nim and C
test: vcftest nvcftest hfiletest nhfiletest samtest nsamtest
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

run-%: %.exe
	./$*.exe
%.exe: %.nim
	nim c ${NIMFLAGS} --out:$*.exe $*
%.exe: %.c
	${LINK.c} $^ ${LOADLIBES} ${LDLIBS} -o $@
