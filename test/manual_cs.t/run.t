Conditional sections, SH35-0069 p.267-268: the Class A/B/C Widget example
verbatim (printed as "This book is written specifically for the operator
of a Class C Widget."); an ignored section still resolves macros (p.268:
"Such a bypass is not a total one"), whose lines are processed; a section
not explicitly ignored is processed (p.267).

  $ gml in.gml
  note: seen although section 2 is ignored
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">This book is written specifically
  for the operator of a
  Class C
  Widget.
  Section 5 text.
  </gml:doc>
