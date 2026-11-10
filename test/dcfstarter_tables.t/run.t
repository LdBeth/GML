The Starter Set tables (SH20-9186-06 ch.7) in the formatting profile
-profile dcfstarter: the APFs make the same rdef/table/thd/tft/row/c/
tnote/tcap/tdesc elements as starter.gml (resolve.xsl works out the grid
from them), explicitly (.xs/.xe), and add the formatting the Starter Set
gives: a skip of .1i before and after the table (&@sk@t, SSR Figure
11), "Note:" in hp2 before a table
note, "Table 1." in hp2 before the caption (counted here), a colon
joining the description to the caption (.ct), and a CONCAT=NO cell as a
format-off region inside its c element.  A :tref resolves from the
symbols the caption set (ft@ID the number, fu@ID the page; page=yes
always gives the page); a forward one is unknown in one pass (DSMGML013W).
A value attribute other than COLUMN/PAGE, a footer after the first row
and an :etable without a table are reported; the footer is ignored with
its end tag (DSMGML024W), so its cell goes on the row (the second cell
of PL, CONCAT=NO).

  $ gml -profile dcfstarter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:4: +++DSMGML013W ID 'pl' NOT DEFINED OR A FORWARD REFERENCE IN ONE PASS. (page 1)
  in.gml:22: +++DSMGML013W ID 'nosuch' NOT DEFINED OR A FORWARD REFERENCE IN ONE PASS. (page 1)
  in.gml:23: +++DSMGML011W :ETABLE END-TAG FOUND OUTSIDE TABLE AND IGNORED. (page 1)
  in.gml:24: +++DSMGML015W wide NOT A VALID VALUE FOR COLUMN OR PAGE ATTRIBUTE OF :TABLE TAG. (page 1)
  in.gml:27: +++DSMGML024W :TFT TAG NOT VALID AFTER FIRST ROW IN TABLE HAS STARTED. (page 1)

  $ gml -profile dcfstarter in.gml 2>/dev/null | sed 's/<gml:d[fhr] [^>]*>//g; s/<gml:fn kind="leader">.*<\/gml:fn>//'
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rf break="yes"><gml:bf font="hi0" break="no"/><gml:sx left="f@shead" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><body><gml:pa page="1" break="yes"/><gml:pn spec="arabic" break="no"/><gml:symval name="f@shead" value="" break="no"/><gml:rf break="yes"><gml:bf font="hi0" break="no"/><gml:sx left="f@shead" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:pa break="yes"/><gml:symval name="f@shead" value="Tables" break="no"/><gml:rf break="yes"><gml:bf font="hi0" break="no"/><gml:sx left="f@sheadTables" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><h1><gml:h level="1" break="yes"><gml:tcmark anchor="gml.tc.1" break="no"/>Tables</gml:h>
  </h1><gml:sk n="0.75" unit="line" break="yes"/>Forward: Table ID unknown.
  <rdef id="pl" hp="2 0" concat="y n" cwidths="1i *"/><rdef id="hd" align="c" cwidths="1i *"/><gml:sk n="0.1" unit="i" break="yes"/><table id="pl" refid="pl" span="column"><thd refid="hd"><c>Name</c><c>Lines
  </c></thd><row><c n="2" xml:space="preserve"><gml:fo fill="no" align="left" overdraw="extend" break="yes"/> kept
    as typed
  <gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/></c><c n="1">Mercury
  </c></row><row split="no"><c>Venus</c><c xml:space="preserve"><gml:fo fill="no" align="left" overdraw="extend" break="yes"/>Second<gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/></c><c>wraps to a new row
  </c></row><tnote><gml:bf font="hi2" break="no"/>Note:
  <gml:pf initial="yes" break="no"/>A note.
  </tnote><tcap><gml:sk n="1" unit="line" break="yes"/><gml:bf font="hi2" break="no"/>Table 1.
  <gml:pf initial="yes" break="no"/>Planets</tcap><tdesc>:
  Two of them.
  </tdesc></table><gml:sk n="0.1" unit="i" break="yes"/><gml:sk n="0.75" unit="line" break="yes"/>Backward: Table 1 on page 1, and none: Table ID unknown.
  <gml:sk n="0.1" unit="i" break="yes"/><table refid="pl" span="page"><row><c>one
  </c><c xml:space="preserve"><gml:fo fill="no" align="left" overdraw="extend" break="yes"/>late
  <gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/></c></row></table><gml:sk n="0.1" unit="i" break="yes"/><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/></body></gml:doc>

Tags out of context and the table checks: table tags outside a table
(DSMGML002W), a required attribute missing (DSMGML019W), an unknown row
definition (DSMGML017W), a table in a table (DSMGML004W, ignored), a row
definition redefined while a table is open (DSMGML012E, ignored), a table not
ended before a heading (DSMGML003W).

  $ gml -profile dcfstarter ctx.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  ctx.gml:3: +++DSMGML002W :C FOUND OUTSIDE ROW. (page 1)
  ctx.gml:4: +++DSMGML002W :ROW FOUND OUTSIDE TABLE. (page 1)
  ctx.gml:5: +++DSMGML019W REQUIRED ATTRIBUTE ID MISSING FROM :RDEF TAG. (page 1)
  ctx.gml:7: +++DSMGML017W ROW DEFINITION nosuch DOES NOT EXIST. (page 1)
  ctx.gml:10: +++DSMGML019W REQUIRED ATTRIBUTE REFID MISSING FROM :TREF TAG. (page 1)
  ctx.gml:11: +++DSMGML004W :TABLE TAG FOUND WITHIN TABLE AND IGNORED. (page 1)
  ctx.gml:12: +++DSMGML012E ROW DEFINITION x CANNOT BE REDEFINED WHILE A TABLE IS ACTIVE, RDEF TAG IGNORED. (page 1)
  ctx.gml:13: +++DSMGML003W TABLE PREMATURELY ENDED BY :H1 TAG. (page 1)
  ctx.gml:14: +++DSMGML011W :ETABLE END-TAG FOUND OUTSIDE TABLE AND IGNORED. (page 1)
