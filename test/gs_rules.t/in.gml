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
.* step: invalid attributes are skipped
.gs rules (step)
:p id=d (x) e=5.Text
.* noatt: no scan at all, everything after the name is residual text
.gs rules (noatt nomsg stop)
:p id=e.Text
.* end-tag rules: attributes on end tags
.gs rules (att) (att)
:p.Para
::p id=z.after end
.* noelem for all tags
.gs rules (noelem)
:p.no element
.* errors
.gs rules (bogus)
.gs rules att
