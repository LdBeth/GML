.se a = 1 + 2 * 4 + 6
.se b = 2 * 3 + 1
.se c = 7 / 2
.se d = -7 / 2
.se e = 7 - 10 / 3
.se f = 5-3*2
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
.se s8 = abcdefghijklmnop
.se s9 = substr 'whole string'
.se s10 = index 'no needle'
.se s11 = index Mrs. O'Grady's Cat Cat
[&s1.] [&s2.] [&s3.] [&s4.] [&s5.] [&s6.] [&s7.] [&s8.] [&s9.] [&s10.] [&s11.]
.se a = &a + 1
Incremented: &a
.se t = 1 +
.se t = 5+-3
.se t = 7 // 3
.se t = (1 + 2) * 3
.se t = 1 / 0
.se t = 1 2 + 3
.se t = * 3
.se t = abcdefghijklmnopq
.se t = index 123456789123456789 1
.se
Unchanged: &t
.se title 'Mrs. O'Grady's Cat'
.se t2 'trailing blanks kept  '
.se t3 = 'Mrs. O''Grady''s Cat'
[&title.] [&t2.] [&t3.]
.se oq '"''"''"''
[&oq.]
