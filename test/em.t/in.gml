.su off
.dm hello /Hello, &*1.!
.su on
.* .em executes a macro whatever .ms says (p.278); .ms is off initially
.em hello world
.em .hello there
.hello not run: .ms is off, so this is .he
.ms on
.hello on
.em nosuch
.em
.* .ec runs the control word, bypassing a macro of the same name
.su off
.dm ty /.ec .ty (macro ty) &*
.su on
.ty via the macro
.ec .ty via .ec
.'ty via the modifier
.ec ty no indicator needed
.ec .zz
