Diagnostics: undefined .go label, unbalanced .do (stray .do end, .do
begin never ended, a skipped group running to end of input), bad .do
operand, .th without .if, bad conditions, bad expressions, runaway
substitution.

  $ gml in.gml
  in.gml:1: error: .go: label nowhere not found in in.gml
  in.gml:2: error: .do end without .do begin
  in.gml:3: error: .do: BEGIN or END expected
  in.gml:4: error: .th without a preceding .if
  in.gml:5: error: .if: invalid comparison operator frob
  in.gml:6: error: .if: condition expected
  in.gml:7: error: .se x: bad expression '1 +': operand expected
  in.gml:8: error: .se x: missing )
  in.gml:10: error: symbol substitution result too long
  in.gml:15: error: symbol substitution does not terminate (more than 10000 steps)
  in.gml:16: error: .do begin without .do end
  in.gml:17: error: .do begin without .do end (skipped to end of input)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Runaway: &amp;a
  Cycle: &amp;p
  </gml:doc>
  [8]
