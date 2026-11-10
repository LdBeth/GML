Rel 4 (LR p.312 r7, p.315 r7, p.316): a symbol in a running heading or
footing is replaced when the heading is placed on the page, with "the
value of the symbol at the time the page is started".  While a
definition is open a reference to a global user symbol in its text (a
text line, the line of .ce, a .sx field) is deferred: gml:symref with
the name and the value now (as written when the symbol is not set:
"Unresolved symbols ... are substituted on each page"); in a .sx field
the value is between U+E001 NAME U+E002 and U+E003 (invisible here: the
field shows "sec" and "One").  Not deferred: the operand of a control
word that is not text (.ce 2, .if, .se: their value now), a macro call
(.arg: the macro gets the value, its parameter &*1 is a local symbol),
an attribute operand (&L'&sec), the end of a compound reference
(&n&lab: its value builds the name &nA, which is not set, so that one
is deferred as written).  A reference after other text (part&lab) is
deferred.  Every later change of a symbol so referred to is the hint
gml:symval with its new value (as written when it is removed); copy
(set inside the definition) and n (only in .ce &n, a count) have
none.  The text of the definition is translated with the initial
table as changed in it (LR p.404 r4): "e" to "E" but not "a" to "A",
which applies outside.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rf break="yes">SEction <gml:symref name="sec">OnE</gml:symref> of <gml:symref name="undef">&amp;undEf.</gml:symref> ok
  <gml:lines word="ce" n="1" break="yes"><gml:symref name="sec">OnE</gml:symref></gml:lines>
  <gml:lines word="ce" n="2" break="yes">part<gml:symref name="lab">A</gml:symref> <gml:symref name="nA">&amp;nA</gml:symref>
  3 chars</gml:lines>
  local OnE
  <gml:sx left="secOnE" fill="" right="PagE &amp;" pagesym="&amp;" break="yes"/><gml:sp n="1" unit="line" break="yes"/></gml:rf>Body: One One Abc.
  <gml:symval name="sec" value="Two" break="no"/><gml:symval name="lab" value="B" break="no"/><gml:symval name="undef" value="Now" break="no"/><gml:symval name="sec" value="&amp;sec" break="no"/></gml:doc>

.rh or .rf inside a definition ends it (LR p.311 r4, p.315 r4), as in
DSMPROF3's duplex footings (.rf odd ... .rf even ... .rf off): two
definitions, and the text after them is not in a running footing.

  $ cat > duplex.gml <<'X'
  > .se sec = One
  > .rf odd
  > &sec. odd
  > .rf even
  > even &sec.
  > .rf off
  > Body &sec.
  > X
  $ gml duplex.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rf page="odd" break="yes"><gml:symref name="sec">One</gml:symref> odd
  </gml:rf><gml:rf page="even" break="yes">even <gml:symref name="sec">One</gml:symref>
  </gml:rf>Body One
  </gml:doc>

A deferred value is text: an "&" in it (here from the text variable
&amp. in a heading, dcfstarter's footing .sx |&f@shead.||&|) is not
the page number symbol, so the field with the symbol (right) still has
it, and pagesym= is U+E000 because a piece holds "&" as text.  (Before
deferral the "&" of the title was split off as a page number too,
so the TeX footing read "A 1 B 1".)  The private characters are shown <E00n>.

  $ printf ':gdoc.\n:body.\n:h1.A &amp. B\n:p.x\n:egdoc.\n' > amp.gml
  $ gml -profile dcfstarter amp.gml 2>/dev/null | perl -CSD -ne 'while (/(<gml:sx [^>]*>)/g) { $x = $1; $x =~ s/([\x{E000}-\x{E003}])/sprintf("<%04X>", ord $1)/ge; print "$x\n" }'
  <gml:sx left="<E001>f@shead<E002><E003>" fill="" right="&amp;" pagesym="&amp;" break="yes"/>
  <gml:sx left="<E001>f@shead<E002><E003>" fill="" right="&amp;" pagesym="&amp;" break="yes"/>
  <gml:sx left="<E001>f@shead<E002>A &amp; B<E003>" fill="" right="&amp;" pagesym="&amp;" break="yes"/>
