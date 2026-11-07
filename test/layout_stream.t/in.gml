.* queries (.se x = &$PN / &$LC) everywhere: inside open provisional
.* elements, line scopes, footnotes, between growing text lines, after
.* a .ct continuation, in format-off text
.gs tag on
.dc gml : : e
.dm p on
.se x = &$LC
.br
.dm off
.dm ref /[ref]/
.dm term on
.se x = &$PN
.br
.dm off
.dm dl /.sp
.dm edl /.sp
.aa p p
.aa ref ref
.aa term term
.aa dl dl edl
.se x = &$PN
:p.A paragraph with a :ref. in it
.se x = &$LC
and more text
.se x = &$LC
that grows
.se x = &$LC
.ct , continued.
.se x = &$LC
:p.Second paragraph.
:dl.
:term.One
.se x = &$PN
:term.Two
.se x = &$LC
:edl.
.ce 2
Centered one
Centered two
.se x = &$PN
.us on
under
.se x = &$PN
scored words
.us off
.se x = &$PN
.fn on
A footnote
.se x = &$PN
with two lines.
.fn off
.fo off
  preformatted   text
.se x = &$PN

  after a blank
.fo on
.se x = &$PN
Tab	separated	line
.se x = &$PN
.sp
.se x = &$PN
The end.
