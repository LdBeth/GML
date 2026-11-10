Diagnostics: undefined .go label, .an without .if, bad conditions, bad
expressions, runaway substitution.  With no comparison yet, .el skips
its target and .th processes it (LR p.164, p.395).

  $ gml in.gml
  in.gml:1: error: .go: label nowhere not found in in.gml
  in.gml:2: error: .an without a preceding .if
  in.gml:5: error: .if: invalid comparison operator frob
  in.gml:6: error: .if: condition expected
  in.gml:7: error: .se x: bad expression '1 +': operand expected
  in.gml:8: error: .se x: missing )
  in.gml:10: error: symbol substitution result too long
  in.gml:15: error: symbol substitution does not terminate (more than 10000 steps)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">target of .th without a comparison (processed)
  Runaway: &amp;a
  Cycle: &amp;p
  </gml:doc>
  [8]
