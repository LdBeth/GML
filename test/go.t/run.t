Labels and .go: forward search from the current line, then wrap to the
top of the current file; the rest of the .go line is discarded; open .do
groups of the file are abandoned by a .go (no unbalanced .do error for a
loop body).  .go searches only the current (imbedded) file.

  $ gml in.gml
  k=3
  in.gml:24: error: .go: label top not found in in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">iteration 1
  iteration 2
  iteration 3
  done after 4
  forward label (case-insensitive)
  dotted operand
  part done p=1
  in part: second pass only, p=2
  part done p=2
  </gml:doc>
  [8]
