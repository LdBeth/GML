The head-level counter (SH20-9161-3 p.247, p.266-268): .hn of a level
defined NUM (.dh n num, until .dh n nonum) is numbered, num="1.0" for
level 1 and "1.2.1" below.  .gs hctr n1.n2... sets the counter (letters
give alphabetic positions: A.0) and the next heading at the deepest
nonzero level given takes that value: after 4.7.7.4 an .h3 is 4.7.8.
.gs hctr n steps level n (after A.0 the first step is A, as IBM's
DSMAPPD and DSMHEAD1 use it); the symbol &xref gets the counter to that
level and &xref(n) each position.  .gs hctr alone reinitialises it.

  $ gml in.gml
  in.gml:27: error: .gs hctr: invalid value 1..2
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:dh level="1" spec="num" break="no"/><gml:dh level="2" spec="num" break="no"/><gml:dh level="3" spec="num" break="no"/><gml:h level="1" num="1.0" break="yes">First</gml:h>
  <gml:h level="2" num="1.1" break="yes">Sub</gml:h>
  <gml:h level="2" num="1.2" break="yes">Sub</gml:h>
  <gml:h level="3" num="1.2.1" break="yes">Deep</gml:h>
  <gml:h level="1" num="2.0" break="yes">Second</gml:h>
  Set: 4.7.7.4 (4 4)
  <gml:h level="4" break="yes">Not numbered</gml:h>
  <gml:h level="3" num="4.7.8" break="yes">Level three</gml:h>
  Step 2: 4.8
  Appendix A
  Appendix B
  <gml:dh level="1" spec="nonum" break="no"/><gml:h level="1" break="yes">Unnumbered</gml:h>
  <gml:h level="2" num="B.1" break="yes">In appendix</gml:h>
  Reset []
  <gml:dh level="1" spec="num" break="no"/><gml:h level="1" num="1.0" break="yes">Again</gml:h>
  </gml:doc>
  [8]
