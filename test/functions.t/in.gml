.se s 'Hello World'
length=&'length(&s.)
substr=[&'substr(&s.,7)] [&'substr(&s.,2,3)] [&'substr('abc',2,5,'*')]
index=&'index(&s.,'o') &'index(&s.,'o',6) &'index(&s.,'xyz')
left=[&'left(&s.,5)] [&'left('ab',4,'.')] right=[&'right(&s.,5)] [&'right('ab',4)]
upper=&'upper(&s.) lower=&'lower(&s.) partial=&'upper(abcdef,2,3)
strip=[&'strip('  pad  ')] [&'strip('  pad  ',L)] [&'strip('  pad  ',t)] [&'strip('xxpadxx',b,'x')]
copies=&'copies('ab',3) [&'copies(x,0)]
delstr=&'delstr(&s.,6) &'delstr(&s.,1,6) &'delstr('abc',9)
insert=[&'insert('XY','abc')] [&'insert('XY','abc',1)] [&'insert('XY','abc',5,3,'-')]
word=&'word(&s.,2) [&'word(&s.,3)] words=&'words('  one two   three ')
min=&'min(5,-2,7) max=&'max(5,-2,7)
nested=&'upper(&'left(&s.,4))
comma in quotes=&'length('a,b')
.se n = &'length(&s.) * 2
computed=&n
bad=&'nosuch(1) &'substr(abc,x) &'left(abc)
