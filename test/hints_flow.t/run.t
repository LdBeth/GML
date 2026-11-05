.h0-.h6 open a gml:h element closed at the end of the line, with the
level; .fn and .rh collect the text that follows into gml:fn and gml:rh;
the device-only words (.dd .it .dl ...) warn once each.

  $ gml in.gml
  in.gml:6: warning: ignored device control word .dd
  in.gml:7: warning: ignored device control word .it
  in.gml:8: warning: ignored device control word .dl
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:h level="0" break="yes">Part one</gml:h>
  <gml:h level="1" break="yes">Chapter one</gml:h>
  Body text
  <gml:h level="2" break="yes">Section</gml:h>
  <gml:h level="6" break="yes"/><gml:fn>A footnote
  </gml:fn><gml:rh>Running head
  </gml:rh><gml:cp n="2" unit="line" break="yes"/><gml:sx left="left" fill="." right="right" break="yes"/><gml:rc code="1" mode="on" break="no"/>revised
  <gml:rc code="1" mode="off" break="no"/><gml:lines word="rc" n="1" char="|" break="no">changed line</gml:lines>
  </gml:doc>
  [4]
