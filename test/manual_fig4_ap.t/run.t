SCRIPT/VS Language Reference, Figure 4 "Imbedding and Appending SCRIPT/VS
Files": OUTER imbeds INNER; INNER appends NAMES; after the last line of
NAMES, processing resumes with the line after ".im inner" in OUTER.

  $ gml outer.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Outer first line
  Inner text
  Names text
  Last line.
  Next line
  </gml:doc>
