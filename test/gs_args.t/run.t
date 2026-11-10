.gs args / .gs vars (LR p.187, SH35-0050 p.17, p.28-29): set the
argument symbols &*0 &*1 ... of the current macro (or file), then copy
them by position to named symbols; .gs args alone sets &*0 to 0 and the
others to null; .gs vars takes no array symbol.

  $ gml in.gml
  in.gml:30: error: .gs vars: array symbol x(1) not allowed
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">(5) (10 2 .75 -1 a-b) (10) (-1) (a-b)
  10 2 .75 -1 a-b
  &lt;.rc adjust&gt; &lt;&gt; &lt;&quot;&gt; &lt;'&gt; &lt;&gt;
  (0) ()
  (3) x
  (3) January March (January February March)
  January March ()
  o 3 4ch
  </gml:doc>
  [8]
