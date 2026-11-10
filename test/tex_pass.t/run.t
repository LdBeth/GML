The pass model with a real TeX run between the passes (plain tex,
share/tex/gml.tex), the TeX file made from the XML by the XSLT stages
as the mkfile does (xslt/resolve.xsl, then xslt/tex.xsl; the test is
enabled only when tex and SaxonC's transform are installed, see
test/dune).  gml.tex answers the questions in JOB.gmlaux: pn at
shipout (the page the place of the question is put out on), lc at
once (the lines left on the page: (\pagegoal-\pagetotal)/\baselineskip
after the page builder ran; on an empty page \vsize/\baselineskip).

  $ command -v tex > /dev/null && echo tex found
  tex found
  $ export TEXINPUTS=../../share/tex:
  $ totex() {
  >   transform -s:in.xml -xsl:../../xslt/resolve.xsl -o:in.r.xml &&
  >   transform -s:in.r.xml -xsl:../../xslt/tex.xsl -o:in.tex
  > }
  $ gml -profile dcfstarter -pass 1 -passes 2 -aux in.gmlaux -symbols-out in.sym -o in.xml in.gml
  $ totex
  $ tex -interaction batchmode in.tex > /dev/null
  $ head -1 in.gmlaux
  .* gml aux
  $ grep -c '^.se pq@' in.gmlaux
  5

The lc answer is written at once, the pn answers at shipout (so after
it in the file): the heading One and the forward reference (q1.4.1,
asked on every pass) are on page 1, Two and the reference back on
page 2.  The anchors are the TOC marks (gml.tc.N) and the ids
of the headings (one, two: tex.xsl anchors every id).

  $ grep '^.se pq@' in.gmlaux
  .se pq@1@5@1 = 37
  .se pq@1@3@1 = 1
  .se pq@1@4@1 = 1
  .se pq@1@7@1 = 2
  .se pq@1@8@1 = 2
  $ grep '^.se pa@' in.gmlaux
  .se pa@one = '1'
  .se pa@gml@tc@1 = '1'
  .se pa@two = '2'
  .se pa@gml@tc@2 = '2'

Pass 2: &$LC and the pages come from the aux file; the forward
reference is resolved by the symbols of pass 1, and fp@TWO, set to the
answer of q1.7.1 in pass 1 (1 then), comes back as TeX's answer to it
in pass 1, page 2 (the page provenance); the backward one names the
page of One, which is not the page of the reference.  The aux file of
the second TeX run raises no "page references have changed", and it
and the symbol file are those of pass 1: two passes are enough
(gmlpass -n 2).

  $ cp in.gmlaux in.gmlaux1
  $ gml -profile dcfstarter -pass 2 -passes 2 -aux in.gmlaux -symbols-in in.sym -symbols-out in.sym2 -o in.xml in.gml
  $ totex
  $ grep 'See\|Back\|Lines' in.tex
  >See <?pn q1.4.1>&8220;Two&8221; on page 2.
  <?lc q1.5.1>Lines left here: 37.
  >Back to <?pn q1.8.1>&8220;One&8221; on page 1.
  $ tex -interaction batchmode in.tex > /dev/null
  $ grep 'changed' in.log
  [1]
  $ cmp in.sym in.sym2 && cmp in.gmlaux1 in.gmlaux && echo stable
  stable
