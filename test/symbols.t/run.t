Symbols (SH35-0069 chapter 21): case-sensitive names except those
beginning with $ (p.239, p.241), termination by blank, period or end of
line only (p.232: "&prodname," is not substituted), undefined symbols
left as written, & before a non-name character, rescanning, compound
names (right to left), local (*) names outside a macro (one set of locals,
undefined ones left as written, p.276), names longer than ten characters
(p.235), deletion, -set, single quotes only.

  $ gml -set cl=fromcli -set CL2=two in.gml
  in.gml:18: error: .se: symbol name verylongsymbolname longer than 10 characters
  John Smith / double "quotes" kept
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Value 5, name John Smith, case double &quot;quotes&quot; kept &amp;b.
  Period: 5. and 5x &amp;numx
  Not references (p.232): &amp;num, &amp;name; &amp;num: stay.
  Undefined &amp;nosuch and &amp;nosuch. stay.
  Ampersands: &amp; alone, &amp;= and &amp;5
  Rescan: 5 + 5
  Compound: 5
  Inside-out: second
  Local outside a macro: local &amp;*undef
  Long: &amp;verylongsymbolname
  Deleted: &amp;num
  Command line: fromcli / two / &amp;cl2
  Dollar names are case-insensitive (p.241): dollar dollar dollar
  </gml:doc>
  [8]
