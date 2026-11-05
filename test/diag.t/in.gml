.go nowhere
.do end
.do sideways
.th no if yet
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
.ty unknown: &'bogus(1)
.do begin
.if 1 eq 2 .do begin
never closed
