Tags out of context under the starter profile: as DSM#CNTX does, the
tag is reported through .mg (+++DSMGML002W, return code 4) and its
residual text kept as plain text with no element; a heading with a list
still open ends the list with +++DSMGML003W (DSM#RSET).

  $ gml -profile starter in.gml
  in.gml:5 (in macro dsm#msg line 3, in macro dsm#cntx line 1): +++DSMGML002W Tag :li is out of context.
  in.gml:6 (in macro dsm#msg line 3, in macro dsm#cntx line 1): +++DSMGML002W Tag :dt is out of context.
  in.gml:7 (in macro dsm#msg line 3, in macro dsm#cntx line 1): +++DSMGML002W Tag :dd is out of context.
  in.gml:8 (in macro dsm#msg line 3, in macro dsm#cntx line 1): +++DSMGML002W Tag :gd is out of context.
  in.gml:11 (in macro dsm#msg line 3, in macro dsm#cntx line 1): +++DSMGML002W Tag :dthd is out of context.
  in.gml:13 (in macro dsm#msg line 6, in macro dsm#rset line 1, in macro dsmhead2 line 1): +++DSMGML003W Tag :ol not ended before tag :h2.
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body><h1>Context errors</h1>
  <p>A list item outside a list:
  stray item
  a term outside a definition list
  a description outside one
  a glossary description outside a glossary list
  </p><ol><li>first
  a heading inside an ordered list
  </li><li>second
  </li></ol><h2>A heading with the list still open</h2>
  <p>Text.
  </p></body></gdoc></gml:doc>
  [4]
