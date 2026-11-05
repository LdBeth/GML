.se i = 0
...loop
.se i = &i + 1
.if &i lt 4 .do begin
iteration &i
.go loop
.do end
done after &i
.go forward
wrong: jumped over
...FORWARD
forward label (case-insensitive)
.se k = 0
...again
.se k = &k + 1
.if &k eq 3 .go out
.go again;.ty wrong: rest of line after .go
...out
.ty k=&k
.go ...back
...back
dotted operand
.im part
.go top
