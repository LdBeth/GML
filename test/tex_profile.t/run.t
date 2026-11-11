TeX is made from a formatting profile only: tex.xsl reports a document
with tags and no .df/.dh/.dr hint before the first of them (made with
the semantic profile starter).  The same tags under dcfstarter, and
control words with no tags at all, are not reported.

  $ totex() {
  >   transform -s:$1.xml -xsl:../../xslt/resolve.xsl -o:$1.r.xml &&
  >   transform -s:$1.r.xml -xsl:../../xslt/tex.xsl -o:$1.tex
  > }
  $ gml -profile starter -o tags.xml tags.gml
  $ totex tags
  tex: gdoc: no .df/.dh/.dr before the first tag: TeX needs a formatting profile (-profile dcfstarter)
  $ gml -profile dcfstarter -o tags.xml tags.gml
  $ totex tags
  $ gml -o words.xml words.gml
  $ totex words
