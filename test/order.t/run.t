Order of operations (SH35-0069 p.40, p.257-258, p.271): the whole line is
substituted first, then classified, then split at the separator.  So
substitution can produce a control word, and a ';' coming out of a
substituted value is a separator (p.258: "a control word modifier cannot
prevent the symbol substitution processor from recognizing a control word
separator").  A .se whose value contains the separator is itself split
(use .' to prevent that).  The part after a separator is not substituted
again: it was substituted with the line, before the .se in front of it ran
(.se x = &x + 1;.se y = &x sets y to the old x, p.271).  Comment and label
lines are not substituted.  The object of .if ends at the separator.
"&b;" is not a reference: only a blank, a period or the end of the line
ends one (p.232).

  $ gml in.gml
  a control word made by substitution
  two'
  [one]
  [one
  two]
  x
  y
  first &b
  second B
  after set: B
  if object
  separate line
  not part of the .if object
  x=2 y=1
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
