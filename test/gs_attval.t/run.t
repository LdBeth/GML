.gs attval name [as sym]: the attribute value in &NAME or the symbol
named; an attribute not given sets the null string.  &NAME is upper case
and symbol names are case-sensitive; an AS name is used as written
(SH35-0069 p.293, p.239).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><tagname id="fred" place="Des Moines">id=fred place=Des Moines local=fred
  [it is Des Moines]
  </tagname><tagname id="bob">id=bob place= local=bob
  </tagname></gml:doc>
