.* a null element 0 is index counter 0
.se t = ''
.se t() = one
.se t() = two
[&t(*)] counter &t
.* nulled by .gs vars (no argument for the second name)
.gs args only
.gs vars p q
.se q() = alpha
.se q() = beta
[&q(*)] counter &q(0)
.* setting an element of a nulled array sets the counter
.se m = ''
.se m(3) = c
.se m() = d
[&m(*)] counter &m
.* a value that is not a number is still an error
.se n = 'abc'
.se n() = x
[&n.]
