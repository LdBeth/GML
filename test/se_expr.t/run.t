.se: integer arithmetic (+ - * / //, unary minus, parentheses), character
values, null value, bad expressions (the symbol is not set).  A single
number is kept as written (.se 3z = 00, SH35-0069 p.269), an arithmetic
result loses its leading zeros (p.241).

  $ gml in.gml
  in.gml:21: error: .se t: bad expression '1 +': operand expected
  in.gml:22: error: .se t: bad expression '(1 + 2': missing )
  in.gml:23: error: .se t: bad expression '1 / 0': division by zero
  in.gml:24: error: .se t: bad expression '1 2 + 3': operator expected
  in.gml:25: error: .se t: bad expression '* 3': operand expected before *
  in.gml:26: error: .se: symbol name expected
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">a=7 b=9 c=3 d=-3 e=1 f=3 g=007 h=-3 i=12
  [quoted string] [abc def] [it is 7] [no equals sign] [plain words] [] [2010]
  Incremented: 8
  Unchanged: &amp;t
  </gml:doc>
  [8]
