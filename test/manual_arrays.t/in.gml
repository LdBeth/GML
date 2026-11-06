.* p.255
.se place() = Goldsboro
.se place() = Kunsan
.se place() = Misawa
At: &place(*)
.se x = ' and '
.dc asep & x .
At: &place(*)
.'se x = ';.br;'
.dc asep & x .
At: &place(*)
.dc asep , 40
.* p.256
.se name(1) = 1
.se name(47) = 2
.se name(25) = 3
.se name(2) = 4
.se name(3) = 5
&name(*)
.se elem = 1
.se array(&elem) = &
&array(1) &array(2). &nosuch(1)
.* p.257
.se name2() = first
.se name2(3) = second
.se name2() = third
&name2(*) / [&name2(2).] / &name2(0) &name2
.se XYZ(0) = 4
.se XYZ() = fifth
&XYZ(5) &XYZ
