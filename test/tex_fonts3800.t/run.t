The 3800 font ids (LR Tables 29 and 32) are faces of gml.tex by their
role (EXT): GB12 is bold, GI12 italic, and .df FONT ST10 roman; a name
gml.tex does not know leaves the font unchanged, with a warning.

  $ export TEXINPUTS=../../share/tex:
  $ gml -profile starter -o f.xml f.gml
  $ transform -s:f.xml -xsl:../../xslt/resolve.xsl -o:f.r.xml
  $ transform -s:f.r.xml -xsl:../../xslt/tex.xsl -o:f.tex
  $ tex -interaction batchmode f.tex > /dev/null
  $ grep 'unknown font' f.log
  GML: unknown font ZZ99 (font unchanged)
  $ strings -n 4 f.dvi | sed -n '2,8p'
  pncb7t
  bold
  pncri7t
  italic
  pncr7t
  roman
  none
