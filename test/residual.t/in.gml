.gs tag on
.dm h1 on
.gs copy r
[h1 residual=(&r)]
.dm off
.dm hp1 on
.gs copy r
[hp1 residual=(&r)]
.dm off
.dm ehp1 on
.gs copy r
[ehp1 residual=(&r)]
.dm off
.dm titlep /[titlep]
.dm title on
.gs copy r
[title residual=(&r)]
.dm off
.* residual text ends at the next tag or the end of the line
:h1.The :hp1.starter set::hp1. Profile
::h1.
.* markup ending a line: the residual text is the next line
:titlep
:title.
First Line
of the Title
::title.::titlep.
.* residual text is literal: a leading period or blank is not special
:hp1..sp 3::hp1.
:hp1.  indented::hp1.
