.se n = 10
.se s 'abc'
.if &n eq 10 numeric eq: yes
.if &n = 10.0 wrong: 10.0 is not a number
.if &n gt 9 gt: yes
.if &n lt 9 lt: wrong
.if 010 eq 10 leading zero numeric: yes
.if '010' eq '10' quoted is character: wrong
.if &s ne abd ne: yes
.if &s < abd string lt: yes
.if &s ^= abc wrong
.if &s /= xyz slash-ne: yes
.if &s <> xyz diamond-ne: yes
.if &n <= 10 le: yes
.if &n >= 11 wrong
.if 9 lt 10 numeric 9 lt 10: yes
.if 9 lt 10a string 9 lt 10a: wrong
.if &s eq 'abc ' padded: yes
.if &s eq abc .ty control word object: yes
.if &nosuch eq &nosuch undefined compares as written: yes
.se e = ''
.if /&e eq / null value, prefix technique (p.266): yes
.if &n eq 10
.th then-branch: yes
.el else-branch: wrong
.if &n eq 11
.th then-branch: wrong
.el else-branch: yes
.if &n eq 10 .if &s eq abc nested: yes
.if 1 eq 1
.an 2 eq 2 an both: yes
.th an then: yes
.if 1 eq 1
.an 2 eq 3 an one false: wrong
.el an else: yes
.if 1 eq 2
.or 2 eq 2 or: yes
.th or then: yes
.if &e = ON .ty null first comparand: an error (p.266)
