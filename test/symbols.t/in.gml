.se num = 5
.se name 'John Smith'
.se B 'double "quotes" kept
Value &num., name &name., case &B &b.
Period: &num.. and &num.x &numx
Not references (p.232): &num, &name; &num: stay.
Undefined &nosuch and &nosuch. stay.
Ampersands: & alone, &= and &&num.
.se c '&num + &num'
Rescan: &c
.se ptr 'num'
Compound: &&ptr..
.se i = 2
.se x2 'second'
Inside-out: &x&i.
.se *loc 'local'
Local outside a macro: &*loc &*undef
.se verylongsymbolname 'long'
Long: &verylongsymbolname
.se num off
Deleted: &num
.ty &name / &B
Command line: &cl / &CL2 / &cl2
.se $mine = 'dollar'
Dollar names are case-insensitive (p.241): &$MINE &$mine &$Mine
