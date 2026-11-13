.* dcfdemo.gml - a Starter Set document for the formatting profile
.* share/profile/dcfstarter.gml (the tags are those of the Starter Set,
.* so it runs under -profile starter too).
.*
.*   cd examples && ../gmlpass -set SYSVARH=yes -o out/passes dcfdemo.gml
.*
.* (or mk out/dcfdemo.pdf in examples/): four passes, as with
.* FPASSES(4), so that the forward references, the TOC, the lists of
.* figures and tables and the index have their pages.  In one pass:
.*
.*   ./gmlfmt -to tex -profile dcfstarter -set SYSVARH=yes \
.*       examples/dcfdemo.gml > dcfdemo.tex
.*   TEXINPUTS=.:share/tex: pdftex dcfdemo.tex
.*
.* (forward references then give DSMGML013W and "ID unknown", and gml
.* returns 4, as SCRIPT/VS does after a warning).  In four passes the
.* document formats without a message: return code 0.
:gdoc sec='IBM Internal Use Only'.
:frontm.
:titlep.
:title stitle='Starter Set Formatting'.Formatting the GML Starter Set
:title.with SCRIPT/VS Control Words
:docnum.GML0-0001-0
:date.
:author.A. Programmer
:author.B. Writer
:address.
:aline.Document Composition Department
:aline.1 Main Street
:aline.Anytown, ST 00000
:eaddress.
:etitlep.
:abstract.
:p.This document shows the Starter Set tags formatted by a profile whose
application processing functions are SCRIPT/VS macros: spacing,
indention, fonts, numbering and the title page all come from control
words such as .sk, .in, .of, .bf and .dh.  The appendix gives a few
control words in the document itself.
:preface.
:p.The formatting follows the descriptions in the
:cit.GML Starter Set Implementation Guide:ecit.: headings, lists,
examples, figures and footnotes are spaced and indented as the Starter
Set does it on a page printer.
:toc.
:figlist.
:tlist.
:body.
:h1 id=intro.Introduction
:p.A paragraph of body text.  Words in it may be
:hp1.emphasized:ehp1., :hp2.bold:ehp2. or :hp3.both:ehp3., and a
:q.quotation can contain :q.another one:eq. inside it:eq..
The Starter Set numbers footnotes through the document.:fn.This is the
first footnote.  Its number is raised in the text.:efn.
:i1 id=para.paragraphs
:i2.spacing
:p.A second paragraph follows after three quarters of a line of
space, as Figure 5 of the Implementation Guide specifies for
paragraphs, ordered lists and simple lists.
:p.Tables have a chapter of their own, :hdref refid=tabs page=yes..
:tref refid=planets page=yes. comes later in the document, so this reference
is a forward one: it is resolved on the second pass, like the
reference to the appendix below.
:h2 id=lists.Lists
:p.An ordered list numbers its items; nested lists change the
identifier:
:ol.
:li.The first item of the list, long enough to need a second output line
so that the hanging indention of the item text can be seen.
:li id=second.The second item, which contains a nested list:
:ol compact.
:li.a nested item
:li.another nested item
:eol.
:p.A paragraph inside the second item, after the nested list.
:li.The third item.
:eol.
:p.An unordered list with a nested unordered list and a list part:
:ul.
:li.bullets for the first level
:ul.
:li.dashes for the second level
:eul.
:lp.A list part continues the list without an identifier.
:li.back to the first level
:eul.
:p.A simple list has no identifiers at all:
:sl compact.
:li.alpha
:li.beta
:esl.
:i1.lists
:i2.definition
:h3.Definition and glossary lists
:dl tsize=12.
:dthd.Term
:ddhd.Description
:dt.GML
:dd.Generalized Markup Language: tags that say what a part of the
document is, not how it looks.
:dt.APF
:dd.Application processing function, the macro that a tag is mapped to.
:dt.Too-long-term
:dd.A term wider than the term column is followed by one blank.
:edl.
:gl.
:gt.profile
:gd.The file processed before the document.
:gt.symbol
:gd.A name for a string, written with an ampersand.
:egl.
:h2 id=xmp.Examples and figures
:p.An example keeps its lines as they were entered:
:xmp.
&gml.xmp. shows a colon: tags are processed here too
  an indented line

the line after a blank one
:exmp.
:i1.figures
:p.A figure floats to the top of a page and is numbered:
:fig id=fig1 frame=box.
:xmp.
       +--------+        +--------+
       |  GML   | -----> | SCRIPT |
       +--------+        +--------+
