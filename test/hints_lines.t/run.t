Line-counted words mark the input lines they cover with a gml:lines
scope (.ce n, .ce text, .ri on/off, .us n).  The scope carries the
state inside it; an element opened inside a scope splits it
(cont="yes").  The words that count output lines are hints only: .in
x for v1 after v2 carries for/for-unit and after/after-unit as given
(lines or any other unit), temporary="yes" when there is a FOR; .il
and .un are the hints il/un with the shift of the next output line
from the margin that line has (LR p.206 r1), signed, to the right: .il
h and .il +h right, .il -h left, .un the reverse (.un 2 is .il -2); the
sign is a direction, not an increment (r5).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:lines word="ce" n="2" break="yes">After this control word is processed,
  the next two lines are centered.</gml:lines>
  However, this one is not.
  <gml:lines word="ce" n="1" break="yes">Chapter 1</gml:lines>
  <gml:lines word="ri" n="on" break="yes">These lines must
  be flush right.
  </gml:lines><gml:in left="5" unit="ch" after="1" after-unit="line" break="yes"/>Subsequent text will be indented,
  except for the first line.
  <gml:in left="0" unit="ch" break="yes"/><gml:in left="2" unit="ch" delta="+2" temporary="yes" for="2" for-unit="line" break="yes"/>temporary one
  temporary two
  permanent
  <gml:in left="3" unit="ch" delta="+3" temporary="yes" for="1" for-unit="line" after="1" after-unit="line" break="yes"/>old margin
  temporary
  back
  <gml:in left="0" unit="ch" break="yes"/><gml:il shift="3" unit="mh" break="yes"/>first line indented
  second line
  <gml:lines word="us" n="3" break="no">Do not
  destroy this letter
  until</gml:lines>
  its expiration date.
  <gml:lines word="ce" n="2" break="yes">before </gml:lines><hp><gml:lines word="ce" cont="yes">a phrase</gml:lines></hp><gml:lines word="ce" cont="yes"> after
  and a second line</gml:lines>
  outside
  <gml:in left="1" unit="i" temporary="yes" for="2" for-unit="i" break="yes"/>a distance in inches, measured by TeX
  not centered
  <gml:un shift="-2" unit="ch" break="yes"/>undented
  <gml:il shift="-1" unit="i" break="yes"/>moved left
  <gml:il shift="6" unit="mh" break="yes"/>moved right
  </gml:doc>
