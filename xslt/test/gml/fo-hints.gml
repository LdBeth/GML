:gdoc.
:body.
:h1.Control words
:p.Before a space
.sp 2
after two lines.
.sk 1
After a skip.
.br
After a break,
.sp 1i
an inch,
.sp p12
and twelve points.
.pa
New page.
.pa odd
Odd page.
.cp 5
Conditional page.
.cc 3
Conditional column.
.kp on
:p.Kept together.
:p.Both paragraphs.
.kp off
.bx on 1 40
:p.Boxed text.
.bx off
.ce 2
Centered one
centered two
not centered.
.ri
Right aligned.
.us on
Underscored
.us off
.up
Uppercase line.
.in 4
.in +1i
.ir 2
:p.Indented both sides.
.of 3
:p.An offset paragraph, the first line at the indent, the rest offset by three.
.in 0
.ir 0
.ll 4i
:p.A shorter line length.
.ll
.fo off
:p.No fill
  keeps lines
.fo on
.fo center
:p.Centered by format mode.
.fo on
.ls by 2
:p.Double spaced.
.ls
.hy on
:p.Hyphenated.
.hy off
.df big type(14 bold)
.bf big
:p.Big bold font.
.pf
.bf hi1
:p.Highlight one.
.pf
.sb 2pt
Raised
.sb
.ws by 1.5
Wide words.
.ws
.wz 3
:p.Widow zone.
.wz
.h3 A control-word heading
:p.Text.
.fn on
A control-word footnote.
.fn off
.rh on
Running heading text
.rh off
.rf on
Running footing text
.rf off
.xr fo |<fo:inline xmlns:fo="http://www.w3.org/1999/XSL/Format" font-weight="bold">raw FO</fo:inline>|
.xr fo |<broken|
.xr html |<b>html only</b>|
.hr
:p.After a rule.
.rc 1 on
:p.Revised text.
.rc 1 off
.tp 5 10
Tabs ignored.
.tp
:egdoc.
