.ms on;.* a macro named like a native word wins (p.275, p.277)
.dm se on
macro se called with [&*.]
.dm off
.se x = 5
.* .' runs the native word
.'se x = 6
x=&x
.* .ms off: native words again
.ms off
.se x = 7
x=&x
.ms on
.se x = 8
x=&x
.* a macro shadowing .cm: its operands are substituted
.dm cm on
comment macro [&*.]
.dm off
.cm hello &x
.dm cm off
.cm gone
.* .ms off and an undefined native name
.dm zz /zz macro/
.ms off
.zz
.ms on
.zz
.* the longest name is the macro; else two characters are the control word
.dm cecenter /macro cecenter
.cecenter this line
.cecentre this line
.'cecenter the modifier: no macro search
