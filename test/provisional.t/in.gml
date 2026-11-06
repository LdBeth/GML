.gs tag on
.dc gml : : e
.dm ref /[ref]/
.dm p /.br
.dm term /.br
.dm dl /.sp
.dm edl /.sp
.dm wrap /.*
.aa ref ref
.aa p p
.aa term term
.aa dl dl edl
.aa wrap wrap
:p.A paragraph with a :ref. in it.
:p.Second paragraph.
:dl.
:term.One
:term.Two
:edl.
:wrap.wrapped text:ewrap.
After.
.dm note /.fn on
.dm enote /.fn off
.aa note note enote
:note.A note in a footnote flow:enote.
Done.
