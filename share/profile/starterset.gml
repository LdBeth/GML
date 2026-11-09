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
.* CONCAT=NO).  Its macros and state symbols are named ss@xxxx; the row
.* definition symbols rp@X rk@X rl@X rn@X rc@X (below).
.*
.* The contract with the profile that imbeds it:
.*  - the profile sets &ss@mp, the message prefix (DSMGML, DCFS): a
.*    message is "&ss@mp.nnnW text", the same number for the same
.*    condition under either profile;
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
.* or FPASSES), 0 before it.  TPG p.247 tests &$TWO and "&$PASS eq 2";
.* with FPASSES(n) the last pass is n: &$PASSES (not a DCF symbol; gml
.* -passes, gmlpass).  DCF puts out only the last pass (SH20-9186-06
.* p.126), so a message about a reference that a later pass resolves
.* (020) waits for it.  The profile removes it at :egdoc (.se ss@last
.* off), so that two passes in the same state write the same symbol
.* file: gmlpass stops on that.
.se ss@last = 1
.if &$TWO eq 1 .if &$PASS lt &$PASSES .se ss@last = 0
.*
.* ---- messages ----------------------------------------------------------------
.* .ss@msg n [word...]: a warning (severity W, as DSM#MSG gives), DCF
.* style "&ss@mp.nnnW text".  &$TAGD.&$TAG. is the current tag as
.* written (:eol for an end tag), &$GML.&*2 a tag named by the caller.
.* DCF-VERIFY: the numbers and wording are ours, not IBM's.
.dm ss@msg on
.go m&*1
...m2
.mg /&ss@mp.002W/Tag &$GML.&*2 is out of context and is ignored./
.me
...m3
.mg /&ss@mp.003W/Tag &$GML.&*2 was not ended before tag &$TAGD.&$TAG../
.me
...m4
.mg /&ss@mp.004W/Tag &$TAGD.&$TAG. found but no &*2 is open./
.me
...m5
.mg /&ss@mp.005W/Tag &$TAGD.&$TAG. does not match the open list &$GML.&*2../
.me
...m10
.mg /&ss@mp.010W/Definition term without description before tag &$TAGD.&$TAG../
.me
...m11
.mg /&ss@mp.011W/Definition description without term at tag &$TAGD.&$TAG../
.me
...m12
.mg /&ss@mp.012W/Tag &$TAGD.&$TAG. requires the &*2 attribute./
.me
...m13
.mg /&ss@mp.013W/Identifier &*2 is defined more than once./
.me
...m14
.mg /&ss@mp.014W/A &*2 cannot be nested in a &*3../
.me
...m15
.mg /&ss@mp.015W/Row definition &*2 is not defined./
.me
...m16
.mg /&ss@mp.016W/Cell &*2 is not in row definition &*3../
.me
...m17
.mg /&ss@mp.017W/Tag &$TAGD.&$TAG. must come before the first row of the table./
.me
...m18
.mg /&ss@mp.018W/Value &*2 is not valid for tag &$TAGD.&$TAG../
.me
...m19
.mg /&ss@mp.019W/Row definition &*2 redefined while a table is open./
.me
...m20
.if &ss@last eq 0 .me
.if &$TWO eq 1 .mg /&ss@mp.020W/Reference to &*2 is undefined./
.if &$TWO eq 0 .mg /&ss@mp.020W/Reference to &*2 is undefined or forward (one pass)./
.dm off
.*
.* ---- context checking (DSMPROF3 item 32) ---------------------------------
.* A tag that is valid only inside a structure is mapped to ss@cntx (the
.* DSM#CNTX of the Starter Set) until the structure starts, and again
.* when it ends: message 002, and the tag is dropped (no element; its
.* text stays).  The attribute rules are those of DSMPROF3: :li :title
.* :thd :tft :row scan their attributes (so they go with the tag), :c its
.* value attribute, the others none.
.dm ss@cntx on
.ss@msg 2 &$TAG
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
.* table with the same id is no duplicate.
.xd rdef empty noid
.dm ss@rdef on
.se ss@narr = 0
.se ss@arr = ''
.gs exatt arrange as ss@rarr
.ss@rdf
.dm off
.dm ss@rarr on
.se ss@narr = &ss@narr + 1
.if &ss@narr eq 1 .se ss@arr '&*1
.el .se ss@arr '&ss@arr / &*1
.dm off
.dm ss@rdf on
.gs attval id hp align concat valign rotate mindepth cwidths shade
.se *a = ''
.if &L'&ID gt 0 .se *a 'id="&ID."
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
.if &L'&ID gt 0 .go id
.ss@msg 12 id
.me
...id
.ss@rdid &ID
.if &ss@intb eq 0 .go new
.if &ss@rok eq 1 .ss@msg 19 &ID
...new
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
.gs args &CWIDTHS
.se *m = &*0
.if &*m eq 0 .se *m = 1
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
.* .ss@rdid id: &ss@ru the identifier as a symbol name part, &ss@rok 1
.* if a row definition of that name was defined in this pass.  .ss@rchk
.* id: the same, with message 015 for an unknown one (&ss@ru is then
.* null).
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
.ss@msg 15 &*1
.se ss@ru = ''
.dm off
.*
.* .ss@tspan &*: the value attributes of :table, the last of COLUMN/PAGE
.* is the span (UG p.55), into &ss@span (default page); message 018 for
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
.if &*v ne COLUMN .if &*v ne PAGE .ss@msg 18 &*&*i
.go vat
.dm off
.* .ss@tbeg: the start of a table: its state, and its row definition
.* (REFID= is required, message 012), the default of the first row,
.* header and footer.
.dm ss@tbeg on
.se ss@intb = 1
.se ss@trows = 0
.se ss@trd = ''
.se ss@tlrd = ''
.se ss@thrd = ''
.gs attval refid
.if &L'&REFID gt 0 .go ref
.ss@msg 12 refid
.me
...ref
.ss@rchk &REFID
.se ss@tlrd '&ss@ru
.se ss@thrd '&ss@ru
.dm off
.* .ss@trow [refid]: the row definition of a row, header or footer (its
.* own, or the one of the row before); no cell yet.  The profile then
.* maps :c to its cell APF.
.dm ss@trow on
.se ss@trd '&ss@tlrd
.if &L'&*1 eq 0 .go set
.ss@rchk &*1
.se ss@trd '&ss@ru
...set
.se ss@tlrd '&ss@trd
.se ss@tcell = 0
.dm off
.* .ss@thft [refid]: a header or footer: before the first row (message
.* 017); their row definitions follow one another, apart from those of
.* the body rows.
.dm ss@thft on
.if &ss@trows gt 0 .ss@msg 17
.se *s '&ss@tlrd
.se ss@tlrd '&ss@thrd
.ss@trow &*1
.se ss@thrd '&ss@tlrd
.se ss@tlrd '&*s
.dm off
.* .ss@cnum [n]: the number of the cell into &ss@tcell: n, or the next
.* cell number of the row definition after the current one (the lowest
.* at first or after the last); message 016 for a number that the row
.* definition does not have.
.dm ss@cnum on
.if x&ss@trd eq x .me
.if &L'&*1 eq 0 .go next
.if &T'&*1 ne N .go bad
.if x&rk@&ss@trd.(&*1) eq x .go bad
.se ss@tcell = &*1
.me
...bad
.ss@msg 16 &*1 &ss@trd
...next
.if &ss@tcell eq 0 .go low
.se *i '&rn@&ss@trd.(&ss@tcell)
.if x&*i eq x .go low
.se ss@tcell = &*i
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
