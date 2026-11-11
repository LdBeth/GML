.in/.ir FOR v1 AFTER v2 are vertical distances of output (LR
p.210-212): the indention holds for all following lines, new paragraphs
and pages too, until another .in or the end of the distance (r1); blank
lines before the first text line do not count, those after it do (r3,
said of v2; DCF-VERIFY for v1).  The engine sends one hint; gml.tex
keeps the distance left per side (lines are n\baselineskip, here 12pt):
line i of a paragraph starts (i-1) lines after its first, and is moved
if it starts before the distance is used up; a paragraph then uses its
\prevgraf lines, a skip or space its amount.  The profile is
dcfstarter (:p. is .sk .75; its figures and tables have skips of their
own, which count too).  gmllocal.tex traces the shipped boxes; lines.awk prints each line's first letters, shift (left
edge) and width, in points (a character is 5.55994pt).

  $ export TEXINPUTS=../../share/tex:
  $ gml -profile dcfstarter -o in.xml in.gml
  $ transform -s:in.xml -xsl:../../xslt/resolve.xsl -o:in.r.xml
  $ transform -s:in.r.xml -xsl:../../xslt/tex.xsl -o:in.tex
  $ tex -interaction batchmode in.tex > /dev/null

(a) .in 5 for 3: one line of B, the .sk (one line, counted: a text
line came first), the first line of C.  A .sk before the first text
line does not count: D has two lines at 5.  (b) .in 5 for 2 after 1:
E's first line at the old margin, then two lines at 5, the second in
the next paragraph (S, after a .br).  (c) .in cancels it at once.

  $ awk -f lines.awk in.log | sed -n '1,18p'
  Afor         0  469.75499
  Bbbb  27.79968   441.9553
  Cccc  27.79968   441.9553
  cccc         0  469.75499
  Askp         0  469.75499
  Dddd  27.79968   441.9553
  dddd  27.79968   441.9553
  dddd         0  469.75499
  Baft         0  469.75499
  Eeee         0  469.75499
  eeee  27.79968   441.9553
  Ssss  27.79968   441.9553
  ssss         0  469.75499
  Ccan         0  469.75499
  Gggg  27.79968   441.9553
  gggg  27.79968   441.9553
  Hhhh         0  469.75499
  hhhh         0  469.75499

