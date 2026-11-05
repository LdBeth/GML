The control word separator splits a control word line; the remainder is a
new input line.  .' suppresses the split; .dc cw changes or disables it.

  $ gml in.gml
  a
  b
  c
  d
  e;f
  g;h
  i
  j#k
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">text after separator
  </gml:doc>
