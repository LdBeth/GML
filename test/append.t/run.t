.ap ends the current file and continues with the named file; afterwards
processing returns to the file that imbedded the current one.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">outer start
  mid start
  tail text
  outer end
  </gml:doc>
