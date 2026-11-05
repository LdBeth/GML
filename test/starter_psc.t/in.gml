.dm mytag on
.se seen = 'yes'
.xs mark n=1
.xe mark
.dm off
.aa mytag mytag (noelem)
.se seen = 'no'
:gdoc.:body.
:p.before
:psc proc=tex.
:p.only for tex
:mytag.
:ol.:li.item
:eol.
.sp 2
:epsc.
:p.after; seen=&seen.
:egdoc.
