.* and .cm lines (and labels) produce nothing.  SH35-0069 p.44: .cm is an
ordinary control word, so its line is split at the separator and the rest
is processed; a .* line is ignored as a whole, separators included.

  $ gml in.gml
  split: the rest of a .cm line is processed (p.44)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">visible
  also visible
  </gml:doc>
