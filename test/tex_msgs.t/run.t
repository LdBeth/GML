The layout messages of gml.tex, in IBM's format, in the log and in
JOB.gmlmsg (gmlpass shows it after the last pass): DSMGML020W, a cell
too narrow for its indents gets none (MSG, GML 020); SVS445S, k* cells
with no width left, severe: TeX stops with an error (LR .TD r4 p.383).
DSMGML043I, a title page past one page, is the profile's (dcfstarter's
f@tipg compares &$PN at its start and end), so it needs the page
answers of a previous pass.

  $ export TEXINPUTS=../../share/tex:
  $ totex() {
  >   transform -s:$1.xml -xsl:../../xslt/resolve.xsl -o:$1.r.xml &&
  >   transform -s:$1.r.xml -xsl:../../xslt/tex.xsl -o:$1.tex
  > }
  $ gml -profile dcfstarter -o cell.xml cell.gml
  $ totex cell
  $ tex -interaction batchmode cell.tex > /dev/null
  $ cat cell.gmlmsg
  +++DSMGML020W CELL WIDTH FOR CELL 1 TOO SMALL, ZERO INDENTS USED. (page 1)

  $ gml -profile dcfstarter -o star.xml star.gml
  $ totex star
  $ tex -interaction batchmode star.tex > /dev/null
  [1]
  $ cat star.gmlmsg
  +++SVS445S RESULTANT CELL WIDTH IN ROW TOO SMALL. (page 1)
  +++DSMGML020W CELL WIDTH FOR CELL 2 TOO SMALL, ZERO INDENTS USED. (page 1)
  $ grep -c 'severe error' star.log
  1

  $ gml -profile dcfstarter -pass 1 -passes 2 -aux title.gmlaux -o title.xml title.gml
  $ totex title
  $ tex -interaction batchmode title.tex > /dev/null
  $ gml -profile dcfstarter -pass 2 -passes 2 -aux title.gmlaux -o title.xml title.gml 2>&1 | sed 's/ (in macro.*): / /'
  title.gml:64 +++DSMGML043I TITLE PAGE SPANS MULTIPLE PAGES. (page 3)

In element mode (-profile starter: no formatting profile, gml.tex lays
the title page out) gml.tex checks the title page itself: DSMGML043I
when more than one page was shipped between :titlep and :etitlep.  The
front matter is numbered in roman (\pageno negative), so the check
compares absolute page numbers.

  $ gml -profile starter -o stitle.xml title.gml
  $ totex stitle
  $ tex -interaction batchmode stitle.tex > /dev/null
  $ cat stitle.gmlmsg
  +++DSMGML043I TITLE PAGE SPANS MULTIPLE PAGES. (page 5)
