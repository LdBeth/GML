The table of contents (SH35-0069 ch.13, p.151-157; SH20-9161-3 .DH,
.TC, .PT).  A head level with a table of contents entry (levels 0-3
initially, Figure 14; .dh n tc|ntc) records its text, with its number,
and marks the heading with gml:tcmark; level 0 is an entry only (TO);
.pt adds a line.  .tc ejects the page, puts the title out as a level
one heading and one gml:tcentry per entry made before it (one pass:
"prior to the .TC control word during the current or previous pass",
p.156), with the definition of its level when it was made: indention
(TCIN, Figure 14: 0 0 0 2 4 6 8), font (TFONT), a skip before it (TS:
level 1), DOT or NODOT.  "2" reserves two page numbers (p.157).

  $ gml in.gml | grep -o '<gml:tc[a-z]* [^>]*>'
  <gml:tcmark anchor="gml.tc.1" break="no"/>
  <gml:tcmark anchor="gml.tc.2" break="no"/>
  <gml:tcmark anchor="gml.tc.3" break="no"/>
  <gml:tcmark anchor="gml.tc.4" break="no"/>
  <gml:tcmark anchor="gml.tc.5" break="no"/>
  <gml:tcmark anchor="gml.tc.6" break="no"/>
  <gml:tcmark anchor="gml.tc.7" break="no"/>
  <gml:tc action="begin" reserve="2" break="yes"/>
  <gml:tcentry level="0" text="Part One" dot="yes" anchor="gml.tc.1" break="yes"/>
  <gml:tcentry level="1" text="First Chapter" dot="yes" anchor="gml.tc.2" break="yes"/>
  <gml:tcentry level="2" text="1.1 A Section" dot="yes" anchor="gml.tc.3" break="yes"/>
  <gml:tcentry level="pt" text="A line of my own" dot="yes" anchor="gml.tc.4" break="yes"/>
  <gml:tcentry level="3" text="A Subsection" indent="2ch" dot="yes" anchor="gml.tc.5" break="yes"/>
  <gml:tcentry level="4" text="Level four" indent="6ch" dot="no" anchor="gml.tc.6" break="yes"/>
  <gml:tcentry level="1" text="Second Chapter" dot="yes" anchor="gml.tc.7" break="yes"/>
  <gml:tc action="end" reserve="2" break="yes"/>

The page of an entry is left to TeX: the entry carries anchor= (the
gml:tcmark of its heading), and gml.tex's page references give the
page, from its .gmlaux file, on a second TeX run.  With the pass model
(gml -aux: TeX reports the pages to the next pass, test/aux.t) an
entry whose anchor the aux file knows gets page= instead.

  $ printf '.h1 One\n.h2 Two\n.tc\n' > small.gml
  $ gml small.gml | grep -o '<gml:tcentry [^>]*>'
  <gml:tcentry level="1" text="One" dot="yes" anchor="gml.tc.1" break="yes"/>
  <gml:tcentry level="2" text="Two" dot="yes" anchor="gml.tc.2" break="yes"/>

A .tc before the headings is empty in one pass (the heading after it
is the second gml:h); the title is &SYSCONTENT, else CONTENTS; "/"
gives none.

  $ printf '.tc\n.h1 Later\n' > front.gml
  $ gml front.gml | grep -o 'gml:tcentry\|<gml:h level="1" break="yes">[A-Za-z]*'
  <gml:h level="1" break="yes">CONTENTS
  <gml:h level="1" break="yes">
  $ printf '.se SYSCONTENT = Inhalt\n.tc\n' > title.gml
  $ gml title.gml | grep -o '<gml:h [^<]*'
  <gml:h level="1" break="yes">Inhalt
  $ printf '.tc /\n' > none.gml
  $ gml none.gml | grep -c 'gml:h '
  0
  [1]
