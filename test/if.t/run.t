.if: numeric comparison when both operands are numbers, else character
comparison (shorter operand padded with blanks); the object (text or
control word) is processed when the condition is true; .th/.el; .an/.or.
A null first comparand leaves the operator as the first comparand: an
error; the prefix technique avoids it (SH35-0069 p.266).
Lines containing "wrong" must not appear.

  $ gml in.gml
  control word object: yes
  in.gml:39: error: .if: invalid comparison operator ON
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">numeric eq: yes
  gt: yes
  leading zero numeric: yes
  ne: yes
  string lt: yes
  slash-ne: yes
  diamond-ne: yes
  le: yes
  numeric 9 lt 10: yes
  padded: yes
  undefined compares as written: yes
  null value, prefix technique (p.266): yes
  then-branch: yes
  else-branch: yes
  nested: yes
  an both: yes
  an then: yes
  an else: yes
  or: yes
  or then: yes
  </gml:doc>
  [8]
