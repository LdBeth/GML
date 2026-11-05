.se cw '.ty'
&cw. a control word made by substitution
.se semi 'one;.ty two'
.ty [&semi.]
.'se semi 'one;.ty two'
.ty [&semi.]
.'se sp '.ty x;.ty y'
&sp
.se b 'B'
.ty first &b;.ty second &b
.se b 'changed';.ty after set: &b
.* comment &nosuch(&'bad(1)) not substituted
...label&'bad(1)
.cm also &nosuch substituted, then ignored
.se star '.*'
&star. a comment made by substitution is dropped
.if 1 eq 1 .ty if object;.ty separate line
.if 1 eq 2 .ty wrong;.ty not part of the .if object
.se x = 1
.se x = &x + 1;.se y = &x
.ty x=&x y=&y
