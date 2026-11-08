The Starter Set tables (SH20-9186-06 ch.7) in the formatting profile
-profile dcfstarter: the APFs make the same rdef/table/thd/tft/row/c/
tnote/tcap/tdesc elements as starter.gml (resolve.xsl works out the grid
from them), explicitly (.xs/.xe), and add the formatting the Starter Set
gives: a skip before and after the table, "Note:" in hp2 before a table
note, "Table 1." in hp2 before the caption (counted here), a colon
joining the description to the caption (.ct), and a CONCAT=NO cell as a
format-off region inside its c element.  A :tref resolves from the
symbols the caption set (ft@ID the number, fu@ID the page; page=yes
always gives the page); a forward one is unknown in one pass (DCFS020W).
A value attribute other than COLUMN/PAGE, a footer after the first row
and an :etable without a table are reported.

  $ gml -profile dcfstarter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:4: +++DCFS020W Reference to pl is undefined or forward (one pass).
  in.gml:22: +++DCFS020W Reference to nosuch is undefined or forward (one pass).
  in.gml:23: +++DCFS004W Tag :etable found but no table is open.
  in.gml:24: +++DCFS018W Value wide is not valid for tag :table.
  in.gml:27: +++DCFS017W Tag :tft must come before the first row of the table.

  $ gml -profile dcfstarter in.gml 2>/dev/null | sed 's/<gml:d[fhr] [^>]*>//g; s/<gml:fn kind="leader">.*<\/gml:fn>//'
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rf><gml:bf font="hi0" break="no"/><gml:sx left="" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><body><gml:pa page="1" break="yes"/><gml:pn spec="arabic" break="no"/><gml:rf><gml:bf font="hi0" break="no"/><gml:sx left="" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:pa break="yes"/><gml:rf><gml:bf font="hi0" break="no"/><gml:sx left="Tables" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><h1><gml:h level="1" break="yes"><gml:tcmark anchor="gml.tc.1" break="no"/>Tables</gml:h>
  </h1><gml:sk n="0.75" unit="line" break="yes"/>Forward: Table ID unknown.
  <rdef id="pl" hp="2 0" concat="y n" cwidths="1i *"/><rdef id="hd" align="c" cwidths="1i *"/><gml:sk n="1" unit="line" break="yes"/><table id="pl" refid="pl" span="column"><thd refid="hd"><c>Name</c><c>Lines
  </c></thd><row><c n="2" xml:space="preserve"><gml:fo fill="no" align="left" overdraw="extend" break="yes"/> kept
    as typed
  <gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/></c><c n="1">Mercury
  </c></row><row split="no"><c>Venus</c><c xml:space="preserve"><gml:fo fill="no" align="left" overdraw="extend" break="yes"/>Second<gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/></c><c>wraps to a new row
  </c></row><tnote><gml:bf font="hi2" break="no"/>Note:
  <gml:pf initial="yes" break="no"/>A note.
  </tnote><tcap><gml:sk n="1" unit="line" break="yes"/><gml:bf font="hi2" break="no"/>Table 1.
  <gml:pf initial="yes" break="no"/>Planets</tcap><tdesc>:
  Two of them.
  </tdesc></table><gml:sk n="1" unit="line" break="yes"/><gml:sk n="0.75" unit="line" break="yes"/>Backward: Table 1 on page 1, and none: Table ID unknown.
  <gml:sk n="1" unit="line" break="yes"/><table refid="pl" span="page"><row><c>one
  </c></row><tft><c>late
  </c></tft></table><gml:sk n="1" unit="line" break="yes"/><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/></body></gml:doc>

Tags out of context and the table checks: table tags outside a table
(DCFS002W), a required attribute missing (DCFS012W), an unknown row
definition (DCFS015W), a table in a table (DCFS014W, ignored), a row
definition redefined while a table is open (DCFS019W), a table not
ended before a heading (DCFS003W).

  $ gml -profile dcfstarter ctx.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  ctx.gml:3: +++DCFS002W Tag :c is out of context and is ignored.
  ctx.gml:4: +++DCFS002W Tag :row is out of context and is ignored.
  ctx.gml:5: +++DCFS012W Tag :rdef requires the id attribute.
  ctx.gml:7: +++DCFS015W Row definition nosuch is not defined.
  ctx.gml:10: +++DCFS012W Tag :tref requires the refid attribute.
  ctx.gml:11: +++DCFS014W A table cannot be nested in a table.
  ctx.gml:12: +++DCFS019W Row definition x redefined while a table is open.
  ctx.gml:13: +++DCFS003W Tag :table was not ended before tag :h1.
  ctx.gml:14: +++DCFS004W Tag :etable found but no table is open.
