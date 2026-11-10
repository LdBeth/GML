The two Starter Set profiles share starterset.gml, and with it one
message catalogue: the same condition gives the same message number
and text under -profile starter and -profile dcfstarter, IBM's
(SH35-0048-09 p.5-11: +++DSMGMLnnnx TEXT (page nn); 010, 012, 013 and
018 are ours, at numbers IBM leaves free; 010 and 012 are errors, so
the return code is 8).  Here a
title page end without a title page, an item and a list end outside a
list, a term without a description and a description without a term,
an rdef without an id, a value attribute of :table that is not COLUMN
or PAGE, a row definition redefined in an open table, a cell number
that the row definition does not have, a footer after the first row,
an unknown row definition and a list open at a heading.  (Starter also
warns that the end tags close no element: its tags are elements.)

  $ gml -profile dcfstarter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:2: +++DSMGML011W :ETITLEP END-TAG FOUND OUTSIDE TITLEP AND IGNORED. (page 1)
  in.gml:4: +++DSMGML002W :LI FOUND OUTSIDE LIST. (page 1)
  in.gml:5: +++DSMGML011W :EOL END-TAG FOUND OUTSIDE LIST AND IGNORED. (page 1)
  in.gml:8: +++DSMGML005W EXTRANEOUS DEFINITION TERM 'term two' IGNORED. (page 1)
  in.gml:10: +++DSMGML006W DEFINITION TERM TAG MISSING. (page 1)
  in.gml:12: +++DSMGML019W REQUIRED ATTRIBUTE ID MISSING FROM :RDEF TAG. (page 1)
  in.gml:14: +++DSMGML015W wide NOT A VALID VALUE FOR COLUMN OR PAGE ATTRIBUTE OF :TABLE TAG. (page 1)
  in.gml:15: +++DSMGML012E ROW DEFINITION r CANNOT BE REDEFINED WHILE A TABLE IS ACTIVE, RDEF TAG IGNORED. (page 1)
  in.gml:17: +++DSMGML010E CELL '9' DOES NOT EXIST IN ROW 'R'. (page 1)
  in.gml:18: +++DSMGML024W :TFT TAG NOT VALID AFTER FIRST ROW IN TABLE HAS STARTED. (page 1)
  in.gml:20: +++DSMGML017W ROW DEFINITION nosuch DOES NOT EXIST. (page 1)
  in.gml:24: +++DSMGML003W OL PREMATURELY ENDED BY :H1 TAG. (page 1)

  $ gml -profile starter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:2: warning: end tag :etitlep: element titlep is not open
  in.gml:2: +++DSMGML011W :ETITLEP END-TAG FOUND OUTSIDE TITLEP AND IGNORED. (page 1)
  in.gml:4: +++DSMGML002W :LI FOUND OUTSIDE LIST. (page 1)
  in.gml:5: warning: end tag :eol: element ol is not open
  in.gml:5: +++DSMGML011W :EOL END-TAG FOUND OUTSIDE LIST AND IGNORED. (page 1)
  in.gml:8: +++DSMGML005W EXTRANEOUS DEFINITION TERM 'term two' IGNORED. (page 1)
  in.gml:10: +++DSMGML006W DEFINITION TERM TAG MISSING. (page 1)
  in.gml:12: +++DSMGML019W REQUIRED ATTRIBUTE ID MISSING FROM :RDEF TAG. (page 1)
  in.gml:14: +++DSMGML015W wide NOT A VALID VALUE FOR COLUMN OR PAGE ATTRIBUTE OF :TABLE TAG. (page 1)
  in.gml:15: +++DSMGML012E ROW DEFINITION r CANNOT BE REDEFINED WHILE A TABLE IS ACTIVE, RDEF TAG IGNORED. (page 1)
  in.gml:17: +++DSMGML010E CELL '9' DOES NOT EXIST IN ROW 'R'. (page 1)
  in.gml:18: +++DSMGML024W :TFT TAG NOT VALID AFTER FIRST ROW IN TABLE HAS STARTED. (page 1)
  in.gml:20: +++DSMGML017W ROW DEFINITION nosuch DOES NOT EXIST. (page 1)
  in.gml:24: +++DSMGML003W OL PREMATURELY ENDED BY :H1 TAG. (page 1)

