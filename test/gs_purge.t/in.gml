.gs tag on
.gs rules (noelem)
.dm a /[A APF: &*1.]
.dm b /[B APF: &*1.]
.dm c /[C APF: &*1.]
.* PURGE: the listed attributes, or all but those after NOT
.dm t1 /.gs purge a/.gs exatt
:t1 a=1 b=2 c=3.
.dm t2 /.gs purge not b/.gs exatt
:t2 a=1 b=2 c=3.
.* PURGEMSG names what it purges; alone: all of them
.dm t3 /.gs exatt a/.gs purgemsg/.gs exatt
:t3 a=1 b=2 c='x y'.
.* EXATT NOT: all but those listed
.dm t4 /.gs exatt not a b
:t4 a=1 b=2 c=3.
