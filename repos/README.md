## submodules

### htslib
We use this for testing, not building. We copied some tests and
converted them to Nim, but they are designed to run in this directory.

You can build against many different versions of htslib. Our tests will
skip code this does not work on your version. (The magic which decides
your version is in `../src/setup.nims`.)

### pbbam
(No longer used.)

This is only for reference. However, if you do not have htslib,
you might find this easy to install. Run **cmake** in:

    pbbam/third-party/htslib

That will not install **pkg-config** `.pc` files, so you will need
to set some environment variables. See `../src/setup.nims`
