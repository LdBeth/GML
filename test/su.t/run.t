.su off disables substitution; .ur forces it for one line; .su n
substitutes the next n lines (SH35-0069 p.230).  With .su off, the
symbols of a .se line outside quotes are still substituted, word by word
(p.230-231), and so are the comparands of .if (p.267).

  $ gml in.gml
  off: &a
  forced control word: value
  in.gml:11: error: .su: ON, OFF or a number expected, not maybe
  .if with .su off: comparands substituted (p.267)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">On: value
  Off: &amp;a
  Forced: value
  Back on: value
  Already on: value
  Counted 1: value
  Counted 2: value
  Counted 3, off again: &amp;a
  B=value C=&amp;a D=alu
  </gml:doc>
  [8]
