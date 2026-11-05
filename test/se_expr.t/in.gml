.se a = 1 + 2 * 3
.se b = (1 + 2) * 3
.se c = 7 / 2
.se d = -7 / 2
.se e = 7 // 3
.se f = -(2 - 5)
.se g = 007
.se h = &a - 10
.se i=3*4
a=&a b=&b c=&c d=&d e=&e f=&f g=&g h=&h i=&i
.se s1 = 'quoted string'
.se s2 = abc def
.se s3 = 'it is' &a
.se s4 'no equals sign'
.se s5 plain words
.se s6 =
.se s7 = 2026-11-05
[&s1.] [&s2.] [&s3.] [&s4.] [&s5.] [&s6.] [&s7.]
.se a = &a + 1
Incremented: &a
.se t = 1 +
.se t = (1 + 2
.se t = 1 / 0
.se t = 1 2 + 3
.se t = * 3
.se
Unchanged: &t
