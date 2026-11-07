.* layout.gml - layout mode: TeX lays out the pages while SCRIPT runs,
.* and &$PN (the page number) and &$LC (the lines left on the page)
.* come from it.  Plain control words only, no profile:
.*
.*   gml -layout aptex examples/layout.gml          (layout.dvi)
.*   gml -layout 'aptex --output-format=pdf' -tex layout.tex examples/layout.gml
.*
.* -tex keeps the TeX source as it was sent, with a comment line
.* "%gml:query pn=N" after each answer.
.*
.* The running footing has the page number symbol (&$PS., "&"), which
.* is replaced by the page number of each page (SH35-0069 p.128).
.rf on
.sp
.sx /Layout mode demo//Page &/
.rf off
.ms on
.* A paragraph: a new page when fewer than 8 lines are left, then the
.* page state where it starts.  The .sp comes first: it ends the
.* paragraph before, so TeX counts it in &$LC (in the middle of a
.* paragraph the lines of that paragraph are not counted yet).
.dm para on
.sp
.if &$LC lt 8 .pa
.se where = &
This paragraph starts on page &$PN with &$LC lines left (and .se where
= & gave &where).
.dm off
.*
.ce on
Layout mode
.ce off
.sp 2
.se n = 0
...again
.se n = &n + 1
.para
Paragraph &n..
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua.  Ut enim
ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat.  Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur.
.if &n lt 24 .go again
.sp
.in 4
The last paragraph, indented, starts on page &$PN with &$LC lines left.
