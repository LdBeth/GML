.* dcfstarter.gml - a Starter Set document for the formatting profile
.* share/profile/dcfstarter.gml (the tags are those of the Starter Set,
.* so it runs under -profile starter too).
.*
.*   ./gmlfmt -to tex -profile dcfstarter -set SYSVARH=yes \
.*       examples/dcfstarter.gml > dcfstarter.tex
.*   TEXINPUTS=.:share/tex: aptex dcfstarter.tex     (twice: page refs)
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
:p.A figure floats to the top of a page and is numbered:
:fig id=fig1 frame=box.
       +--------+        +--------+
       |  GML   | -----> | SCRIPT |
       +--------+        +--------+
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
later is a forward reference: :hdref refid=last. (one pass).
:note.Cross-references to targets that come later need a second pass.
:lq.
:p.A long quotation is indented on both sides and set off by a line of
space before and after it.
:elq.
:h4.A level four heading
:p.Level four headings are the last numbered ones.
:h5.Run-in heading.
The text of a level five heading continues on the same line.
:appendix.
:h1 id=last.Control Words Used
:p.The appendix headings are lettered.
:i1 pg=major.control words
:i1 seeid=para.text
:h2.Spacing
:p.:hp2..sk:ehp2. skips, :hp2..sp:ehp2. spaces.
:backm.
:index.
:egdoc.