:exmp.
:figcap.The processing of a document
:figdesc.Tags are mapped to macros, which issue control words.
:efig.
:fig id=fig2.
A second figure, with a rule frame.
:figcap.A figure with rules
:efig.
:p.See :figref refid=fig1. for the overview, :figref refid=fig2.
for the second figure, item :liref refid=second. of the first list,
and :hdref refid=lists. for lists.  A reference to a heading that comes
later is a forward reference: :hdref refid=last. (resolved on the second pass).
:note.Cross-references to targets that come later need a second pass.
:lq.
:p.A long quotation is indented on both sides and set off by a line of
space before and after it.
:elq.
:h4.A level four heading
:p.Level four headings are the last numbered ones.
:h5.Run-in heading.
The text of a level five heading continues on the same line.
:h1 id=tabs.Tables
:i1 id=tbls pg=start.tables
:p.A table is described by row definitions (:hp2.&gml.rdef:ehp2.):
the widths of the columns, the space between them, the alignment of
each cell and, with ARRANGE, cells that span several columns or
rows.  Each row of the table names its definition, or takes the one of
the row before.  The tables of this chapter are listed in the front
matter, after the figures.
:i1 seeid=tbls.figures
:i1 seeid=tbls.grid
:h2.A table with a header and a footer
:p.The planets table has a header row and a footer row, which are
repeated at the top and the bottom of every page the table is on
(UG p.58).  Its second column is five picas wide; the first takes one
part of the width that is left, the third two parts.
:ih1 id=cells.cells
:i2.out of order
:i2.footnotes in
:rdef id=planet cwidths='1* 5p 2*' hp='2 0' align='l r c'.
:rdef id=phead cwidths='1* 5p 2*' hp=2 align=c valign=bot.
:table id=planets refid=planet column split=yes.
:thd refid=phead.
:c.Planet:c.Moons:c.Notes
:ethd.
:tft refid=phead.
:c.Planet:c.Moons:c.Notes
:etft.
:row.
:c.Mercury
:c.0
:c.Closest to the Sun.
:row refid=planet.
:c.Venus:c.0:c.It turns the other way.
:row split=no.
:c 3.Our home; these cells are given out of order.
:c 1.Earth
:c 2.1
:row.
:c.Mars:c.2:c.Two small moons.:fn.Both were found in 1877.:efn.
:c.Jupiter:c.95:c.The largest; this row was started by the cell after
the last one.
:tnote.Moon counts change as new moons are found.
:etnote.
:row.
:c.Saturn:c.146:c.The brightest rings.
:row.
:c.Uranus:c.28:c.It spins on its side.
:row.
:c.Neptune:c.16:c.The farthest planet.
:row.
:c.Pluto:c.5
:tcap.Planets of the solar system
:tdesc.The eight planets and one dwarf planet;
the last row leaves its third cell empty.
:etable.
:p.You should see the caption under the table, numbered and
followed by its description after a colon, and the table note: a row
of its own, one cell as wide as the table, after which a
:hp2.&gml.row:ehp2. tag starts the next row (UG p.59).  The Earth row is given
with its cells in the order 3, 1, 2 and is printed in column order; it is also marked
:hp1.split=no:ehp1., so it is never divided between pages.  The
footnote in the Mars row is numbered with the footnotes of the text
and printed at the foot of the page.  The Jupiter row was not
started by a :hp2.&gml.row:ehp2. tag: the cell after the last one
of a row begins a new row.
:h2.Spanning cells
:p.A row definition can arrange its cells in more than one line:
the numbers in each ARRANGE value are the cells, and a number that
is repeated makes the cell span those columns (across) or lines
(down).  In the timetable below, cell 1 spans two columns, cell 2
two lines, and cell 5 the whole width.
:ih1.cells
:i2.spanning
:rdef id=sched arrange='1 1 2'
arrange='3 4 2'
arrange='5 5 5'
cwidths='2i 2i 1.5i' align='c l l r c' valign='top top center'
concat='y y n y y'.
:table id=sched refid=sched width='5.5i'.
:row.
:c.Morning session
:c.Afternoon, in room :hp1.4:ehp1. only
:c 4.Lab work
:c 3.
first line
  second line, indented
