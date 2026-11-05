Duplicate id attribute values are reported (warning).

  $ gml in.gml
  in.gml:7: warning: duplicate id intro (first used at in.gml:5)
  in.gml:8: warning: duplicate id next (first used at in.gml:6)
  in.gml:11: warning: duplicate id intro (first used at in.gml:5)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><h1 id="intro">Introduction
  </h1><h1 id="next">Next
  </h1><h1 id="intro">Again
  <fig id="next"/><fig id="intro"/></h1></gml:doc>
  [4]
