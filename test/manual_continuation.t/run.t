Continuation (SH35-0069 p.47-48): there is no continuation character until
.dc cont sets one; a text line that ends with it gets no word space.
.ct text continues the previous text line; .ct alone cancels a
continuation in effect, as does a null line (p.281).  &$CONT is the
continuation character (p.244, used so on p.297).  .bf and .pf give
font hints inside the continued word.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">A word space+
  A few high<gml:bf font="hi2" break="no"/>light<gml:pf initial="yes" break="no"/>ed characters.
  This input line and this input line should be one line.
  continued
  not continued: .ct alone cancels it.
  continued
  a null line resets continuation (p.281).
  For Legal Questions Contact:John Doe
  no+
  </gml:doc>
