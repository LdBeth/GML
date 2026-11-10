.ce 2
After this control word is processed,
the next two lines are centered.
However, this one is not.
.ce Chapter 1
.ri on
These lines must
be flush right.
.ri off
.in 5 after 1
Subsequent text will be indented,
except for the first line.
.in 0
.in +2 for 2
temporary one
temporary two
permanent
.in +3 for 1 after 1
old margin
temporary
back
.in 0
.il 3m
first line indented
second line
.us 3
Do not
destroy this letter
until
its expiration date.
.gs tag on
.dc gml : :e
.dm hp /.*
.aa hp hp
.ce 2
before :hp.a phrase:ehp. after
and a second line
outside
.in 1i for 2i
a distance in inches, measured by TeX
.ce 3
.ce off
not centered
.un 2
undented
.il -1i
moved left
.il +6m
moved right
