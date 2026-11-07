#!/bin/sh
# tex-parity.sh - check that gml -tex (lib/be_tex.ml) is byte-identical to
# xslt/tex.xsl (tex-mode=hints) applied to the XML of the same run.
#
#   test/tex-parity.sh [file.gml ...]
#
# Run from anywhere; with no arguments it checks every document of
# xslt/test/gml, examples and test/*.t, each with -profile starter,
# -profile dcfstarter and no profile (-set SYSVARH=yes).  A document runs
# in its own directory (for .im).  It needs SaxonC (tex.xsl is XSLT 3.0),
# so it is not a dune cram test; "mk test" runs it.  Environment: SAXON
# (default /usr/local/bin/transform), GMLEXE (default the dune build,
# _build/default/bin/main.exe).  Exit status 1 if any output differs; the
# differing pairs are kept in a temporary directory, which is printed.
root=$(cd "$(dirname "$0")/.." && pwd) || exit 2
SAXON=${SAXON:-/usr/local/bin/transform}
GMLEXE=${GMLEXE:-$root/_build/default/bin/main.exe}
[ -x "$GMLEXE" ] || { echo "tex-parity: $GMLEXE not found (dune build)" >&2; exit 2; }
command -v "$SAXON" > /dev/null || { echo "tex-parity: $SAXON not found" >&2; exit 2; }
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tex-parity.XXXXXX") || exit 2
if [ $# -eq 0 ]; then
  set -- "$root"/xslt/test/gml/*.gml "$root"/examples/*.gml "$root"/test/*.t/*.gml
fi
ok=0 bad=0
for f in "$@"; do
  d=$(cd "$(dirname "$f")" && pwd)
  b=$(basename "$f")
  for p in starter dcfstarter none; do
    if [ $p = none ]; then prof=; else prof="-profile $p"; fi
    out=$tmp/$(basename "$d")_${b%.gml}.$p
    (cd "$d" && "$GMLEXE" -share "$root/share" $prof -set SYSVARH=yes \
       -o "$out.xml" -tex "$out.ml.tex" "$b" > /dev/null 2>&1 < /dev/null)
    if [ ! -f "$out.xml" ]; then
      echo "NO OUTPUT $f ($p)"; bad=$((bad + 1)); continue
    fi
    "$SAXON" -s:"$out.xml" -xsl:"$root/xslt/tex.xsl" tex-mode=hints -o:"$out.xsl.tex" 2> /dev/null
    if cmp -s "$out.ml.tex" "$out.xsl.tex"; then
      ok=$((ok + 1)); rm -f "$out.xml" "$out.ml.tex" "$out.xsl.tex"
    else
      echo "DIFFER $f ($p): diff $out.xsl.tex $out.ml.tex"; bad=$((bad + 1))
    fi
  done
done
echo "tex-parity: $ok identical, $bad differ"
if [ $bad -eq 0 ]; then rm -rf "$tmp"; else echo "tex-parity: outputs in $tmp"; exit 1; fi
