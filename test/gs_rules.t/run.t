.gs rules (tag rules) (end-tag rules): the Starter Set defaults,
vat, stop/step with msg, noatt (no scan at all), end-tag attributes,
noelem, errors.

  $ gml in.gml
  in.gml:14: warning: tag :p: invalid attribute (x) (treated as text)
  in.gml:17: warning: tag :p: invalid attribute (x) (ignored)
  in.gml:29: error: .gs rules: unknown rule bogus
  in.gml:30: error: .gs rules: (tag rules) [(end-tag rules)] expected
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p id="a">compact text after.
  </p><p id="b" compact="compact" text="text" after="after"/><p id="c">(x) rest
  </p><p id="d" e="5">Text
  </p><p> id=e.Text
  </p><p>Para
  </p>after end
  no element
  </gml:doc>
  [8]
