Macros shadow native control words while .ms on; .'name runs the
native word; .ms off disables macro calls.  A control word name is two
characters and the blank after it is optional (.cecenter = .ce center,
SH35-0069 p.40); with .ms on the whole name is tried as a macro first.  The native .ce
gives a gml:lines scope.

  $ gml in.gml
  in.gml:26: warning: unsupported control word .zz
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">macro se called with [x = 5]
  x=6
  x=7
  macro se called with [x = 8]
  x=7
  comment macro [hello 7]
  zz macro
  macro cecenter
  <gml:lines word="ce" n="1" break="yes">centre this line</gml:lines>
  <gml:lines word="ce" n="1" break="yes">center the modifier: no macro search</gml:lines>
  </gml:doc>
  [4]
