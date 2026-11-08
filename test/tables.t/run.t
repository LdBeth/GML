The Starter Set table tags (SH20-9186-06 ch.7, SH20-9187-06 3.31-3.36).
:rdef makes its element itself: a repeated ARRANGE is joined with " / ";
its id is a name of its own (.xd rdef noid), so the table with the same
id is no duplicate.  Cells take the next cell number of their row
definition (&@rkX, &@rnX), :c n an explicit one; a concat=no cell keeps
its lines (xml:space="preserve", a leading blank is text).  The last of
COLUMN/PAGE gives span=; an unknown value attribute, a missing ID or
REFID, an unknown row definition or cell number, a header or footer
after the first row, table tags outside a table and a table open at a
heading are reported.

  $ gml -profile starter in.gml
  in.gml:3 (in macro ss@msg line 3, in macro ss@cntx line 1): +++DSMGML002W Tag :c is out of context and is ignored.
  in.gml:6 (in macro ss@msg line 21, in macro ss@rdf line 15, in macro ss@rdef line 4, in macro dsmrdef line 1): +++DSMGML012W Tag :rdef requires the id attribute.
  in.gml:8 (in macro ss@msg line 39, in macro ss@tspan line 9, in macro dsmtable line 2): +++DSMGML018W Value wide is not valid for tag :table.
  in.gml:19 (in macro ss@msg line 33, in macro ss@cnum line 8, in macro dsmcell line 4): +++DSMGML016W Cell 9 is not in row definition GRID.
  in.gml:22 (in macro ss@msg line 3, in macro ss@cntx line 1): +++DSMGML002W Tag :c is out of context and is ignored.
  in.gml:23 (in macro ss@msg line 30, in macro ss@rchk line 3, in macro ss@trow line 3, in macro dsmrow line 4): +++DSMGML015W Row definition nosuch is not defined.
  in.gml:25 (in macro ss@msg line 36, in macro ss@thft line 1, in macro dsm#thft line 3, in macro dsmtft line 1): +++DSMGML017W Tag :tft must come before the first row of the table.
  in.gml:34 (in macro ss@msg line 6, in macro dsm#rset line 5, in macro dsmhead1 line 1): +++DSMGML003W Tag :table was not ended before tag :h1.
  in.gml:35 (in macro ss@msg line 21, in macro dsmtref line 2): +++DSMGML012W Tag :tref requires the refid attribute.
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body>a cell before any table
  <rdef id="Grid" concat="yes y no yes" arrange="1 1 2 / 3 4 2" cwidths="2i 1i *"/><rdef cwidths="*"/><p>Text before the table
  </p><table refid="grid" id="grid" column="column" page="page" wide="wide" span="page"><thd><c>Head</c><c n="4">Four
  </c></thd><row><c n="2">second, given first
  </c><c xml:space="preserve">kept
    as typed
  </c><c>joined
  lines
  </c><c n="9">no such cell: the next one, cell 1 of a new row
  </c><c>cell 2
  </c></row><tnote>A note ends the row.</tnote>
  out of context
  <row refid="nosuch"><c>unknown definition
  </c></row><tft><c>late footer
  </c></tft><tcap>The caption</tcap>
  <tdesc>The description.
  </tdesc></table><table refid="grid" span="page"><row><c>open at a heading
  </c></row></table><h1>Heading</h1>
  <p><tref/> and <tref refid="grid"/>.
  </p><tlist/></body></gdoc></gml:doc>
  [4]
