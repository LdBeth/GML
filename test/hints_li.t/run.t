.li (SH35-0069 p.89; LR p.231): .li on treats every input line as text until .li
off: control words and implicit words (leading blank, null line) are not
recognised, symbols are still substituted; GML tags are (LR p.231 r2),
but the control words their APFs produce are text (no APF here, so :p.
stays text).  .li text makes the
rest of the line text; .li n the next n lines.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">.sp 2
  :p.not a tag; value is substituted
   leading blank, no break
  
  .ce is text
  <gml:lines word="ce" n="1" break="yes">centered value</gml:lines>
  .br
  .in 5
  </gml:doc>
