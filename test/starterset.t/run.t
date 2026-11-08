The two Starter Set profiles share starterset.gml, and with it one
message catalogue: the same condition gives the same message number
and text, DSMGMLnnnW under -profile starter and DCFSnnnW under
-profile dcfstarter (&ss@mp, the prefix the profile sets).  Here a
title page end without a title page, an item and a list end outside a
list, a term without a description and a description without a term,
an rdef without an id, a value attribute of :table that is not COLUMN
or PAGE, a row definition redefined in an open table, a cell number
that the row definition does not have, a footer after the first row,
an unknown row definition and a list open at a heading.  (Starter also
warns that the end tags close no element: its tags are elements.)

  $ gml -profile dcfstarter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:2: +++DCFS004W Tag :etitlep found but no titlep is open.
  in.gml:4: +++DCFS002W Tag :li is out of context and is ignored.
  in.gml:5: +++DCFS004W Tag :eol found but no list is open.
  in.gml:8: +++DCFS010W Definition term without description before tag :dt.
  in.gml:10: +++DCFS011W Definition description without term at tag :dd.
  in.gml:12: +++DCFS012W Tag :rdef requires the id attribute.
  in.gml:14: +++DCFS018W Value wide is not valid for tag :table.
  in.gml:15: +++DCFS019W Row definition r redefined while a table is open.
  in.gml:17: +++DCFS016W Cell 9 is not in row definition R.
  in.gml:18: +++DCFS017W Tag :tft must come before the first row of the table.
  in.gml:20: +++DCFS015W Row definition nosuch is not defined.
  in.gml:24: +++DCFS003W Tag :ol was not ended before tag :h1.

  $ gml -profile starter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:2: warning: end tag :etitlep: element titlep is not open
  in.gml:2: +++DSMGML004W Tag :etitlep found but no titlep is open.
  in.gml:4: +++DSMGML002W Tag :li is out of context and is ignored.
  in.gml:5: warning: end tag :eol: element ol is not open
  in.gml:5: +++DSMGML004W Tag :eol found but no list is open.
  in.gml:8: +++DSMGML010W Definition term without description before tag :dt.
  in.gml:10: +++DSMGML011W Definition description without term at tag :dd.
  in.gml:12: +++DSMGML012W Tag :rdef requires the id attribute.
  in.gml:14: +++DSMGML018W Value wide is not valid for tag :table.
  in.gml:15: +++DSMGML019W Row definition r redefined while a table is open.
  in.gml:17: +++DSMGML016W Cell 9 is not in row definition R.
  in.gml:18: +++DSMGML017W Tag :tft must come before the first row of the table.
  in.gml:20: +++DSMGML015W Row definition nosuch is not defined.
  in.gml:24: +++DSMGML003W Tag :ol was not ended before tag :h1.

The last-pass flag ss@last is removed at :egdoc under both profiles,
so that two passes in the same state write the same symbol file
(gmlpass stops on that).

  $ gml -profile dcfstarter -pass 1 -passes 2 -symbols-out d.sym in.gml > /dev/null 2>&1
  [4]
  $ gml -profile starter -pass 1 -passes 2 -symbols-out s.sym in.gml > /dev/null 2>&1
  [4]
  $ grep -c 'ss@last' d.sym s.sym
  d.sym:0
  s.sym:0
  [1]

The month names of &date are starterset.gml's.

  $ grep 'ss@mon(6)' d.sym s.sym
  d.sym:.se ss@mon(6) = 'June'
  s.sym:.se ss@mon(6) = 'June'
