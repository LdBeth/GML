.se a = 1
.if &a eq 1 .do begin
group one line 1
group one line 2
.do end
.el .do begin
wrong: else group
.do end
.if &a eq 2 .do begin
wrong: false group
.if &a eq 1 .do begin
wrong: nested inside skipped group
.do end
.ty wrong: control word in skipped group
.se a = 99
.im nosuch
.sp;.do begin;.ty wrong: nested group opened after a separator
.do end
.do end
.el .do begin
else group runs, a=&a
.if 1 eq 2 .do begin
wrong
.do end
.el inner else after inner group
.do end;.ty after group (separator remainder after .do end)
.do begin
plain group
.do end
.if 1 eq 1
.th .do begin
th group
.if 5 eq 6
.do end
.el .do begin
wrong: .el refers to the outer .if restored at .do end
.do end
