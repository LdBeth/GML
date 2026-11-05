.gs tag on
.dc gml : :e
.* the element opens before the APF runs: its output is inside
.dm ol /[start of list]
.dm eol /[end of list]
.dm li on
.dm off
.xd li closedby=li
.aa ol (vat)
:ol compact id=l1.
:li.one
:li.two
:eol.after the list
.* an end tag with no APF still closes its element
.dm q on
.dm off
:q.quoted:eq.
.* elements opened inside are closed by the end tag, with a warning
.* unless they are implicitly closable
.dm b on
.dm off
:q.a :b.bold:eq. text
.* an end tag whose element is not open
:eol.
.* tag names that are not XML names get no element
.* (.aa: .dm cannot define the macro @x yet)
.dm atx /[at-x APF]
.aa @x atx
:@x.text
