.gs tag on
.dm p on
.dm off
.dm ep on
.dm off
.xd p closedby=p
.* the default rules are the Starter Set's: (att novat stop nomsg) (noatt)
:p id=a compact text after.
.* vat: value attributes are taken
.gs rules (vat)
:p id=b compact text after.
.* stop with msg: the invalid attribute and what follows are text
.gs rules (novat msg)
:p id=c (x) rest
.* nostop: invalid attributes are skipped
.gs rules (nostop)
:p id=d (x) e=5.Text
.* noatt: no scan at all, everything after the name is residual text;
.* the other rules are immaterial (LR p.186)
.gs rules (noatt vat nomsg stop)
:p id=e.Text
:p big.Text
.* end-tag rules: attributes on end tags
.gs rules (att) (att)
:p.Para
::p id=z.after end
.* = leaves a set unchanged, () restores the default (LR p.186)
.gs rules = ()
:p.Para2
::p id=y.end default
.gs rules () =
:p id=f big.default again
.* noelem for all tags
.gs rules (noelem)
:p.no element
.* errors
.gs rules (bogus)
.gs rules att
