.se x(1) = 10
.se x(2) 'two'
.se x(3) = &x(1) * 3
.se i = 2
Elements: &x(1) &x(&i) &x(&i.). &x(3).
All: &x(*)
Index counter (element 0): &x &x(0)
.se x = plain
Plain: &x., element: &x(1)
Missing element is null: [&x(9).]
Text in parentheses: &i(s) and &i (s)
.se x(2) off
After delete: [&x(2).], all &x(*)
.se y() = first
.se y(3) = second
.se y() = third
Appended: &y(*); counter &y.; element 2 [&y(2).]
.dc asep 20 / 20
Separator: &y(*)
None: &nosuch(*) &nosuch(1)
.se z(abc) = 1
.se x() = 1
.se y off
Array gone: &y(*) &y(1)