The last-pass flag ss@last is removed at :egdoc under both profiles,
so that two passes in the same state write the same symbol file
(gmlpass stops on that).

  $ gml -profile dcfstarter -pass 1 -passes 2 -symbols-out d.sym in.gml > /dev/null 2>&1
  [8]
  $ gml -profile starter -pass 1 -passes 2 -symbols-out s.sym in.gml > /dev/null 2>&1
  [8]
  $ grep -c 'ss@last' d.sym s.sym
  d.sym:0
  s.sym:0
  [1]

The month names of &date are starterset.gml's.

  $ grep 'ss@mon(6)' d.sym s.sym
  d.sym:.se ss@mon(6) = 'June'
  s.sym:.se ss@mon(6) = 'June'

More of IBM's messages (SH35-0048-09): a row definition ID longer than
7 characters is truncated (008); ARRANGE lines of different lengths
give one cell (021: the rdef element says arrange="1"); a :c without a
number past the last cell of a header is ignored (023; under
dcfstarter no cell is made, its text stays in the last one); an ID
defined twice is ignored (009, dcfstarter: the first one's symbols
stay); a :gt after a :gt without its :gd is ignored (005, dcfstarter
drops it), a :gd without its :gt gets "?" (006); a list ended after a
term without its description gives 018 (ours).

  $ cat > more.gml <<'EOT'
  > :gdoc.
  > :body.
  > :rdef id=longidxx cwidths='1i 1i'.
  > :rdef id=rag arrange='1 2 / 3'.
  > :table refid=longidx.
  > :thd.
  > :c.h1
  > :c.h2
  > :c.h3
  > :ethd.
  > :row.
  > :c.a
  > :c.b
  > :etable.
  > :h1 id=dup.First
  > :h1 id=dup.Second
  > :p.See :hdref refid=dup..
  > :gl.
  > :gt.one
  > :gt.two
  > :gd.desc
  > :gd.nogt
  > :gt.last
  > :egl.
  > :egdoc.
  > EOT
  $ gml -profile dcfstarter -o d.xml more.gml 2>&1 | sed 's/ (in macro[^)]*)//'
  more.gml:3: +++DSMGML008W RDEF ID 'longidxx' TRUNCATED TO SEVEN CHARACTERS. (page 1)
  more.gml:4: +++DSMGML021W INVALID ARRANGE SPECIFICATION, DEFAULT OF 1 USED. (page 1)
  more.gml:9: +++DSMGML023W CANNOT START A NEW ROW IN A HEADER OR FOOTER, C TAG IGNORED. (page 1)
  more.gml:16: warning: duplicate id dup (first used at more.gml:15 (in macro f@hd line 48, in macro f@hd1 line 1))
  more.gml:16: +++DSMGML009W DUPLICATE H1 ID 'dup' IGNORED. (page 1)
  more.gml:20: +++DSMGML005W EXTRANEOUS GLOSSARY TERM 'two' IGNORED. (page 1)
  more.gml:22: +++DSMGML006W GLOSSARY TERM TAG MISSING. (page 1)
  more.gml:24: +++DSMGML018W GLOSSARY TERM WITHOUT A DESCRIPTION AT THE END OF THE LIST. (page 1)
  $ grep -o '<rdef [^>]*>\|See .*' d.xml
  <rdef id="longidxx" cwidths="1i 1i"/>
  <rdef id="rag" arrange="1"/>
  See “First”.
  $ tr -d '\n' < d.xml | grep -o '<thd>.*</thd>'
  <thd><c>h1</c><c>h2h3</c></thd>
  $ sed 's/<[^>]*>//g' d.xml | grep 'one\|two\|desc\|?\|nogt\|last'
  one:
  desc
  ?:
  nogt
  last:
  $ gml -profile starter more.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  more.gml:3: +++DSMGML008W RDEF ID 'longidxx' TRUNCATED TO SEVEN CHARACTERS. (page 1)
  more.gml:4: +++DSMGML021W INVALID ARRANGE SPECIFICATION, DEFAULT OF 1 USED. (page 1)
  more.gml:9: +++DSMGML023W CANNOT START A NEW ROW IN A HEADER OR FOOTER, C TAG IGNORED. (page 1)
  more.gml:16: warning: duplicate id dup (first used at more.gml:15)
  more.gml:20: +++DSMGML005W EXTRANEOUS GLOSSARY TERM 'two' IGNORED. (page 1)
  more.gml:22: +++DSMGML006W GLOSSARY TERM TAG MISSING. (page 1)
