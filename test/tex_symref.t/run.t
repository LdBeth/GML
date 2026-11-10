A symbol in a running footing is replaced on each page with its value
"at the time the page is started" (LR p.316).  gml.tex makes every
change (gml:symval) an e-TeX mark of the symbol's class; the footing
takes the last mark before the page's first line (a .se after the page
eject, as dcfstarter's .pa .se f@shead), else the last one on the pages
before (a .se before the eject, as IBM's DSMHEAD1, or in the middle of
a page), else the value where it was defined.  A value set to the null
string is a value.  hook.tex writes what the footing got to in.heads.

  $ export TEXINPUTS=../../share/tex:.:
  $ gml -o in.xml in.gml
  $ transform -s:in.xml -xsl:../../xslt/resolve.xsl -o:in.r.xml
  $ transform -s:in.r.xml -xsl:../../xslt/tex.xsl -o:in.tex 'tex-preamble=\input hook'
  $ grep symval in.tex
  .pa><,symval name=sec,value=Beta>Second page text.
  <,symval name=sec,value=Gamma><
  <,symval name=sec,value=Delta>More text on the third page.
  <,symval name=sec,value=><
  $ pdftex -interaction batchmode in.tex > /dev/null
  $ cat in.heads
  page 1: sec = [Alpha]
  page 2: sec = [Beta]
  page 3: sec = [Gamma]
  page 4: sec = [Delta]
  page 5: sec = []
