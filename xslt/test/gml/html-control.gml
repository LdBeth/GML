.* html/control: SCRIPT control words in a document of the semantic
.* profile (the rendering that is not the profile's: hanging indention
.* over breaks, a .is "to h" tab after a label, a run-in heading of a
.* level defined NBR, consecutive .sk skips, the .fn leader definition).
.fn leader
.sp 1
.fn off
:gdoc.
:body.
:h1 id=ctl.Control words
.in 4
.of 4
The first run of the hanging text, given on two input lines, so
that the indention is seen on its second output line.
.br
The second run, after a break, starts again at the hanging indention.
.in 0
.sk 1
.in 8
.of 8
GML
.is to 8 min 1 blank
Generalized Markup Language: the label before the tab is as wide as
the indention.
.br
Too-long-term
.is to 8 min 1 blank
A label wider than the indention is followed by one blank.
.sk 1
.in 0
.sk 2
.sk 1
:p.Of the three skips above (one line at the end of the indented
block, two lines and one line after it) only the two-line one is kept.
.sk 1
.sk 1
Two equal skips make one.
:h2.Headings
.dh 5 nbr
.h5 Run-in heading.
The text after a level five heading defined NBR continues on its line.
.dh 5
.h5 A heading again
After .dh 5 alone the level breaks again.
:egdoc.
