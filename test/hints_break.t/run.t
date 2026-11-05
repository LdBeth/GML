Every hint says whether its control word causes a break.  .us and .up do
not (p.43), .in and .ir do unless NOBREAK (p.78, p.81), an inline keep
(.kp v) does not (p.198), the font, hyphenation and tab words do not.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Some text
  <gml:br break="yes"/><gml:sp n="1" unit="line" break="yes"/><gml:sk n="2" unit="line" absolute="yes" break="yes"/><gml:lines word="us" n="1" break="no">not a break</gml:lines>
  <gml:lines word="up" n="1" break="no">not a break</gml:lines>
  <gml:bf font="hi1" break="no"/><gml:pf initial="yes" break="no"/><gml:in left="2" unit="ch" break="no"/><gml:ir right="3" unit="ch" break="yes"/><gml:kp mode="inline" depth="5line" break="no"/><gml:kp mode="on" break="yes"/><gml:kp mode="off" break="yes"/><gml:pa break="yes"/><gml:pa nobreak="yes" break="no"/><gml:cp n="3" unit="line" break="yes"/><gml:hy mode="on" options="minword 7" break="no"/><gml:hw word="un-cer-e-mo-ni-ous-ly" break="no"/><gml:tp action="set" stops="8mh 18mh 30mh" break="no"/><gml:bx action="on" spec="1ch 30ch" break="yes"/><gml:bx action="off" break="yes"/><gml:fo fill="yes" align="left" overdraw="extend" break="yes"/><gml:pf initial="yes" break="no"/></gml:doc>
