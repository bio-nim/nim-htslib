HEADERS=bgzf.h faidx.h hfile.h hts.h kstring.h sam.h vcf.h

# test both Nim and C
test:
	${MAKE} -C tests/ run-main test
submodule:
	git submodule update --init

# Ideally, htslib is already installed. But if not, this can help:
build-htslib: htslib-1.6/CONFIGURED
	cd htslib-1.6; ${MAKE} -j
htslib-1.6/CONFIGURED: export CPPFLAGS=$(shell pkg-config --cflags zlib)
htslib-1.6/CONFIGURED: export LDFLAGS=$(shell pkg-config --libs zlib)
htslib-1.6/CONFIGURED: htslib-1.6
	cd htslib-1.6; ./configure --disable-bz2 --disable-lzma
	touch htslib-1.6/CONFIGURED
htslib-1.6: htslib-1.6.tar.bz2
	tar xvfj htslib-1.6.tar.bz2
htslib-1.6.tar.bz2:
	# The "release" has the configure script. Otherwise, we need autoconf/autoheader.
	curl -OL https://github.com/samtools/htslib/releases/download/1.6/htslib-1.6.tar.bz2

# We are gradually wrapping the headers we actually use.
# Someday we might actually convert the underlying C code too.
HTSLIB_DIR=htslib-1.6
cp:
	for i in ${HEADERS}; do cp ${HTSLIB_DIR}/htslib/$$i inc/; done
header-%:
	c2nim --header --cdecl inc/$*.h --out:$*.nim
full-%:
	c2nim inc/$*.h --out:$*.nim
clean:
	git clean -Xdf .
distclean: clean
	git clean -df .
	git submodule deinit --all
.PHONY: tests
