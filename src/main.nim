# vim: sw=2 ts=2 sts=2 tw=80 et:
{.passC: "-I" & staticExec("pwd").}
import htslib/faidx
import os

proc main(fn: string) =
  echo "FASTA:'", fn, "'"
  block:
    var ret = faidx.fai_build(fn.cstring)
    echo "fai_build returned:", ret
  var foo = faidx.fai_load(fn.cstring)
  echo "nseq:", faidx_nseq(foo)
  faidx.fai_destroy(foo)

if isMainModule:
  var fn = os.getEnv("MY_FASTA")
  main(fn)
