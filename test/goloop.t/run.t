An endless .go loop is stopped after -maxgo jumps (default 100000).

  $ gml -maxgo 50 in.gml
  in.gml:3: error: .go: more than 50 jumps (loop?); processing stopped
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">before
  </gml:doc>
  [8]
  $ gml in.gml > /dev/null
  in.gml:3: error: .go: more than 100000 jumps (loop?); processing stopped
  [8]
  $ gml -maxgo 10 inmac.gml
  inmac.gml:6 (in macro spin line 3): error: .go: more than 10 jumps (loop?); processing stopped
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
  [8]
