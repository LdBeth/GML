.pi (SH35-0069 p.213-218, SH20-9161-3 p.297) puts an index entry: the
hint gml:pi with the terms t1-t3 of the delimited string, the sort keys
k1-k3 of KEY /k1/k2/k3/, start/end/order (ORDER: a major reference);
a fourth field is the page: absent or the page number symbol "&" is the
current page, null is pageref="no", other text is page=; REF makes the
last term a cross reference (see=).  .pi is ignored unless &$INDX is 1
(the INDEX option; 1 here).  .ix [n] [name|control|/] places the index:
the hint gml:ix (resolve.xsl puts the entries after it); a control word
operand is processed in place of the heading.

  $ gml in.gml
  in.gml:8: error: .pi ref: at least two terms expected
  in.gml:9: error: .pi: index term expected
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:pi t1="weasels" t2="training" break="no"/><gml:pi t1="melodrama" start="yes" break="no"/><gml:pi t1="melodrama" t2="plot" k1="MELO" order="yes" break="no"/><gml:pi t1="circular definition" see="definition, circular" break="no"/><gml:pi t1="Pines" t2="Japanese Black" page="Folio 4" break="no"/><gml:pi t1="walrus" pageref="no" break="no"/><gml:pi t1="walrus" break="no"/><gml:pi t1="alone" break="no"/><gml:ix reserve="3" title="Subject Index" break="yes"/><gml:ix title="" break="yes"/><gml:sp n="2" unit="line" break="yes"/><gml:ix title="" break="yes"/></gml:doc>
  [8]

  $ gml -set '$INDX=0' in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:ix reserve="3" title="Subject Index" break="yes"/><gml:ix title="" break="yes"/><gml:sp n="2" unit="line" break="yes"/><gml:ix title="" break="yes"/></gml:doc>
