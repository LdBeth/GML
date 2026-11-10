.go nowhere
.an 1 eq 1 wrong: .an without .if
.el wrong: .el without a comparison
.th target of .th without a comparison (processed)
.if 1 frob 2 x
.if
.se x = 1 +
.se x(1 = 2
.se a = &a&a&a&a&a&a&a&a
Runaway: &a
.su off
.se p '&q'
.se q '&p'
.su on
Cycle: &p
