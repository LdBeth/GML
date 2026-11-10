Labels and .go (LR p.59, p.179): forward search from the current line,
then wrap to the top of the current file; the rest of the .go line is
discarded; .go searches only the current (imbedded) file.  TO is
ignored (.go to x, .goto x).  The text after a label, from its first
non-blank character, is an input line of its own.

  $ gml in.gml
  k=3
  label then a control word, k=3
  in.gml:30: error: .go: label top not found in in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">iteration 1
  iteration 2
  iteration 3
  done after 4
  forward label (case-insensitive)
  dotted operand
  text after the label (3)
  part done p=1
  in part: second pass only, p=2
  part done p=2
  </gml:doc>
  [8]
