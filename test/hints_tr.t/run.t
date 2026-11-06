.tr (SH35-0069 p.207) is a real translate table applied to the text:
pairs of characters or two-digit hex codes.  A lone last character
translates to a blank; .tr with no operands resets the table.  A hex
code is EBCDIC (code page 037), written as UTF-8: c1 is "A", 40 a blank
and 42 is "â".

  $ gml in.gml
  in.gml:11: error: .tr: invalid character xyz
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">ABc And BoB
  *gAin: ABc
  x yâz
   Bc
  abc~#
  still abc
  </gml:doc>
  [8]
