HEADERS=bgzf.h faidx.h hfile.h hts.h kstring.h sam.h vcf.h

# test both Nim and C
test:
	${MAKE} -C tests/ run-main test
submodule:
	git submodule update --init
build-htslib:
	mkdir -p repos/pbbam/third-party/htslib/build
	(cd repos/pbbam/third-party/htslib/build; cmake -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_INSTALL_PREFIX=$(shell pwd)/DESTDIR ..; make VERBOSE=1)
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
.PHONY: tests
