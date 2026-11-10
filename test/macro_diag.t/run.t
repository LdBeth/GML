Macro diagnostics: bad .dm operands (.dm name x, assigning a macro to a
symbol, is not supported; LR p.143), locations inside (nested) macros,
the recursion limit, an unended definition.

  $ gml in.gml
  in.gml:1: error: .dm: macro name required
  in.gml:2: error: .dm: invalid macro name in (x) /a/
  in.gml:3: error: .dm x y: assigning a macro to a symbol is not supported
  in.gml:4: error: .dm x z: assigning a macro to a symbol is not supported
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
