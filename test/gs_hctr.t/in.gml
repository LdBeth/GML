.dh 1 num
.dh 2 num
.dh 3 num
.h1 First
.h2 Sub
.h2 Sub
.h3 Deep
.h1 Second
.gs hctr 4.7.7.4
Set: &@xref &xref (&xref(1) &xref(4))
.h4 Not numbered
.h3 Level three
.h3 Level three again
.gs hctr 4.7.7.4
.dh 4 num
.dh 5 num
.h5 Level five
.h4 Level four
.gs hctr 2
Step 2: &@xref
.* a zero position resets the later ones; 0 alone reinitialises
.gs hctr 3.0.5
Zero: &@xref
.gs hctr 0
Zero alone [&@xref.]
.h1 After zero
.gs hctr A.0
.gs hctr 1
Appendix &xref(1)
.gs hctr 1
Appendix &xref(1)
.dh 1 nonum
.h1 Unnumbered
.h2 In appendix
.gs hctr
Reset [&xref.]
.dh 1 num
.h1 Again
.gs hctr 1..2
