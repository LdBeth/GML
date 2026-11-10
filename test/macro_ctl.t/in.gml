.ms on
.* .me leaves the macro, its operand runs in the caller
.dm early on
before me
.if &*1 eq stop .me after me &*1
not reached when stopped
.dm off
.early go
.early stop
.* .go loop inside a macro
.dm count on
.se i = 0
...top
.se i = &i + 1
count &i
.if &i lt &*1 .go top
.dm off
.count 3
.* .if/.th/.el inside a macro, and the long forms .then .else
.dm cond on
.if &*1 = 1
.th one
.then (then)
.el not one
.else (else)
.dm off
.cond 1
.cond 2
.* recursion with a counter
.dm down on
.if &*1 le 0 .me bottom
down &*1
.se n = &*1 - 1
.down &n
up &*1
.dm off
.down 3
.* .ef inside a macro ends the calling file
.im sub
back in main
.me outside a macro the line is processed
