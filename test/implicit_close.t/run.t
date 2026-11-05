The .xd implicit-close model: p closed by p and ol, li by li, li
closed by the end of ol, empty elements, end of input; a non-closable
element closed by an end tag is reported.

  $ gml in.gml
  in.gml:28: warning: element hp1 implicitly closed by end tag :eol
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p>First paragraph,<br/>second line.
  </p><p>Second paragraph.
  </p><ol><li>one
  </li><li>two<br/>
  </li></ol><p>Third paragraph, closed at end of input.
  </p><ol><li>item <hp1>highlighted
  </hp1></li></ol></gml:doc>
  [4]
