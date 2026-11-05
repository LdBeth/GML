.ms on
.* p.271: the sequence on one line increments only x
.se x = 1
.se y = 1
.se x = &x + 1;.se y = &x
.ty x=&x y=&y
.su off
.dm increment /.se x = &x + 1 /.se y = &x
.su on
.increment
.ty x=&x y=&y
.* p.272: the single-line form
.su off
.dm para /.ty sk /.ty in 3 for 2 /.ty &*
.su on
.para On second thought,
.dm echo on
.ty ---
.ty &*
.ty ---
.dm off
.echo inline form
.* p.273: the subscripted form, executed in subscript order
.dm para off
.su off
.dm para(5) /.ty sk
.dm para(15) /.ty &*
.dm para(10) /.ty in 3 for 2
.su on
.para subscripted
.dm para(10) /.ty in 5 for 1
.dm para(12) /.ty kp 6
.para modified
.dm echo off
.su off
.'dm echo(1) /.ty ===;.ty &*
.dm echo(3) /.ty ===
.su on
.echo with the modifier
.dm echo off
.su off
.dm echo( ) /.ty --
.dm echo( ) /.ty &*
.dm echo( ) /.ty --
.su on
.echo numbered by 10
.* p.274
.dm count on
.se x = &x + 1
.ty &x
.dm off
.count
.count
.se off = 7
.su off
.dm of /.ty sk/.ty in &off after 1/
.su on
.of
.se off = 9
.of
.* p.274-275
.dm canbe on
.if &who eq Geoff .or &who eq Dot
.th &*
.dm off
.se who = Dot
.canbe .im pg$sym
.se who = Ann
.canbe .im pg$sym
.* p.253: tokens
.dm burger /.ty &*0.: &*1.|&*2.|&*3.|&*4.|&*5.|
.burger fries+shake nosauce 'on a great big poppy-seed bun'
.* p.275-276
.dm process /.ty * is &*.| 0 is &*0., 1-5 are &*1.|&*2.|&*3.|&*4.|&*5.|&*6.|
.process fileb 10 filea no
.dm insert /.ty * is &*.| 0 is &*0., 1-5 are &*1.|&*2.|&*3.|&*4.|&*5.|&*6.|
.insert filea 10 % fileb 15
.dm process off
.dm process /.ty processing &*
.dm macro on
.se *i = 1
...loop
.process &*&*i
.se *i = &*i + 1
.if &*i le &*0 .go loop
.dm off
.macro one two three
.* p.277: .me
.dm score on
.ty sk 1
.if &place eq inline .me
.ty hr left to right
.ty sk 1
.dm off
.se place = inline
.score
.se place = display
.score
.dm macro off
.dm macro on
.me .se *rc = 4
.dm off
.dm caller on
.macro
.ty caller's *rc=&*rc
.dm off
.caller
.macro
.ty the file's *rc=&*rc
.dm case on
.se *i = &*1 + 1
.if &*i gt &*0 .ty CASE index error.
.el .me .go &*&*i
.dm off
.se function = 2
.case &function open read write close
...open
.ty open
...read
.ty read
...write
.ty write
...close
.ty close
.case 7 open read write close
.* p.278: redefining .sk; .ec and the modifier run the control word
.dm sk on
.ec .ty sk &*
.ty il 5
.dm off
.sk 3
.ec .sk 4
.'sk 4
.ms off
.em .sk 3
.ms on
.dm sk off
.* p.279: redefining .im with .ec, still allowing macros in the file
.dm im on
.ty Imbedding &* ...
.ec .im &*
.dm off
.im pg$sym
.dm im off
.* p.279-280: associative memory
.su off
.se figctr = 0
.dm fignum on
.se figctr = &figctr + 1
.se fig@&*1 = &figctr
.se fig#&*1 = &
Figure &fig@&*1..
.dm off
.dm figref /Figure &fig@&*1 on page &fig#&*1
.su on
.fignum fred
Example of Aardvark's Table Manners
... as shown in
.figref fred
.* the FIGNUM that builds FIGLIST (.sx shown with .ty)
.se figctr = 0
.dm fignum on
.se figctr = &figctr + 1
.se *sx '/Figure &fig@&*1../ /&fig#&*1../'
.dm figlist() /.ty sx &*sx
.se fig@&*1 = &figctr
.se fig#&*1 = &
Figure &fig@&*1..
.dm off
.fignum ann
.fignum bob
.figlist
