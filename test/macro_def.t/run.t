.dm (SH35-0069 p.272-274, p.280): the delimited form (any delimiter,
final delimiter optional; the .dm line is substituted when .su is on, so
symbols meant for the call need .su off), the on/off form (body captured
raw, ended only by .dm off in column 1 without the modifier: run, the
.'dm off body line is an error), redefinition,
an inline .dm ending the definition it is in, a macro defining another one
and deleting itself, deletion with OFF and DELETE.  A name that is no
longer a macro is taken as its first two characters, a control word.
A null line adds no text (p.281).

  $ gml in.gml
  in.gml:23 (in macro block line 5): error: .dm off without .dm name on
  in.gml:43: warning: unsupported control word .ma
  in.gml:46: warning: unsupported control word .tw
  in.gml:48: warning: unsupported control word .ab
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">first line
  second line
  a
  b
  c
  x=1 y=2
  v was now at definition
  block z=7; no split here
  <gml:br break="yes"/> .dm off is a body line: not in column 1
  redefined
  outer runs
  inner body x
  made, defined with A
  a
  b
  </gml:doc>
  [8]
