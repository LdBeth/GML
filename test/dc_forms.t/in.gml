.dm ol on
.dm off
.dm eol on
.dm off
.dm li on
.dm off
.dm p on
.dm off
.* two blank-separated end-tag operands: tag char, then second char
.dc gml : : e
[&$GML.] [&$EGML.]
.gs tag on
:ol.:li.alpha
:eol.
.gs tag off
.* two-character end-tag as one operand
.dc gml ! !x
[&$GML.] [&$EGML.]
.* single-character end-tag
.dc gml ! %
[&$GML.] [&$EGML.]
.gs tag on
!ol.!li.beta
%ol.
.gs tag off
.* tag delimiter only: end-tag is it doubled
.dc gml +
[&$GML.] [&$EGML.]
.* bare option given last: back to the default
.dc gml
[&$GML.] [&$EGML.]
.dc gml : : e mcs >
[&$GML.] [&$EGML.]
.gs tag on
:p>gamma
.gs tag off
.dc mcs
.* a lone tag delimiter is not an end-tag delimiter
.dc gml : :
.dc cw #
.dc cw
.se v = 1;.se w = 2
v=&v w=&w
.dc cont +
cont [&$CONT.]
.dc cont
cont [&$CONT.]
.se a(1) = x
.se a(2) = y
.dc asep /
&a(*)
.dc asep
&a(*)
