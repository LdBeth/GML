.ms on
.* in a file: the base locals; then .gs vars copies them by position
.gs args 10 2 .75 -1 a-b
(&*0) (&*) (&*1) (&*4) (&*5)
.gs vars in@d in@f sk@d neg dash
&in@d &in@f &sk@d &neg &dash
.* quoted values, null values, doubled quotes; a name beyond the values
.gs args '.rc adjust' '' '"' ''''
.gs vars rc1 rc2 oqq oq extra
<&rc1.> <&rc2.> <&oqq.> <&oq.> <&extra.>
.* .gs args alone: &*0 is 0, &* and the old &*1 ... null (LR p.187)
.gs args
(&*0) (&*1)
.* in a macro: replaces the arguments; &* appends
.dm months on
(&*0) &*1
.gs args January February
.gs args &* March
(&*0) &*1 &*3 (&*)
.gs vars *m1 *m2 *m3
&*m1 &*m3 (&*4)
.dm off
.months x y z
.* packed state: an array element holding a whole list
.se st(1) = 'o 3 4ch'
.gs args &st(1)
.gs vars ltype item# in
&ltype &item# &in
.* no array symbols
.gs vars x(1)
