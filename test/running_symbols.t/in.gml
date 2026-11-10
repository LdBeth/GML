.se sec = One
.se n = 2
.se lab = A
.ms on
.dm arg on
local &*1
.dm off
.tr a A
.rf on
.tr e E
Section &sec. of &undef. ok
.ce &sec
.ce &n
part&lab &n&lab.
&L'&sec chars
.arg &sec
.sx /&sec.//Page &/
.if &sec eq One .sp 1
.se copy = &sec
.rf off
Body: &sec. &copy. abc.
.se sec = Two
.se lab = B
.se copy = Three
.se n = 3
.se undef = Now
.se sec off
