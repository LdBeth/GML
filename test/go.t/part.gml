.se p = 0
...top
.se p = &p + 1
.if &p eq 1 .go end
in part: second pass only, p=&p
...end
part done p=&p
.if &p lt 2 .go top
