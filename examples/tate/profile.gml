.* profile.gml -- the "tate" tag set: the formatting profile dcfstarter
.* in Japanese, set vertically (tategaki) by tagset.tex.  PDF only, with
.* a pTeX engine:  gmlpass -tex aptex -app examples/tate doc.gml
.* (or the examples' mkfile, out/tategaki.pdf).
.* The title page starts where a vertical line starts, at the top
.* (dcfstarter's default SYSVART is right: the foot of the line here).
.if &E'&SYSVART eq 0 .se SYSVART = left
.im dcfstarter
.*
.* ---- the title page ---------------------------------------------------
.* dcfstarter's .f@tipg spaces 2i, 2i and 1i across the page; here the
.* page is crossed by the lines (the text block is 112mm wide), so the
.* spaces are smaller: the title lines (24-point type: a line pitch of
.* 2.1 body lines), then the date and the authors.
.* (No document number, address or security classification.)
.dm f@tipg on
.pa
.rh sup
.rf sup
.sa
.hy off
.fo &SYSVART
.sp .5i
.bf title
.ls by 2.1
.se *i = 0
...tl
.se *i = &*i + 1
.if &*i gt &f@ttn .go te
.if &*i gt 1 .br
&f@ttl(&*i)
.go tl
...te
.* (a break first: TeX sets a paragraph with the line spacing in effect
.* at its end)
.br
.ls normal
.pf
.sp 1i
.if &L'&f@date eq 0 .go au
&f@date
.sk 1
...au
.se *i = 0
...al
.se *i = &*i + 1
.if &*i gt &f@aun .go end
.br
&f@aut(&*i)
.go al
...end
.br
.re
.rh res
.rf res
.pa
.dm off
.*
.* ---- headings ----------------------------------------------------------
.* dcfstarter's space before and after a heading is across the lines
.* here, from the right edge of the text block toward the left: its
.* 1.3i before a chapter (h0, h1: a new page) would be a third of the
.* block.  A chapter heading begins at the edge; the other headings
.* have less space around them (.dh changes only what it names).
.dh 0 spbf 0 spaf 2
.dh 1 spbf 0 spaf 2
.dh 2 skbf 2 spaf 1
.dh 3 skbf 2 spaf 1
.dh 4 skbf 2 spaf 1
.*
.* ---- paragraphs --------------------------------------------------------
.* A Japanese paragraph begins one full-width character in (字下げ):
.* dcfstarter's :p APFs (f@para, and f@para1 for the first paragraph
.* after a heading) with .il 1mh, the first line indented by the em of
.* the font (the kanji are set at the Latin quad: 1zw).  Not after a
.* run-in heading (the paragraph begins on the heading's line), nor at
.* :pc (a continuation, f@pcont).
.dm f@para on
.sk .75
.il 1mh
.dm off
.dm f@para1 on
.aa p f@para (noatt)
.if &f@hrun eq 0 .sk .75
.if &f@hrun eq 0 .il 1mh
.dm off
.*
.* ---- literals (dcfstarter's, starterset.gml's quotation marks) ------
.se f@l@note '注：
.se f@l@fig '図
.se f@l@app '付録
.se f@l@docnm '文書番号
.se f@l@page 'p.
.se f@l@abs '概要
.se f@l@pref 'まえがき
.se f@l@index '索引
.se f@l@toc '目次
.se f@l@flist '図目次
.se f@l@tbl '表
.se f@l@tlist '表目次
.se oqq '「
.se cqq '」
.se oq '『
.se cq '』
.* &date: 1986年6月13日 (starterset.gml's rules for the year)
.se *y = &SYSYEAR
.if &L'&SYSYEAR eq 2 .se *y = 20&SYSYEAR
.se *m = &SYSMONTH + 0
.se *d = &SYSDAYOFM + 0
.se date '&*y.年&*m.月&*d.日
.*
.* ---- :ruby.日:rt.に:ert.本:rt.ほん:ert.:eruby. ----------------------------
.* The bases and their readings interleaved, as in HTML: each :rt is
.* the reading of the text before it.  Elements under dcfstarter too
.* (elem on the tags; dcfstarter's default rules say noelem): tex.xsl
.* pairs them and places the readings, tagset.tex sets them.
.* The widths come from the passes: :rt numbers its pair (k=, in the
.* order of the document); TeX writes the measured widths of the pair
.* to the aux file (.se px@rbw(k) = base, .se px@rbr(k) = reading, in
.* sp), and the next pass puts them on the :rt (bw= rw=).  px@ is the
.* aux prefix of a tag set's own symbols: they are not carried to the
.* symbol file (so the passes' JOB.sym do not differ by them).  Without
.* them (the first pass) tex.xsl estimates the widths from the characters.
.se rb@k = 0
.dm rubyapf on
.dm off
.dm rtapf on
.se rb@k = &rb@k + 1
.xa k=&rb@k
.if &L'&px@rbw(&rb@k) gt 0 .if &L'&px@rbr(&rb@k) gt 0 .xa bw=&px@rbw(&rb@k) rw=&px@rbr(&rb@k)
.dm off
.aa ruby rubyapf (elem) rubyapf (elem)
.aa rt rtapf (elem) rubyapf (elem)
.* :ert is needed only before the next base text: a reading is closed
.* implicitly by the next :rt and by :eruby (the .xd model), as in HTML.
.xd rt closedby=rt
