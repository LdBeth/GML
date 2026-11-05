Macro diagnostics: bad .dm operands, .me outside a macro, locations
inside (nested) macros, open .do groups at the end of a macro, a .dm on
inside a skipped group, the recursion limit, an unended definition.

  $ gml in.gml
  in.gml:1: error: .dm: macro name required
  in.gml:2: error: .dm: invalid macro name in (x) /a/
  in.gml:3: error: .dm x: definition expected
  in.gml:4: error: .dm x: ON, OFF or a delimited definition expected
  in.gml:5: error: .dm off without .dm name on
  in.gml:6: warning: .me outside a macro ignored
  in.gml:15 (in macro bad line 1, in macro calls line 1): warning: unsupported control word .xx
  in.gml:15 (in macro bad line 2, in macro calls line 1): error: .go: label nowhere not found in macro bad
  in.gml:21 (in macro open line 1): warning: .do begin without .do end in macro open; group discarded
  in.gml:27 (in macro skipper line 1): error: .do begin without .do end (skipped to end of macro skipper)
  in.gml:36: warning: unsupported control word .gh
  in.gml:39 (in macro rec line 1 [100 times]): error: macro rec: calls nested deeper than 100; processing stopped
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">open group
  after skipper
  </gml:doc>
  [8]
  $ gml unclosed.gml
  unclosed.gml:1: error: .dm never on without .dm off (definition ignored)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
  [8]
