A permanent .in ends the offset: "the offset remains in effect until
changed by another offset or indent control word" (SH35-0069 Figure 6,
p.80).  The .in hint then carries offset="0", and a later relative .of
starts from 0.  A temporary .in (FOR) and .ir keep the offset
(DCF-VERIFY): no offset attribute on them.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">a
  <gml:of offset="3" unit="ch" break="yes"/>b
  <gml:in left="0" unit="ch" offset="0" break="yes"/>c
  <gml:of offset="2" unit="ch" delta="+2" break="yes"/>d
  <gml:lines word="in" n="1" left="4" unit="ch" break="yes">e</gml:lines>
  <gml:ir right="2" unit="ch" break="yes"/>f
  <gml:in left="1" unit="ch" offset="0" break="yes"/>g
  </gml:doc>
