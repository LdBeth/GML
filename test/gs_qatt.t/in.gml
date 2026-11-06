.dm fn on
.gs qatt *q id refid
.if &E'&*q eq 0 .go all
Missing &*q.: &*q(*).
.me
...all
All present.
.dm off
.ms on
.gs tag on
.aa fn fn (att noelem)
:fn id=a.
:fn refid=b.
:fn.
:fn id=c refid=d.
