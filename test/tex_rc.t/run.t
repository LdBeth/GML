Revision bars (.rc): a rule beside the revised text, from the first
revised line to the last (share/tex/gml.tex, "revision bars").  Where a
stretch opens and closes is noted with \pdfsavepos and written to the
aux file at shipout; the next pass draws the rules.  hook.tex writes
the rules of each page to in.bars: the side and the length.

  $ export TEXINPUTS=../../share/tex:.:
  $ fmt() { gml -profile dcfstarter -aux in.gmlaux -o in.xml in.gml &&
  >   transform -s:in.xml -xsl:../../xslt/resolve.xsl -o:in.r.xml &&
  >   transform -s:in.r.xml -xsl:../../xslt/tex.xsl -o:in.tex 'tex-preamble=\input hook' &&
  >   pdftex -interaction batchmode in.tex > /dev/null; }

The first pass has nothing to draw; it writes the segments (o, c), and
the top (t) and the last line (e) of each page:

  $ fmt
  $ cat in.bars
  $ grep -c '^\.\* rc [oc] ' in.gmlaux
  8
  $ grep -c '^\.\* rc [te] ' in.gmlaux
  12
  $ cp in.gmlaux pass1.gmlaux

The second pass draws them, and writes the same file again:

  $ fmt
  $ cat in.bars
  page 1: left 30pt
  page 2: left 10pt
  page 2: left 9pt
  page 3: left 9pt
  page 3: right 29pt
  page 4: left 51pt
  page 5: right 51pt
  page 6: left 31pt
  $ cmp in.gmlaux pass1.gmlaux
