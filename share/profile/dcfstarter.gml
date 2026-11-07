.* ------------------------------------------------------------------------
.* dcfstarter.gml: the GML Starter Set as a FORMATTING profile.
.*
.* "gml -profile dcfstarter doc.gml".  The tags and attributes are those
.* of the Starter Set (SH20-9186-06 User's Guide; SH35-0050-2
.* Implementation Guide, cited IG p.n), so a document written for
.* -profile starter (or for DCF itself) runs unchanged.  Unlike
.* starter.gml, which only builds a semantic tree for the XSLT stages,
.* the APFs here do the formatting the DCF way: SCRIPT/VS control words
.* (SH35-0069-3 Text Programmer's Guide, cited TPG p.n), symbols and
.* counters, as a real Release 3 profile does.  The result is a stream
.* of formatting hints that a layout engine (TeX in hint mode: gml -tex,
.* or tex.xsl, which picks it because .df/.dh/.dr come before the first
.* element) turns into pages.
.*
.* This is NOT IBM's DSMPROF3.  It is written from the documented
.* behaviour (the IG's descriptions of the formatted result, Figure 5
.* indention and skips, Figure 6 page printer fonts, TPG Figure 14 head
.* levels); none of IBM's macro code is used.  Its macros are named
.* f@xxxx, its state symbols f@xxxx (lower case: symbol names are case
.* sensitive), its cross-reference symbols fh@ID, fg@ID ... (below).
.*
.* Design.
.*  - Every tag maps to an APF with the NOELEM rule (the default rules
.*    below): the tree has no automatic elements, because the hints do
.*    the layout.  The few elements kept are made explicitly with
.*    .xs/.xe where a later stage needs them: the section elements
.*    frontm body appendix backm, the h0-h6 heading elements (resolve.xsl
.*    builds the :toc entries and their page references from them), toc
.*    and figlist (where resolve.xsl puts those lists), fig (the float in
.*    TeX hint mode) and figcap (the figure list).
.*  - Margins are absolute: &f@tm is the text left margin in characters
.*    (&f@rm the right one); every structure computes its .in/.ir from
.*    them and restores them at its end, so nesting does not depend on
.*    the formatter's own &$IN.
.*  - Numbers (headings, figures, footnotes, list items) are counted
.*    here, in one pass, and written into the text.  A reference
.*    (:hdref :figref :fnref :liref) is resolved from symbols set when
.*    its target was processed: a backward reference prints the target
.*    (and "on page n" when the target's &$PN differs from the current
.*    one, or with page=yes); a FORWARD reference finds no symbol on the
.*    first pass (&$PASS = 1), gives message DCFS020W and prints the
.*    Starter Set's "ID unknown" text.  DCF-VERIFY: with TWOPASS the
.*    symbols of pass 1 would be kept for pass 2; the engine has one pass.
.*  - Context checking follows the Starter Set's scheme: a tag that is
.*    valid only inside a structure (:li, :dt, :figcap, :title, :aline
.*    ...) is mapped to f@cntx until the structure starts and again when
.*    it ends; f@cntx gives DCFS002W and drops the tag (its text stays).
.*    A heading or a document section ends every open structure (lists,
.*    quotations, examples, figures, footnotes) with DCFS003W.
.*  - Page numbering: front matter in roman numerals, the body restarts
.*    at arabic 1 (.pa 1, .pn roman|arabic).  The running footing (.rf,
.*    redefined at each :h0/:h1 and section) is the short heading on the
.*    left and the page number on the right (.sx with the page number
.*    symbol &, the default of .dc PS); the running heading is the
.*    security classification (:gdoc sec=) centred.
.*  - TOC: in DCF the .hN words write TC entries (.dh n tc: h0-h4 in
.*    the body, appendix and back matter, none in the front matter) and
.*    .tc prints them (TPG p.151-157), each entry referring to its
.*    heading's anchor for the page.  A .tc at the front sees only the
.*    entries of a previous pass, so :toc issues it with TWOPASS
.*    (&$TWO); in one pass it makes an empty toc element, which
.*    resolve.xsl fills from the h0-h4 elements (the heading APFs wrap
.*    their .hN in an hN element).  The numbers are in the heading text
.*    (the profile numbers), so in hint mode the TOC and figure list
.*    print no numbers of their own.
.*  - Index: :i1 :i2 :i3 :ih1 :ih2 :ih3 :iref give .pi entries (TPG
.*    p.213-218); :index places them with .ix.
.*  - Tables (:table :row :c, Rel 3.2) are not formatted yet: the tags
.*    are out of context (DCFS002W).  :psc and :l are not done either.
.*
.* Known limits: an APF's .gs scan takes the residual text up to the
.* next tag (IG p.9), so a tag inside a heading, title or index term
.* ends the text there and the rest follows as ordinary text, as in DCF
.* (the Starter Set forbids tags in a heading, SH20-9186-06 p.13).
.* ------------------------------------------------------------------------
.*
.* ---- delimiters and processing (IG p.21 items 9-13) ---------------------
.dc gml : :e
.dc cont 03
.ms on
.gs tag on
.* every tag: attributes scanned, no value attributes, no element
.gs rules (att novat stop nomsg noelem) (noatt noelem)
.*
.* ---- symbols for text --------------------------------------------------------
.* &gml. &amp. &semi. are protected by the output translation (TPG
.* p.259), so they are not read again as a tag, symbol or separator;
.* hex codes are EBCDIC (7a 50 5e: colon, ampersand, semicolon; 41 the
.* required blank).
.se gml '&X'01.
.se amp '&X'02.
.se semi '&X'04.
.tr 01 7a 02 50 04 5e
.se rbl '&X'41.
.*
.* ---- literals (change them for another language) ---------------------
.se f@l@note 'Note:
.se f@l@fig 'Figure
.se f@l@app 'Appendix
.se f@l@docnm 'Document Number
.se f@l@page 'on page
.se f@l@abs 'Abstract
.se f@l@pref 'Preface
.se f@l@index 'Index
.se f@l@toc 'Table of Contents
.se f@l@flist 'List of Illustrations
.se f@l@hunk 'Heading ID unknown
.se f@l@funk 'Figure ID unknown
.se f@l@lunk 'LI ID unknown
.* a prefix for numbered body :h1 headings ("Chapter"), null: none (IG
.* p.22 item 17); give it with -set f@bodyh1=Chapter
.if &E'&f@bodyh1 eq 0 .se f@bodyh1 = ''
.* quotation marks by :q nesting (odd, even levels)
.se f@oq1 '“
.se f@cq1 '”
.se f@oq2 '‘
.se f@cq2 '’
.* list item identifiers: unordered by nesting of :ul, ordered by
.* nesting of :ol (IG p.21 item 14: "1. a. 1) a) i. i)")
.se f@ubul(1) '•
.se f@ubul(2) '–
.se f@ubul(3) '*
.se f@sbul '*
.*
.* ---- &date and &time (as the Starter Set: "November 18th, 1983") -------
.se f@mon(1) = January
.se f@mon(2) = February
.se f@mon(3) = March
.se f@mon(4) = April
.se f@mon(5) = May
.se f@mon(6) = June
.se f@mon(7) = July
.se f@mon(8) = August
.se f@mon(9) = September
.se f@mon(10) = October
.se f@mon(11) = November
.se f@mon(12) = December
.se *d = &SYSDAYOFM + 0
.se *m = &SYSMONTH + 0
.se *s = th
.if &*d eq 1 .or &*d eq 21 .or &*d eq 31 .se *s = st
.if &*d eq 2 .or &*d eq 22 .se *s = nd
.if &*d eq 3 .or &*d eq 23 .se *s = rd
.* &SYSYEAR is 00-99 (TPG p.241); a 2-digit year is taken as 20xx (EXT)
.se *y = &SYSYEAR
.if &L'&SYSYEAR eq 2 .se *y = 20&SYSYEAR
.se date '&f@mon(&*m) &*d.&*s., &*y
.se time '&SYSHOUR.:&SYSMINUTE
.*
.* ---- SYSVARs (IG p.19) ----------------------------------------------------
.* SYSVARH yes (or a start number): number the headings h1-h4;
.* SYSVART right|left|center|no: the title page alignment (no: none).
.if &E'&SYSVARH eq 0 .se SYSVARH = no
.if &E'&SYSVART eq 0 .se SYSVART = right
.se f@hnum = 0
.if &U'&SYSVARH eq YES .se f@hnum = 1
.if &T'&SYSVARH eq N .se f@hnum = 1
.*
.* ---- fonts: the page printer column of IG Figure 6 -------------------------
.* (hiN: highlight levels; hdN: headings; TYPE(...) changes the body font
.* into its bold/italic version at a size; UP capitalises.)
.df hi0 type(normal)
.df hi1 type(italic)
.df hi2 type(bold)
.df hi3 type(bold italic)
.df hd0 type(bold 20 italic)
.df hd1 type(bold 20)
.df hd2 type(bold 18 italic)
.df hd3 type(bold 14)
.df hd4 type(bold 12 italic)
.df hd5 type(bold)
.df hd6 type(bold italic)
.* the title page (DCF-VERIFY: the title size) and examples (a mono face)
.df title type(bold 24)
.df xmp type('courier')
.* the raised footnote numbers
.df f@sup type(7)
.*
.* ---- rules (IG p.22 item 16): figures in the default weight, a lighter
.* footnote leader
.dr f@frule
.dr f@fnrule weight .2mm
.*
.* ---- head levels: TPG Figure 14 with the Starter Set's spacing (IG
.* p.22 item 24: 1.3i before h0/h1, 5 and 3 lines after them, 3 skips
.* before and 2 after h2-h4; h5/h6 run in) ----------------------------------
.dh 0 pa spbf 1.3i spaf 5 font hd0 up nohy left nto
.dh 1 pa spbf 1.3i spaf 3 font hd1 up nohy left
.dh 2 skbf 3 spaf 2 font hd2 up nohy left
.dh 3 skbf 3 spaf 2 font hd3 nohy left
.dh 4 skbf 3 spaf 2 font hd4 nohy left
.dh 5 skbf 1 nbr font hd5 nohy
.dh 6 skbf 1 nbr font hd6 nohy
.*
.* ---- footnote leader (IG p.22 item 21: 16 spaces long) --------------------
.fn leader
.sp 1
.hr f@fnrule 0 for 16
.fn off
.*
.* ---- state --------------------------------------------------------------
.* f@sect   the open section element (frontm body appendix backm), or null
.* f@tm/rm  the text margins (characters)
.* f@ln     list nesting; per list n: f@lt(n) type (o u s d g), f@lw(n)
.*          indent, f@lo(n) the margin outside the list, f@lk(n) the
.*          item skip (0: compact), f@lx(n) items so far, f@ld(n) a
.*          term is pending (d g), f@lh(n) term highlight, f@lj(n)
.*          heading highlight, f@lb(n) missed-tab mode (dl break), f@lu(n)
.*          depth among lists of the same kind (identifiers), f@lg(n) the
.*          end tag name
.* f@qn     :q nesting; f@lq the :lq nesting, f@qm(n)/f@qr(n) the margins
.* f@inxmp f@infig f@incap f@infn f@intp  open example, figure, figure
.*          caption, footnote, title page
.* f@h1c..f@h4c  heading counters; f@fign, f@fnn  figure and
.*          footnote counters; f@shead the short heading of the footing
.se f@sect = ''
.se f@tm = 0
.se f@rm = 0
.se f@ln = 0
.se f@olev = 0
.se f@ulev = 0
.se f@qn = 0
.se f@lq = 0
.se f@inxmp = 0
.se f@infig = 0
.se f@incap = 0
.se f@infn = 0
.se f@intp = 0
.se f@h1c = 0
.se f@h2c = 0
.se f@h3c = 0
.se f@h4c = 0
.se f@fign = 0
.se f@fnn = 0
.se f@shead = ''
.se f@sec = ''
.se f@i1 = ''
.se f@i2 = ''
.se f@it = ''
.*
.* ---- messages ---------------------------------------------------------
.* .f@msg n [word...]: a warning (DCF style "DCFSnnnW text").
.dm f@msg on
.go m&*1
...m2
.mg /DCFS002W/Tag &$GML.&*2 is out of context and is ignored./
.me
...m3
.mg /DCFS003W/Tag &$GML.&*2 was not ended before tag &$TAGD.&$TAG../
.me
...m4
.mg /DCFS004W/Tag &$TAGD.&$TAG. found but no &*2 is open./
.me
...m5
.mg /DCFS005W/Tag &$TAGD.&$TAG. does not match the open list &$GML.&*2../
.me
...m10
.mg /DCFS010W/Term &*2 has no description before tag &$TAGD.&$TAG../
.me
...m11
.mg /DCFS011W/Description without a term at tag &$TAGD.&$TAG../
.me
...m12
.mg /DCFS012W/Tag &$TAGD.&$TAG. requires the &*2 attribute./
.me
...m13
.mg /DCFS013W/Identifier &*2 is defined more than once./
.me
...m14
.mg /DCFS014W/A &*2 cannot be nested in a &*3../
.me
...m20
.mg /DCFS020W/Reference to &*2 is undefined or forward (one pass)./
.me
.dm off
.*
.* f@cntx: the APF of a tag that is out of context.
.dm f@cntx on
.f@msg 2 &$TAG
.dm off
.*
.* the out-of-context mappings
.dm f@lcnx on
.aa li f@cntx (noatt)
.aa lp f@cntx (noatt)
.aa dthd f@cntx (noatt)
.aa ddhd f@cntx (noatt)
.aa dt f@cntx (noatt)
.aa dd f@cntx (noatt)
.aa gt f@cntx (noatt)
.aa gd f@cntx (noatt)
.dm off
.dm f@tcnx on
.aa title f@cntx (noatt)
.aa docnum f@cntx (noatt)
.aa date f@cntx (noatt)
.aa author f@cntx (noatt)
.dm off
.dm f@fcnx on
.aa figcap f@cntx (noatt)
.aa figdesc f@cntx (noatt)
.dm off
.*
.* ---- margins ------------------------------------------------------------
.* .f@marg: set the formatter's margins from &f@tm and &f@rm.
.dm f@marg on
.in &f@tm
.ir &f@rm
.dm off
.*
.* ---- running heading and footing ---------------------------------------
.* .f@runf: the footing with the current short heading on the left and
.* the page number (the page number symbol &) on the right; redefined
.* whenever the short heading changes (DCF processes a running footing
.* where it is defined, TPG p.127).
.dm f@runf on
.rf on
.bf hi0
.sx |&f@shead.||&|
.pf
.rf off
.dm off
.* .f@runh: the security classification centred at the top
.dm f@runh on
.if &L'&f@sec eq 0 .me
.rh on
.bf hi2
.ce &f@sec
.pf
.rh off
.dm off
.*
.* ---- ending open structures (before headings and sections) -------------
.dm f@rset on
.if &f@infn ne 0 .f@msg 3 fn
.if &f@infn ne 0 .f@efn
.if &f@inxmp ne 0 .f@msg 3 xmp
.if &f@inxmp ne 0 .f@exmp
.if &f@infig ne 0 .f@msg 3 fig
.if &f@infig ne 0 .f@efig
...lq
.if &f@lq eq 0 .go ls
.f@msg 3 lq
.f@elq
.go lq
...ls
.if &f@ln eq 0 .go rest
.f@msg 3 &f@lg(&f@ln)
.f@lend
.go ls
...rest
.if &f@qn gt 0 .f@msg 3 q
.se f@qn = 0
.se f@tm = 0
.se f@rm = 0
.f@marg
.f@lcnx
.f@fcnx
.dm off
.*
.* ---- document sections ---------------------------------------------------------
.* .f@sect name: end the open section element and start another one
.dm f@sect on
.f@rset
.if &L'&f@sect gt 0 .xe &f@sect
.se f@sect = &*1
.xs &*1
.dm off
.dm f@gdoc on
.gs attval sec
.se f@sec '&SEC
.f@runh
.f@runf
.dm off
.dm f@egdoc on
.f@rset
.if &L'&f@sect gt 0 .xe &f@sect
.se f@sect = ''
.dm off
.* .f@tc tc|ntc: table of contents entries for h0-h4 (TPG p.151-157;
.* none for the front matter, as IBM's DSMFRONT)
.dm f@tc on
.dh 0 &*1
.dh 1 &*1
.dh 2 &*1
.dh 3 &*1
.dh 4 &*1
.dm off
.* front matter: roman page numbers from i
.dm f@front on
.f@sect frontm
.f@tc ntc
.pa 1
.pn roman
.dm off
.* the body: arabic page numbers from 1; the heading counters restart
.dm f@body on
.f@sect body
.f@tc tc
.pa 1
.pn arabic
.se f@h1c = 0
.se f@shead = ''
.f@runf
.dm off
.dm f@appd on
.f@sect appendix
.f@tc tc
.pa
.se f@h1c = 0
.dm off
.dm f@backm on
.f@sect backm
.f@tc tc
.pa
.se f@shead = ''
.f@runf
.dm off
.* .f@shd text: a front or back matter heading (level 1, no number)
.dm f@shd on
.f@rset
.pa
.se f@shead '&*
.f@runf
.h1 &*
.dm off
.dm f@abstr /.f@shd &f@l@abs
.dm f@pref /.f@shd &f@l@pref
.* :toc: with TWOPASS (&$TWO) the DCF way, .tc (TPG p.156-157: the
.* entries of the previous pass); in one pass a .tc here would be empty,
.* so resolve.xsl writes the list into the toc element instead.
.* :figlist: resolve.xsl writes the list into the figlist element.
.dm f@toc on
.f@rset
.pa
.se f@shead '&f@l@toc
.f@runf
.if &$TWO eq 1 .tc &f@l@toc
.if &$TWO eq 1 .me
.xs toc
.xe toc
.dm off
.dm f@flist on
.f@rset
.pa
.se f@shead '&f@l@flist
.f@runf
.xs figlist
.xe figlist
.dm off
.* :index: the entries of the .pi words (TPG p.217: .ix)
.dm f@index on
.f@rset
.pa
.se f@shead '&f@l@index
.f@runf
.ix &f@l@index
.dm off
.*
.* ---- title page (IG p.45-52) ---------------------------------------------
.* The title page tags only collect: the page is formatted by
.* :etitlep, right aligned (SYSVART), no running heading or footing.
.dm f@ttlp on
.f@rset
.se f@intp = 1
.se f@ttn = 0
.se f@aun = 0
.se f@adn = 0
.se f@docnm = ''
.se f@date = ''
.aa title f@title
.aa docnum f@docnm (noatt)
.aa date f@date (noatt)
.aa author f@auth (noatt)
.dm off
.dm f@title on
.gs attval stitle
.gs scan *t
.se f@ttn = &f@ttn + 1
.se f@ttl(&f@ttn) '&*t
.if &L'&STITLE gt 0 .se f@shead '&STITLE
.if &L'&STITLE eq 0 .if &f@ttn eq 1 .se f@shead '&*t
.dm off
.dm f@docnm on
.gs scan *t
.se f@docnm '&*t
.dm off
.* :date without text: the processing date
.dm f@date on
.gs scan *t
.se f@date '&*t
.if &L'&*t eq 0 .se f@date '&date
.dm off
.dm f@auth on
.gs scan *t
.se f@aun = &f@aun + 1
.se f@aut(&f@aun) '&*t
.dm off
.* :address/:aline: on the title page collected; elsewhere a block of
.* lines indented as a long quotation
.dm f@addr on
.aa aline f@aline (noatt)
.if &f@intp ne 0 .me
.sk 1
.se f@ao = &f@tm
.se f@tm = &f@tm + 3
.f@marg
.dm off
.dm f@eaddr on
.aa aline f@cntx (noatt)
.if &f@intp ne 0 .me
.br
.se f@tm = &f@ao
.f@marg
.sk 1
.dm off
.dm f@aline on
.gs scan *t
.if &f@intp ne 0 .go tp
.br
&*t
.me
...tp
.se f@adn = &f@adn + 1
.se f@adl(&f@adn) '&*t
.dm off
.dm f@ettlp on
.if &f@intp ne 0 .go ok
.f@msg 4 titlep
.me
...ok
.se f@intp = 0
.f@tcnx
.if &U'&SYSVART eq NO .me
.f@tipg
.dm off
.* .f@tipg: the title page.  2 inches down, the title lines in the
.* title font with a little more line spacing, then (each set off by
.* space) the document number, the date, the authors, the address
.* lines and the security classification.
.dm f@tipg on
.pa
.rh sup
.rf sup
.sa
.hy off
.fo &SYSVART
.sp 2i
.bf title
.ls by 1.2
.se *i = 0
...tl
.se *i = &*i + 1
.if &*i gt &f@ttn .go te
.if &*i gt 1 .br
&f@ttl(&*i)
.go tl
...te
.ls normal
.pf
.sp 2i
.if &L'&f@docnm eq 0 .go dt
&f@l@docnm &f@docnm
.sk 2
...dt
.if &L'&f@date eq 0 .go au
.br
&f@date
.sk 2
...au
.if &f@aun eq 0 .go ad
.sp 1i
.se *i = 0
...al
.se *i = &*i + 1
.if &*i gt &f@aun .go ad
.br
&f@aut(&*i)
.go al
...ad
.if &f@adn eq 0 .go sc
.sk 1
.se *i = 0
...dl
.se *i = &*i + 1
.if &*i gt &f@adn .go sc
.br
&f@adl(&*i)
.go dl
...sc
.if &L'&f@sec eq 0 .go end
.sp .5i
.bf hi2
&f@sec
.pf
...end
.br
.re
.rh res
.rf res
.pa
.dm off
.*
.* ---- headings (IG p.75-83) ---------------------------------------------------
.* .f@hd n: the APF of :hN [id=] [stitle=].  The text is numbered
.* (SYSVARH: h1 "1.0", h2 "1.1", h3 "1.1.1", h4 "1.1.1.1"; in the
.* appendix h1 is always "Appendix A." and h2-h4 "A.1" ...; a body h1
.* with &f@bodyh1 is "Chapter 1."), then formatted by .hN with the
.* .dh definition of its level inside an hN element (for :toc).  Level
.* 0 and 1 start a page: the .pa comes before the element, so that a
.* page reference to the heading names the new page.  The reference
.* symbols: fh@ID the heading text, fp@ID its page.
.dm f@hd on
.f@rset
.gs attval id stitle
.gs scan *t
.se *l = &*1
.se *n = ''
.se *p = ''
.if &*l eq 0 .go cnt
.if &*l gt 4 .go cnt
.* count
.if &*l eq 1 .se f@h1c = &f@h1c + 1
.if &*l eq 1 .se f@h2c = 0
.if &*l le 2 .se f@h3c = 0
.if &*l le 3 .se f@h4c = 0
.if &*l eq 2 .se f@h2c = &f@h2c + 1
.if &*l eq 3 .se f@h3c = &f@h3c + 1
.if &*l eq 4 .se f@h4c = &f@h4c + 1
.if &f@sect eq frontm .go cnt
.if &f@sect eq backm .go cnt
.se *c = &f@h1c
.if &f@sect eq appendix .se *c = &A'&f@h1c
.* prefixed level 1: always numbered
.if &*l ne 1 .go num
.if &f@sect eq appendix .se *p '&f@l@app &*c..
.if &f@sect eq body .if &L'&f@bodyh1 gt 0 .se *p '&f@bodyh1 &*c..
.if &L'&*p gt 0 .go cnt
...num
.if &f@hnum eq 0 .go cnt
.if &*l eq 1 .se *n '&*c..0
.if &*l eq 2 .se *n '&*c..&f@h2c
.if &*l eq 3 .se *n '&*c..&f@h2c..&f@h3c
.if &*l eq 4 .se *n '&*c..&f@h2c..&f@h3c..&f@h4c
...cnt
.se *x '&*t
.if &L'&*p gt 0 .se *x '&*p &*t
.if &L'&*n gt 0 .se *x '&*n.&rbl.&rbl.&*t
.* the reference text: a prefixed heading keeps its label
.se *r '&*t
.if &L'&*p gt 0 .se *r '&*x
.* the short heading of the running footing
.if &*l gt 1 .go el
.pa
.se f@shead '&*x
.if &L'&STITLE gt 0 .se f@shead '&STITLE
.f@runf
...el
.if &L'&ID eq 0 .xs h&*l
.if &L'&ID eq 0 .go hd
.xs h&*l id=&ID
.se *k = &U'&ID
.if &E'&fh@&*k eq 1 .f@msg 13 &ID
.se fh@&*k '&*r
.se fp@&*k = &$PN
...hd
.h&*l &*x
.xe h&*l
.aa p f@para1 (noatt)
.dm off
.dm f@hd0 /.f@hd 0
.dm f@hd1 /.f@hd 1
.dm f@hd2 /.f@hd 2
.dm f@hd3 /.f@hd 3
.dm f@hd4 /.f@hd 4
.dm f@hd5 /.f@hd 5
.dm f@hd6 /.f@hd 6
.*
.* ---- paragraphs and notes (IG Figure 5: skip .75) -------------------------
.dm f@para /.sk .75
.* the first paragraph after a heading: the heading's space after is
.* enough (a .sk after a heading is conditional anyway, TPG p.152)
.dm f@para1 on
.aa p f@para (noatt)
.sk .75
.dm off
.dm f@pcont /.sk .75
.dm f@note on
.sk .75
.bf hi2
&f@l@note
.pf
.dm off
.*
.* ---- lists (IG p.97-110, Figure 5) -------------------------------------------
.* An item: the margin at the label (the list's margin less its
.* indent), an offset of the indent for the lines after the first
.* (.of, TPG p.80), the identifier, and an immediate tab (.is TO, TPG
.* p.89) to the text position.
.* .f@lbeg type indent skip endtag [values...]
.dm f@lbeg on
.sk .75
.se f@ln = &f@ln + 1
.se *n = &f@ln
.se f@lt(&*n) = &*1
.se f@lw(&*n) = &*2
.se f@lk(&*n) = &*3
.se f@lg(&*n) = &*4
.se f@lo(&*n) = &f@tm
.se f@lx(&*n) = 0
.se f@ld(&*n) = 0
.se f@lh(&*n) = 2
.se f@lj(&*n) = 3
.se f@lb(&*n) = blank
.se f@lu(&*n) = 0
.if &*1 eq o .se f@olev = &f@olev + 1
.if &*1 eq o .se f@lu(&*n) = &f@olev
.if &*1 eq u .se f@ulev = &f@ulev + 1
.if &*1 eq u .se f@lu(&*n) = &f@ulev
.* value attributes: compact, break
.se *i = 4
...va
.se *i = &*i + 1
.if &*i gt &*0 .go set
.se *v = &U'&*&*i
.if &*v eq COMPACT .se f@lk(&*n) = 0
.if &*v eq BREAK .se f@lb(&*n) = break
.go va
...set
.se f@tm = &f@tm + &f@lw(&*n)
.f@marg
.f@lmap &*1
.dm off
.* :ol :ul :sl: indent 4, skip .75; :dl: indent tsize (10), skip 1;
.* :gl: indent 0, skip .75
.dm f@ol /.f@lbeg o 4 .75 ol &*
.dm f@ul /.f@lbeg u 4 .75 ul &*
.dm f@sl /.f@lbeg s 4 .75 sl &*
.dm f@dl on
.gs attval tsize termhi headhi
.se *w = 10
.if &T'&TSIZE eq N .se *w = &TSIZE
.f@lbeg d &*w 1 dl &*
.if &T'&TERMHI eq N .se f@lh(&f@ln) = &TERMHI
.if &T'&HEADHI eq N .se f@lj(&f@ln) = &HEADHI
.dm off
.dm f@gl on
.gs attval termhi
.f@lbeg g 0 .75 gl &*
.if &T'&TERMHI eq N .se f@lh(&f@ln) = &TERMHI
.dm off
.* .f@lmap type: the item tags of the innermost list
.dm f@lmap on
.f@lcnx
.go x&*1
...xd
.aa dthd f@dthd (noatt)
.aa ddhd f@ddhd (noatt)
.aa dt f@dt (noatt)
.aa dd f@dd (noatt)
.aa lp f@lp (noatt)
.me
...xg
.aa gt f@gt (noatt)
.aa gd f@gd (noatt)
.aa lp f@lp (noatt)
.me
...xo
...xu
...xs
.aa li f@li
.aa lp f@lp (noatt)
.dm off
.* .f@lend: end the innermost list
.dm f@lend on
.se *n = &f@ln
.if &f@ld(&*n) ne 0 .f@msg 10 &f@lt(&*n)
.if &f@lt(&*n) eq o .se f@olev = &f@olev - 1
.if &f@lt(&*n) eq u .se f@ulev = &f@ulev - 1
.se f@tm = &f@lo(&*n)
.se f@ln = &f@ln - 1
.f@marg
.sk .75
.if &f@ln eq 0 .f@lcnx
.if &f@ln gt 0 .f@lmap &f@lt(&f@ln)
.dm off
.* :eol :eul ... (f@elst endtag)
.dm f@elst on
.if &f@ln gt 0 .go ok
.f@msg 4 list
.me
...ok
.if &f@lg(&f@ln) ne &*1 .f@msg 5 &f@lg(&f@ln)
.f@lend
.dm off
.dm f@eol /.f@elst ol
.dm f@eul /.f@elst ul
.dm f@esl /.f@elst sl
.dm f@edl /.f@elst dl
.dm f@egl /.f@elst gl
.* .f@lpos: the margin at the label (&*m) and the item skip
.dm f@lpos on
.se *n = &f@ln
.se f@lx(&*n) = &f@lx(&*n) + 1
.if &f@lk(&*n) ne 0 .sk &f@lk(&*n)
.se f@lm = &f@tm - &f@lw(&*n)
.in &f@lm
.dm off
.* .f@lid: the identifier of the next item into &f@lbl
.dm f@lid on
.se *n = &f@ln
.se *k = &f@lx(&*n)
.se f@lbl = ''
.if &f@lt(&*n) eq u .go u
.if &f@lt(&*n) ne o .me
.* ordered: by depth among ordered lists, cycling every 6 levels
.se *d = &f@lu(&*n) - 1
.se *d = &*d // 6 + 1
.if &*d eq 1 .se f@lbl '&*k..
.if &*d eq 2 .se f@lbl '&a'&*k..
.if &*d eq 3 .se f@lbl '&*k.)
.if &*d eq 4 .se f@lbl '&a'&*k.)
.if &*d eq 5 .se f@lbl '&r'&*k..
.if &*d eq 6 .se f@lbl '&r'&*k.)
.me
...u
.se *d = &f@lu(&*n) - 1
.se *d = &*d // 3 + 1
.se f@lbl '&f@ubul(&*d)
.dm off
.dm f@li on
.gs attval id
.f@lpos
.f@lid
.if &L'&ID eq 0 .go lb
.se *k = &U'&ID
.if &E'&fl@&*k eq 1 .f@msg 13 &ID
.se fl@&*k '&f@lbl
...lb
.if &f@lt(&f@ln) eq s .go s
.of &f@lw(&f@ln)
&f@lbl
.is to &f@lw(&f@ln) min 1 blank
.me
...s
.in &f@tm
.dm off
.* :lp: a list part, at the label position
.dm f@lp on
.sk .75
.se f@lm = &f@tm - &f@lw(&f@ln)
.in &f@lm
.dm off
.* definition and glossary terms: the term in its highlight, an
.* immediate tab to the description (a term longer than the indent: one
.* blank, or with BREAK the description on the next line)
.dm f@term on
.se *n = &f@ln
.if &f@ld(&*n) ne 0 .f@msg 10 &f@lt(&*n)
.se f@ld(&*n) = 1
.f@lpos
.if &f@lt(&*n) eq g .go g
.of &f@lw(&*n)
.bf hi&*1
&f@it
.pf
.is to &f@lw(&*n) min 1 &f@lb(&*n)
.me
...g
.bf hi&*1
&f@it.:
.pf
.dm off
.dm f@dt on
.gs scan f@it
.f@term &f@lh(&f@ln)
.dm off
.dm f@dthd on
.gs scan f@it
.f@term &f@lj(&f@ln)
.dm off
.dm f@gt on
.gs scan f@it
.f@term &f@lh(&f@ln)
.dm off
.dm f@dd on
.if &f@ld(&f@ln) eq 0 .f@msg 11
.se f@ld(&f@ln) = 0
.dm off
.dm f@gd /.f@dd
.dm f@ddhd on
.gs scan *t
.f@dd
.bf hi&f@lj(&f@ln)
&*t
.pf
.dm off
.*
.* ---- long quotations (Figure 5: indent 3 each side, skip 1) -------------------
.dm f@lq on
.se f@lq = &f@lq + 1
.se f@qm(&f@lq) = &f@tm
.se f@qr(&f@lq) = &f@rm
.se f@tm = &f@tm + 3
.se f@rm = &f@rm + 3
.sk 1
.f@marg
.dm off
.dm f@elq on
.if &f@lq gt 0 .go ok
.f@msg 4 lq
.me
...ok
.se f@tm = &f@qm(&f@lq)
.se f@rm = &f@qr(&f@lq)
.se f@lq = &f@lq - 1
.f@marg
.sk 1
.dm off
.*
.* ---- examples (Figure 5: indent 2, skip 1) ------------------------------------------
.* format off: the lines as entered, in the example font, kept on one
.* page if they fit (.kp)
.dm f@xmp on
.if &f@inxmp eq 0 .go ok
.f@msg 14 xmp xmp
.me
...ok
.se f@inxmp = 1
.se f@xo = &f@tm
.se f@tm = &f@tm + 2
.sk 1
.if &f@infig eq 0 .kp on
.f@marg
.bf xmp
.fo off
.dm off
.dm f@exmp on
.if &f@inxmp ne 0 .go ok
.f@msg 4 xmp
.me
...ok
.se f@inxmp = 0
.fo on
.pf
.if &f@infig eq 0 .kp off
.se f@tm = &f@xo
.f@marg
.sk 1
.dm off
.*
.* ---- figures (IG p.115-125; Figure 5: indent 2, skip 1) ----------------------
.* :fig [id=] [frame=rule|box|none|'string'] [place=top|bottom|inline]
.* [width=page|column].  A floating keep (inline: a keep) in a fig
.* element (the float of TeX hint mode, which draws a box frame
.* itself: frame=box is passed on, and .bx inside a fig is not drawn
.* there); the body in format off; a rule frame is a .hr above and
.* below, a string frame a line of it (.sx).
.dm f@fig on
.if &f@infig eq 0 .go ok
.f@msg 14 fig fig
.me
...ok
.gs attval id frame place width
.se f@infig = 1
.se f@incap = 0
.se f@fid = &U'&ID
.se f@fframe = rule
.if &L'&FRAME gt 0 .se f@fframe '&FRAME
.se *u = &U'&f@fframe
.if &*u eq RULE .se f@fframe = rule
.if &*u eq BOX .se f@fframe = box
.if &*u eq NONE .se f@fframe = none
.se *p = top
.if x&U'&PLACE eq xINLINE .se *p = inline
.if x&U'&PLACE eq xBOTTOM .se *p = bottom
.se f@fo = &f@tm
.sk 1
.if &f@fframe eq box .xs fig frame=box place=&*p
.if &f@fframe ne box .xs fig frame=none place=&*p
.if &*p eq inline .kp on
.if &*p ne inline .kp float
.f@ffrm
.se f@tm = &f@tm + 2
.f@marg
.fo off
.aa figcap f@fcap (noatt)
.aa figdesc f@fdesc (noatt)
.dm off
.* .f@ffrm: one side of the frame
.dm f@ffrm on
.if &f@fframe eq none .me
.if &f@fframe eq rule .hr f@frule left right
.if &f@fframe eq rule .me
.if &f@fframe eq box .me
.sx |&f@fframe.|&f@fframe.|&f@fframe.|
.dm off
.* :figcap: "Figure n." in bold, then the caption, in a figcap element
.* for the figure list; fg@ID the number, fq@ID the page.  The caption
.* is scanned so that the element ends with its last word (";" is the
.* control word separator: the text before it has no line end), and a
.* :figdesc colon follows it with .ct.
.dm f@fcap on
.gs scan *t
.se f@fign = &f@fign + 1
.if &L'&f@fid eq 0 .go cap
.if &E'&fg@&f@fid eq 1 .f@msg 13 &f@fid
.se fg@&f@fid = &f@fign
.se fq@&f@fid = &$PN
...cap
.fo on
.sk 1
.xs figcap
.se f@incap = 1
.bf hi2
&f@l@fig &f@fign..
.pf
&*t.;.xe figcap
.dm off
.* :figdesc: after a caption a colon, then the description
.dm f@fdesc on
.if &f@incap eq 0 .go nc
.ct :
.se f@incap = 2
.me
...nc
.fo on
.sk 1
.dm off
.dm f@efig on
.if &f@infig ne 0 .go ok
.f@msg 4 fig
.me
...ok
.fo on
.se f@tm = &f@fo
.f@marg
.f@ffrm
.kp off
.xe fig
.se f@infig = 0
.se f@incap = 0
.f@fcnx
.dm off
.*
.* ---- footnotes (IG p.129-131; Figure 5: skip 1) --------------------------------
.* The number is called out where :fn stands, raised in a smaller font
.* (the Starter Set's "shifts" style for page printers, IG p.130-131:
.* DSM#SUPR changes to a small font and shifts the baseline up); a
.* footnote with an id is called out by :fnref instead (fn@ID).  The
.* footnote starts with its number in the same style.
.* .f@fncall n: &f@fnc is the raised number n (a .dv text variable,
.* TPG p.258-261: a font and a baseline shift)
.dm f@fncall on
.dv f@fnc font f@sup baseline p3 /&*1
.dm off
.dm f@fn on
.if &f@infn eq 0 .go ok
.f@msg 14 footnote footnote
.me
...ok
.gs attval id
.se f@fnn = &f@fnn + 1
.se f@infn = 1
.f@fncall &f@fnn
.if &L'&ID gt 0 .go id
.ct &f@fnc.
.go on
...id
.se *k = &U'&ID
.if &E'&fn@&*k eq 1 .f@msg 13 &ID
.se fn@&*k = &f@fnn
...on
.fn on
.sp 1
&f@fnc.
.dm off
.dm f@efn on
.if &f@infn ne 0 .go ok
.f@msg 4 footnote
.me
...ok
.se f@infn = 0
.fn off
.dm off
.*
.* ---- highlighting, citations, quotations ---------------------------------------
.dm f@hp0 /.bf hi0
.dm f@hp1 /.bf hi1
.dm f@hp2 /.bf hi2
.dm f@hp3 /.bf hi3
.dm f@ehp /.pf
.dm f@cit /.bf hi1
.dm f@ecit /.pf
.* :q / :eq: typographic quotes, double and single by nesting (IG
.* p.21 item 27), joined to the quoted text (.gs insert)
.dm f@q on
.se f@qn = &f@qn + 1
.se *d = &f@qn // 2
.if &*d eq 1 .gs insert &f@oq1
.if &*d eq 0 .gs insert &f@oq2
.dm off
.dm f@eq on
.if &f@qn gt 0 .go ok
.f@msg 4 quotation
.me
...ok
.se *d = &f@qn // 2
.se f@qn = &f@qn - 1
.if &*d eq 1 .gs insert &f@cq1
.if &*d eq 0 .gs insert &f@cq2
.dm off
.*
.* ---- cross-references (IG p.151-156) ---------------------------------------------
.* .f@pgr page yes|no: " on page n" when asked for, or when the target
.* is on another page (&$PN; in a one-pass run the page of a backward
.* target is final)
.dm f@pgr on
.se f@pgt = ''
.if x&U'&*2 eq xNO .me
.if x&U'&*2 eq xYES .go p
.if &*1 eq &$PN .me
...p
.se f@pgt ' &f@l@page &*1
.dm off
.dm f@hdref on
.gs attval refid page
.if &L'&REFID gt 0 .go id
.f@msg 12 refid
.me
...id
.se *k = &U'&REFID
.if &E'&fh@&*k eq 1 .go ok
.f@msg 20 &REFID &f@l@hunk
.gs insert &f@oq1.&f@l@hunk.&f@cq1
.me
...ok
.se *t '&fh@&*k
.se *g = &fp@&*k
.f@pgr &*g &PAGE
.gs insert &f@oq1.&*t.&f@cq1.&f@pgt
.dm off
.dm f@fgref on
.gs attval refid page
.if &L'&REFID gt 0 .go id
.f@msg 12 refid
.me
...id
.se *k = &U'&REFID
.if &E'&fg@&*k eq 1 .go ok
.f@msg 20 &REFID &f@l@funk
.gs insert &f@l@funk
.me
...ok
.se *t = &fg@&*k
.se *g = &fq@&*k
.f@pgr &*g &PAGE
.gs insert &f@l@fig.&rbl.&*t.&f@pgt
.dm off
.dm f@fnref on
.gs attval refid
.se *k = &U'&REFID
.if &E'&fn@&*k eq 1 .go ok
.f@msg 20 &REFID 00
.gs insert (00)
.me
...ok
.se *t = &fn@&*k
.f@fncall &*t
.gs insert &f@fnc.
.dm off
.dm f@liref on
.gs attval refid page
.se *k = &U'&REFID
.if &E'&fl@&*k eq 1 .go ok
.f@msg 20 &REFID &f@l@lunk
.gs insert &f@l@lunk
.me
...ok
.se *t '&fl@&*k
.gs insert &*t
.dm off
.*
.* ---- index (IG p.137-145; TPG p.213-218) -----------------------------------------
.* :i1 :i2 :i3 [id=] [pg=start|end|major|text] [see= | seeid=]:
.* .pi /t1[/t2[/t3]] with START, END or ORDER (major) and the page text
.* as the fourth field; see= makes a REF entry.  :ih1-:ih3 [print=]
.* are terms with no page reference (a null fourth field); print= is
.* the printed term, the tag text its sort key.  :iref refid= adds a
.* page reference to the entry of an index tag with that id (fi@ID,
.* the term path).
.* .f@pi level: the entry for the term in &f@it
.dm f@pi on
.gs attval id pg see seeid print
.se *l = &*1
.se *t '&f@it
.if &*l eq 1 .se f@i1 '&*t
.if &*l eq 1 .se f@i2 = ''
.if &*l eq 2 .se f@i2 '&*t
.se f@ip '/&*t
.se f@is '&*t
.if &*l eq 2 .se f@ip '/&f@i1./&*t
.if &*l eq 2 .se f@is '&f@i1., &*t
.if &*l eq 3 .se f@ip '/&f@i1./&f@i2./&*t
.if &*l eq 3 .se f@is '&f@i1., &f@i2., &*t
.f@piid
.f@piop &PG
.* see= / seeid=: a cross reference instead of a page
.if &L'&SEE gt 0 .go see
.if &L'&SEEID eq 0 .go pg
.se *k = &U'&SEEID
.if &E'&fi@&*k eq 1 .go sid
.f@msg 20 &SEEID ?
.me
...sid
.se SEE '&fs@&*k
...see
.pi ref &f@ip./&SEE
.me
...pg
.if &L'&f@pip gt 0 .pi &f@pio &f@ip.////&f@pip
.el .pi &f@pio &f@ip
.dm off
.* .f@piid: the id of an index tag (fi@ID its path &f@ip, fs@ID its
.* text &f@is)
.dm f@piid on
.if &L'&ID eq 0 .me
.se *k = &U'&ID
.if &E'&fi@&*k eq 1 .f@msg 13 &ID
.se fi@&*k '&f@ip
.se fs@&*k '&f@is
.dm off
.* .f@piop pg: &f@pio the operation, &f@pip a page text
.dm f@piop on
.se f@pio = ''
.se f@pip = ''
.se *v = &U'&*1
.if &L'&*1 eq 0 .me
.if &*v eq START .se f@pio = start
.if &*v eq BEGIN .se f@pio = start
.if &*v eq END .se f@pio = end
.if &*v eq MAJOR .se f@pio = order
.if &L'&f@pio eq 0 .se f@pip '&*
.dm off
.dm f@i1 on
.gs scan f@it
.f@pi 1
.dm off
.dm f@i2 on
.gs scan f@it
.f@pi 2
.dm off
.dm f@i3 on
.gs scan f@it
.f@pi 3
.dm off
.* .f@ih level: a term (&f@it) without a page reference
.dm f@ih on
.gs attval id print
.se *l = &*1
.se *t '&f@it
.se *w '&*t
.if &L'&PRINT gt 0 .se *w '&PRINT
.if &*l eq 1 .se f@i1 '&*w
.if &*l eq 1 .se f@i2 = ''
.if &*l eq 2 .se f@i2 '&*w
.se f@ip '/&*w
.se f@is '&*w
.se *q '/&*t///
.if &*l eq 2 .se f@ip '/&f@i1./&*w
.if &*l eq 2 .se f@is '&f@i1., &*w
.if &*l eq 2 .se *q '/&f@i1./&*t//
.if &*l eq 3 .se f@ip '/&f@i1./&f@i2./&*w
.if &*l eq 3 .se f@is '&f@i1., &f@i2., &*w
.if &*l eq 3 .se *q '/&f@i1./&f@i2./&*t/
.f@piid
.if &L'&PRINT gt 0 .pi key &*q &f@ip.////
.el .pi &f@ip.////
.dm off
.dm f@ih1 on
.gs scan f@it
.f@ih 1
.dm off
.dm f@ih2 on
.gs scan f@it
.f@ih 2
.dm off
.dm f@ih3 on
.gs scan f@it
.f@ih 3
.dm off
.dm f@iref on
.gs attval refid pg
.se *k = &U'&REFID
.if &E'&fi@&*k eq 1 .go ok
.f@msg 20 &REFID ?
.me
...ok
.se *p '&fi@&*k
.f@piop &PG
.if &L'&f@pip gt 0 .pi &f@pio &*p.////&f@pip
.el .pi &f@pio &*p
.dm off
.*
.* ---- the tag-to-APF mapping -----------------------------------------------------------
.aa gdoc f@gdoc f@egdoc
.aa frontm f@front (noatt)
.aa titlep f@ttlp (noatt) f@ettlp
.aa title f@cntx (noatt)
.aa docnum f@cntx (noatt)
.aa date f@cntx (noatt)
.aa author f@cntx (noatt)
.aa address f@addr (noatt) f@eaddr
.aa aline f@cntx (noatt)
.aa abstract f@abstr (noatt)
.aa preface f@pref (noatt)
.aa toc f@toc (noatt)
.aa figlist f@flist (noatt)
.aa body f@body (noatt)
.aa appendix f@appd (noatt)
.aa backm f@backm (noatt)
.aa index f@index (noatt)
.aa h0 f@hd0
.aa h1 f@hd1
.aa h2 f@hd2
.aa h3 f@hd3
.aa h4 f@hd4
.aa h5 f@hd5
.aa h6 f@hd6
.aa p f@para (noatt)
.aa pc f@pcont (noatt)
.aa note f@note (noatt)
.aa ol f@ol (vat) f@eol
.aa ul f@ul (vat) f@eul
.aa sl f@sl (vat) f@esl
.aa dl f@dl (vat) f@edl
.aa gl f@gl (vat) f@egl
.f@lcnx
.aa lq f@lq (noatt) f@elq
.aa xmp f@xmp (noatt) f@exmp
.aa fig f@fig f@efig
.f@fcnx
.aa fn f@fn f@efn
.aa hp0 f@hp0 (noatt) f@ehp
.aa hp1 f@hp1 (noatt) f@ehp
.aa hp2 f@hp2 (noatt) f@ehp
.aa hp3 f@hp3 (noatt) f@ehp
.aa cit f@cit (noatt) f@ecit
.aa q f@q (noatt) f@eq
.aa hdref f@hdref
.aa figref f@fgref
.aa fnref f@fnref
.aa liref f@liref
.aa i1 f@i1
.aa i2 f@i2
.aa i3 f@i3
.aa ih1 f@ih1
.aa ih2 f@ih2
.aa ih3 f@ih3
.aa iref f@iref
.* not formatted yet: tables (SH20-9186-06 ch.7)
.aa table f@cntx
.aa row f@cntx
.aa c f@cntx (vat)
.aa rdef f@cntx
.aa thd f@cntx
.aa tft f@cntx
.aa tnote f@cntx (noatt)
.aa tcap f@cntx (noatt)
.aa tdesc f@cntx (noatt)
