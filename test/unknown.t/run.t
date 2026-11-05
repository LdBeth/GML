Unknown control words warn and are ignored; return code 4.  (.sp is a
formatting hint.)

  $ gml in.gml
  in.gml:2: warning: unsupported control word .xx
  in.gml:5: warning: unsupported .dc option tb
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">text
  <gml:sp n="2" unit="line" break="yes"/>more
  </gml:doc>
  [4]
