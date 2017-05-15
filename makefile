NIMFLAGS?=--verbosity:2
HEADERS=bgzf.h faidx.h hfile.h hts.h kstring.h sam.h vcf.h
MY_FASTA?=data/p_ctg.fa
#LDFLAGS+=-Lpbbam/third-party/htslib/build/ -lhts -lz
#CFLAGS+=-g -Wall -Ipbbam/third-party/htslib/htslib
LDLIBS=-lhts -lz
CFLAGS+=-g -Wall
export LDFLAGS CFLAGS MY_FASTA

default: run-main
test: ntest ctest # both Nim and C
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
ntest: run-test_vcf_api
ctest: test-vcf-api.exe
	./test-vcf-api.exe
htest: test-hfile.exe
	mkdir -p test/
	./test-hfile.exe
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
