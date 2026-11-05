The array examples of SH35-0069 p.254-257, verbatim (OCR: ".de asep" is
.dc asep, and the value of &x must end with a blank to give the result shown
on p.255): &x(*) joins the elements in index order with the array
separator, initially a comma and a blank; .dc asep & x . makes it the
symbol &x., substituted in turn, which can even hold a separator (here
the extended symbol rule splits the line at each ';.br;'); .se x() = v
uses the index counter, element 0; a missing element is null.  Each .br gives a
break hint.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">At: Goldsboro, Kunsan, Misawa
  At: Goldsboro and Kunsan and Misawa
  At: Goldsboro
  <gml:br break="yes"/>Kunsan
  <gml:br break="yes"/>Misawa
  1, 4, 5, 3, 2
  1  &amp;nosuch(1)
  first, second, third / [] / 4 4
  fifth 5
  </gml:doc>
