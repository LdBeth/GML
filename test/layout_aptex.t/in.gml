.* paragraphs that report where they start; a new page when fewer
.* than 8 lines are left
.rf on
.sp
.sx ///Page &/
.rf off
.ms on
.dm para on
.sp
.if &$LC lt 8 .pa
Paragraph &n starts on page &$PN with &$LC lines left.
.dm off
.se n = 0
...again
.se n = &n + 1
.para
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua.  Ut enim
ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat.  Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur.  Excepteur sint occaecat cupidatat non proident.
.if &n lt 12 .go again
