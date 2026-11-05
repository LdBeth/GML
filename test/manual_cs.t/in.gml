.* p.268, verbatim
.cs 1 ignore
.cs 2 ignore
.cs 3 include
This book is written specifically
for the operator of a
.cs 1 on
Class A
.cs 1 off
.cs 2 on
Class B
.cs 2 off
.cs 3 on
Class C
.cs 3 off
Widget.
.* p.268: an ignored section is not a total bypass, macros are resolved
.ms on
.dm note /.ty note: &*
.cs 2 on
.note seen although section 2 is ignored
.ty not seen
dropped text
.cs 2 off
.* the default is to process a section not specifically bypassed
.cs 5 on
Section 5 text.
.cs 5 off
