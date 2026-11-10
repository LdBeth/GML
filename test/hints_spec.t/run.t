Operand normalisation of the "spec" words: only space-unit operands
(SH35-0069 p.44-46) get a unit.  The factors of .ls/.ws/.es BY, SKIP,
SPACE and TEXT (p.92-93, p.106, p.114), the .wz and .pn operands and the
column count of .cd are kept as written.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:ls spec="by 2" break="yes"/><gml:ls spec="normal 15pt" break="yes"/><gml:ls spec="1line" break="yes"/><gml:ls spec="skip .8 2.0" break="yes"/><gml:ws spec="by 1.5" break="no"/><gml:ws spec="normal 8pt" break="no"/><gml:es spec="by .5" break="no"/><gml:wz spec="3" break="yes"/><gml:wz spec="off" break="yes"/><gml:pn spec="5" break="no"/><gml:pn spec="pref 2-" break="no"/><gml:cd spec="3 0ch 144pt 312pt" break="yes"/><gml:ud spec="thick -2pt" break="no"/><gml:sb spec="0.15cm" break="no"/><gml:cl spec="22mh" break="yes"/><gml:pl spec="11i" break="no"/></gml:doc>
