.* dcfdemo.gml - a Starter Set document for the formatting profile
.* share/profile/dcfstarter.gml (the tags are those of the Starter Set,
.* so it runs under -profile starter too).
.*
.*   cd examples && ../gmlpass -set SYSVARH=yes -o out dcfdemo.gml
.*
.* (or mk out/dcfdemo.pdf in examples/): four passes, as with
.* FPASSES(4), so that the forward references, the TOC, the lists of
.* figures and tables and the index have their pages.  In one pass:
.*
.*   ./gmlfmt -to tex -profile dcfstarter -set SYSVARH=yes \
.*       examples/dcfdemo.gml > dcfdemo.tex
.*   TEXINPUTS=.:share/tex: pdftex dcfdemo.tex
.*
.* (forward references then give DCFS020W and "ID unknown").
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
words such as .sk, .in, .of, .bf and .dh.
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
:p.The appendix headings are lettered.
:i1 pg=major.control words
:i1 seeid=para.text
:h2.Spacing
:iref refid=para.
:p.:hp2..sk:ehp2. skips, :hp2..sp:ehp2. spaces.
:backm.
:index.
:egdoc.
