.em runs a macro, also under .ms off, which is the initial setting
(SH35-0069 p.271, p.278); .ec runs the native control word even when a
macro of that name exists (p.277-279), as the .' modifier does.

  $ gml in.gml
  in.gml:7: warning: unsupported control word .he
  in.gml:10: error: .em: macro nosuch not defined
  in.gml:11: error: .em: macro name required
  (macro ty) via the macro
  via .ec
  via the modifier
  no indicator needed
  in.gml:20: warning: unsupported control word .zz
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Hello, world!
  Hello, there!
  Hello, on!
  </gml:doc>
  [8]
