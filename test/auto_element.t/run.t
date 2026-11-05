Automatic elements: opened before the APF runs, closed by the end tag
(also one without APF), inner elements closed with it; an end tag
whose element is not open; tag names that are not XML names.

  $ gml in.gml
  in.gml:22: warning: element b implicitly closed by end tag :eq
  in.gml:24: warning: end tag :eol: element ol is not open
  in.gml:29: warning: tag @x is not an XML name; no element
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><ol id="l1" compact="compact">[start of list]
  <li>one
  </li><li>two
  </li></ol>[end of list]
  after the list
  <q>quoted</q>
  <q>a <b>bold</b></q> text
  [end of list]
  [at-x APF]
  text
  </gml:doc>
  [4]
