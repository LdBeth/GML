.* a query inside a .ce scope that an element splits later: the scope
.* goes to TeX before its continuation is known
.gs tag on
.dm hp1 /.*
.dm ehp1 /.*
.aa hp1 hp1 ehp1
.ce 2
Centered one
.se x = &$LC
before :hp1.a phrase::hp1. after
