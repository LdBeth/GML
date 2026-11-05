.gs tag on
.dc gml : :e
.gs rules (noatt)
.dm p on
.dm off
.dm ol on
.dm off
.dm li on
.dm off
.dm br on
.dm off
.dm hp1 on
.dm off
.* p is closed by p and by ol; li by li; the end of ol closes li
.xd p closedby=p,ol
.xd li closedby=li
.xd br empty
:p.First paragraph,:br.second line.
:p.Second paragraph.
:ol.
:li.one
:li.two:br.
:eol.
:p.Third paragraph, closed at end of input.
.* a non-closable element left open inside ol
:ol.
:li.item :hp1.highlighted
:eol.
