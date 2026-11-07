.ct text (SH35-0069 p.48) continues the previous text without a word
space; its text is an input line, so a continuation character at its
end continues it in turn (IBM's DSMFDESC: ".ct :&$RB.&$RB.&$CONT").

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">First partand the restjoined to this line.
  Plain line.
  </gml:doc>

It continues the last word put out, across hints that do not break and
element ends (DCF has no tree; SH35-0069 p.107: "5", ".sb .15cm", ".ct
3"); a control word that breaks cancels it (p.47).

  $ gml across.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">5<gml:sb spec="0.15cm" break="no"/>3
  and <hp1><gml:bf font="hi1" break="no"/>bold</hp1><gml:pf initial="yes" break="no"/>ly continued.
  A line
  <gml:br break="yes"/>stays apart.
  </gml:doc>

A control word that does not break (here .se, reading &$PN) does not
stop the join either.

  $ printf '5\n.sb .15cm\n.se x = &$PN\n.ct 3\n' > sent.gml
  $ gml sent.gml | grep -o '>5<.*'
  >5<gml:sb spec="0.15cm" break="no"/>3
