.gs tag on
.gs rules (noelem)
.dm hd /[hd: &*0 &*1.]
.dm hd2 /[hd2: &*0 &*1.]
.* a first .aa without rules takes the current rules (novat) and keeps
.* them when .gs rules changes (LR p.63 r2, r4)
.aa hd hd
.gs rules (vat)
:hd big.Frozen
.* a new APF without rules keeps the old rules (r3)
.aa hd hd2
:hd big.Kept
.* = keeps the APF; () is the current rules (vat)
.aa hd = ()
:hd big.Current
.* NULL: no processing, the rules kept
.gs rules (novat)
.aa hd NULL
:hd big.Null
.aa hd .
:hd.Dot
.* OFF: the class mapping (here the macro hd) with the current rules
.aa hd OFF
:hd big.Class
.* one side only: the end tag by .aa, the start tag by class mapping
.dm ehd /[end APF]
.aa hd OFF hd2
:hd.Start
::hd.
.gs snap hd
