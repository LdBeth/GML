.ms on
.* .ly is off initially: no library search
.hello
&SYMONLY
.dm hello lib
.hello one
.* the definition is in storage now; .dm name lib replaces it
.dm hello /stored hello
.hello
.dm hello lib
.hello two
.* .se name lib: the first line, the name translated to upper case
.se libsym lib
.se LIBSYM lib
&libsym./&LIBSYM.
.se MAC@ID lib
.if /&MAC@ID eq /DSMGML3 .th library id ok
.* .ly mac: unresolved macros (and APFs); not symbols
.ly mac
.other x y
&SYMONLY
.d#s@$
.dsfoo
.* a long name is never searched; a control word name neither
.qlongname
.* run-once members: .dm name off deletes the macro, so the next call
.* fetches it from the library again; a comment redefinition stays
.once
.once
.cmt
.cmt
.* GML APFs: an .aa APF, a direct APF and a direct end-tag APF (etagy)
.gs tag on
.aa tagx apfx
:tagx.text after tagx
::tagx.
:tagy.text after tagy
::tagy.
.* .ly sym: symbols, not macros
.ly sym
&SYMONLY / &NOSUCH / &NOSUCH
.dm other off
.other
.* .ly on: both; .ly off: neither
.ly on
.other z
.ly off
.dm other off
.other
.* errors
.dm nosuch lib
.se nosuch lib
