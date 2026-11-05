.gs tag on
.gs rules (noelem)
.* value attributes are the APF's &*1..., as written, the count in &*0
.dm sl on
.if /&U'&*1 eq /COMPACT .th [compact list, &*0 value attribute(s): &*.]
.el [normal list]
.dm off
.aa sl (vat noelem)
:sl Compact.
:sl.
.* an APF can build elements itself
.dm note on
.xs note type=&*1
.xs label
NOTE:
.xe label
.dm off
.aa note (vat noelem)
.dm enote /.xe note
:note warning.Do not touch.
::note.
.* tag APFs are macros: they can call other tags
.dm warn /:note warning.
:warn.Hot surface.
::note.
