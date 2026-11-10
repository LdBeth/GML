Any .in clears all offsets, a temporary one (FOR) too: "any .IN
request clears all offsets" (LR p.260), and ".in" alone cancels .in
and .of (p.211).  The .in hint (or the first piece of its line scope)
then carries offset="0", and a later relative .of starts from 0.  .ir
keeps the offset.  Without FOR the number after h is v1 (".in 6 1" is
FOR 1, p.212 r6); v1 0 is a temporary indention until another .in:
the hint says the margin, and a relative .in still starts from the
permanent indention (after ".in 1", ".in +1 0" gives 2 and ".in +2"
then 3); FOR with no value is permanent (p.212: ".in .7i for after 1").

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">a
  <gml:of offset="3" unit="ch" break="yes"/>b
  <gml:in left="0" unit="ch" offset="0" break="yes"/>c
  <gml:of offset="2" unit="ch" delta="+2" break="yes"/>d
  <gml:lines word="in" n="1" left="4" unit="ch" offset="0" break="yes">e</gml:lines>
  <gml:of offset="2" unit="ch" break="yes"/><gml:ir right="2" unit="ch" break="yes"/>f
  <gml:in left="1" unit="ch" offset="0" break="yes"/>g
  <gml:of offset="5" unit="ch" break="yes"/><gml:lines word="in" n="1" left="7" unit="ch" offset="0" break="yes">h</gml:lines>
  <gml:in left="2" unit="ch" delta="+1" break="yes"/>i
  <gml:in left="3" unit="ch" delta="+2" break="yes"/>j
  <gml:in left="0.7" unit="i" break="yes"/><gml:lines word="in" n="1" after="yes" left="3" unit="ch" break="no">k</gml:lines>
  <gml:of offset="1" unit="ch" break="yes"/><gml:in left="0" unit="ch" offset="0" break="yes"/>l
  </gml:doc>
