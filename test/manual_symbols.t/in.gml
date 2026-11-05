.* p.229
.se printer = 'IBM 1403 Printer'
Our publisher uses the &printer for output.
Our publisher uses the &printer..
.* p.232
.se item1 = 'apple'
This list ends with an &item1..
.se prodname = Whizbanger
.se shipmo = June
.se shipday = 13th
.se shipyr = 86
The name of our product is &prodname., which is scheduled
for shipment on &shipmo &shipday., 19&shipyr..
Without the period, &prodname, is a character string.
.* p.233
.se x = 1
.se type1 = first
.se type2 = second
This is the &type&x try.
.* p.234
I have defined the symbols &AAA, &BBB, &CCC, and others
.* p.236
.se test = on
The result is &E'&test..
&E'czechoslovakia
.se test = 'This is a test.'
.se length = &L'&test
&length
.se test off
.se length = &L'&test
&length
.* p.237
.se a = '&b.linda'
.se b = 'Be'
&a &L'&a &V'&a &L'&V'&a
.se a = '&c.linda'
&V'&a / &V'&c.linda / [&V'&V'&a.]
.* p.238
.se a = '&J'
.se b = 'K'
.se JK = 'TIMOTHY'
&a.&b / &L'&a.&b / &L'&a&b
.* p.256
.se x = ry
.se ry = 4
&&x
.* p.269
.se 5z =
.se 4z = 0
.se 3z = 00
.se 2z = 000
.se 1z = 0000
.se num = 123
&&L'&num.z.&num
.se num = 7
&&L'&num.z.&num
