.dm
.dm (x) /a/
.dm x y
.dm x(1) z
.dm off
.dm x(-1) /a/
.ms on;.* diagnostics inside macros carry the macro chain
.dm bad on
.xx inside bad
.go nowhere
.dm off
.dm calls on
.bad
.dm off
.calls
.* runaway recursion
.dm rec /.rec/
.rec
