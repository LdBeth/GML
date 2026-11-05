.ms on
.* delimited form, trailing delimiter optional, any delimiter
.dm two /first line/second line/
.dm abc3 ,a,b,c
.* the single-line form is substituted when .su is on (p.274)
.su off
.'dm semi /.se x = 1;.se y = 2/x=&x y=&y/
.su on
.se v = now
.dm early /v was &v at definition
.two
.abc3
.semi
.early
.* the on/off form: body captured raw, ended by .dm off (p.272)
.dm block on
.se z = 7
block z=&z.; no split here
.* a comment in the body
 .dm off is a body line: not in column 1
.'dm off
.dm off
.block
.* redefinition replaces
.dm two /redefined/
.two
.* an inline .dm inside an inline definition ends it (p.280)
.dm outer on
outer runs
.dm inner on
inner body &*1
.dm off
.outer
.inner x
.* other .dm forms inside an inline body are body lines; a macro can
.* define another one (p.280) and delete itself (SH35-0050 p.15)
.dm maker on
.dm made /made, defined with &*1
.dm maker off
.dm off
.maker A
.made
.maker
.* deletion
.dm two off
.two
.dm abc3 delete
.abc3
.* name directly followed by delimiter, empty pieces
.dm tight/a//b/
.tight
