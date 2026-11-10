.h0-.h6 open a gml:h element closed at the end of the line, with the
level; a level with a table of contents entry (0-3, SH35-0069 Figure
14) marks it with gml:tcmark, and level 0 is an entry only (TO): no
heading in the text; .fn and .rh collect the text that follows into gml:fn and gml:rh;
the device-only words (.dd .it .dl ...) warn once each.

  $ gml in.gml
  in.gml:6: warning: ignored device control word .dd
  in.gml:7: warning: ignored device control word .it
  in.gml:8: warning: ignored device control word .dl
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:tcmark anchor="gml.tc.1" break="no"/><gml:h level="1" break="yes"><gml:tcmark anchor="gml.tc.2" break="no"/>Chapter one</gml:h>
  Body text
  <gml:h level="2" break="yes"><gml:tcmark anchor="gml.tc.3" break="no"/>Section</gml:h>
  <gml:h level="6" break="yes"/><gml:fn>A footnote
  </gml:fn><gml:rh break="yes">Running head
  </gml:rh><gml:cp n="2" unit="line" break="yes"/><gml:sx left="left" fill="." right="right" break="yes"/><gml:rc code="1" mode="on" break="no"/>revised
  <gml:rc code="1" mode="off" break="no"/><gml:lines word="rc" n="1" char="|" break="no">changed line</gml:lines>
  </gml:doc>
  [4]
