.se i = 0
...loop
.se i = &i + 1
.if &i ge 4 .go done
iteration &i
.go loop
...done
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
.go to there
wrong: .go to
...there text after the label (&k)
.goto here
wrong: .goto
...here   .ty label then a control word, k=&k
.im part
.go top
