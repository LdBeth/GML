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
.* that are valid only inside a structure are mapped to DSM#CNTX until
.* the structure starts (DSMPROF3 item 32), which gives an "out of
.* context" message and drops the tag, its text staying in place.
.* Formatting (spacing, numbering, fonts, the title page layout, the
.* table of contents) is NOT done here: that is the XSLT stage's job.
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
.* ---- delimiters and processing (DSMPROF3 items 9-13) ---------------------
.dc gml : :e
.dc cont 03
.ms on
.gs tag on
.gs rules (att novat stop nomsg) (noatt)
.*
.* ---- symbols for text (items 15, 27) -----------------------------------------
.* &gml. &amp. &semi. are protected by the output translation (SH35-0069
.* p.259: ".se amp &X'08" with ".tr 08 &"), so they are never read again
.* as a tag, a symbol or a separator.
.se gml '&X'01.
.se amp '&X'02.
.se semi '&X'04.
.tr 01 3a 02 26 04 3b
.se rbl '&X'a0.
.se oqq '“
.se cqq '”
.se oq '‘
.se cq '’
.*
.* ---- &date (DSM#SETS: "November 18th, 1983") and &time --------------------------
.se @mon(1) = January
.se @mon(2) = February
.se @mon(3) = March
.se @mon(4) = April
.se @mon(5) = May
.se @mon(6) = June
.se @mon(7) = July
.se @mon(8) = August
.se @mon(9) = September
.se @mon(10) = October
.se @mon(11) = November
.se @mon(12) = December
.se @d = &SYSDAYOFM + 0
.se @m = &SYSMONTH + 0
.se @sfx = th
.if &@d eq 1 .or &@d eq 21 .or &@d eq 31 .se @sfx = st
.if &@d eq 2 .or &@d eq 22 .se @sfx = nd
.if &@d eq 3 .or &@d eq 23 .se @sfx = rd
.* &SYSYEAR is 00-99 (SH35-0069 p.241); DCF assumed 19xx.  Modern edge: a
.* 2-digit year is 20xx; a 4-digit value given with -set is kept.
.se @y = &SYSYEAR
.if &L'&SYSYEAR eq 2 .se @y = 20&SYSYEAR
.se date '&@mon(&@m) &@d.&@sfx., &@y
.se time '&SYSHOUR.:&SYSMINUTE
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
.if &E'&SYSVARP eq 0 .se SYSVARP = ''
.*
.* ---- element models (implicit closing) -------------------------------------------
.* @blk: the block structures that end a paragraph; @str: what DSM#RSET
.* ends (open text structures) before a heading or a document section.
.se @blk 'p,pc,note,lp,li,dthd,ddhd,dt,dd,gt,gd,ol,ul,sl,dl,gl,l,lq,xmp,fig,figcap,figdesc,address,h0,h1,h2,h3,h4,h5,h6,titlep,frontm,abstract,preface,toc,figlist,body,appendix,backm,index
.se @str 'p,pc,note,lp,li,dthd,ddhd,dt,dd,gt,gd,ol,ul,sl,dl,gl,l,lq,xmp,fig,figcap,figdesc,fn,q,hp0,hp1,hp2,hp3,cit,address,aline
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
.xd index empty closes=&@str
.xd hdref empty
.xd figref empty
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
.* ---- messages (DSM#MSG) ----------------------------------------------------------
.* .dsm#msg n [name]: a warning (severity W, as DSM#MSG gives).
.dm dsm#msg on
.go m&*1
...m2
.mg /DSMGML002W/Tag &$GML.&*2 is out of context./
.me
...m3
.mg /DSMGML003W/Tag &$GML.&*2 not ended before tag &$GML.&$TAG../
.me
...m4
.mg /DSMGML004W/Tag &$GML.&$TAG. found but no list is open./
.me
...m5
.mg /DSMGML005W/Tag &$GML.&$TAG. found outside the title page./
.me
...m6
.mg /DSMGML006W/Tag &$GML.&$TAG. found but no &*2 is open./
.me
...m10
.mg /DSMGML010W/Definition term without description before tag &$GML.&$TAG../
.me
...m11
.mg /DSMGML011W/Definition description without term at tag &$GML.&$TAG../
.me
.dm off
.*
.* DSM#CNTX: the APF of a tag that is out of context.
.dm dsm#cntx on
.dsm#msg 2 &$TAG
.dm off
.*
.* The out-of-context mappings (no element, the tag is dropped).
.dm dsm#lcnx on
.aa li dsm#cntx (noelem)
.aa lp dsm#cntx (noatt noelem)
.aa dthd dsm#cntx (noatt noelem)
.aa ddhd dsm#cntx (noatt noelem)
.aa dt dsm#cntx (noatt noelem)
.aa dd dsm#cntx (noatt noelem)
.aa gt dsm#cntx (noatt noelem)
.aa gd dsm#cntx (noatt noelem)
.dm off
.dm dsm#tcnx on
.aa title dsm#cntx (noelem)
.aa author dsm#cntx (noatt noelem)
.aa date dsm#cntx (noatt noelem)
.aa docnum dsm#cntx (noatt noelem)
.dm off
.dm dsm#fcnx on
.aa figcap dsm#cntx (noatt noelem)
.aa figdesc dsm#cntx (noatt noelem)
.dm off
.*
.* DSM#RSET: end the open text structures (the elements are closed by
.* the models above; here the messages and the bookkeeping).
.dm dsm#rset on
.if &@nest@l gt 0 .dsm#msg 3 &@ltag(&@nest@l)
.if &@nest@q gt 0 .dsm#msg 3 q
.if &@state ne open .dsm#msg 3 &@state
.if &@fn ne 0 .dsm#msg 3 fn
.se @nest@l = 0
.se @nest@q = 0
.se @state = open
.se @fn = 0
.dsm#lcnx
.dsm#fcnx
.dsm#tcnx
.aa aline dsm#cntx (noatt noelem)
.dm off
.*
.* ---- document sections ------------------------------------------------------------
.dm dsmgdoc /.*/
.dm dsmegdoc /.*/
.dm dsmfront /.*/
.dm dsmabstr /.dsm#rset/
.dm dsmpref /.dsm#rset/
.dm dsmtoc /.dsm#rset/
.dm dsmflist /.dsm#rset/
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
.dsm#msg 5
.me
...ok
.se @state = open
.dsm#tcnx
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
.dm dsmeaddr /.aa aline dsm#cntx (noatt noelem)/
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
.* The list type (d g o s u z) and tag of each open list are kept in
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
.dsm#lcnx
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
...xz
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
.dsm#msg 4
.me
...ok
.se @nest@l = &@nest@l - 1
.if &@nest@l eq 0 .dsm#lcnx
.el .dsm#lmap &@ltype(&@nest@l)
.dm off
.dm dsmlitem /.*/
.dm dsmlpart /.*/
.dm dsmdthd /.*/
.dm dsmddhd /.*/
.dm dsmdterm on
.if &@dterm eq 1 .dsm#msg 10
.se @dterm = 1
.dm off
.dm dsmddef on
.if &@dterm ne 1 .dsm#msg 11
.se @dterm = 0
.dm off
.dm dsmgterm on
.if &@gterm eq 1 .dsm#msg 10
.se @gterm = 1
.dm off
.dm dsmgdef on
.if &@gterm ne 1 .dsm#msg 11
.se @gterm = 0
.dm off
.*
.* ---- examples and figures -----------------------------------------------------------
.dm dsmxmp on
.se @state = xmp
.xa xml:space=preserve
.fo off
.dm off
.dm dsmexmp on
.if &@state eq xmp .go ok
.dsm#msg 6 example
.me
...ok
.se @state = open
.fo on
.xe xmp
.dm off
.dm dsmfig on
.se @state = fig
.aa figcap dsmfcap (noatt)
.aa figdesc dsmfdesc (noatt)
.dm off
.dm dsmefig on
.if &@state ne fig .dsm#msg 6 figure
.se @state = open
.dsm#fcnx
.dm off
.dm dsmfcap /.*/
.dm dsmfdesc /.*/
.*
.* ---- quotes, footnotes, highlights ---------------------------------------------------
.* inline form: a single-line .dm is substituted when it is defined
.* (SH35-0069 p.274), which would freeze &@nest@q at 0
.dm dsmquote on
.se @nest@q = &@nest@q + 1
.dm off
.dm dsmequot on
.if &@nest@q gt 0 .se @nest@q = &@nest@q - 1
.el .dsm#msg 6 quotation
.dm off
.dm dsmlquot /.*/
.dm dsmelqu /.*/
.dm dsmftnt /.se @fn = 1/
.dm dsmeftnt on
.if &@fn eq 0 .dsm#msg 6 footnote
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
.dm dsmfnref /.*/
.dm dsmliref /.*/
.*
.* ---- conditional processing (DSMPSC, DSM@PROC) ----------------------------------------
.* :psc proc='a b'. ... :epsc. -- the text is processed only when one of
.* the names is &SYSVARP (-set SYSVARP=name); conditional section 9.
.dm dsmpsc on
.cs 9 include
.gs attval proc process p
.dsm@proc &PROC &PROCESS &P
.cs 9 on
.dm off
.dm dsm@proc on
.if &*0 eq 0 .me
.se *i = 0
...loop
.se *i = &*i + 1
.if &*i gt &*0 .go nomatch
.if x&*&*i eq x&SYSVARP .me
.go loop
...nomatch
.cs 9 ignore
.dm off
.dm dsmepsc /.cs 9 off/
.*
.* ---- the tag-to-APF mapping (DSMPROF3 Figures 7 and 8) ---------------------------------
.aa abstract dsmabstr (noatt)
.aa address dsmaddr (noatt) dsmeaddr
.aa aline dsm#cntx (noatt noelem)
.aa appendix dsmappd (noatt)
.aa author dsm#cntx (noatt noelem)
.aa backm dsmbackm (noatt)
.aa body dsmbody (noatt)
.aa cit dsmcit (noatt) dsmecit
.aa date dsm#cntx (noatt noelem)
.aa dd dsm#cntx (noatt noelem)
.aa ddhd dsm#cntx (noatt noelem)
.aa dl dsmdlist (vat) dsmelist
.aa docnum dsm#cntx (noatt noelem)
.aa dt dsm#cntx (noatt noelem)
.aa dthd dsm#cntx (noatt noelem)
.aa fig dsmfig dsmefig
.aa figcap dsm#cntx (noatt noelem)
.aa figdesc dsm#cntx (noatt noelem)
.aa figlist dsmflist (noatt)
.aa figref dsmfgref
.aa fn dsmftnt dsmeftnt
.aa fnref dsmfnref
.aa frontm dsmfront (noatt)
.aa gd dsm#cntx (noatt noelem)
.aa gdoc dsmgdoc dsmegdoc
.aa gl dsmglist (vat) dsmelist
.aa gt dsm#cntx (noatt noelem)
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
.aa l dsmlistm (vat) dsmelist
.aa li dsm#cntx (noelem)
.aa liref dsmliref
.aa lp dsm#cntx (noatt noelem)
.aa lq dsmlquot (noatt) dsmelqu
.aa note dsmnote (noatt)
.aa ol dsmolist (vat) dsmelist
.aa p dsmpara (noatt)
.aa pc dsmpcont (noatt)
.aa preface dsmpref (noatt)
.aa psc dsmpsc (noelem) dsmepsc
.aa q dsmquote (noatt) dsmequot
.aa sl dsmslist (vat) dsmelist
.aa title dsm#cntx (noelem)
.aa titlep dsmttlep (noatt) dsmettlp
.aa toc dsmtoc (noatt)
.aa ul dsmulist (vat) dsmelist
.aa xmp dsmxmp dsmexmp (noelem)
.aa i1 dsmindx1
.aa i2 dsmindx2
.aa i3 dsmindx3
.aa ih1 dsmihd1
.aa ih2 dsmihd2
.aa ih3 dsmihd3
.aa iref dsmiref