(d) a footnote inside the duration takes none of its lines (its own
lines, at the foot of the page, are not moved: the first page ends
inside G's paragraph).  (e) .il 2 during a
FOR: the next line gets both (7), the FOR goes on (5).  (f) .in 3 for
0.5i after 1: the dimension form, 0.5i = 36.135pt after 12pt: the lines
that start at 12, 24, 36 and 48pt (< 48.135pt).  (g) .of 3 inside a FOR: the offset is
kept in the shape (5, then 5+3, then 3 alone).

  $ awk -f lines.awk in.log | sed -n '19,43p'
  Dfno         0  469.75499
  Tttt  27.79968   441.9553
  wwww  27.79968   441.9553
  wwww  27.79968   441.9553
  wwww         0  469.75499
  wwww         0  469.75499
  Eil.         0  469.75499
  Jjjj  27.79968   441.9553
  Kkkk  38.91956  430.83543
  kkkk  27.79968   441.9553
  kkkk         0  469.75499
  Fdim         0  469.75499
  Uuuu         0  469.75499
  uuuu  16.67981  453.07518
  uuuu  16.67981  453.07518
  uuuu  16.67981  453.07518
  uuuu  16.67981  453.07518
  uuuu         0  469.75499
  Gofs         0  469.75499
  Mmmm  27.79968   441.9553
  mmmm  44.47949   425.2755
  Note         0  469.75499
  nnnn         0  469.75499
  mmmm  44.47949   425.2755
  mmmm  16.67981  453.07518

(h) .ir 5 for 2: two shorter lines.  (i) format off, .in 4 for 2 after
1: each input line is a line; the blank line after Q is the second FOR
line, so R is back at the margin.

  $ awk -f lines.awk in.log | sed -n '44,51p'
  Hrgt         0  469.75499
  Oooo         0   441.9553
  oooo         0   441.9553
  oooo         0  469.75499
  Ifmt         0  469.75499
  Pppp         0  469.75499
  Qqqq  22.23975  447.51524
  Rrrr         0  469.75499

(j) a permanent .in 5 after 1: one line at the old margin (shifted
back by the new one, which \leftskip already has), then the new
margin.  (k) .in 4 after 0.25i: 18.07pt, the lines at 0 and 12pt at
the old margin.  (l) a figure (a \vbox) inside .in 5 for 3 takes none
of its lines, the skip before it (dcfstarter's .sk 1) counts: one line
of Y, one of A.

  $ awk -f lines.awk in.log | sed -n '52,63p'
  Jprm         0  469.75499
  Vvvv -27.79968  497.55467
  vvvv         0  469.75499
  Kdim         0  469.75499
  Xxxx -22.23975  491.99474
  xxxx -22.23975  491.99474
  xxxx         0  469.75499
  Mpic         0  469.75499
  Yyyy  27.79968   441.9553
  Aaaa  27.79968   441.9553
  aaaa         0  469.75499
  aaaa         0  469.75499

(m) the demo of examples/dcfdemo.gml: .in 5 for 4, a paragraph of three
lines, the paragraph skip (.75 line) makes 3.75 lines: the next
paragraph's first line starts before the distance is used up and is
moved, its second is not.  (n) FOR in lines, AFTER a dimension: .in 5
for 2 after 0.25i, the lines at 0 and 12pt at the margin, at 24 and 36pt
(< 18.07 + 24) moved.  (o) a skip at the top of a page (after .pa) is
discarded by TeX and does not count: one line of E, then two of Z.  (p)
a paragraph ended by plain's \endgraf (in.gml makes the note's text an
element, .xs note, and gmllocal.tex ends it with \endgraf) is counted
and shaped: the note's two lines, the skip, then one line
of H.

  $ awk -f lines.awk in.log | sed -n '64,$p'
  Ndem         0  469.75499
  Bbbb  27.79968   441.9553
  bbbb  27.79968   441.9553
  bbbb  27.79968   441.9553
  Cccc  27.79968   441.9553
  cccc         0  469.75499
  Odim         0  469.75499
  Dddd         0  469.75499
  dddd         0  469.75499
  dddd  27.79968   441.9553
  dddd  27.79968   441.9553
  dddd         0  469.75499
  Ptop         0  469.75499
  Eeee  27.79968   441.9553
  Zzzz  27.79968   441.9553
  zzzz  27.79968   441.9553
  zzzz         0  469.75499
  Qeng         0  469.75499
  Note  27.79968   441.9553
  gggg  27.79968   441.9553
  Hhhh  27.79968   441.9553
  hhhh         0  469.75499

in2.gml: .il/.un, boxes, .sa/.re and tables.  lines.awk -v all=1 also
prints the lines of a box (a figure), their shift relative to it.

  $ gml -profile dcfstarter -o in2.xml in2.gml
  $ transform -s:in2.xml -xsl:../../xslt/resolve.xsl -o:in2.r.xml
  $ transform -s:in2.r.xml -xsl:../../xslt/tex.xsl -o:in2.tex
  $ tex -interaction batchmode in2.tex > /dev/null

(q) .il "is triggered by the next text, skip, or space line" (LR p.206
r7): an .il before a paragraph tag is used up by the tag's skip (B's
first line at the margin), one before a .sp by the space (C); after the
tag it moves the paragraph's first line (D, 3 characters).  (r) the
shift is from the margin the line has (r1): .un 2 in .in 6 for 2, 4
then 6; .of 4: its first line at the margin, the next at 4 (Y); .il 2
with the offset in effect, 6 then 4 (G); .il -1 under .in 3, one
character left of that margin (H, 3 in \leftskip).

  $ awk -v all=1 -f lines.awk in2.log | sed -n '1,16p'
  Ailk         0  469.75499
  Bbbb         0  469.75499
  bbbb         0  469.75499
  Cccc         0  469.75499
  Dddd  16.67981  453.07518
  dddd         0  469.75499
  Bund         0  469.75499
  Eeee  22.23975  447.51524
  eeee  33.35962  436.39537
  eeee         0  469.75499
  Yyyy         0  469.75499
  yyyy  22.23975  447.51524
  Gggg  33.35962  436.39537
  gggg  22.23975  447.51524
  Hhhh  -5.55994  475.31493
  hhhh         0  469.75499

(s) a box has a queue of its own: in a figure (format off, a line a
paragraph) .in 4 for 2 moves two lines (K, L), a permanent .in 3
after 1 keeps one line at the old margin (N, the figure's margin:
dcfstarter's .in 2); the text around it is not counted by the figure:
I and the skip before the figure (.sk 1) are the two lines of .in 5
for 2, so P is at the margin.  (t) a footnote's .in 3 for 1 moves its
first line (R, after the line of its mark), the text around it keeps
its three lines (Q).  (The page footings, the page numbers, are left
out.)

  $ awk -v all=1 -f lines.awk in2.log | sed -n '17,30p;38,39p'
  Cbox         0  469.75499
  Iiii  27.79968   441.9553
  Jjjj         0  469.75499
  Kkkk  22.23975  447.51524
  Llll  22.23975  447.51524
  Mmmm         0  469.75499
  Nnnn  -5.55994  475.31493
  Oooo         0  469.75499
  Pppp         0  469.75499
  pppp         0  469.75499
  Dfno         0  469.75499
  Qqqq  27.79968   441.9553
  qqqq  27.79968   441.9553
  qqqq  27.79968   441.9553
  Rrrr  16.67981  453.07518
  rrrr         0  469.75499

(u) .sa saves the distance left (Table 25 note 3: the indention is
saved), .in cancels it (T), .re puts it back: two lines of U.  (.br
before .sa and .re, as LR p.323 r5 advises.)  (v) the rows of a table
are counted (their height): .in 5 for 4, one line of V, the table's
skips (dcfstarter's .sk 0.1i before and after) and its row use up all
but the first line of X (without the row its second would be moved
too).

  $ awk -v all=1 -f lines.awk in2.log | sed -n '31,37p;41,43p'
  Esav         0  469.75499
  Ssss  27.79968   441.9553
  Tttt         0  469.75499
  Uuuu  27.79968   441.9553
  uuuu  27.79968   441.9553
  uuuu         0  469.75499
  Ftbl         0  469.75499
  Vvvv  27.79968   441.9553
  Xxxx  27.79968   441.9553
  xxxx         0  469.75499
