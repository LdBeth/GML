Every hint says whether its control word causes a break (LR Table 13,
p.441, and the Notes of each entry).  .us and .up do not (p.420,
p.418), .in and .ir do unless NOBREAK (p.210, p.217), an inline keep
(.kp v) does not (p.228), the font, hyphenation and word spacing words
do not.  The tab words (.tb p.374, .tp p.401), .vr (p.423), .wz
(p.434), .pm (p.284) and .rh/.rf (p.314, p.310) do; .ls does unless
NOBREAK (p.237).  .pa always breaks: it has no NOBREAK operand (p.276),
so ".pa nobreak" is an error and ignored.  .tp alone clears the tab
table (p.400); .tb alone restores the initial tabs.

  $ gml in.gml
  in.gml:16: error: .pa: NOBREAK is not an operand of .pa; ignored
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Some text
  <gml:br break="yes"/><gml:sp n="1" unit="line" break="yes"/><gml:sk n="2" unit="line" absolute="yes" break="yes"/><gml:lines word="us" n="1" break="no">not a break</gml:lines>
  <gml:lines word="up" n="1" break="no">not a break</gml:lines>
  <gml:bf font="hi1" break="no"/><gml:pf initial="yes" break="no"/><gml:in left="2" unit="ch" break="no"/><gml:ir right="3" unit="ch" break="yes"/><gml:kp mode="inline" depth="5line" break="no"/><gml:kp mode="on" break="yes"/><gml:kp mode="off" break="yes"/><gml:pa break="yes"/><gml:cp n="3" unit="line" break="yes"/><gml:hy mode="on" options="minword 7" break="no"/><gml:hw word="un-cer-e-mo-ni-ous-ly" break="no"/><gml:tp action="set" stops="8mh 18mh 30mh" break="yes"/><gml:tb action="del" stops="5ch" break="yes"/><gml:bx action="on" spec="1ch 30ch" break="yes"/><gml:bx action="off" break="yes"/><gml:fo fill="yes" align="left" overdraw="extend" break="yes"/><gml:pf initial="yes" break="no"/><gml:vr spec="thin 5ch" break="yes"/><gml:ls spec="by 2" break="yes"/><gml:ls spec="by 1 nobreak" break="no"/><gml:wz spec="3" break="yes"/><gml:pm spec="1i" break="yes"/><gml:rh action="sup" page="odd" break="yes"/><gml:ws spec="by 2" break="no"/><gml:tp action="set" stops="" break="yes"/><gml:tb action="reset" break="yes"/></gml:doc>
  [8]
