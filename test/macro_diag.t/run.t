Macro diagnostics: bad .dm operands (.dm name x of an undefined macro;
see dm_assign.t), locations inside (nested) macros,
the recursion limit, an unended definition.

  $ gml in.gml
  in.gml:1: error: .dm: macro name required
  in.gml:2: error: .dm: invalid macro name in (x) /a/
  in.gml:3: error: .dm x y: macro x is not defined
  in.gml:4: error: .dm x z: macro x is not defined
  in.gml:5: error: .dm off without .dm name on
  in.gml:6: error: .dm x: invalid line number -1
  in.gml:15 (in macro bad line 1, in macro calls line 1): warning: unsupported control word .xx
  in.gml:15 (in macro bad line 2, in macro calls line 1): error: .go: label nowhere not found in macro bad
  in.gml:18 (in macro rec line 1 [100 times]): error: macro rec: calls nested deeper than 100; processing stopped
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
  [8]
  $ gml unclosed.gml
  unclosed.gml:1: error: .dm never on without .dm off (definition ignored)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
  [8]
