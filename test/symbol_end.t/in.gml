.gs tag on
.dc gml : : e
.se t = TEXT
.se fhAB = 1
.ms on
.dm show on
.se *k = AB
[&E'&fh&*k..] [&E'&fh&*k.] [&fh&*k..]
.dm off
.show
&t;.br
&t.;.br
after
.dm tg on
.se d = start
.if &$TAGD eq &$EGML .se d = end
.if &L'&$TAGD eq 2 .se d = '&d (2 characters)'
[&$TAG &d ]
.dm off
.aa fig tg tg
:fig.
:efig.
