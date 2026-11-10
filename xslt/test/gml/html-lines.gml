:gdoc.
:body.
:h1.Line-counted words
:p.start
.in 3 for 2
two lines
indented
back
.in 4 after 1
one line
then indented
.il 2
indented line
.un 2
undented line
.uc
underscore caps
.rc 1 |
.rc * |
revised
.sx /left/./right/
.hr
.sk 2
.kp on
kept
.kp off
.in 0
.ce on
first centred
second centred
.ce off
:p.A distance is a float before the next text: each paragraph below is
one block.
.in +4 for 2 after 2
:p.A paragraph of
three input lines
in one block.
:p.
.il 3
An indented first line
and a second one.
:p.A length:
.in 1i for 0.5i
half an inch at one inch.
.ir 6 for 3
:p.Three lines with a right indention.
.il 5
:p.An .il before a paragraph tag: its skip uses it up.
:p.
.un 2
A first line moved left
of the margin.
.in 2 for 1
.in 5 for 2
:p.Only the second of two FOR before the text counts.
.in 3
:p.A permanent change.
.in 2 for 2
:p.Back to the permanent one plus two.
.in 0
.il 2
.br
:p.A skip between.
:egdoc.
