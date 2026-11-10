.gs attval [[NOT] name [as sym] ...] (LR p.184, p.188): the attribute
value in &NAME or the symbol named; no names: all the stacked
attributes; NOT: all but those listed; a processed attribute is deleted
from the stack; an attribute not given sets the null string.  &NAME is
upper case and symbol names are case-sensitive; an AS name is used as
written (LR p.188).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><tagname id="fred" place="Des Moines">id= place=Des Moines local=fred
  [it is Des Moines]
  </tagname><tagname id="bob">id= place= local=bob
  <all a="1" b="2" c="3"/>a=1 b=old c=3
  b=2
  </tagname></gml:doc>
