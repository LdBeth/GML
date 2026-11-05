.* p.230
.se number = 25
.se add = 1
.se text1 = 'IBM 1403 Printer'
.se TEXT1 = 'IBM 1403 printer'
.se type 'prepared on a "word processing" machine
.ty &type
.se type = 'prepared on a "word processing" machine
.ty &type
.se break = '.br'
.se printer = '&text1'
.ty &number &add / &text1 / &TEXT1 / &break / &printer
.se incr = &add + 1
.se next = &number + 1
.se prev = &number - 1
.se half = &number / 2
.* p.231
.se mult = &add * 10
.se cost = &number * 20
.se negvalue = -&number
.ty &incr &next &prev &half &mult &cost &negvalue
.su off
.se corp = 'Scriptographicology, Inc.'
.se name = substr &corp 1 6
.su on
.ty &name
.se name = substr Jonathan 5 4
.ty &name
.* p.232
.se name = 'Nicola'
.se location = index &name cola
.ty &location
.se x = index '_1_2_' '_&SYSVARC._'
.ty x=&x
.if &x eq 0 .ty SYSVAR C invalid.
.se cols = substr '1_2' &x 1
.ty cols=&cols
.* p.235
.se oldsymbol = 1
.se oldsymbol off
.ty &oldsymbol
.se oldsymbol =
.ty [&oldsymbol.]
.* p.241
.se SYSDAYOFM = 08
.se SYSDAYOFM = &SYSDAYOFM + 0
.ty &SYSDAYOFM
.* SH35-0050 p.14, Figure 3
.se *a = index '-NO-YES-DUPLEX-SIMPLEX-' '-&U'&SYSVARD.'
.if &*a eq 0 .se *a 1
.se SYSVARD = substr 'no yes yes    no' &*a 3
.ty SYSVARD=&SYSVARD
