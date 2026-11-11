.* ------------------------------------------------------------------------
.* starter.gml: the GML Starter Set as a SEMANTIC profile.
.*
.* Modelled on DSMPROF3, the DCF Release 3 profile of the Starter Set
.* (SH35-0050, "Starter Set Initialization", pp.20-30): the same tag
.* names, the same tag-to-APF mapping (Figure 7, Figure 8), the same
.* attribute scanning rules, and APFs of the same names, so a legacy
.* document maps 1:1.  Use it with "gml -profile starter doc.gml".
.*
.* What the APFs do here is only what is SEMANTIC: every tag opens an
.* element of its own name (the automatic element), its attributes
.* become XML attributes, and the .xd models below close elements
.* implicitly where the Starter Set ends a structure (DSM#RSET: headings
.* and document sections end open lists, quotations, figures, examples,
.* footnotes and the title page).  The APFs keep the Starter Set's
.* bookkeeping (list nesting, &@state) for its context checking: tags
.* that are valid only inside a structure are mapped to ss@cntx (the
.* DSM#CNTX of starterset.gml) until the structure starts (DSMPROF3 item
.* 32), which gives an "out of context" message and drops the tag, its
.* text staying in place.  Formatting (spacing, numbering, fonts, the
.* title page layout, the table of contents) is NOT done here: that is
.* the XSLT stage's job.
.*
.* What does not depend on the output is shared with the formatting
.* profile dcfstarter.gml in starterset.gml (imbedded below): the
.* delimiters, the text symbols, &date, :psc, the message catalogue
.* (IBM's +++DSMGMLnnnx, the same under dcfstarter), the
.* out-of-context maps and the decisions of the table tags.
.*
.* :xmp is verbatim: DSMXMP marks the element xml:space="preserve" and
.* turns format mode off (a <gml:fo fill="no"/> hint inside it), so its
.* lines are kept as written (leading blanks, blank lines); :exmp turns
.* it on again inside the element, then closes it.  Tags, symbols and
.* control words in an example are still processed, as in DCF (use
.* &gml. for a colon).
.*
.* Users override any APF by redefining the macro after this profile,
.* or remap a tag with .aa, as with DSMPROF3.
.* ------------------------------------------------------------------------
.*
.* ---- the shared part: delimiters and processing (DSMPROF3 items 9-13),
.* ---- symbols for text (items 15, 27), &date (DSM#SETS), messages ------
.im starterset
.gs rules (att novat stop nomsg) (noatt)
.*
.* ---- state (DSM#SET) ---------------------------------------------------------------
.se @nest@l = 0
.se @nest@q = 0
.se @state = open
.* Modern edge: a footnote has its own flag, &@fn, instead of
.* &@state = N: DSMFTNT refuses a footnote in a figure or example
.* (keeps and floats exclude footnotes, SH35-0050 p.129); in the tree
.* there is no such conflict, so :fn may appear inside :fig or :xmp.
.se @fn = 0
.se @dterm = 0
.se @gterm = 0
.* the table state is starterset.gml's (ss@intb ...); @tlb: the current
.* cell is CONCAT=NO (the .lb macro is defined, below)
.se @tlb = 0
.*
.* ---- element models (implicit closing) -------------------------------------------
.* @blk: the block structures that end a paragraph; @str: what DSM#RSET
.* ends (open text structures) before a heading or a document section.
.se @blk 'p,pc,note,lp,li,dthd,ddhd,dt,dd,gt,gd,ol,ul,sl,dl,gl,l,lq,xmp,fig,figcap,figdesc,table,thd,tft,row,c,tnote,tcap,tdesc,tlist,address,h0,h1,h2,h3,h4,h5,h6,titlep,frontm,abstract,preface,toc,figlist,body,appendix,backm,index
.se @str 'p,pc,note,lp,li,dthd,ddhd,dt,dd,gt,gd,ol,ul,sl,dl,gl,l,lq,xmp,fig,figcap,figdesc,table,thd,tft,row,c,tnote,tcap,tdesc,fn,q,hp0,hp1,hp2,hp3,cit,address,aline
.xd p closedby=&@blk
.xd pc closedby=&@blk
.xd note closedby=&@blk
.xd li closedby=li,lp
.xd lp closedby=li,lp
.xd dthd closedby=ddhd,dt,dd
.xd ddhd closedby=dt,dd,dthd
.xd dt eol closedby=dt,dd
.xd dd closedby=dt,dd,dthd,ddhd
.xd gt eol closedby=gt,gd
.xd gd closedby=gt,gd
.xd figcap eol closedby=figdesc
.* a cell ends at the next cell, row, note, caption or description, and
.* at the end tags of the structures around it (SH20-9187-06 3.32.3)
.xd c closedby=c,row,thd,tft,tnote,tcap,tdesc
.xd row closedby=row,thd,tft,tnote,tcap,tdesc
.xd tcap eol closedby=tdesc
.xd aline eol closedby=aline
.xd title eol
.xd docnum eol
.xd date eol
.xd author eol
.xd h0 eol closes=&@str
.xd h1 eol closes=&@str
.xd h2 eol closes=&@str
.xd h3 eol closes=&@str
.xd h4 eol closes=&@str
.xd h5 eol closes=&@str
.xd h6 eol closes=&@str
.xd i1 eol
.xd i2 eol
.xd i3 eol
.xd ih1 eol
.xd ih2 eol
.xd ih3 eol
.xd frontm closedby=body,appendix,backm
.xd abstract closes=&@str.,titlep closedby=abstract,preface,toc,figlist,body,appendix,backm
.xd preface closes=&@str.,titlep closedby=abstract,preface,toc,figlist,body,appendix,backm
.xd body closes=&@str.,titlep closedby=appendix,backm
.xd appendix closes=&@str closedby=backm
.xd backm closes=&@str closedby=gdoc
.xd toc empty closes=&@str.,titlep
.xd figlist empty closes=&@str.,titlep
.xd tlist empty closes=&@str.,titlep
.xd index empty closes=&@str
.xd hdref empty
.xd figref empty
.xd tref empty
.xd fnref empty
.xd liref empty
.xd iref empty
.xd q inline
.xd hp0 inline
.xd hp1 inline
.xd hp2 inline
.xd hp3 inline
.xd cit inline
.xd fn inline
.*
.* DSM#RSET: end the open text structures (the elements are closed by
.* the models above; here the messages and the bookkeeping).
.dm dsm#rset on
.if &@nest@l gt 0 .ss@msg 3 &@ltag(&@nest@l)
.if &@nest@q gt 0 .ss@msg 3 q
.if &@state ne open .ss@msg 3 &@state
.if &@fn ne 0 .ss@msg 3 fn
.if &ss@intb ne 0 .ss@msg 3 table
.se @nest@l = 0
.se @nest@q = 0
.se @state = open
.se @fn = 0
.se ss@intb = 0
.dsm#cend
.ss@lcnx
.ss@fcnx
.ss@tbcx
.ss@tcnx
.aa aline ss@cntx (noatt noelem)
.dm off
.*
.* ---- document sections ------------------------------------------------------------
.dm dsmgdoc /.*/
.* ss@last goes at the end of the document (starterset.gml): gmlpass
.* compares the symbol files of two passes
.dm dsmegdoc /.se ss@last off/
.dm dsmfront /.*/
.dm dsmabstr /.dsm#rset/
.dm dsmpref /.dsm#rset/
.dm dsmtoc /.dsm#rset/
.dm dsmflist /.dsm#rset/
.dm dsmtlist /.dsm#rset/
.dm dsmbody /.dsm#rset/
.dm dsmappd /.dsm#rset/
.dm dsmbackm /.dsm#rset/
.dm dsmindex /.dsm#rset/
.*
.* ---- title page ---------------------------------------------------------------------
.dm dsmttlep on
.se @state = titlep
.aa title dsmtitle
.aa author dsmauthr (noatt)
.aa date dsmdate (noatt)
.aa docnum dsmdcnum (noatt)
.dm off
.dm dsmettlp on
.if &@state eq titlep .go ok
.ss@msg 11 titlep
.me
...ok
.se @state = open
.ss@tcnx
.dm off
.dm dsmtitle /.*/
.dm dsmauthr /.*/
.dm dsmdcnum /.*/
.* :date without text is the processing date (DSMDATE).
.dm dsmdate on
.gs copy *t
.if 'x&*t.' eq 'x' &date
.dm off
.dm dsmaddr /.aa aline dsmaline (noatt)/
.dm dsmaline /.*/
.dm dsmeaddr /.aa aline ss@cntx (noatt noelem)/
.*
.* ---- headings -----------------------------------------------------------------------
.dm dsmhead0 /.dsm#rset/
.dm dsmhead1 /.dsm#rset/
.dm dsmhead2 /.dsm#rset/
.dm dsmhead3 /.dsm#rset/
.dm dsmhead4 /.dsm#rset/
.dm dsmhead5 /.dsm#rset/
.dm dsmhead6 /.dsm#rset/
.*
.* ---- paragraphs, notes ---------------------------------------------------------------
.dm dsmpara /.*/
.dm dsmpcont /.*/
.dm dsmnote /.*/
.*
.* ---- lists (DSMLISTM, DSMELIST) -------------------------------------------------------
.* The list type (d g o s u) and tag of each open list are kept in
.* @ltype() and @ltag(); the item tags of the innermost list are mapped.
.dm dsmlistm on
.se @nest@l = &@nest@l + 1
.se @ltype(&@nest@l) = '&*1
.se @ltag(&@nest@l) = '&$TAG
.se @dterm = 0
.se @gterm = 0
.dsm#lmap &*1
.dm off
.dm dsm#lmap on
.ss@lcnx
.go x&*1
...xd
.aa dthd dsmdthd (noatt)
.aa ddhd dsmddhd (noatt)
.aa dt dsmdterm (noatt)
.aa dd dsmddef (noatt)
.aa lp dsmlpart (noatt)
.me
...xg
.aa gt dsmgterm (noatt)
.aa gd dsmgdef (noatt)
.aa lp dsmlpart (noatt)
.me
...xo
...xu
...xs
.aa li dsmlitem
.aa lp dsmlpart (noatt)
.dm off
.dm dsmolist /.dsmlistm o/
.dm dsmulist /.dsmlistm u/
.dm dsmslist /.dsmlistm s/
.dm dsmdlist /.dsmlistm d/
.dm dsmglist /.dsmlistm g/
.dm dsmelist on
.if &@nest@l gt 0 .go ok
.ss@msg 11 list
.me
...ok
.se @nest@l = &@nest@l - 1
.if &@nest@l eq 0 .ss@lcnx
.el .dsm#lmap &@ltype(&@nest@l)
.dm off
.dm dsmlitem /.*/
.dm dsmlpart /.*/
.dm dsmdthd /.*/
.dm dsmddhd /.*/
.* two terms in a row (005) and a description without a term (006):
.* IBM's messages; the elements stay in the tree (the Starter Set
.* ignores the second term, and puts "?" for the missing one: MSG p.7)
.dm dsmdterm on
.gs copy *t
.if &@dterm eq 1 .ss@msg 5 definition &*t
.se @dterm = 1
.dm off
.dm dsmddef on
.if &@dterm ne 1 .ss@msg 6 definition
.se @dterm = 0
.dm off
.dm dsmgterm on
.gs copy *t
.if &@gterm eq 1 .ss@msg 5 glossary &*t
.se @gterm = 1
.dm off
.dm dsmgdef on
.if &@gterm ne 1 .ss@msg 6 glossary
.se @gterm = 0
.dm off
.*
.* ---- examples and figures -----------------------------------------------------------
.* An example may be inside a figure: :exmp gives back the state that
.* :xmp found (&@xstate), so that :efig still sees fig.
.dm dsmxmp on
.se @xstate = &@state
.se @state = xmp
.xa xml:space=preserve
.fo off
.dm off
.dm dsmexmp on
.if &@state eq xmp .go ok
.ss@msg 11 xmp
.me
...ok
.se @state = &@xstate
.fo on
.xe xmp
.dm off
.dm dsmfig on
.se @state = fig
.aa figcap dsmfcap (noatt)
.aa figdesc dsmfdesc (noatt)
.dm off
.dm dsmefig on
.if &@state ne fig .ss@msg 11 fig
.se @state = open
.ss@fcnx
.dm off
.dm dsmfcap /.*/
.dm dsmfdesc /.*/
.*
.* ---- tables (Rel 3.2: SH20-9186-06 ch.7; SH20-9187-06 3.31-3.36) ---------------
.* The layout (the grid of ARRANGE, spans, widths, the per-cell values,
.* cell numbering, new rows) is worked out by resolve.xsl.  The decisions
.* (the context of the table tags, required attributes, known row
.* definitions and cell numbers, with their messages; which cells are
.* CONCAT=NO) are starterset.gml's, shared with dcfstarter.gml.  Here:
.* the elements are the automatic ones, and concat=no cells keep their
.* lines (xml:space="preserve", as :xmp).  Format mode is not
.* switched, since a cell is mostly ended implicitly and the hint would
.* fall outside it; instead, until the cell ends, a leading blank is
.* made ordinary text (an .lb macro, SH35-0069 p.281), and a blank or
.* null line is an empty line of the cell (.bl and .nl macros: a
.* literal empty line, which is no blank line again, LR p.78 remark 2),
.* as each input line is an output line (SSR 3.32.3.1; LR .BL p.78: a
.* blank line gives one line of white space).  The semantic tree cannot
.* leave out a :c that the Starter Set ignores (023: resolve.xsl does),
.* nor a :thd or :tft after the first row (024).
.*
.* :rdef: the element is made by ss@rdef, so that a repeated ARRANGE is
.* kept (joined with " / ", one value per line of the arrangement).
.dm dsmrdef /.ss@rdef/
.dm dsmtable on
.if &ss@intb ne 0 .ss@msg 4 table
.ss@tspan &*
.xa span=&ss@span
.gs attval refid
.ss@tbeg
.aa thd dsmthd dsmethd
.aa tft dsmtft dsmetft
.aa row dsmrow dsmerow
.aa tnote dsmtnote (noatt) dsmetnot
.aa tcap dsmtcap (noatt)
.aa tdesc dsmtdesc (noatt)
.dm off
.dm dsmetabl on
.dsm#cend
.se ss@intb = 0
.ss@tbcx
.dm off
.* :thd :tft [refid]: a header or footer (ss@thft), no :row inside
.dm dsmthd /.dsm#thft/
.dm dsm#thft on
.dsm#cend
.gs attval refid
.ss@thft &REFID
.aa c dsmcell (vat) dsmecell
.aa row ss@cntx (noelem)
.dm off
.dm dsmethd on
.dsm#tend
.aa row dsmrow dsmerow
.dm off
.dm dsmtft /.dsm#thft/
.dm dsmetft on
.dsm#tend
.aa row dsmrow dsmerow
.dm off
.dm dsmrow on
.se ss@trows = &ss@trows + 1
.gs attval refid
.dsm#cend
.ss@trow &REFID
.aa c dsmcell (vat) dsmecell
.dm off
.dm dsmerow on
.dsm#cend
.aa c ss@cntx (vat noelem)
.dm off
.* :c [n]: the cell number (ss@cnum) and its CONCAT value (ss@ccat):
.* in a concat=no cell a leading blank is text (.lb), until the cell ends
.dm dsmcell on
.se *n '&*1
.dsm#cend
.if &L'&*n gt 0 .xa n=&*n
.ss@cnum &*n
.ss@ccat
.if &ss@cno eq 0 .me
.dm lb /.*/
.dm bl /.dsm#el/
.dm nl /.dsm#el/
.se @tlb = 1
.dm off
.* .dsm#el: an empty line of text (a literal line: no .nl again)
.dm dsm#el on
.li

.dm off
.dm dsmecell /.dsm#cend/
.* .dsm#cend: the end of a concat=no cell
.dm dsm#cend on
.if &@tlb eq 0 .me
.dm lb off
.dm bl off
.dm nl off
.se @tlb = 0
.dm off
.* the end of the cells: a note, the caption, the description
.dm dsm#tend on
.dsm#cend
.aa c ss@cntx (vat noelem)
.dm off
.dm dsmtnote /.dsm#tend/
.dm dsmetnot /.*/
.dm dsmtcap /.dsm#tend/
.dm dsmtdesc /.dsm#tend/
.*
.* ---- quotes, footnotes, highlights ---------------------------------------------------
.* inline form: a single-line .dm is substituted when it is defined
.* (SH35-0069 p.274), which would freeze &@nest@q at 0
.dm dsmquote on
.se @nest@q = &@nest@q + 1
.dm off
.dm dsmequot on
.if &@nest@q gt 0 .se @nest@q = &@nest@q - 1
.el .ss@msg 11 q
.dm off
.dm dsmlquot /.*/
.dm dsmelqu /.*/
.dm dsmftnt /.se @fn = 1/
.dm dsmeftnt on
.if &@fn eq 0 .ss@msg 11 fn
.se @fn = 0
.dm off
.dm dsmcit /.*/
.dm dsmecit /.*/
.dm dsmhp0 /.*/
.dm dsmhp1 /.*/
.dm dsmhp2 /.*/
.dm dsmhp3 /.*/
.dm dsmehp /.*/
.*
.* ---- index and cross-references (resolved in XSLT) -----------------------------------
.dm dsmindx1 /.*/
.dm dsmindx2 /.*/
.dm dsmindx3 /.*/
.dm dsmihd1 /.*/
.dm dsmihd2 /.*/
.dm dsmihd3 /.*/
.dm dsmiref /.*/
.dm dsmhdref /.*/
.dm dsmfgref /.*/
.dm dsmtref on
.gs qatt *q refid
.if &E'&*q ne 0 .ss@msg 19 refid
.dm off
.dm dsmfnref /.*/
.dm dsmliref /.*/
.*
.* ---- conditional processing (DSMPSC: starterset.gml's ss@psc) ---------------------
.dm dsmpsc /.ss@psc/
.dm dsmepsc /.ss@epsc/
.*
.* ---- the tag-to-APF mapping (DSMPROF3 Figures 7 and 8) ---------------------------------
.aa abstract dsmabstr (noatt)
.aa address dsmaddr (noatt) dsmeaddr
.aa aline ss@cntx (noatt noelem)
.aa appendix dsmappd (noatt)
.aa author ss@cntx (noatt noelem)
.aa backm dsmbackm (noatt)
.aa body dsmbody (noatt)
.aa cit dsmcit (noatt) dsmecit
.aa date ss@cntx (noatt noelem)
.aa dd ss@cntx (noatt noelem)
.aa ddhd ss@cntx (noatt noelem)
.aa dl dsmdlist (vat) dsmelist
.aa docnum ss@cntx (noatt noelem)
.aa dt ss@cntx (noatt noelem)
.aa dthd ss@cntx (noatt noelem)
.aa fig dsmfig dsmefig
.aa figcap ss@cntx (noatt noelem)
.aa figdesc ss@cntx (noatt noelem)
.aa figlist dsmflist (noatt)
.aa figref dsmfgref
.aa fn dsmftnt dsmeftnt
.aa fnref dsmfnref
.aa frontm dsmfront (noatt)
.aa gd ss@cntx (noatt noelem)
.aa gdoc dsmgdoc dsmegdoc
.aa gl dsmglist (vat) dsmelist
.aa gt ss@cntx (noatt noelem)
.aa hdref dsmhdref
.aa hp0 dsmhp0 (noatt) dsmehp
.aa hp1 dsmhp1 (noatt) dsmehp
.aa hp2 dsmhp2 (noatt) dsmehp
.aa hp3 dsmhp3 (noatt) dsmehp
.aa h0 dsmhead0
.aa h1 dsmhead1
.aa h2 dsmhead2
.aa h3 dsmhead3
.aa h4 dsmhead4
.aa h5 dsmhead5
.aa h6 dsmhead6
.aa index dsmindex (noatt)
.aa li ss@cntx (noelem)
.aa liref dsmliref
.aa lp ss@cntx (noatt noelem)
.aa lq dsmlquot (noatt) dsmelqu
.aa note dsmnote (noatt)
.aa ol dsmolist (vat) dsmelist
.aa p dsmpara (noatt)
.aa pc dsmpcont (noatt)
.aa preface dsmpref (noatt)
.aa psc dsmpsc (noelem) dsmepsc
.aa q dsmquote (noatt) dsmequot
.aa sl dsmslist (vat) dsmelist
.aa title ss@cntx (noelem)
.aa titlep dsmttlep (noatt) dsmettlp
.aa toc dsmtoc (noatt)
.aa table dsmtable (vat) dsmetabl
.ss@tbcx
.aa rdef dsmrdef (noelem)
.aa tref dsmtref
.aa tlist dsmtlist (noatt)
.aa ul dsmulist (vat) dsmelist
.aa xmp dsmxmp dsmexmp (noelem)
.aa i1 dsmindx1
.aa i2 dsmindx2
.aa i3 dsmindx3
.aa ih1 dsmihd1
.aa ih2 dsmihd2
.aa ih3 dsmihd3
.aa iref dsmiref
