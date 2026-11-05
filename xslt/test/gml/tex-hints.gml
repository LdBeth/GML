:gdoc.
.rh on
.ce Hint test running head
.rh off
:body.
:h1.Formatting hints
:p.Normal filled text that goes on for a while so that it wraps at least
once in the justified paragraph mode of the formatter.
.in 4
Indented by four characters, still in the same paragraph? No: .in breaks.
.in +1i
A mixed indent of four characters plus one inch.
.in 0
.ir 10m
Right margin pulled in by ten ems so that this text wraps earlier than the
others do on the page.
.ir 0
.sp 2
After two blank lines.
.sk 1
.sk 2
After skips of one and two lines: only the larger counts.
.ce 2
These two lines
are centered.
.ri on
Flush right one
flush right two
.ri off
.fo off
No fill: this line
and this line
  are kept as lines.
.fo on
.fo center
Centered fill mode text.
.fo on
.us 2
Underscored words here
and here
.up Upper case line with café
Back to normal.
.in 5 after 1
First line at the old margin, then the following lines are indented by
five characters until the margin changes again, which is right now.
.in 0
.il 3m
An indented first line in a paragraph that is long enough to wrap onto a
second line so the effect can be seen.
.of 4
Offset: the first line is at the margin and every following line is
indented by four characters, for this paragraph and the next.
.br
Next paragraph still offset by the .of control word, all of its lines.
.in 0
.bf hi2
Bold from a font change,
:hp1.italic inside it:ehp1.,
.pf
and back to the initial font.
.df big type(bold italic)
.bf big
Defined bold italic font.
.pf
.tp 10m 20m 30m
.fo off
Name&$TAB.Value&$TAB.Note
Apple&$TAB.12&$TAB.red
.tp ./25m
Leader&$TAB.dots
.tp
.fo on
.sx /Left side/./Right side/
.hr
.bx 1 40
Text inside a box.
.bx off
.hy on
.hw ex-cep-tion-al
Hyphenation is now on for exceptional words.
.hy off
.cp 5
.kp on
Kept text one.
Kept text two.
.kp off
.ls by 1.5
Wider line spacing for a while so that a couple of lines of text show
the change in spacing between the lines of one paragraph.
.br
.ls normal
.ws by 2
Wide word spaces.
.ws normal
.rc 1 *
.br
.rc 1 on
Revised text marked in the margin.
.br
.rc 1 off
.ll 4i
A shorter line length of four inches for this paragraph which is long
enough to wrap at that length.
.ll
.fn on
An unnumbered footnote from .fn on.
.fn off
.dh 2 font bold
.vr
.pa
.pn roman
After a page eject, roman page numbers.
.h2 A control word heading
Text after .h2.
.pa odd
On an odd page.
:egdoc.
