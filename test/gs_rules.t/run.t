.gs rules (tag rules) (end-tag rules) (LR p.185-186): the defaults
(att novat stop nomsg) (noatt), vat, stop/nostop with msg, noatt (no
scan at all, the other rules immaterial), end-tag attributes, = for an
unchanged set and () for the default, noelem, errors.

  $ gml in.gml
  in.gml:14: warning: tag :p: invalid attribute (x) (treated as text)
  in.gml:17: warning: tag :p: invalid attribute (x) (ignored)
  in.gml:37: error: .gs rules: unknown rule bogus
  in.gml:38: error: .gs rules: (tag rules) [(end-tag rules)] expected
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p id="a">compact text after.
  </p><p id="b" compact="compact" text="text" after="after"/><p id="c">(x) rest
  </p><p id="d" e="5">Text
  </p><p> id=e.Text
  </p><p> big.Text
  </p><p>Para
  </p>after end
  <p>Para2
  </p> id=y.end default
  <p id="f">big.default again
  no element
  </p></gml:doc>
  [8]
