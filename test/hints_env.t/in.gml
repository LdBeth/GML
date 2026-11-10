.in 2
.bf body
.tr x X
Main text x.
.sa
.in +3
.ll 5i
.fo off
.hy on
.bf hi1
.bf hi2
.tr
Saved x.
.re
Restored x.
.sa outer
.of 4
.sa
.ir 1
.sa inner
.ir 2
.re outer
After outer.
.re inner
After inner.
.re
After unnamed.
.re
Initial values.
.re nosuch
.in 6
.of 1
.fn on
Footnote.
.in 9
.fn off
.in +1
.fv justify
.dc ps #
.ce on
.sa
.dc ps %
.ce off
Page symbol &$PS. not centred.
.re
Page symbol &$PS. centred again.
.ce off
