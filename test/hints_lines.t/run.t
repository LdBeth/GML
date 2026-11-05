Line-counted words mark the input lines they cover with a gml:lines
scope (.ce n, .ce text, .ri on/off, .in x after n, .in x for n, .il,
.us n).  The scope carries the state inside it; an element opened inside
a scope splits it (cont="yes").  A FOR/AFTER amount that is not in lines
is left on the hint.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:lines word="ce" n="2" break="yes">After this control word is processed,
  the next two lines are centered.</gml:lines>
  However, this one is not.
  <gml:lines word="ce" n="1" break="yes">Chapter 1</gml:lines>
  <gml:lines word="ri" n="on" break="yes">These lines must
  be flush right.
  </gml:lines><gml:in left="5" unit="ch" break="yes"/><gml:lines word="in" n="1" after="yes" left="0" unit="ch" break="no">Subsequent text will be indented,</gml:lines>
  except for the first line.
  <gml:in left="0" unit="ch" break="yes"/><gml:lines word="in" n="2" left="2" unit="ch" delta="+2" break="yes">temporary one
  temporary two</gml:lines>
  permanent
  <gml:lines word="in" n="1" after="yes" left="0" unit="ch" break="yes">old margin</gml:lines>
  <gml:lines word="in" n="1" left="3" unit="ch" delta="+3" break="no">temporary</gml:lines>
  back
  <gml:in left="0" unit="ch" break="yes"/><gml:lines word="il" n="1" left="3" unit="mh" break="yes">first line indented</gml:lines>
  second line
  <gml:lines word="us" n="3" break="no">Do not
  destroy this letter
  until</gml:lines>
  its expiration date.
  <gml:lines word="ce" n="2" break="yes">before </gml:lines><hp><gml:lines word="ce" cont="yes">a phrase</gml:lines></hp><gml:lines word="ce" cont="yes"> after
  and a second line</gml:lines>
  outside
  <gml:in left="1" unit="i" for="2" for-unit="i" temporary="yes" break="yes"/>not counted: the amount is not in lines
  not centered
  </gml:doc>
