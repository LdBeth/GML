.sa [name] / .re [name] save and restore the formatting environment
(SH20-9161-3 p.110; SX26-3723): the indention, offset, line length,
format mode, hyphenation, the font stack (SH35-0069 p.179) and the .tr
table.  They are the hints gml:sa / gml:re; .re is followed by the
hints that set again each part that changes, with restore="yes" (.pf
for the fonts pushed since the .sa), so a backend need not know gml:re.
.re name restores that environment, dropping the ones saved after it.
A footnote saves the environment and clears the offset (p.110); .fn off
restores it without hints.  .fv (SH35-0069 p.111) is a hint.

  $ gml in.gml
  in.gml:22: warning: .re: no environment saved
  in.gml:23: warning: .re NOSUCH: no environment saved with this name
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:in left="2" unit="ch" break="yes"/><gml:bf font="body" break="no"/>Main teXt X.
  <gml:sa break="no"/><gml:in left="5" unit="ch" delta="+3" break="yes"/><gml:ll length="5" unit="i" break="yes"/><gml:fo fill="no" align="left" overdraw="extend" break="yes"/><gml:hy mode="on" break="no"/><gml:bf font="hi1" break="no"/><gml:bf font="hi2" break="no"/>Saved x.
  <gml:re break="no"/><gml:in left="2" unit="ch" restore="yes" break="no"/><gml:ll length="default" restore="yes" break="no"/><gml:fo fill="yes" align="justify" overdraw="extend" restore="yes" break="no"/><gml:hy mode="off" restore="yes" break="no"/><gml:pf font="hi1" restore="yes" break="no"/><gml:pf font="body" restore="yes" break="no"/>Restored X.
  <gml:sa name="OUTER" break="no"/><gml:of offset="4" unit="ch" break="yes"/><gml:sa name="INNER" break="no"/><gml:ir right="1" unit="ch" break="yes"/><gml:re name="OUTER" break="no"/><gml:of offset="0" unit="ch" restore="yes" break="no"/><gml:ir right="0" unit="ch" restore="yes" break="no"/>After outer.
  <gml:in left="6" unit="ch" break="yes"/><gml:of offset="1" unit="ch" break="yes"/><gml:fn>Footnote.
  <gml:in left="9" unit="ch" break="yes"/></gml:fn><gml:in left="7" unit="ch" delta="+1" offset="0" break="yes"/><gml:fv spec="justify" break="no"/></gml:doc>
  [4]
