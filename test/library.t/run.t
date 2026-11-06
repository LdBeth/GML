Symbol and macro libraries (SH35-0069 p.239-240, p.281-283): -lib dirs
searched in order, members NAME or NAME.scr; .dm name lib, .se name lib,
.ly on|off|mac|sym; run-once members that end with .dm name off.

  $ gml -lib lib1 -lib lib2 in.gml
  in.gml:3: warning: unsupported control word .he
  in.gml:25: warning: unsupported control word .ql
  in.gml:43: warning: unsupported control word .ot
  in.gml:49: warning: unsupported control word .ot
  in.gml:51: error: .dm nosuch lib: no member NOSUCH in the libraries
  in.gml:52: error: .se nosuch lib: no member NOSUCH in the libraries
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">&amp;SYMONLY
  hello from lib1 one
  second line
  stored hello
  hello from lib1 two
  second line
  library value/library value
  library id ok
  only in lib2 (x y)
  &amp;SYMONLY
  macro D#S@$ ran
  dsfoo macro ran
  once ran
  once ran
  comment ran
  <tagx>APF tagx called
  text after tagx
  </tagx><tagy>direct APF of tagy
  text after tagy
  </tagy>end APF of tagy
  sym only / &amp;NOSUCH / &amp;NOSUCH
  only in lib2 (z)
  </gml:doc>
  [8]
