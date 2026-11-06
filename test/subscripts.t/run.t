Arrays (SH35-0069 p.254-257): .se x(n), &x(n) with substituted subscripts;
&x(*) is all elements in index order joined by the array separator
(", ", .dc asep, whose hex codes are EBCDIC: 40 is a blank); &x = &x(0) is the index counter, which follows the
element last set; .se x() = v appends; a missing element of an existing
symbol is null; .se x off drops the whole array.

  $ gml in.gml
  in.gml:21: error: .se z: invalid subscript abc
  in.gml:22: error: .se: index counter &x is not a number
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Elements: 10 two two 30
  All: 10, two, 30
  Index counter (element 0): 3 3
  Plain: plain, element: 10
  Missing element is null: []
  Text in parentheses: &amp;i(s) and 2 (s)
  After delete: [], all 10, 30
  Appended: first, second, third; counter 4; element 2 []
  Separator: first / second / third
  None: &amp;nosuch(*) &amp;nosuch(1)
  Array gone: &amp;y(*) &amp;y(1)
  </gml:doc>
  [8]
