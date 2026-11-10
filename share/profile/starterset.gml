.* ------------------------------------------------------------------------
.* starterset.gml: what the two Starter Set profiles share.
.*
.* Imbedded (.im starterset) near the top of starter.gml (the SEMANTIC
.* profile: every tag builds an element, the XSLT stages format) and of
.* dcfstarter.gml (the FORMATTING profile: the APFs issue SCRIPT/VS
.* control words, SH35-0069-3 Text Programmer's Guide, cited TPG p.n).
.* It holds the parts of the Starter Set (SH20-9186-06 User's Guide, cited
.* UG p.n; SH20-9187-06 for the tables of Release 3.2; SH35-0050-2
.* Implementation Guide, cited IG p.n) that do not depend on how the
.* output is made: the delimiters, the text symbols, &date and &time,
.* the SYSVARP default and :psc, the last-pass flag, the message
.* catalogue, the out-of-context handling, and the decisions of the
.* table tags (row definitions, the table's state, cell numbers,
.* CONCAT=NO).  Its macros and state symbols are named ss@xxxx; the
.* element a tag belongs in (for DSMGML002W) sx@TAG; the row
.* definition symbols rp@X rk@X rl@X rn@X rc@X (below).
.*
.* The contract with the profile that imbeds it:
.*  - the messages are IBM's (+++DSMGMLnnnx, below) under either
.*    profile, the same number for the same condition;
.*  - the profile sets its own .gs rules (starter: elements, dcfstarter:
.*    noelem), after the .im (the .aa lines here run when the macros are
.*    called, and their rules are taken with the defaults of the time);
.*  - the profile maps the tags (.aa).  It may map a tag straight to
.*    ss@cntx (with the rules of the ss@lcnx/ss@tcnx/ss@fcnx/ss@tbcx maps
.*    below; :aline is ss@cntx (noatt noelem) where the profile ends an
.*    address), :rdef to ss@rdef and :psc/:epsc to ss@psc/ss@epsc, or
.*    wrap them in APFs of its own (starter keeps DSMPROF3's names:
.*    dsmrdef, dsmpsc ...).  The helpers ss@msg, ss@lcnx ... ss@tbcx,
.*    ss@tspan, ss@tbeg, ss@trow, ss@thft, ss@cnum and ss@ccat are
.*    called from the profile's own APFs; what a table makes (elements,
.*    the end of a cell, captions, numbers) is the profile's.
.*
.* The file is found by .im, which looks in the working directory and the
.* -I directories before the shipped profile directory: a file named
.* starterset.gml in the document's directory would shadow this one.
.* ------------------------------------------------------------------------
.*
.* ---- delimiters and processing (IG p.21 items 9-13) ---------------------
.dc gml : :e
.dc cont 03
.ms on
.gs tag on
.*
.* ---- symbols for text (IG items 15, 27) ---------------------------------
.* &gml. &amp. &semi. are text variables, as in IBM's DSMPROF3
.* (TPG p.259-261: no code point is given up, no translate table is
.* needed, and they may be used anywhere, a heading, a running heading
.* or a message too): known text, never read again as a tag, a symbol
.* or a separator; &amp. in a running heading is an ampersand, not the
.* page number.  &rbl. is EBCDIC 41, the required blank.
.dv amp text /&
.dv gml text /:
.'dv semi text /;
.se rbl '&X'41.
.* quotation marks: double at odd :q nesting levels, single at even ones
.* (IG p.21 item 27)
.se oqq '“
.se cqq '”
.se oq '‘
.se cq '’
.*
.* ---- &date (DSM#SETS: "November 18th, 1983") and &time ------------------
.se ss@mon(1) = January
.se ss@mon(2) = February
.se ss@mon(3) = March
.se ss@mon(4) = April
.se ss@mon(5) = May
.se ss@mon(6) = June
.se ss@mon(7) = July
.se ss@mon(8) = August
.se ss@mon(9) = September
.se ss@mon(10) = October
.se ss@mon(11) = November
.se ss@mon(12) = December
.se *d = &SYSDAYOFM + 0
.se *m = &SYSMONTH + 0
.se *s = th
.if &*d eq 1 .or &*d eq 21 .or &*d eq 31 .se *s = st
.if &*d eq 2 .or &*d eq 22 .se *s = nd
.if &*d eq 3 .or &*d eq 23 .se *s = rd
.* &SYSYEAR is 00-99 (TPG p.241); DCF assumed 19xx.  Modern edge (EXT): a
.* 2-digit year is 20xx; a 4-digit value given with -set is kept.
.se *y = &SYSYEAR
.if &L'&SYSYEAR eq 2 .se *y = 20&SYSYEAR
.se date '&ss@mon(&*m) &*d.&*s., &*y
.se time '&SYSHOUR.:&SYSMINUTE
.*
.* ---- passes ---------------------------------------------------------------
.* ss@last: 1 on the last formatting pass (the only one without TWOPASS
.* or FPASSES), 0 before it: &$PSNO is the number of passes (1 without
.* TWOPASS or FPASSES; gml -passes, gmlpass), &$PASS the current one.
.* DCF puts out only the last pass (SH20-9186-06 p.126), so a message
.* about a reference that a later pass resolves (013) waits for it.
.* The profile removes it at :egdoc (.se ss@last off), so that two
.* passes in the same state write the same symbol file: gmlpass stops
.* on that.
.se ss@last = 1
.if &$PASS lt &$PSNO .se ss@last = 0
.*
.* ---- messages ----------------------------------------------------------------
.* The GML Starter Set messages (SH35-0048-09, cited MSG p.n): one
.* catalogue for both profiles, IBM's numbers and wording, the label
.* "+++DSMGMLnnnx" (MSG p.5: the +++ is .mg's, nnn the number, x the
.* severity) and the suffix "(page nn)", the output page (MSG p.5).
.* &ss@mp is the DSMGML of the label (a tag set may change it).
.* .ss@msg n [word...]: message n.  &$TAGD.&$TAG. is the current tag as
.* written (:eol for an end tag), put in upper case as IBM's texts are;
.* &*2 is an element (a tag name: OL, XMP, TABLE ...) or another word
.* of the caller's, &*3 and after (joined) the rest.  The severity is W
.* for the GML messages (the MSG gives none; 015 says S only when the
.* attribute has no default) and that of the SCRIPT/VS message for our
.* own E ones.  The page is &$PN: one pass, 1 (the neutral value); with
.* the pass model a question to TeX, answered from the previous pass
.* (lib/ctx.ml).  A message that is issued on some passes and not on
.* others (013: a forward reference is known on pass 2) must not ask a
.* question of its own, or the ids of the questions after it on the
.* line would differ from pass to pass: its caller gives the page it
.* asked on every pass in &ss@pg.
.* The numbers IBM does not use (MSG p.7-11 lists 001-009, 011, 014-017,
.* 019-043) are ours: 010, 012, 013, 018.
.se ss@mp 'DSMGML
.dm ss@msg on
.if &E'&ss@pg eq 1 .go pg
.se *p '&$PN
.go tx
...pg
.se *p '&ss@pg
.se ss@pg off
...tx
.se *g '&$TAGD.&$TAG
.se *g '&U'&*g
.se *e '&U'&*2
.se *r = ''
.se *i = 2
...rl
.se *i = &*i + 1
.if &*i gt &*0 .go m&*1
.if &*i eq 3 .se *r '&*&*i
.el .se *r '&*r &*&*i
.go rl
.* 002: a tag mapped to ss@cntx, dropped (*2 the tag, *3 the element)
...m2
.mg /&ss@mp.002W/&$GML.&*e FOUND OUTSIDE &*r.. (page &*p)/
.me
.* 003: an open element ended by a heading or a section (DSM#RSET)
...m3
.mg /&ss@mp.003W/&*e PREMATURELY ENDED BY &*g TAG. (page &*p)/
.me
.* 004: a tag that cannot be nested in the element, ignored
...m4
.mg /&ss@mp.004W/&*g TAG FOUND WITHIN &*e AND IGNORED. (page &*p)/
.me
.* 005: a second term without a description before it (*2 DEFINITION
.* or GLOSSARY, *3... the term)
...m5
.mg /&ss@mp.005W/EXTRANEOUS &*e TERM '&*r.' IGNORED. (page &*p)/
.me
.* 006: a description without a term (*2 DEFINITION or GLOSSARY)
...m6
.mg /&ss@mp.006W/&*e TERM TAG MISSING. (page &*p)/
.me
.* 008: an identifier longer than 7 (*2 the element, *3 the identifier)
...m8
.mg /&ss@mp.008W/&*e ID '&*r.' TRUNCATED TO SEVEN CHARACTERS. (page &*p)/
.me
.* 009: an identifier defined twice (*2 the element, *3 the identifier)
...m9
.mg /&ss@mp.009W/DUPLICATE &*e ID '&*r.' IGNORED. (page &*p)/
.me
.* 010 (ours, the text of SCRIPT/VS 449 E, MSG p.29): a cell number
.* that the row definition does not have (SSR 3.32.3: "an error
.* results"; *2 the cell, *3 the row definition)
...m10
.mg /&ss@mp.010E/CELL '&*2.' DOES NOT EXIST IN ROW '&*r.'. (page &*p)/
.me
.* 011: an end tag without its element (*2 the element), ignored
...m11
.mg /&ss@mp.011W/&*g END-TAG FOUND OUTSIDE &*e AND IGNORED. (page &*p)/
.me
.* 012 (ours): a row definition redefined while a table is active
.* (SSR 3.31), ignored (LR .TD remark 5, p.383: an error)
...m12
.mg /&ss@mp.012E/ROW DEFINITION &*2 CANNOT BE REDEFINED WHILE A TABLE IS ACTIVE, RDEF TAG IGNORED. (page &*p)/
.me
.* 013 (ours): a reference to an identifier not defined; on the last
.* pass only (ss@last), the page from the caller (&ss@pg)
...m13
.if &ss@last eq 0 .me
.if &$PSNO gt 1 .mg /&ss@mp.013W/ID '&*2.' NOT DEFINED, REFERENCE NOT RESOLVED. (page &*p)/
.if &$PSNO eq 1 .mg /&ss@mp.013W/ID '&*2.' NOT DEFINED OR A FORWARD REFERENCE IN ONE PASS. (page &*p)/
.me
.* 015: a value not valid for an attribute (*2 the value, *3... the
.* attribute), the default used
...m15
.mg /&ss@mp.015W/&*2 NOT A VALID VALUE FOR &*r ATTRIBUTE OF &*g TAG. (page &*p)/
.me
.* 017: a REFID that names no row definition (*2 ROW, *3 the REFID)
...m17
.mg /&ss@mp.017W/&*e DEFINITION &*r DOES NOT EXIST. (page &*p)/
.me
.* 018 (ours): a list ended after a term without its description (*2
.* DEFINITION or GLOSSARY)
...m18
.mg /&ss@mp.018W/&*e TERM WITHOUT A DESCRIPTION AT THE END OF THE LIST. (page &*p)/
.me
.* 019: a required attribute missing (*2 the attribute)
...m19
.mg /&ss@mp.019W/REQUIRED ATTRIBUTE &*e MISSING FROM &*g TAG. (page &*p)/
.me
.* 021: ARRANGE lines of different lengths (or a value that is not a
.* positive integer): one cell
...m21
.mg /&ss@mp.021W/INVALID ARRANGE SPECIFICATION, DEFAULT OF 1 USED. (page &*p)/
.me
.* 023: a :c without a number past the last cell of a header or
.* footer, ignored
...m23
.mg /&ss@mp.023W/CANNOT START A NEW ROW IN A HEADER OR FOOTER, C TAG IGNORED. (page &*p)/
.me
.* 024: a :thd or :tft after the first row
...m24
.mg /&ss@mp.024W/&*g TAG NOT VALID AFTER FIRST ROW IN TABLE HAS STARTED. (page &*p)/
.me
.* 043: the title page runs onto a second page (MSG p.11; the caller
.* gives the page in &ss@pg)
...m43
.mg /&ss@mp.043I/TITLE PAGE SPANS MULTIPLE PAGES. (page &*p)/
.dm off
.*
.* ---- context checking (DSMPROF3 item 32) ---------------------------------
.* A tag that is valid only inside a structure is mapped to ss@cntx (the
.* DSM#CNTX of the Starter Set) until the structure starts, and again
.* when it ends: message 002, and the tag is dropped (no element; its
.* text stays).  The element it belongs in is &sx@<TAG>.  The
.* attribute rules are those of DSMPROF3: :li :title :thd :tft :row scan
.* their attributes (so they go with the tag), :c its value attribute,
.* the others none.  (Set with .se, not .gs args/vars: at file level
.* .gs args would leave &* defined for the profile that imbeds this
.* file, whose single-line .dm f@ol /... &* must keep &* unresolved.)
.se sx@LI = LIST;.se sx@LP = LIST
.se sx@DTHD = DL;.se sx@DDHD = DL;.se sx@DT = DL;.se sx@DD = DL
.se sx@GT = GL;.se sx@GD = GL
.se sx@TITLE = TITLEP;.se sx@DOCNUM = TITLEP;.se sx@DATE = TITLEP
.se sx@AUTHOR = TITLEP;.se sx@ALINE = ADDRESS
.se sx@FIGCAP = FIG;.se sx@FIGDESC = FIG
.se sx@THD = TABLE;.se sx@TFT = TABLE;.se sx@ROW = TABLE;.se sx@C = ROW
.se sx@TNOTE = TABLE;.se sx@TCAP = TABLE;.se sx@TDESC = TABLE
.dm ss@cntx on
.se *t = &U'&$TAG
.se *e = TABLE
.if &E'&sx@&*t eq 1 .se *e = &sx@&*t
.ss@msg 2 &$TAG &*e
.dm off
.dm ss@lcnx on
.aa li ss@cntx (noelem)
.aa lp ss@cntx (noatt noelem)
.aa dthd ss@cntx (noatt noelem)
.aa ddhd ss@cntx (noatt noelem)
.aa dt ss@cntx (noatt noelem)
.aa dd ss@cntx (noatt noelem)
.aa gt ss@cntx (noatt noelem)
.aa gd ss@cntx (noatt noelem)
.dm off
.dm ss@tcnx on
.aa title ss@cntx (noelem)
.aa docnum ss@cntx (noatt noelem)
.aa date ss@cntx (noatt noelem)
.aa author ss@cntx (noatt noelem)
.dm off
.dm ss@fcnx on
.aa figcap ss@cntx (noatt noelem)
.aa figdesc ss@cntx (noatt noelem)
.dm off
.dm ss@tbcx on
.aa thd ss@cntx (noelem)
.aa tft ss@cntx (noelem)
.aa row ss@cntx (noelem)
.aa c ss@cntx (vat noelem)
.aa tnote ss@cntx (noatt noelem)
.aa tcap ss@cntx (noatt noelem)
.aa tdesc ss@cntx (noatt noelem)
.dm off
.*
.* ---- conditional processing (DSMPSC, DSM@PROC) ----------------------------
.* :psc proc='a b'. ... :epsc. -- the text is processed only when one of
.* the names is &SYSVARP (-set SYSVARP=name); conditional section 9.
.if &E'&SYSVARP eq 0 .se SYSVARP = ''
.dm ss@psc on
.cs 9 include
.gs attval proc process p
.ss@proc &PROC &PROCESS &P
.cs 9 on
.dm off
.dm ss@proc on
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
.dm ss@epsc /.cs 9 off/
.*
.* ---- tables (Rel 3.2: SH20-9186-06 ch.7; SH20-9187-06 3.31-3.36) ---------------
.* The decisions of the Starter Set, the same under both profiles: the
.* context of the table tags, required attributes, the row definition of
.* each row and the number of each cell (with their messages), CONCAT=NO.
.* The layout (the grid of ARRANGE, spans, widths, the per-cell values,
.* new rows) is resolve.xsl's; the elements other than rdef, the end of a
.* cell, captions and numbers are the profile's.
.* The state of row definition X (its ID in upper case, at most 7
.* characters, UG p.52, so that the names stay within 10): &rp@X the
.* ordinal of the :rdef that defined it among the row definitions of
.* the pass (the symbols come back from the previous pass, so their
.* existence is no test: X is defined in this pass when &rp@X is at
.* most &ss@nrd, the count so far; the pass number would do, but would
.* change the symbol file on every pass and keep gmlpass from settling);
.* &rk@X(n) the position of cell number n among the cell numbers in
.* ascending order (null: no such cell); &rl@X the lowest cell number,
.* &rn@X(n) the next higher after n; &rc@X the CONCAT values.
.* The table: &ss@intb a table is open; &ss@trows the rows so far (a
.* header or footer must come first); &ss@trd the row definition (X) of
.* the current row, header or footer, &ss@tlrd the one of the last body
.* row, &ss@thrd of the last header or footer (the defaults of the next,
.* from the table's at first: SH20-9187-06 3.32.2, 3.32.4-5);
.* &ss@tcell the current cell number.
.se ss@nrd = 0
.se ss@intb = 0
.se ss@trows = 0
.se ss@trd = ''
.se ss@tlrd = ''
.se ss@thrd = ''
.se ss@tcell = 0
.se ss@cno = 0
.*
.* :rdef: the element is made here (the APF's rules say noelem), so that
.* a repeated ARRANGE is kept (joined with " / ", one value per line of
.* the arrangement).  The id of rdef is a name of its own (.xd noid): a
.* table with the same id is no duplicate.  The tag is ignored without
.* an ID (019) or when it redefines a row definition while a table is
.* active (012: SSR 3.31; LR .TD remark 5, p.383); an ID of more than 7
.* characters is truncated (008, SSR 3.31.1); ARRANGE lines of
.* different lengths, or a value that is not a positive integer, give
.* one cell (021, MSG p.8): the element says arrange="1".
.xd rdef empty noid
.dm ss@rdef on
.se ss@narr = 0
.se ss@arr = ''
.gs exatt arrange as ss@rarr
.ss@rdf
.dm off
.dm ss@rarr on
.se ss@narr = &ss@narr + 1
.if &ss@narr eq 1 .se ss@arr '&*
.el .se ss@arr '&ss@arr / &*
.dm off
.dm ss@rdf on
.gs attval id hp align concat valign rotate mindepth cwidths shade
.if &L'&ID gt 0 .go id
.ss@msg 19 id
.me
...id
.ss@rdid &ID
.if &L'&ID gt 7 .ss@msg 8 rdef &ID
.if &ss@intb eq 0 .go arr
.if &ss@rok eq 0 .go arr
.ss@msg 12 &ID
.me
...arr
.ss@rarc
.se *a 'id="&ID."
.if &L'&HP gt 0 .se *a '&*a hp="&HP."
.if &L'&ALIGN gt 0 .se *a '&*a align="&ALIGN."
.if &L'&CONCAT gt 0 .se *a '&*a concat="&CONCAT."
.if &L'&VALIGN gt 0 .se *a '&*a valign="&VALIGN."
.if &L'&ROTATE gt 0 .se *a '&*a rotate="&ROTATE."
.if &L'&MINDEPTH gt 0 .se *a '&*a mindepth="&MINDEPTH."
.if &ss@narr gt 0 .se *a '&*a arrange="&ss@arr."
.if &L'&CWIDTHS gt 0 .se *a '&*a cwidths="&CWIDTHS."
.if &L'&SHADE gt 0 .se *a '&*a shade="&SHADE."
.xs rdef &*a
.se ss@nrd = &ss@nrd + 1
.se rp@&ss@ru = &ss@nrd
.se rk@&ss@ru off
.se rn@&ss@ru off
.se rc@&ss@ru '&CONCAT
.* the cell numbers: those of ARRANGE, or 1 to the number of CWIDTHS
.se *m = 0
.if &ss@narr eq 0 .go cw
.gs args &ss@arr
.se *i = 0
...al
.se *i = &*i + 1
.if &*i gt &*0 .go pos
.se *t '&*&*i
.if &T'&*t ne N .go al
.if &*t le 0 .go al
.se rk@&ss@ru.(&*t) = 0
.if &*t gt &*m .se *m = &*t
.go al
...cw
.se *m = 1
.if &L'&CWIDTHS eq 0 .go cw1
.gs args &CWIDTHS
.se *m = &*0
.if &*m eq 0 .se *m = 1
...cw1
.se *i = 0
...cl
.se *i = &*i + 1
.if &*i gt &*m .go pos
.se rk@&ss@ru.(&*i) = 0
.go cl
.* positions and successors in ascending order
...pos
.se *k = 0
.se *p = 0
.se *i = 0
...pl
.se *i = &*i + 1
.if &*i gt &*m .me
.if x&rk@&ss@ru.(&*i) eq x .go pl
.se *k = &*k + 1
.se rk@&ss@ru.(&*i) = &*k
.if &*p eq 0 .se rl@&ss@ru = &*i
.el .se rn@&ss@ru.(&*p) = &*i
.se *p = &*i
.go pl
.dm off
.* .ss@rarc: check the ARRANGE of &ss@arr: the same number of values on
.* every line (between slashes), each a positive integer; else message
.* 021 and &ss@arr is 1.
.dm ss@rarc on
.if &ss@narr eq 0 .me
.gs args &ss@arr
.se *i = 0
.se *n = 0
.se *w = 0
.se *b = 0
...l
.se *i = &*i + 1
.if &*i gt &*0 .go end
.se *t '&*&*i
.if x&*t eq x/ .go sl
.if &T'&*t ne N .se *b = 1
.if &T'&*t eq N .if &*t le 0 .se *b = 1
.se *n = &*n + 1
.go l
...sl
.if &*w eq 0 .se *w = &*n
.if &*n ne &*w .se *b = 1
.se *n = 0
.go l
...end
.if &*w eq 0 .se *w = &*n
.if &*n ne &*w .se *b = 1
.if &*b eq 0 .me
.ss@msg 21
.se ss@arr = 1
.dm off
.* .ss@rdid id: &ss@ru the identifier as a symbol name part (at most 7
.* characters), &ss@rok 1 if a row definition of that name was defined
.* in this pass.  .ss@rchk id: the same, with message 017 for an
.* unknown one (&ss@ru is then null).
.dm ss@rdid on
.se ss@ru = &U'&*1
.if &L'&ss@ru gt 7 .se ss@ru = substr &ss@ru 1 7
.se ss@rok = 0
.if &E'&rp@&ss@ru eq 0 .me
.if &rp@&ss@ru le &ss@nrd .se ss@rok = 1
.dm off
.dm ss@rchk on
.ss@rdid &*1
.if &ss@rok eq 1 .me
.ss@msg 17 row &*1
.se ss@ru = ''
.dm off
.*
.* .ss@tspan &*: the value attributes of :table, the last of COLUMN/PAGE
.* is the span (UG p.55), into &ss@span (default page); message 015 for
.* any other value.
.dm ss@tspan on
.se ss@span = page
.se *i = 0
...vat
.se *i = &*i + 1
.if &*i gt &*0 .me
.se *v = &U'&*&*i
.if &*v eq COLUMN .se ss@span = column
.if &*v eq PAGE .se ss@span = page
.if &*v ne COLUMN .if &*v ne PAGE .ss@msg 15 &*&*i COLUMN OR PAGE
.go vat
.dm off
.* .ss@tbeg: the start of a table: its state, and its row definition
.* (&REFID, read by the caller's .gs attval; REFID= is required, message
.* 019), the default of the first row, header and footer.
.dm ss@tbeg on
.se ss@intb = 1
.se ss@trows = 0
.se ss@trd = ''
.se ss@tlrd = ''
.se ss@thrd = ''
.se ss@thf = 0
.if &L'&REFID gt 0 .go ref
.ss@msg 19 refid
.me
...ref
.ss@rchk &REFID
.se ss@tlrd '&ss@ru
.se ss@thrd '&ss@ru
.dm off
.* .ss@trow [refid]: the row definition of a row, header or footer (its
.* own, or the one of the row before); no cell yet.  The profile then
.* maps :c to its cell APF.  &ss@thf: 1 in a header or footer.
.dm ss@trow on
.se ss@thf = 0
.se ss@trd '&ss@tlrd
.if &L'&*1 eq 0 .go set
.ss@rchk &*1
.se ss@trd '&ss@ru
...set
.se ss@tlrd '&ss@trd
.se ss@tcell = 0
.dm off
.* .ss@thft [refid]: a header or footer: before the first row (message
.* 024; dcfstarter ignores the tag, SSR 3.32.4-5, MSG p.9); their row
.* definitions follow one another, apart from those of the body rows.
.dm ss@thft on
.if &ss@trows gt 0 .ss@msg 24
.se *s '&ss@tlrd
.se ss@tlrd '&ss@thrd
.ss@trow &*1
.se ss@thrd '&ss@tlrd
.se ss@tlrd '&*s
.se ss@thf = 1
.dm off
.* .ss@cnum [n]: the number of the cell into &ss@tcell: n, or the next
.* cell number of the row definition after the current one (the lowest
.* at first or after the last: a new row, SSR 3.32.3).  Message 010 for
.* a number that the row definition does not have (SSR 3.32.3: "an
.* error results"; the next cell is taken).  In a header or footer
.* there is no new row: message 023 and &ss@cign is 1 (the :c is
.* ignored, MSG p.9; else 0).
.dm ss@cnum on
.se ss@cign = 0
.if x&ss@trd eq x .me
.if &L'&*1 eq 0 .go next
.if &T'&*1 ne N .go bad
.if x&rk@&ss@trd.(&*1) eq x .go bad
.se ss@tcell = &*1
.me
...bad
.ss@msg 10 &*1 &ss@trd
...next
.if &ss@tcell eq 0 .go low
.se *i '&rn@&ss@trd.(&ss@tcell)
.if x&*i eq x .go wrap
.se ss@tcell = &*i
.me
...wrap
.if &ss@thf eq 0 .go low
.ss@msg 23
.se ss@cign = 1
.me
...low
.se ss@tcell = &rl@&ss@trd
.dm off
.* .ss@ccat: CONCAT=NO for the current cell: the cell keeps its lines
.* (xml:space="preserve", as :xmp, so that the tree is the same under
.* both profiles) and &ss@cno is 1 (else 0); the profile then keeps the
.* lines its own way until the cell ends.
.dm ss@ccat on
.se ss@cno = 0
.if x&ss@trd eq x .me
.if &L'&rc@&ss@trd eq 0 .me
.se *k = &rk@&ss@trd.(&ss@tcell)
.gs args &rc@&ss@trd
.if &*k gt &*0 .se *k = &*0
.se *v '&*&*k
.se *f = substr &*v 1 1
.if &U'&*f ne N .me
.xa xml:space=preserve
.se ss@cno = 1
.dm off