third line
:c 5.All day: the registration desk is open.
:tcap.A timetable with spanning cells
:etable.
:p.Cell 3 has :hp1.concat=no:ehp1. in the row definition: its lines
are kept as they were entered, like those of an example, instead of
being joined and filled.  Cell 4 is given before cell 3 and is
right-aligned.
:h2.Repeated cells
:p.A cell number can be given more than once in a row.  The parts
of a repeated cell are printed one under the other and divided by
rules, as in this table without a caption:
:ih1.cells
:i2.repeated
:rdef id=two cwidths='1i *' hp='1 0'.
:table id=steps refid=two.
:row.
:c 1.Steps
:c 2.Unpack the box.
:c 2.Read the leaflet.
:c 2.Switch it on.
:tnote.The second cell is repeated: its parts are divided by rules.
:etnote.
:row.
:c.Result:c.It works.
:etable.
:p.A table without a caption has no number: it is not in the list of
tables, and :hp2.&gml.tref:ehp2. cannot refer to it.  The planets are in
:tref refid=planets page=yes. and the timetable is
:tref refid=sched page=yes.: these references are backward ones, and
:hp1.page=yes:ehp1. asks for the page even when the table is on the
same page as the reference.
:i1 pg=end.tables
:appendix.
:h1 id=last.Control Words Used
:p.The appendix headings are lettered.  The tags of this document are
mapped to macros of the profile, and the macros issue control words;
a document can also give control words itself, between its tags, as
this appendix does.
:i1 pg=major.control words
:i1 seeid=para.text
:h2.Spacing
:iref refid=para.
:p.:hp2..sk:ehp2. skips, :hp2..sp:ehp2. spaces.  A paragraph tag of
this profile is a skip of three quarters of a line and nothing else, so
the control words below go on across paragraphs.
:h2.Indention for a distance
:i1.control words
:i2.indention
:p.With FOR, an indention lasts for a vertical distance: here four
output lines, counted from the first line of text, so the skip of the
paragraph tag before it does not count.
.in +4 for 4
:p.The next four output lines are indented four characters more than
the text around them, wherever a paragraph ends.  The first line of text
starts the count, and the lines are counted as they are printed, not
as they were entered.
:p.The skip between two paragraphs, three quarters of a line here, is
part of the distance.  If the paragraph above is shorter than the
distance, this one begins indented and goes back to the margin of the
text where the four lines end; if not, all of it is at the margin.
:p.With AFTER, the indention starts later: in the next paragraph the
first two lines are at the margin, the next two indented, and the rest
at the margin again.
.in +4 for 2 after 2
:p.Two output lines at the margin of the text, then two output lines
indented by four characters, then the margin again, all in one
paragraph that was entered as eight input lines and is printed as the
lines it needs.  The distances are vertical ones: AFTER and FOR could
as well be given in inches or points, and a skip after the first line
of text is part of them.  A new .in before the end of a duration ends
it at once, and an .in without FOR is a permanent change of the
indention, until the next one.
:h2.One line moved
:i2.one line
:p.Indent line (.il) moves the next output line only, from the margin
that line has.  The next text, skip or space line uses it up, so it is
given after a paragraph tag, whose skip would otherwise take it: in the
next paragraph the first line begins three characters to the right, as
in a book, and the others are at the margin.
:p.
.il 3
This paragraph starts with an indented first line, which was not given
in the text: the control word after the paragraph tag moved it.  The
following lines are at the margin of the text again.
:h2.Centred lines
:i2.centring
:p.The two lines below are centred, each as it was entered:
.ce 2
Tags say what a part of the document is,
control words say how it looks.
:h2.Revision codes
:i2.revision codes
.rc 1 |
.rc 2
:p.Revision code (.rc) marks the text that has changed since the last
edition of a document.  A code has a number, from 1 to 9, and a
character, and it is turned on before the changed text and off after
it.  SCRIPT/VS prints the character beside every output line of that
text; here a rule is drawn beside it, from its first line to its last,
as in the later manuals.
.br
.rc 1 on
:p.This paragraph is new in this edition, and so is the list after it.
The rule begins with the first line of the paragraph and goes on, over
the skips between the paragraphs and the items, until the code is
turned off.
:ul compact.
:li.The rule is beside the items of a list,
:li.beside a table or an example,
:li.and beside the lines of a footnote.:fn.A footnote in revised text
has a rule of its own, where the footnote is printed.:efn.
:eul.
.rc 1 off
:p.The control word does not break, so a revision can begin and end
inside a paragraph.  Of this one only
.rc 1 on
the words of this clause are new,
.rc 1 off
and the rule is beside the line or lines that hold them, however the
paragraph is broken into lines, while the rest of it, which was in the
last edition too, has none.  A .br before the control word ends the
unrevised line first, where a revision must not reach into it.
:p.Codes nest: one turned on while another is on is the active one
until it is turned off.  A code whose character is a blank marks
nothing, so one level of revision can be hidden and another shown.
.br
.rc 1 on
:p.In this revised paragraph
.rc 2 on
this sentence is revised at a level that is not shown, which is why the
rule has a gap beside it, a gap of at least one whole line, because the
sentence was made long enough to fill a line of its own and more.
.rc 2 off
Where it ends, code 1 is the active one again.
.rc 1 off
:p.The rule can be placed at the right of the text, at the inside or
the outside of the page, and nearer to the text or farther from it:
.br
.rc align right
.rc adjust 1
.rc 1 on
:p.this paragraph is marked at the right (.rc align right), one
character away from the end of the line (.rc adjust 1).
.rc 1 off
.rc align left
.rc adjust
:h2.A macro as a symbol
:i2.macro value
.dm motto /Generalized Markup Language/
.dm motto x
:p.The symbol &amp.x below was given the current value of the macro
motto, defined with .dm motto, by the control word .dm motto x:
:q.&x.:eq.
:backm.
:index.
:egdoc.
