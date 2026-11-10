Tags out of context under the starter profile: as DSM#CNTX does, the
tag is reported through .mg (+++DSMGML002W, return code 4) and its
residual text kept as plain text with no element; a heading with a list
still open ends the list with +++DSMGML003W (DSM#RSET).

  $ gml -profile starter in.gml
  in.gml:5 (in macro ss@msg line 21, in macro ss@cntx line 4): +++DSMGML002W :LI FOUND OUTSIDE LIST. (page 1)
  in.gml:6 (in macro ss@msg line 21, in macro ss@cntx line 4): +++DSMGML002W :DT FOUND OUTSIDE DL. (page 1)
  in.gml:7 (in macro ss@msg line 21, in macro ss@cntx line 4): +++DSMGML002W :DD FOUND OUTSIDE DL. (page 1)
  in.gml:8 (in macro ss@msg line 21, in macro ss@cntx line 4): +++DSMGML002W :GD FOUND OUTSIDE GL. (page 1)
  in.gml:11 (in macro ss@msg line 21, in macro ss@cntx line 4): +++DSMGML002W :DTHD FOUND OUTSIDE DL. (page 1)
  in.gml:13 (in macro ss@msg line 25, in macro dsm#rset line 1, in macro dsmhead2 line 1): +++DSMGML003W OL PREMATURELY ENDED BY :H2 TAG. (page 1)
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
