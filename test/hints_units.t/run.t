Space units (SH35-0069 p.44-46, Figure 3): every form normalised to a
value and a unit name, nothing converted to device units.  Unqualified
vertical amounts are lines, horizontal ones characters; a comma is a
decimal point; picas and ciceros become points (pt) and Didot points
(dd); m is the em of the axis.  More than two decimals, or an unknown
unit, is an error.

  $ gml in.gml
  in.gml:24: error: .sp: invalid space unit 1.234
  in.gml:25: error: .sp: invalid space unit 2x
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:sp n="2" unit="line" break="yes"/><gml:sp n="1.5" unit="line" break="yes"/><gml:sp n="0.75" unit="line" break="yes"/><gml:sp n="3.5" unit="i" break="yes"/><gml:sp n="6.5" unit="i" break="yes"/><gml:sp n="4.25" unit="cm" break="yes"/><gml:sp n="2.54" unit="cm" break="yes"/><gml:sp n="12.7" unit="mm" break="yes"/><gml:sp n="10" unit="dv" break="yes"/><gml:sp n="1" unit="mv" break="yes"/><gml:sp n="6" unit="pt" break="yes"/><gml:sp n="38" unit="pt" break="yes"/><gml:sp n="1.5" unit="pt" break="yes"/><gml:sp n="12" unit="dd" break="yes"/><gml:sp n="27" unit="dd" break="yes"/><gml:sp n="1.5" unit="dd" break="yes"/><gml:in left="5" unit="ch" break="yes"/><gml:in left="6" unit="mh" break="yes"/><gml:in left="6" unit="mh" break="yes"/><gml:in left="0.33" unit="mh" break="yes"/><gml:in left="10" unit="dh" break="yes"/><gml:in left="15" unit="cm" break="yes"/></gml:doc>
  [8]
