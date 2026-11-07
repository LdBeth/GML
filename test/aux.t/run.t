The aux file of the pass model (lib/aux.ml): JOB.gmlaux, written by TeX
(share/tex/gml.tex) in the previous pass, imbedded by gml -aux before
the profile.  It is SCRIPT source: a constant first line ".* gml aux"
and .se lines, pa@ENC = 'FOLIO' (the page an anchor was put out on, at
shipout), pr@N = 'FOLIO' (gml.tex's own auto page references, not used
by the engine) and pq@ENC = VALUE (the answer to a question).  ENC is
the name with "." as "@" (another character than a letter or digit as
#HH), a question id without its "q"; such a name may be longer than
ten characters in this file.  As with any .se, the last line for a
name wins (a question in content that TeX typesets twice is answered
twice).

With -aux every reference to &$PN or &$LC is a question: the hint
gml:query id=qF.L.N what=pn|lc where it is made: the N-th question on
line L of input file F (files numbered by their first question), so
that a decision taken differently on one line changes only the ids of
that line (.se x = & is a reference to &$PN too).
The answer comes from the aux file; a question it does not answer gets
the neutral constant (1, 60).  A .tc entry whose anchor the file knows
gets page= (here gml.tc.1 and the .pt line gml.tc.2; gml.tc.3 is not in
the file: anchor=).

  $ gml -aux in.gmlaux in.gml | grep -o '<gml:query [^>]*>\|<gml:tcentry [^>]*>\|On page[^<]*\|^[0-9].*'
  <gml:query id="q1.2.1" what="pn" break="no"/>
  <gml:query id="q1.3.1" what="lc" break="no"/>
  On page 3 with 41 lines left.
  <gml:tcentry level="1" text="First" dot="yes" page="3" break="yes"/>
  <gml:tcentry level="pt" text="A line of my own" dot="yes" page="iv" break="yes"/>
  <gml:tcentry level="1" text="Second" dot="yes" anchor="gml.tc.3" break="yes"/>
  <gml:query id="q1.7.1" what="pn" break="no"/>
  3 5

A missing aux file is an empty one (the first pass): the questions are
asked, the answers are the constants.

  $ gml -aux missing.gmlaux in.gml | grep -o 'On page[^<]*\|^[0-9].*\|anchor="[^"]*"' | sort -u
  1 1
  On page 1 with 60 lines left.
  anchor="gml.tc.1"
  anchor="gml.tc.2"
  anchor="gml.tc.3"
  anchor="gml.tc.4"

Without -aux there are no questions (one pass, the constants), and
-set gives a page symbol a value that is not asked either.

  $ gml in.gml | grep -c 'gml:query'
  0
  [1]
  $ gml -aux in.gmlaux -set '$LC=20' in.gml | grep -o '<gml:query [^>]*>\|On page[^<]*'
  <gml:query id="q1.2.1" what="pn" break="no"/>
  On page 3 with 20 lines left.
  <gml:query id="q1.7.1" what="pn" break="no"/>

The engine encodes a name the way gml.tex does: tex.xsl's
escape first (t:name: +code+ for a character other than A-Z a-z 0-9 .
-), then "." as "@", any other character as #HH; nothing is decoded.
An anchor gml.tc.1 is pa@gml@tc@1; a hand-made anchor x-y+z would be
pa@x#2Dy#2B43#2Bz.

  $ printf '.pt Entry\n.tc\n' > esc.gml
  $ printf ".* gml aux\n.se pa@gml@tc@1 = 'x&y'\n" > esc.gmlaux
  $ gml -aux esc.gmlaux esc.gml | grep -o 'page="[^"]*"'
  page="x&amp;y"
