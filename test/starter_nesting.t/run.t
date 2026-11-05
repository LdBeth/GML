Starter Set bookkeeping for nested quotations and footnotes.  :q nests
(&@nest@q counts the levels, DSMQUOTE/DSMEQUOT, SH35-0050 p.125), so
only the extra :eq on line 7 has no quotation open.  A footnote has its own flag
(&@fn), apart from &@state: a :fn inside a :fig does not end the figure
state (modern edge: DSMFTNT refuses footnotes in figures because of
keeps and floats, SH35-0050 p.129; the tree has no such conflict).
DSM#RSET reports a quotation and a footnote still open at a heading.

  $ gml -profile starter in.gml
  in.gml:7: warning: end tag :eq: element q is not open
  in.gml:7 (in macro dsm#msg line 15, in macro dsmequot line 2): +++DSMGML006W Tag :q found but no quotation is open.
  in.gml:8: warning: end tag :efn: element fn is not open
  in.gml:8 (in macro dsm#msg line 15, in macro dsmeftnt line 1): +++DSMGML006W Tag :fn found but no footnote is open.
  in.gml:11 (in macro dsm#msg line 6, in macro dsm#rset line 2, in macro dsmhead1 line 1): +++DSMGML003W Tag :q not ended before tag :h1.
  in.gml:11 (in macro dsm#msg line 6, in macro dsm#rset line 4, in macro dsmhead1 line 1): +++DSMGML003W Tag :fn not ended before tag :h1.
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body><p>He said <q>she said <q>no</q> there</q> and left.
  </p><fig>A figure<fn>a footnote in a figure</fn> with more text.
  <figcap>Caption</figcap>
  </fig><p>Text<fn>a plain footnote</fn> and <q>one</q> too many.
  </p><p>Stray end.
  </p><h1>Heading <q>open</q></h1>
  <fn>not ended
  </fn><h1>Next</h1>
  </body></gdoc></gml:doc>
  [4]
