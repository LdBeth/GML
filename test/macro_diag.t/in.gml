.dm
.dm (x) /a/
.dm x
.dm x 1a1
.dm off
.me
.ms on;.* diagnostics inside macros carry the macro chain
.dm bad on
.xx inside bad
.go nowhere
.dm off
.dm calls on
.bad
.dm off
.calls
.* .do groups left open in a macro are discarded
.dm open on
.do begin
open group
.dm off
.open
.* a skipped group running to the end of the macro
.dm skipper on
.if 1 eq 2 .do begin
skipped
.dm off
.skipper
after skipper
.* a .dm on inside a skipped group: body skipped, .do lines in it ignored
.if 1 eq 2 .do begin
.dm ghost on
.do end
.do begin
.dm off
.do end
.ghost
.* runaway recursion
.dm rec /.rec/
.rec
