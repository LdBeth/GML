The head-level counter (SH20-9161-3 p.247; LR p.185, p.188): .hn of a
level defined NUM (.dh n num, until .dh n nonum) is numbered, num="1.0"
for level 1 and "1.2.1" below.  .gs hctr n1.n2... sets the counter
(letters give alphabetic positions: A.0; a zero position resets the
later ones) and the first step after it is ignored at a level up to the
deepest nonzero one set: after 4.7.7.4 an .h4 is 4.7.7.4, an .h5
4.7.7.4.1, an .h3 4.7.7.  .gs hctr n steps level n (after A.0 the first
step is A, as IBM's DSMAPPD and DSMHEAD1 use it); the symbols &@xref
and &xref get the counter to that level and &xref(n) each position.
.gs hctr alone or 0 reinitialises it.

  $ gml in.gml
  in.gml:39: error: .gs hctr: invalid value 1..2
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:dh level="1" spec="num" break="no"/><gml:dh level="2" spec="num" break="no"/><gml:dh level="3" spec="num" break="no"/><gml:h level="1" num="1.0" break="yes"><gml:tcmark anchor="gml.tc.1" break="no"/>First</gml:h>
  <gml:h level="2" num="1.1" break="yes"><gml:tcmark anchor="gml.tc.2" break="no"/>Sub</gml:h>
  <gml:h level="2" num="1.2" break="yes"><gml:tcmark anchor="gml.tc.3" break="no"/>Sub</gml:h>
  <gml:h level="3" num="1.2.1" break="yes"><gml:tcmark anchor="gml.tc.4" break="no"/>Deep</gml:h>
  <gml:h level="1" num="2.0" break="yes"><gml:tcmark anchor="gml.tc.5" break="no"/>Second</gml:h>
  Set: 4.7.7.4 4.7.7.4 (4 4)
  <gml:h level="4" break="yes">Not numbered</gml:h>
  <gml:h level="3" num="4.7.7" break="yes"><gml:tcmark anchor="gml.tc.6" break="no"/>Level three</gml:h>
  <gml:h level="3" num="4.7.8" break="yes"><gml:tcmark anchor="gml.tc.7" break="no"/>Level three again</gml:h>
  <gml:dh level="4" spec="num" break="no"/><gml:dh level="5" spec="num" break="no"/><gml:h level="5" num="4.7.7.4.1" break="yes">Level five</gml:h>
  <gml:h level="4" num="4.7.7.5" break="yes">Level four</gml:h>
  Step 2: 4.8
  Zero: 3.0.0
  Zero alone []
  <gml:h level="1" num="1.0" break="yes"><gml:tcmark anchor="gml.tc.8" break="no"/>After zero</gml:h>
  Appendix A
  Appendix B
  <gml:dh level="1" spec="nonum" break="no"/><gml:h level="1" break="yes"><gml:tcmark anchor="gml.tc.9" break="no"/>Unnumbered</gml:h>
  <gml:h level="2" num="B.1" break="yes"><gml:tcmark anchor="gml.tc.10" break="no"/>In appendix</gml:h>
  Reset []
  <gml:dh level="1" spec="num" break="no"/><gml:h level="1" num="1.0" break="yes"><gml:tcmark anchor="gml.tc.11" break="no"/>Again</gml:h>
  </gml:doc>
  [8]
