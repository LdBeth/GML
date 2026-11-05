The :disc/:edisc example of SH35-0069 p.296-298, under a profile that
imbeds the starter set (as the manual's imbeds DSMPROF3) and adds the
two APFs.  The disclaimer comes out as formatting hints inside a disc
element; &rbl. is a required blank (U+00A0) and &$cont. joins the
residual text "John Doe" to the last line.

  $ gml -profile disc.gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body><p>Before the disclaimer.
  <disc><gml:pa nostart="yes" break="yes"/><gml:bf font="hi2" break="no"/><gml:bx action="on" spec="1ch 45ch" break="yes"/><gml:sp n="1" unit="line" break="yes"/><gml:in left="2" unit="ch" delta="+2" break="yes"/><gml:ir right="2" unit="ch" delta="+2" break="yes"/><gml:fo fill="yes" align="left" overdraw="extend" break="yes"/>Any Similarity To Living Or Dead Persons
  Of The Same Name Is Purely Coincidental.
  <gml:sp n="1" unit="line" break="yes"/>For Legal Questions Contact: John Doe
  </disc><gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/><gml:sp n="1" unit="line" break="yes"/><gml:bx action="off" break="yes"/><gml:pf initial="yes" break="no"/></p><p>After it.
  </p></body></gdoc></gml:doc>
