# DCF SCRIPT/VS semantics: findings from the manuals

Primary source: *SH35-0070-07, DCF SCRIPT/VS Language Reference, Rel. 4*
(cited "LR p.n"), with *SH35-0048-09, DCF Messages* ("MSG p.n") and
*SH20-9187-06, GML Starter Set Reference, Rel. 4* ("SSR §x").  The Rel. 3
sources stay where they are still the best: *SH35-0069-3, DCF SCRIPT/VS
Text Programmer's Guide, Rel. 3 (Jun 1986)*, the PDF in the project root
(a bare "p.n", or "TPG p.n"), *SH35-0050, DCF GML Starter Set
Implementation Guide* ("SH35-0050 p.n"), SH20-9161-3 and the quick
reference SX26-3723.  Page numbers are the books' printed pages.
Status column: **DONE** = implemented as described (with the test that
shows it); **OK** = it already matched; **EXT** = kept as an extension;
**not yet modelled** = known DCF behaviour we do not have; otherwise the
entry explains what we do.  Open questions are marked `DCF-VERIFY` in the
source; "(not in LR Rel 4)" there means the Rel. 4 manual does not settle
them either.

## Line processing (ch. 3, p.39–41; ch. 21, p.257–258)
The per-line order is documented at the top of `lib/interp.ml`.

| Rule | Status |
|---|---|
| **Substitution happens before the line is classified** as control word or text (p.258). Order: end of a `.dm` capture → ignored `.cs` section → classify (comments and labels are never substituted) → substitute → separator split → dispatch. | DONE (`order.t`) |
| *Extended symbol rule*: a symbol value that begins with the separator makes the rest of the value start a new input line, during substitution (p.257). | DONE (`sysvars.t`, `manual_separator.t`, `manual_implguide.t`) |
| On a **control word line**, the line is split at any separator; the part to the right becomes the next input line (p.40, p.258). An empty rest is dropped. | OK (`manual_separator.t`) |
| On a **text line**, the line is split only where the separator is followed by the control word indicator (optionally `'`) and a 2-char control word name; the text before is "text with continuation" (p.41). Otherwise `;` is text. | DONE (`manual_separator.t`, `separator.t`) |
| `.'xx` = no macro search **and** no separator scan; it applies only to the first line after substitution (p.41, p.258). | OK |
| A separator in a **text variable**'s string (`.dv name TEXT /string`, p.258–261: "known text") is text on a control word line and a text line alike: DSMPROF3's `.'dv semi text /;` makes `.ty a&semi.b` one line.  The same holds for the `.mg` field delimiter, the `.pi` delimiter and the page number symbol in `.sx` fields (`Line.index_sep`). | DONE (`dv_messages.t`) |
| **Control word names are 2 chars**; the blank after them is optional: `.cecenter` = `.ce center` (p.40). With `.ms on` and no modifier the whole run of name characters (≤10) is tried as a macro first (p.271). The long forms `.AND .ELSE .THEN .GOTO` are `.an .el .th .go` (LR p.66, p.164, p.395, p.179). | DONE (`macro_shadow.t`, `rel4_cw.t`, `macro_ctl.t`, `go.t`) |
| `.*` ignores the whole line, separators included (p.44). `.cm` is an ordinary control word: its line **is** split at a separator (LR p.464 r5). | DONE (`comments.t`) |
| Macros are not recognised in text lines; `.em` runs one, also under `.ms off` (p.41, p.278). `.ec` runs the native word (p.277). | DONE (`em.t`, `manual_macros.t`) |
| Continuation character `.dc cont c` (none initially) and `.ct` (p.47–48). | DONE (`manual_continuation.t`) |
| `.dc gml c [e1 [e2]]` (LR p.113): `c` alone makes the end-tag delimiter null, so **end tags are not recognized**; `c e1` makes `e1` the end-tag delimiter, `c e1 e2` the pair (initially `: : :`, LR p.115).  The pair may also be one operand beginning with `c` (DSMPROF3's `.dc gml : :e`); the Starter Set's `.dc gml : : e` gives `:` and `:e` (SH35-0050 p.6).  A delimiter may not be a blank, a period, `&` or a tag name character (of `e1 e2` only `e1` is checked).  X'00' or X'40' is OFF for `cw`, `gml`, `mcs` (LR p.113 note 6); the blank stays an MCS (LR p.115 r4).  Our old reading (`c` alone = `c` doubled) is gone. | DONE (`dc_forms.t`) |
| `.dc OPTION` with no value restores its initial value (LR p.114, "Default: Restores the initial setting"); the Starter Set's DSM#XLST and DSM#WRIT issue bare `.dc cw` and `.dc asep`.  The syntax has one option per `.dc`; several on one line is EXT.  IXB IXI PUNC STOP WORD are not supported. | DONE (`dc_forms.t`), EXT |
| `.lb`/`.lt`/`.nl`/`.bl` implicit words (p.281): natively a leading blank/tab gives a break and the line is text; a macro of that name (with `.ms on`) is invoked with the line as `&*`, and for `.lb`/`.lt` the line is then processed as text (`.dm lb /.*` makes the blank ordinary). | DONE (`manual_implicit.t`) |

## Symbols (ch. 21; LR .SE p.337–342, Tables 17–24 p.443–450)
| Rule | Status |
|---|---|
| Names up to 10 chars from letters, digits, `@ # $` (p.42, p.229; LR p.337); a longer name is an error. A name may start with a digit (`&3z`, p.269). | DONE (`symbols.t`) |
| **Symbol names are case-sensitive** (p.239); names beginning with `$` are not (p.241). | DONE (`symbols.t`, `manual_symbols.t`) |
| A reference ends at a blank, a period (consumed), end of line, or `)` (needed by `.se array(&elem)` of p.256). `&prodname,` is **not** substituted (p.232), nor is `&*t;` (a `;` is a name character of no symbol but does not end the reference either: SH20-9161-3 .SE; IBM's DSMLISTM writes `&*1/`), so `&*t.;` is the idiom.  An attribute's operand runs "up to next delimiter (period or blank)" (p.238): `&E'&fh@&*k.` takes `&*k` (after substitution, the rest of the operand) and the period, so a following character is part of the operand string unless written `&*k..` (`symbol_end.t`). `&` or `(` continues the reference. | DONE (`symbols.t`, `symbol_end.t`, `manual_symbols.t`) |
| Resolution is **right to left** (p.233, p.238, p.256); values are rescanned; a runaway is stopped (10 000 steps, 100 000 chars). | DONE (`manual_symbols.t`, `diag.t`) |
| Undefined global: left as written. Undefined local (`*`): null, only when the current source is a macro (p.253, p.276). | DONE (`macro_locals.t`) |
| One set of locals per macro call, plus one set for when no macro is the current source (p.276); files have no scope of their own. | DONE (`macro_locals.t`, `imbed_args.t`) |
| `.su on|off|n` (n = the next n lines, then off). Initially on. `.se` lines (outside quotes) and `.if` comparands are substituted even with `.su off` (p.230, p.267; LR p.341 r13). | DONE (`su.t`, `manual_if.t`) |
| `.se x = 'str'`, `.se x 'str` (next row), `.se x = 25`.  **Arithmetic** (LR p.339–341): only `+ - * /`, evaluated **strictly left to right**, no precedence, no parentheses (`1 + 2 * 4 + 6` = 18, r8); a sign only before the first number (`5+-3` is invalid, r12); no blanks needed (`&.3+1`, r10); an integer of 9 digits or more warns (LR p.339); leading zeros go.  Our old `//` and parentheses are gone.  A **single number is kept as written** (`.se 3z = 00`, p.269): only an expression with an operator is evaluated.  DCF-VERIFY (not in LR Rel 4): `/` truncates toward zero. | DONE (`se_expr.t`, `manual_se.t`) |
| A **doubled quote** inside a quoted string of the `=` form is one quote and does not end it: `.se t = 'Mrs. O''Grady''s Cat'` (LR p.338); `''` alone is null.  The **qstring form** `.se t 'Mrs. O'Grady's Cat'` takes the rest of the line: a single quote in it need not be doubled, a doubled quote is still one (read left to right), and a quote left alone at the end is the closing quote, dropped (it keeps trailing blanks) (LR p.337, p.339).  DCF-VERIFY: the manual shows only the undoubled case; DSMPROF3's `@oquote` (below) needs the undoubling.  The symbol file of the pass model writes the `=` form. | DONE (`se_expr.t`, `symbols_pass.t`) |
| An unquoted value with blanks or special characters "must be enclosed in single quotation marks" (LR p.338): blanks warn, the text is kept.  A single word with special characters is taken silently: IBM's DSM#XLST `.se @ = ;` and DSMELIST `.se @sk@l = .75` would warn in every run, so DCF evidently accepts them.  An unquoted word over 16 characters (also as the string of SUBSTR/INDEX) is an error, the symbol not set (LR p.341 r14; user decision 2026-11-10).  A bare `.se name` or a value without `=` or quote is outside the syntax (LR p.337): warned, then null or the value as written.  A tab (X'05', `&$TAB`) is not a blank but a character resolved by `.tb`/`.tp` when the text is formatted (LR p.118, p.374, p.400 r1–r2): `.se x = a&$TAB.b` is one word; the same blank (X'40' only) delimits `.if` operands and macro and imbed parameters. | DONE (`se_expr.t`, `symbols_pass.t`) |
| `.se x = substr STR [n [len]]` and `.se x = index STR [SUB]` (LR p.337, p.339): SUBSTR from 1 to the end when n/len are omitted, INDEX 0 when SUB is not there, omitted or null; the rest of the line is ignored. The `&'substr(` function family was removed: it is Waterloo SCRIPT / WATCOM Script (wgmlref, Appendix B messages SC--087..093), not DCF. | DONE (`se_expr.t`, `manual_se.t`); `&'name(` removed |
| `.se x off` = undefined; for an array with no subscript the whole array goes. `.se x =` / `.se x = ''` = null (p.235; LR p.340 r5). | OK |
| **Arrays (p.254–257):** `&x(*)` = all elements joined by the array separator (`", "`, `.dc asep`), in index order. `&x(0)` = the counter (= `&x`). `.se x() = v` appends at counter+1. A missing element of a defined array is null. Setting element n sets the counter when element 0 is numeric or unset. At most 32767 elements; setting a higher one is an error (LR p.342 r18). | DONE (`subscripts.t`, `manual_arrays.t`) |
| A **null element 0 is counter 0**: `.se x = ''` (or a null from `.gs vars`) then `.se x() = v` sets element 1, and setting element n makes n the counter. A value that is not a number is an error when the counter is needed (p.257). DCF-VERIFY (not in LR Rel 4): p.257 does not mention null; the Starter Set's DSMTTLEP nulls `@title`/`@author`/`@address` with `.gs vars` and then appends, which only this reading fits; a non-numeric element 0 is left alone. | DONE (`null_counter.t`) |
| Attributes `&E' &L' &T' &V' &W' &U' &A'/&a'` (base 26) `&R'/&r'` (roman) `&X'` (hex) (p.235–238; LR Table 24 p.450). `&AD' &SW' &SD'` are device-dependent: 0 here, with a one-time warning. EXT: `&DH'`/`&DV'` give device units of a 240-pel page printer (3800 Model 3, 3820): a figure space or em 24, a line 40, an inch 240; there is no device (IBM's list and footnote indents are computed with them). `&SH' &SV'` (LR p.450) are not implemented. | DONE (`attrfuncs.t`), EXT device units |
| **Hexadecimal codes are EBCDIC** (`&X'`, the `.tr` operands, the `.dc` values): translated to Unicode with code page 037 (`lib/ebcdic.ml`), so `.dc asep , 40` is a comma and a blank and `&X'41` the required blank.  CP037 rather than CP500 (they differ in 4A 4F 5A 5F B0 BA BB) is our choice: Rel 4 names code page 500 for `.hy` (LR p.198) and `.DO` names (LR p.150), but its `.RC` example has `|` at X'4F' (LR p.305), as CP037 does.  EXT: B0–B9 are the superscript digits of the 1403/3800 text fonts, as IBM's DSM#SUPR uses them (SH35-0050, "a 1 becomes a hex b1"); in Rel 4 that is a matter of the font (LR p.405).  A `.tr` operand is one (UTF-8) character or two hex digits; the table is by code point. | DONE (`ebcdic.t`, `hints_tr.t`), EXT B0–B9, DCF-VERIFY CP037 |
| **System symbols of the device, the SCRIPT command options and the page** (LR Tables 18–21, p.443–447; SH35-0069 Figure 15, p.242–244; SX26-3723): there is no device, so they are neutral (EXT), as for a 3800 under CMS with the INDEX option: `&$PDEV`=3800 `&$LDEV`=3800N6 `&$OUT`=FILE `&$DCF`=3.0.0 (format n.n.n, LR p.444) `&$SYS`=CMS `&$PASS`=1 `&$PSNO`=1 `&$TWO &$UNF &$BE &$BO`=0 `&$INDX`=1 `&$LIB` (1 with `-lib`) `&$PRT`=ON `&$PARM`; `&$CHAR(n)` the CHARS fonts, an array (element 0 the count, a missing font null), font ids of 1–8 characters (LR p.444); without CHARS DCF gives the device's default font (LR .BF r5, p.75), we give TEXT and BOLD, so DSMPROF3 takes its 3800f2 font set (p.178–179); `&$FNAM` the current file name in upper case without extension, at most 8 characters (LR p.446); `&$RB` (`.dc rb`, EBCDIC 41 = U+00A0) and `&$PS` (`.dc ps`, `&`); `&$IN &$IR &$OF &$LL &$CL` in figure spaces of 1/10 inch (`&$IN`/`&$IR`: the permanent indention, or the temporary one until changed; see `.in`), `&$PL`=66 `&$PW`=85 `&$LC`=60 (the page state, below), the margins 0, `&$KP &$VR`=OFF, `&$LST`=0, `&$BS` backspace.  3800N6 is a 3800 Model 1 (8.5 by 10 inches at 6 lpi, LR p.26, so 60 lines; 180 pels per inch, LR p.493); the profiles test `&$PDEV`/`&$LDEV`, so the values stay.  `-set '$NAME=v'` overrides any system symbol (`-set '$CHAR=f1 f2 ...'` the font list), so IBM's Starter Set runs with no `-set`.  Not provided: the font symbols (LR p.448), `&SYSINDEX` and the other index symbols (LR p.449), `&$C256` and others. | DONE (`sysvars_dcf.t`), EXT values |
| `&SYSYEAR &SYSMONTH &SYSDAYOFM &SYSDAYOFW`(1 = Sunday) `&SYSDAYOFY &SYSHOUR &SYSMINUTE &SYSSECOND`, zero-padded, settable, and the read-only `&$YEAR` (four digits) (LR p.443 Table 17; p.240–241); our old `&$DATE`/`&$TIME` are gone (not DCF). `&$GML &$EGML &$CW &$CONT &$SU &$LNUM &$TAB &$ENV`(= BODY) `&$PN`(= 1, the page state, below) (p.246–247). | DONE (`sysvars.t`) |
| The page state: `&$PN` (the page number; its numeric part, LR p.446 and p.447 note 3, so under `.pn roman` too it is the number) and `&$LC` (the lines left in the column, LR p.445).  In one pass they are neutral constants, 1 and 60: the page is not known while the document is processed.  With the pass model (`gml -aux`, below) each reference is a question to TeX, answered from the previous pass (see "Passes"). | DONE (`aux.t`) |
| `.se p = &` = the page number (p.254; LR p.337): a reference to `&$PN` (1 in one pass, a question with passes). | DONE (`manual_macros.t`, FIGNUM; `aux.t`) |

## Logic (ch. 22)
| Rule | Status |
|---|---|
| `.if c1 op c2 target`; ops `= eq`, `¬= ne`, `> gt`, `< lt`, `>= ge`, `<= le`; the shorter comparand padded with blanks (p.264; LR p.204 r4). The first token is always comparand 1: a null comparand is an error ("invalid comparison operator", p.266). | DONE (`if.t`, `manual_if.t`) |
| `.th`/`.el` use the most recent comparison in the current file or macro, preserved across macro calls and imbeds (p.265): each frame has its own.  With no comparison yet `.th` processes its target and `.el` does not (LR p.395 r5, p.164 r5). | DONE (`manual_if.t`, `diag.t`) |
| `.an` / `.or` (p.265; `.AND`, LR p.66). An `.an`/`.or` object of a condition is processed whatever its result, so `.if a .or b` works when `a` is false. | DONE (`manual_if.t`, `rel4_cw.t`) |
| `.go [TO] label` (LR p.179): TO is ignored (`.go to x`, `.goto x`); an undefined label is an error (DCF stops; we go on).  In a macro it searches from the **top**; in a file forward, then from the top (p.265).  The text after a label, from its first nonblank character, is a new input line (LR p.60). | DONE (`manual_go.t`, `go.t`) |
| `.do begin`/`.do end` (ours before) are removed: no DCF manual has them (a Waterloo leftover); Rel 4 `.do` is Define Object (LR p.147), not supported. | removed (`go.t`, `diag.t`) |
| `.cs n on|off|ignore|include` (LR p.105–106; p.267–268): sections are included unless ignored; `.cs n ignore/include` inside an ignored section has no effect (TABLE example, p.55–56; LR p.106 r6). | DONE (`manual_cs.t`, `manual_ef.t`) |
| In an ignored section "macros and GML tags are resolved" (SH35-0069 p.268): the macros invoked from it (frames not on the stack when it began, e.g. the APFs of its tags) run in full, so their symbol side effects happen, but the document builder is muted (no elements, hints, raw output, text or implicit closes), so the tree is as if the section were absent.  Kept by decision: the Rel 4 Starter Set's `:psc`/`:epsc` put the element in conditional section 9, which DSM@PROC sets to ignore (SSR B.2.16); that works only if the `:epsc` APF runs inside it.  LR Rel 4 reads otherwise: all control words in the section are ignored "except" `.cs n off` (p.105), "no control word processing is done" (p.464).  DCF-VERIFY: whether macro side effects happen. | DONE (`starter_psc.t`, `dcfstarter_psc.t`), DCF-VERIFY |

## Macros (ch. 23; LR .DM p.142–145)
| Rule | Status |
|---|---|
| **`.ms` is off initially** (p.271). With it off, the first 2 chars are the control word. | DONE (tests add `.ms on`) |
| Single-line form `.dm name /a/b/`: the line **is** substituted when `.su on` (p.274; LR p.142). | DONE (`macro_def.t`, `manual_macros.t`) |
| Inline `.dm name on … .dm off`: no substitution or tag scan of the body; `.dm off` must be in column 1 without modifier (LR p.143); a nested inline `.dm x on` ends the outer definition; single-line/subscripted `.dm` in a body are body lines (p.280). | DONE (`macro_def.t`, `manual_macros.t`) |
| Subscripted form `.dm name(n) /line/`, `.dm name() /line/` (step 10); n from 0; one final delimiter is dropped and no line is a null line (LR p.142); runs in subscript order; patches single lines; `.dm name(n) off` removes one (p.273, SH35-0050 p.16). `.dm name` alone is a null macro. Inline and single-line definitions are numbered 10, 20, … ; `&$LNUM` in a macro is the line's subscript (SH35-0050 p.16).  `.dm name x` (LR p.142–143): the current value of the macro into symbol `&x`, x a single alphanumeric character (not `@ # $`); `.dm name(n) x` line n (null if there is none); an undefined macro is an error.  DCF-VERIFY: the lines are joined by the control word separator (a blank without one), so that `&x` on a control word line runs them again; LR p.143 says only "the current value". | DONE (`manual_macros.t`, `manual_implguide.t`, `rel4_cw.t`, `dm_assign.t`), DCF-VERIFY joining |
| A running macro reads its definition **live**: a change to a later line takes effect in the same call (SH35-0050 p.181, DSM#DUPL), a change to a line already read at the next call (p.16). DCF-VERIFY (not in LR Rel 4): a running macro that is deleted ends there; one that is redefined goes on in the new definition. | DONE (`manual_implguide.t`) |
| Names ≤10 chars, case-insensitive; a macro may redefine a 2-letter control word (p.275). | OK |
| `&*` = everything after the blank after the macro name; `&*0` = token count; tokens delimited by blanks, arithmetic operators and parentheses (which are tokens); `'quoted'` is one token; `%` is a null token (p.253, p.276). No keyword arguments. (p.276 says `&*0` = 4 for `.insert filea 10 % fileb 15` but lists five tokens; we count five.) | DONE (`macro_args.t`, `manual_macros.t`) |
| Locals saved and restored across nested calls (p.276). | OK |
| `.me [line]`: the line runs in the caller, substituted with the macro's symbols (p.277, SH35-0050 p.17); outside a macro the line is processed as if written without `.me` (LR p.245 r1). | DONE (`manual_macros.t`, `manual_implguide.t`, `macro_ctl.t`) |
| `.ec .xx`, `.em .xx` (p.277–278). | DONE (`em.t`, `manual_macros.t`) |
| GML APF lookup finds the macro whatever `.ms` says (a tag is not a control word line). | DCF-VERIFY, not in LR Rel 4 (`gmlproc.ml`) |
| **Macro and symbol libraries** (p.239–240, p.281–283): `-lib dir` (repeatable, searched in order; DCF's LIB option takes up to eight). A member is the file `dir/NAME` or `dir/NAME.scr`, NAME the member name in upper case (≤ 8 characters, p.282; a longer name is never searched, DCF-VERIFY). A macro member is the whole body (no `.dm` line, p.283); a symbol member's value is its first line (p.282 note 63), trailing blanks removed (DCF-VERIFY: record padding). | DONE (`library.t`) |
| `.ly on|off|mac|sym`, initially OFF (LR p.243): ON searches for unresolved macros and symbols; MAC adds macros and SYM symbols to what was asked before; only OFF clears; `.ly` alone = ON. An unresolved macro is a control word line (`.ms on`, no modifier) whose long name is neither a macro nor a control word name, an `.aa`/class/direct APF that is neither a macro nor native, or the target of `.em`; the library is tried before the two-character native word, so `.dsmgdoc` is the macro DSMGDOC, not `.ds mgdoc` (DCF-VERIFY, not in LR Rel 4). Unresolved symbols: global, non-system names during substitution, the member name in upper case (`&libsym` and `&LIBSYM` both come from LIBSYM, p.240). What is found is defined, so the next use does not search (p.282); members are read once and misses are remembered. | DONE (`library.t`) |
| `.dm name lib` / `.se name lib`: fetched whatever `.ly` says, replacing any definition (p.282; LR p.243 r2); a missing member is an error. | DONE (`library.t`) |
| `.dm name off` outside a definition **deletes** the macro (SH35-0050 p.16, "Reclaiming Space"): the next call fetches the real macro from the library again, so a member that ends with `.dm name off` runs on every call; one that redefines itself as `.dm name /.*` runs once. | DONE (`library.t`) |

## Files (ch. 4)
| Rule | Status |
|---|---|
| `.im`/`.ap` semantics, Figure 4 (p.49–51); MASTER/FILEA/FILEB/FILEC (p.49). | OK (`manual_fig4_ap.t`, `manual_master.t`) |
| `(long.name)` in parentheses = the real file name (p.50). `.dd` is not supported. | DONE (`imbed_args.t`) |
| Imbed/append parameters are the **global** symbols `&0` … `&14` (p.252–253). Every `.im`/`.ap` resets `&1` … `&14` and sets `&0` to the number of non-null tokens; a `%` token leaves its symbol unset; a token is at most 8 characters (longer ones are cut, with a warning); more than 16 tokens on the line warn, two fewer for a parenthesised file name and one fewer per further word of it (LR p.68, p.208–209). | DONE (`imbed_args.t`) |
| `.ef`: re-imbedding resumes after the `.ef`; `.ef close` restarts from the top (p.50). `.ef` in the profile: the rest is the *epifile*, processed after the main document (p.50). | DONE (`manual_ef.t`, `ef.t`) |
| `.qu` / `.qq` stop processing, also from an imbedded file; the epifile is not processed (p.51). | DONE (`manual_ef.t`) |

## GML (ch. 24; LR .AA p.62–63, .GS p.183–188): see the Phase 4 rework
`.gs args v1 v2 ...` (LR p.187) sets the argument symbols of the current
macro (or of the file): `&*1 ...`, `&*0` (count), `&*` (the operand
string), destroying the previous `&*n` (SH35-0050 p.17); `.gs args` alone
sets `&*0` to 0 and `&*` and the `&*n` to null (LR p.187).  Values are
blank-separated; `'quoted values'` may hold blanks, `''` is null, a
doubled quote is one quote; `.gs args &* x` appends.  At file level
`.gs args`/`.gs vars` leave `&*` set, which dcfstarter's single-line `.dm f@ol /… &*` would
then substitute, so starterset.gml uses plain `.se` there
(`dcfstarter_compact.t`).  `.gs vars n1 n2 ...`
sets n1 to `&*1`, n2 to `&*2` ... (p.17: "totally equivalent to" `.se n1
'v1` ...); array names are refused (LR p.187).  DCF-VERIFY (not in LR
Rel 4): blank-only tokenization (`-1`, `a-b` stay one value, unlike macro
operands), a name beyond the last value gets null (`gs_args.t`).
`.gs qatt sym name ...` (LR p.185; SH20-9161-3 p.266): the listed
attributes that are not on the attribute stack become the elements of
`sym`; when all are present `sym` is undefined (DSMFTNT tests `&E'&*q`;
DCF-VERIFY) (`gs_qatt.t`).  `.gs hctr [n | n1.n2... | 0]` (LR p.185,
p.188; SH20-9161-3 p.266–268, `lib/headctr.ml`): a single number steps
that level and resets the ones below; a dotted value sets the counter
(letters for alphabetic positions, `A.0`), a zero position resets the
later ones, and `0` or no operand reinitialises it.  The first step after
a set is ignored at a level up to the deepest one set: after `.gs hctr
4.7.7.4`, `.h4` is 4.7.7.4, `.h5` 4.7.7.4.1, `.h3` 4.7.7 (LR p.188); it
also gives IBM's "Appendix A" (DSMAPPD sets `A.0`).  `&@xref` (LR p.185)
and `&xref` (SH20-9161-3; DSMHEAD1 prefixes appendix headings with
`&xref(1)`) get the counter to that level, their elements each position.
DCF-VERIFY (not in LR Rel 4): an ignored step above the deepest level set
keeps the levels below; the elements; `&@xref` after 0 (`gs_hctr.t`).
`.gs exatt [[NOT] name [AS apf] ...]` (LR p.184, p.188): an attribute
given more than once is processed once per occurrence, in order, each
with its own value (`:rdef` repeats ARRANGE; LR p.188 runs DIET twice);
the value is passed as the macro's operands, tokenized (`&*` the value,
`&*1` ... its tokens); a control word gets it as operands (`gs_exatt.t`,
`gs_purge.t`).  `.gs attval [[NOT] name [AS sym] ...]` (LR p.184,
p.188): no names = every stacked attribute; `&NAME` (upper case) or the
AS name as written gets the value (the text of p.188; its example shows
`&*xyz`); processed attributes leave the stack.  DCF-VERIFY: a name not
on the stack sets null (`gs_attval.t`).  `.gs purge`/`.gs purgemsg
[[NOT] name ...]` delete stacked attributes, PURGEMSG naming them (LR
p.185); `.gs snap [tag ...]` shows the rules and each tag's association
(LR p.186) (`gs_purge.t`, `aa_rules.t`).
`.gs rules [(rules) | =] [(end rules) | =]` (LR p.185–186): initially
(ATT NOVAT STOP NOMSG) (NOATT); `=` leaves a set unchanged, `()` restores
its default; the rule is NOSTOP (our old `step` is gone); NOATT means no
scan at all, the other rules immaterial.  An unquoted value that is not a
word of name characters should be quoted (LR p.186): warned and taken
(EXT).  DCF-VERIFY: the keywords change the current rules one by one
(`gs_rules.t`, `tag_scan.t`).  `.aa tag [apf (rules)] [endapf (rules)]`
(LR p.62–63): each APF a name, OFF (the association goes, the class
mapping applies), NULL or `.` (no processing) or `=` (unchanged); an
association keeps its rules when `.gs rules` changes (r2), a new APF
without rules keeps the old ones (r3), `()` is the current rules (r4); a
native control word as APF gets the value attributes as operands (LR
p.62, p.186).  EXT: `noelem` is frozen only when written, and rules with
no APF apply to the class mapping (`.aa ol (vat)`).  DCF-VERIFY: `.aa
tag` alone removes the association; an omitted side is deleted
(`aa_rules.t`, `aa.t`).  `.gs prefix [p [e]]` (LR p.187): the class
mapping's start- and end-tag APF prefixes, each OFF, `=` or one or two
characters.  EXT: the initial mapping, which LR Rel 4 does not give, is
direct (start tag x → APF x, end tag x → APF ex).  DCF-VERIFY: an
omitted end prefix is unchanged; `.gs prefix` alone restores the initial
mapping (`aa.t`).
`.xd name noid` (EXT): the element's `id` is not a document id, so it is
not checked for duplicates (`:rdef id` names a row definition)
(`tables.t`).
**Provisional elements:** a tag with no end tag (its `.aa` names no end
APF and there is no end-tag class APF) and no `.xd` model has nothing to
close its automatic element (IBM's profile has no models; its `:p :li :dt
:figref` ... have no end tags).  If it is closed by anything but its own
end tag it is left empty, a marker, with what followed it after it; an end
tag that does close it keeps the content inside (EXT, as the automatic
element is; LR Rel 4 has neither) (`provisional.t`).  An end tag with an APF closes its element after the
APF when a `.fn`/`.rh`/`.rf` flow is open inside it, since the APF ends the
flow (IBM's `:efn` → DSMEFTNT `.fn off`) (`provisional.t`).
`.gt`/`.ga` are Waterloo SCRIPT, not DCF. `&$TAG` is the tag name as written, in lower case, for a start and an end
tag alike (`fig` for `:efig`), and `&$TAGD` the delimiter that began it,
`&$EGML` (`:e`) for an end tag (LR p.446; SH35-0069 p.251; DCF-VERIFY:
the case) (`symbol_end.t`).
`.gs scan`/`.gs copy sym [string]` (LR p.184; SH35-0050 p.9, SH20-9186-06
p.13): with a string, that string is scanned (its attributes to the
stack); else the text after the tag up to the next tag on the line, not
the rest of the line.  `.gs insert` with no residual text still inserts,
as text (LR p.187) (`gs_scan.t`).  Scanning ends at residual text,
another tag or a control word line (LR p.187).  DCF-VERIFY (not in LR
Rel 4): with no residual text the symbol gets null; value attributes
found by `.gs scan` are dropped; a blank line also ends the markup; a
markup-continuation line is substituted on its own; an explicit APF that
does not exist is not replaced by the class mapping; a tag name over 8
characters (LR p.62) is text; whether the tag delimiter ends an unquoted
value.

## Formatting hints (Phase 5, `lib/hints.ml`)
Formatting control words do not format: each becomes a `gml:NAME` hint
carrying the new state, the operand and `break="yes|no"`.  The table in
`hints.ml` lists every word, its break behaviour and its attributes.

| Rule | Status |
|---|---|
| Space units (p.44–46, Figure 3; LR p.58 Table 6): `n` / `n.dd` / `n,dd`, `i`, `cm`, `mm`, `pN`/`NpM` (points), `cN`/`NcM` (Didot points), `mh`/`mv` (horizontal/vertical em), `m` = `mh` on either axis ("Em space (Horizontal) aMH or aM"), `dh`/`dv`; unqualified = lines (vertical) or characters (horizontal).  Normalised to `n` + `unit`, never converted. | DONE (`hints_units.t`, `rel4_cw.t`) |
| Breaks follow LR Table 13 (p.441) and the Notes of each entry: `.us`/`.up`, font words, `.hy`/`.hw`, `.ws` and an inline `.kp n` (LR p.228) do not break; `.in`/`.ir` and `.ls` break unless NOBREAK (LR p.210, p.237); `.tb`/`.tp` (LR p.374, p.401), `.vr` (LR p.423), `.wz` (LR p.434), `.pm` (LR p.284) and `.rh`/`.rf` (LR p.314, p.310) break; `.pa` always breaks and has no NOBREAK operand (LR p.276); `.re` breaks when the format mode or centring changes (LR p.309 r3).  `.tp` alone clears the tab table (LR p.400); `.tb` alone restores the initial tabs. | DONE (`hints_break.t`, `hints_env.t`) |
| `.in +n`/`-n` relative to the current value; `.in` alone = 0 and cancels `.of` too (LR p.211); a mixed-unit sum is kept as `3ch+1i` (unit="mixed"). | DONE (`hints_state.t`) |
| Any `.in`, a temporary one too, clears all offsets ("any .IN request clears all offsets", LR p.260; Figure 6, p.80): its hint carries `offset="0"` (scope.xsl, gml.tex).  `.ir` does not. | DONE (`hints_offset.t`) |
| Only space-unit operands are normalised in a `spec`: the factors of `.ls BY` and its SKIP/SPACE/TEXT/ALL ranges (LR p.235–237; NORMAL/INCREMENT/EXTRA are vertical amounts), `.ws`/`.es` `BY` (p.106, p.114), the `.wz`/`.pn`/`.fl`/`.bc` operands and the `.cd` column count stay as written. | DONE (`hints_spec.t`) |
| Line-counted words (`.ce`, `.ri`, `.us`, `.up`, `.uc`, `.rc * c`) are `gml:lines` scopes over the input text lines they cover; elements inside a scope split it (`cont="yes"`).  The words that count output lines (`.in`/`.ir` FOR/AFTER, `.il`, `.un`) are hints only (below). | DONE (`hints_lines.t`) |
| `.in [h] [[FOR] v1] [[AFTER] v2]` (LR p.210–212): without FOR the number after h is v1, without AFTER the next one is v2 (r6, r7); v1 `*` is permanent, v2 0 or omitted is at once.  The example `.in .7i 1` "(or .in .7i for after 1)" (LR p.212) is a misprint: SH20-9161-3 prints `.in .7i 0 1` (or `.in .7i for 0 after 1`); r6/r7 govern.  FOR and AFTER are vertical distances of output (r1: "for all following lines (including new paragraphs and pages)"): the engine sends one hint, `for`/`for-unit` (with `temporary="yes"`) and `after`/`after-unit` as given, lines (`unit=line`) or a dimension, and counts nothing; its state is the permanent indention and a temporary one until changed (v1 = 0), which `&$IN` gives.  r4 wants "the composite net indention for the next output line, including permanent and temporary components": a FOR or AFTER distance is measured by TeX (lines of text, skips and spaces all use it, so even one given in lines cannot be followed by the engine), so `&$IN` is the indention once the pending distances are over, without a pending `.il`/`.un` (limit).  gml.tex measures: a global queue per side (`.in` left, `.ir` right) of the distance left before the change (AFTER) and of the change (FOR); n lines are n`\baselineskip` when the hint is seen.  Line i of a paragraph starts (i−1) lines after its first, and is moved iff AFTER ≤ (i−1)`\baselineskip` < AFTER+FOR: it starts before the distance is used up (stretch ignored).  A paragraph then uses its `\prevgraf` lines, a skip or space its amount; nothing counts before the first nonblank text line (r3), nor a skip at the top of a page, which TeX discards.  The shape is set as `\parshape` at each paragraph end (also one ended by `\endgraf`), as long as it needs (no line cap; beyond `\maxdimen`, about 1365 lines of 12pt, the distance has no end); format-off lines are one-line paragraphs.  `.of` is folded into the shape; a new `.in`/`.ir` empties its side.  Each vertical list has a queue of its own: the main list, and every box (`\everyvbox`, `\output`, the footnote `\insert`: `\gml@pqenter`) starts with an empty one, the queue outside coming back when the box ends; so a figure, table cell or footnote neither takes the distance of the text around it nor uses it, and a FOR, AFTER or `.il` inside it is measured there (a format-off figure: a line each).  LR p.228 `.KP` r1: a keep "operates with a separate environment", its indention "set to the basic indention currently in effect"; DCF-VERIFY that a temporary indention of the text outside does not go into it.  A box without a queue (an `\everyvbox` a tag set sets after `\gmlbegindocument`) uses none and a hint there moves one paragraph.  The rows of a table use their height (as text: they begin the count).  `.sa`/`.re`: gml.tex saves the queue at `gml:sa` and puts it back at `gml:re`.  A permanent `.in` with AFTER queues the old margin for v2.  HTML (html.xsl): `.in`/`.ir` FOR is an empty float (`span.gml-in`/`gml-ir`, `aria-hidden`, inline CSS only) before the next text: `float` and `clear` on its side, the width the new margin less the one of the scopes around, the height v1, or v2 + v1 with `shape-outside: inset(v2 0 0 0)`; n lines are n`lh` (CSS `lh`, 2023 browsers).  The lines beside it make room, across paragraphs and the skips between them, as DCF counts; placed before the first text, a paragraph's top margin does not count.  A FOR inside running text gives a `br` (the paragraph is not split).  Limits: an outdent for a distance (a margin left of the one around) is dropped, a float cannot move lines out; the AFTER of a permanent `.in` is ignored (scope.xsl applies the margin at once); a new `.in`/`.ir` ends a distance only when it is a FOR given before the text (the earlier one is not written; a float clears the floats of its side), a float placed is not shortened by a later margin change; a float stays in its block formatting context (a table cell, a `pre`); a line taller than `lh` counts as more than one.  There is no display math in gml.tex.  Limit: a skip at which TeX later breaks the page (and discards it) still counts.  TeX's page builder chooses a glue as the break only when it meets a later breakpoint, after the next paragraph has been shaped and broken; a refund then would leave that paragraph wrong, and finding the break in `\output` (the page's height against `\pagetotal` at the skip) or through the aux file was judged too fragile (merged skips, insertions, the table and index output routines).  Only a skip on an empty page (`\pagetotal` = 0) is not counted.  DCF-VERIFY: r3 speaks of v2 only; we apply it to v1 too (a skip of a paragraph tag before the first text line does not use a FOR); it is apart from the trigger of `.il`/`.un`, which a skip does use up. | DONE (`hints_offset.t`, `hints_lines.t`, `hints_env.t`, `tex_forafter.t`), DCF-VERIFY v1, keeps |
| `.il h` / `.un h` (LR p.206, p.416): the next output line shifted "from the current margin (which includes any indent or offset values in effect)" (p.206 r1; `.un`: subtracted from the "indent value plus offset value", p.416 r2): `h`/`+h` right, `-h` left, `.un 5` = `.il -5` (r3); the sign is a direction, not an increment, and successive ones without text: the last (r5, `.il 4m` `.il +6m` is 6m; p.416 r3).  The engine sends `il`/`un` with `shift` (signed, to the right) and `unit`; gml.tex adds it to the shift the line has (a FOR/AFTER, `.of`, in the `\parshape`; the permanent `.in` is in `\leftskip`).  The word "is triggered by the next text, skip, or space line" (p.206 r7, p.416 r4; `.pp` is `.sk` then `.il +3`, LR p.474): the first line of the next paragraph takes it, a `.sk`, `.sp`, blank line or the skip of a paragraph tag uses it up, so a document gives it after the paragraph tag.  A `.in` leaves it pending (Table 25 note 3, p.451: `.IN .IL .UN .OF` values "individually saved"; DCF-VERIFY).  In a box, the box's own queue; `.sa`/`.re` save and restore it.  Not checked: a line moved left of the real margin (r6, p.416 r2: an error).  HTML (html.xsl, decided on the output blocks): `text-indent` on the block when the moved line is its first and it has no block inside (the `.il` after a paragraph tag; `.un` too, a hanging line, which may reach into the page margin); else a moved-right line is a float `span.gml-il`, h wide and 1`lh` high, before the text (after a `br` inside running text); nothing when a block ends or a whole one (a skip) comes between the hint and the text, nor for a line moved left that is not a block's first; of several, the last. | DONE (`hints_lines.t`, `tex_forafter.t`), DCF-VERIFY `.in` |
| `.li` (p.89; LR p.231) literal mode: only a `.li off` line (column 1, LR p.464 r6) is a control word; other lines are substituted and scanned for GML tags; no separator split, no implicit words. | DONE (`hints_li.t`) |
| `.tr [s t ...]` (LR p.404): pairs; a source without its output character is an error (the pairs before it are taken); no operands restore the initial table; hex codes are EBCDIC (see Symbols).  The text of a running heading or footing is translated with the initial table as changed by `.tr` inside the definition (r4): a definition starts with its own empty table (`Doc.tr_table`), and the document's table is untouched.  Not yet modelled: DCF translates the output line just before it is measured (r8), so a change in mid-line affects the whole line; here text is translated as it enters the tree. | DONE (`hints_tr.t`, `running_symbols.t`) |
| `.sa [name]` / `.re [name]` (LR p.323, p.309; Table 25 p.451) save "the active and page environments along with the .TI and .TR translate tables".  Of them the engine tracks the indention (with a temporary one until changed), offset and right indention, line length, format mode, hyphenation, the font stack (SH35-0069 p.179), the `.tr` table, the `.dc` characters CONT CW GML MCS PS, and the `.ce .ri .us .up .uc` line counts.  The rest of the indention (Table 25 note 3: the `.IN .IL .UN .OF` values "individually saved"), the FOR/AFTER distances left and a pending `.il`/`.un`, is gml.tex's: saved at `gml:sa` (unnamed ones on a stack, named ones by name) and put back at `gml:re` (the `in` hint with `restore="yes"` that follows sets only the margin); as LR p.323 r5 says, a `.sa` within a line saves before that line is counted.  Named environments are apart from the unnamed stack: `.re` restores the latest unnamed one, `.re name` that one, dropping none; with nothing saved `.re` restores the initial values (LR p.309 r2).  Hints `gml:sa`/`gml:re` (with `name`), and after `gml:re` the ordinary hints for each part that changes, with `restore="yes"` (`.pf` for fonts pushed since the `.sa`), so backends need not know `gml:re`.  Not saved yet: tabs, `.ls`, `.sb`, `.rc`, `.ti` (not implemented), the page words (hints only). | DONE (`hints_env.t`) |
| A footnote saves the active environment and clears the offset; `.fn off` restores it, without hints (LR p.451; SH20-9161-3 p.110). | DONE (`hints_env.t`) |
| `.fv top|bottom|center|justify` (LR p.177): hint `gml:fv spec`, no break. | DONE (`hints_env.t`) |
| `.pi [start|end|order|ref] [key /k1/k2/k3/] /t1[/t2[/t3[/page]]]` (SH35-0069 p.213–218, SH20-9161-3 p.297): hint `gml:pi` with `t1`–`t3`, `k1`–`k3`, `start/end/order="yes"`, `page="text"` or `pageref="no"` (null fourth term; absent or the page number symbol = current page), `see` (REF: the last term). Ignored unless `&$INDX` = 1. `.ix [n] [name|control|/]` (SH20-9161-3 p.291): hint `gml:ix [reserve] [title]`, a control-word operand is processed in place of the heading. resolve.xsl builds the index from the `gml:pi` (merging terms by their upper case, SH35-0069 p.218) and puts each `.ix`'s entries after its `gml:ix` (fixture `resolve/index-pi`). | DONE (`index_pi.t`) |
| `.dh n num/nonum` and the head-level counter (SH20-9161-3 p.247, p.266–268): an `.hn` of a NUM level gets `num="1.0"` / `"1.2.1"`; see `.gs hctr`. | DONE (`gs_hctr.t`) |
| `.ct text`: the text is an input line, so a continuation character at its end continues it (IBM's DSMFDESC `.ct :&$RB.&$RB.&$CONT`, which left a stray `&X'03`, shown as U+FFFD, in the output). | DONE (`ct_cont.t`) |
| `.ct` joins the previous text across what does not break: hints with `break="no"` and element ends (`:hp1`…`:ehp1` then `.ct ,`), as DCF joins the output words; a break cancels it (p.47; p.107 `5` `.sb` `.ct 3`). | DONE (`ct_cont.t`) |
| `.dv name [FONT f] [BASELINE b] [TEXT] /string` (LR p.157–159; p.258–261): with a keyword, a text variable: the hint `gml:dv` (`text`, `font`, `baseline`, positive up as for `.sb`) where the symbol enters the text, which gml.tex sets in that font, raised; a plain `.dv name /string` is a symbol (DSMPROF3 uses it so under `.su off`, once as a control word line).  The name is at most 10 characters and not an array (LR p.157); FONT or BASELINE and TEXT exclude each other, the last one given counting (LR p.159 r12); BASELINE without FONT is allowed (the syntax, LR p.157).  `.ty` and `.mg` write a text variable as its string (`+++ASSERTE &util ...` from `&amp.util`). The Starter Set profiles define `&amp.` `&gml.` `&semi.` as DSMPROF3 does, `.dv amp text /&`, `.dv gml text /:`, `.'dv semi text /;` (starterset.gml), not by the translate-table method of p.259 (a code point given up and `.tr` back on output, which a message never sees). DCF-VERIFY (not in LR Rel 4): no string = null. | DONE (`dv.t`, `dv_messages.t`, `hints_rel4.t`), DCF-VERIFY |
| `.hr [rule] LEFT|h1 [[TO] h2 | FOR l | RIGHT] ...` (LR p.192–193): a bare number after a start position is the end (TO optional); a rule name needs a displacement (alone it is an error); no operands repeat the previous rule (r6, `repeat="yes"`), with none before, a rule across the column. DCF-VERIFY (not in LR Rel 4): a start position without an end runs to the right edge of the column. | DONE (`dv.t`, `hints_rel4.t`) |
| `.dh n` TC/NTC TO/NTO TS/NTS DOT/NODOT TCIN h TFONT f (SH20-9161-3 p.247), defaults of SH35-0069 Figure 14 (p.153: entries for 0–3, level 0 an entry only, a skip before level 1, TCIN 0 0 0 2 4 6 8); `.pt text` / `.pt .xx` (p.155); `.tc [n] [title|/]` (p.156–157): an eject, the title (`&SYSCONTENT`, else CONTENTS), the entries "prior to the .TC during the current or previous pass", `n` pages reserved (`lib/toc.ml`).  Each entry's heading carries `gml:tcmark`, and the entry `anchor=` (gml.tex's page reference gives the page on the second TeX run); with passes an anchor's page from the previous pass's aux file gives `page=` (`Ctx.page_of`).  One pass: a `.tc` before its headings is empty (dcfstarter prints its TOC only with more than one pass, `&$PSNO gt 1`); with passes it prints the previous pass's entries (below). | DONE (`toc.t`, `hints_flow.t`, `aux.t`, `symbols_pass.t`) |
| `.dh n` options of Rel 4 (LR p.136–138): BR/NBR PA/NPA TC/NTC TO/NTO TS/NTS UP/NUP US/NUS DOT/NODOT NUM/NONUM SECT/NOSECT AUTOHY/NOHY, CENTER LEFT INSIDE OUTSIDE RIGHT, OJ/NOJ, NOHANG, HANG n|AUTO, FONT f, SKBF/SPAF/SPBF v, TCIN h, TFONT f; any other word is warned about and skipped (our old `hy tind tskip` are gone). `.dh n` alone restores the level's initial definition. US "underscore the head level" (LR p.138) is set in italic by gml.tex, as a `.df` US font is: a rendering choice (user preference), while `.us`/`.uc` keep `\underbar`. | DONE (`hints_rel4.t`); US italic by choice |
| `.h0`–`.h6`: `gml:h level=n` closed at the end of the line. | DONE (`hints_flow.t`) |
| The page number symbol (`.dc ps`, `&$PS`, default `&`) "is replaced, wherever it appears in the running heading and footing, with the current page number" (SH35-0069 p.125; p.128, p.259): in the text of an open `gml:rh`/`gml:rf` it is split off as the hint `gml:pageno`, before `.tr` translation and outside text variables, so `&amp.` stays text, whether DSMPROF3's text variable (the profiles') or X'08 translated to `&` (p.234 and its note 60, p.259); a `.sx` there whose fields hold it gets `pagesym=` (the symbol).  The `.sx` fields are split around the symbol (not inside a text variable) and put out (`.tr`, text variables as their text) piece by piece, and `pagesym=` names it (U+E000 if a piece contains it as text).  tex.xsl writes such a heading or footing as `\gmlrundyn{...}`, which gml.tex typesets again at every page with the hints made local (the environment is saved and restored around a running heading, p.128 note 37); `gml:pageno` and the `.sx` fields split at `pagesym` are `\gmlpageno{}`, so a text `\&` stays an ampersand.  | DONE (`dv.t`) |
| The other symbols of a running heading or footing are "replaced with the symbol's value when the running heading is placed on the page", substitution being off while it is defined (LR p.312 r7, p.315 r7), "the value of the symbol at the time the page is started" (p.316, also for unresolved symbols).  The definition is still processed where it is defined; while it is open, a reference to a global user symbol in its text (a text line, the line of `.ce .ri .us .up .uc`, a `.sx` field, `.ct`) is deferred: `<gml:symref name="NAME">value now</gml:symref>` (as written when the symbol is not set; in a `.sx` field the value between U+E001 NAME U+E002 and U+E003).  Not deferred (substituted now, as before): the operands of other control words and macro calls (`.if .se .sk`: `lib/interp.ml` takes the deferred spans out), local symbols (macro parameters), `$` system symbols, array elements, attribute operands, the end of a compound reference (`&type&x`), and a value beginning with the separator; a value with references in it (DSM#SET's `@shead = '&@stitle.'`) is carried substituted.  Every later `.se`/`.gs vars`/APF assignment or removal of a symbol so referred to is the hint `gml:symval name value` (break="no") where it happens, its value substituted (as written when removed).  tex.xsl: `\gmlsymval` is an e-TeX `\marks` of a class per name; `\gmlsymref` in the heading (made dynamic, `\gmlrundyn`) takes the last mark before the page's first line, else `\topmarks`, else the carried value (Knuth's `tex`: always the carried value).  html.xsl, strip-hints.xsl: `gml:symval` dropped, `gml:symref` its value.  Limits: marks inside boxes (figures, table cells, footnotes) do not reach the page; a change between two `.sk` skips makes them add up (the mark hides the first from `\lastskip`); the rest of a page split by the table output comes back with its marks; a two-column output routine sets the heading at its second column; the value is not translated by the heading's `.tr` table when it comes from a mark; symbols inside a carried value are taken where it is set, not per page.  IBM's DSMPROF3 footing `.'sx f &X'01.&@shead.&X'01...` now shows each page's section title (and with SYSVARD=yes its odd and even footings).  `.rh`/`.rf` inside a definition ends it (LR p.311 r4, p.315 r4; DSMPROF3's `.rf odd ... .rf even ... .rf off`).  DCF-VERIFY (not settled by LR Rel 4): a `.se` in the first output line of a page counts from the next page only (gml.tex counts the marks before the first line; LR p.315 r1 warns that a non-breaking `.se` may act "earlier than expected" and advises a `.br`); and every global user symbol is deferred, also constant ones such as the text variable `&amp.` (same output, marked as `gml:symref`). | DONE (`running_symbols.t`, `tex_symref.t`, `dv.t`), DCF-VERIFY |
| `.bf [font...] [=]` (LR p.75–77): no font restarts the current font, saved for `.pf`; `=` restarts quietly when none of the list is usable.  `.rh`/`.rf` [ODD|EVEN] (LR p.310–314) limit the definition, or the CANCEL/SUP/RES action, to pages of that parity; gml.tex acts per parity. | DONE (`hints_rel4.t`) |
| `.df` TYPE (LR p.130–132): a size is points, signed relative, 0 unchanged; an omitted weight is MEDIUM and an omitted width NORMAL, not inherited (tex.xsl).  EXT: the 3800 font ids (LR Tables 29 and 32 and the GS GU TU fonts of Table 31, p.455–457), in `.bf`, `.pf` and `.df` FONT, are faces of gml.tex by role: text fonts roman, italic and underscored ones italic, bold and overstruck ones bold; pitch and family are not kept (`\gmldeffont{gt12}{...}` changes one).  Provisional: by role or by family is decided when font selection in TeX is modelled.  Not yet modelled: OLDWEIGHT/OLDATTR.  DCF-VERIFY: the family is guessed from the typeface name. | partial (tex.xsl, `tex_fonts3800.t`), DCF-VERIFY, EXT 3800 ids |
| Device words (`.dd .it .sv .dl .uw .oc .sy .te .lo`) warn once each. | DONE (`hints_flow.t`) |
| `.mg /code/message/` (LR p.246): a single field is the code; the last character of the code gives the severity: R and I informational, W 4, E 8, S 12 and T 16, S and T stop.  We emulate the MESSAGE(ID) option (the code is shown) and CONTINUE (an E message goes on; NOCONT is DCF's default, LR p.37).  `'&*r'` in the message text is an ordinary symbol reference. | DONE (`rel4_cw.t`, `starter_context.t`) |
| A null line in fill mode adds no text (p.281; LR p.252: `.nl` cancels a continuation); a blank line is `.sp 1` (LR p.78).  EXT: in no-fill mode a null line is kept as an empty line, as a blank one is (modern editors write null lines where CMS had blank ones). | DONE (`text.t`), EXT no-fill |

## Passes (FPASSES/TWOPASS; `gml -pass/-passes/-aux/-symbols-in/-symbols-out`, `gmlpass`)
| Rule | Status |
|---|---|
| **FPASSES(n) / TWOPASS** (LR p.35; SH20-9186-06 p.126, p.129): the document is processed n times (TWOPASS = FPASSES(2)), output only on the last pass; IBM's limit is 4.  Here a pass is a gml run and a TeX run (`gmlpass`, default 4): before the last pass TeX makes a draft (gml.tex `\gmlpass`: `\pdfdraftmode`, ApTeX's DVI path), the last puts out.  Modern edge: gmlpass stops early when a pass leaves the aux and symbol files as the pass before (the next would repeat it) and goes to the last pass, numbered n; it warns when the last pass still changed them. | DONE (`passes.t`, `tex_pass.t`) |
| `&$PASS` = the current pass, `&$PSNO` = the number of passes requested (FPASSES(n), 1 without; LR p.35, p.444), `&$TWO` = 1 only for TWOPASS or FPASSES(2) (LR p.444 Table 19).  The profiles test `&$PSNO gt 1`, and the last pass as `&$PASS` = `&$PSNO`.  Our old `&$PASSES` is gone. | DONE (`symbols_pass.t`, `passes.t`) |
| `.tc n title` reserves n page numbers (TPG p.157): the page after the table is numbered as if the table had n pages, so that the pages after it are the same on every pass. gml.tex renumbers at `gml:tc action=end reserve=n`; dcfstarter takes n from `f@tcres`. | DONE (`toc.t`) |
| **Symbols carried to the next pass** (TPG p.233; LR p.359 .SU r4: a symbol defined later in the document is known on the second pass): `-symbols-out` dumps every global symbol defined at the end of the pass (not system, local, date and time symbols), `-symbols-in` loads them before the profile runs, so `-set` and the profile's `.se` lines win.  The file is SCRIPT `.se` lines the next pass imbeds (README "Passes"; lib/symbols.ml).  The TOC entries (DSMUTTOC) go along as the array `gml@toc`: a `.tc` prints the previous pass's entries (p.156).  Modern edge, the page provenance: a symbol set by `.se` to the answer of the one page question on its line (`.se fp@ID = &$PN`) goes as an element of the array `gml@pgq` (name, subscript, question id, neutral default), and the next pass sets it to the answer the aux file of the same pass gives, so a forward page reference is right on pass 2.  DCF sets `.se refer = &` twice, again when its output line is placed (LR p.340 r6), so its `&$PN` is the page on pass 1 already.  DCF-VERIFY (not in the Rel 4 manuals): a line end in a value is written as a blank; the set of symbols DCF keeps, and whether the profile's settings are redone (we redo them). | DONE (`symbols_pass.t`, `passes.t`, `page_provenance.t`), DCF-VERIFY |
| The page questions: with `-aux` each reference to `&$PN`/`&$LC` is a hint `gml:query id what` (`\gmlquery`); TeX writes `.se pq@ENC = v` to `JOB.gmlaux` (ENC: the id without its `q`, `.` as `@`; gml.tex header), which the next pass imbeds: `pn` at shipout (the page the place is put out on, so a target's recorded `&$PN` is the page an anchor would give), `lc` at once.  Ids `qF.L.N` (file, line, n-th on the line) keep the answers of the other lines when a pass takes another decision on one line. | DONE (`aux.t`, `tex_pass.t`) |
| `&$LC` in the middle of a paragraph: TeX has not broken the paragraph yet, so its lines are not counted (in vertical mode the page builder runs first).  This matches DCF: `&$LC` excludes "unplaced keeps, floats, footnotes, tables, widow zones, and partial lines" (LR p.445 Table 20 note 3); it counts line spaces of the default font, and in page mode DCF says to use `&DV'&$LC`. | DONE (`tex_pass.t`) |
| dcfstarter: `ss@last` (starterset.gml; also removed at starter's `:egdoc`, `starterset.t`); `DSMGML013W` (ours) and the "ID unknown" texts only on the last pass (a stand-in, the ID, before it); duplicate IDs checked per pass (`f@dfid`: a stamp per ID, removed at `:egdoc` with the other per-pass state so that two passes in the same state write the same symbol file). | DONE (`passes.t`) |

## Starter Set profile (`share/profile/starter.gml`)
Modelled on DSMPROF3 (SH35-0050 Figure 7): `.aa` mappings of every Starter
Set tag, `.xd` implicit-close models, DSM#CNTX/DSM#RSET messages through
`.mg`, `:xmp` verbatim (`xml:space="preserve"` + `.fo off`).  `&date` is
built like DSM#SETS ("June 13th, 1986").  What does not depend on the
output is shared with dcfstarter in `share/profile/starterset.gml` (`.im
starterset`, `ss@...` names): the delimiters, text symbols, `&date`,
`:psc` (DSMPSC, `starter_psc.t`, `dcfstarter_psc.t`), the message
catalogue, the out-of-context maps (DSM#CNTX with DSMPROF3's attribute
rules: `:li :title :thd :tft :row` scan theirs, so they go with the tag,
`dcfstarter_cntx.t`) and the table decisions.  `-profile starter` searches
`-share dir`, `$GML_SHARE`, then `share/gml` near the executable (or the
source tree's `share` from `_build`); that profile directory is also
last on the `.im` path so a user profile can `.im starter` (p.297).
**Messages** are IBM's numbers and wording (MSG p.5–11), written
`+++DSMGMLnnnx TEXT (page n)`, under both profiles from one catalogue
(`ss@msg`); the `DCFSnnnW` prefix is gone.  Old → IBM: 004→011, 014→004,
010→005, 011→006, 012→019, 013→009, 015→017, 017→024, 018→015.  Ours, at
numbers IBM leaves free: 010 (a cell the row definition lacks, E, the
text of SCRIPT/VS 449 E, MSG p.29), 012 (a row definition redefined in a
table, E), 013 (an unknown REFID), 018 (a list ended after a term without
its description).  New: 008, 021, 022, 023, and SCRIPT/VS SVS445S,
SVS447E, SVS448W from resolve.xsl.  Old 005 (an end tag of another list
type) is dropped: DSMPROF3 maps every list end tag to DSMELIST, which ends
the innermost list (SSR B.2.9) (`starterset.t`, `starter_context.t`).
Laid out by TeX (gml.tex `\gml@ibmmsg`, written to the log and to
JOB.gmlmsg, which gmlpass shows after the last pass): SVS445S when k*
cells get no width, severe (TeX stops with an error); 020 W, a cell too
narrow for its indents, which are then zero.  043 I (a title page past
one page) is dcfstarter's: f@tipg compares `&$PN` at its start and end,
so it comes from the second pass (`tex_msgs.t`).
`:q` nests (`&@nest@q`, DSMQUOTE/DSMEQUOT, SH35-0050 p.125); APF macros
that read state at call time use the inline `.dm` form, since a
single-line `.dm` is substituted when it is defined (p.274).  **EXT:** a
footnote has its own flag `&@fn` instead of `&@state = N`, so `:fn` is
allowed inside `:fig`/`:xmp` (DSMFTNT refuses it there because keeps and
floats exclude footnotes, SH35-0050 p.129; the tree has no such
conflict) (`starter_nesting.t`).

## Tables (SH20-9186-06 ch. 7, p.51–71; SH20-9187-06 §3.31–3.36)
In this section a bare "p.n" is SH20-9186-06 and "§x" is SSR.  The Rel 3.2 tag set: `:rdef :table :thd :tft :row :c :tcap :tdesc :tnote
:tref :tlist`.  The profile checks attributes and context; `xslt/resolve.xsl`
assigns cells to the ARRANGE grid (see its header); the backends lay out the
result.

| Rule | Status |
|---|---|
| `:rdef` holds HP ALIGN CONCAT VALIGN ROTATE MINDEPTH ARRANGE CWIDTHS (p.52–54, §3.31.1). Its `id` names a row definition, not a cross-reference target: `.xd rdef noid`, so a table may share it. | DONE (`tables.t`) |
| ARRANGE may be repeated, one grid row per attribute (p.54, p.66); the engine joins the values with ` / `. Lines of different lengths, or a value that is not a positive integer, give one cell (DSMGML021W, MSG p.8). A cell number must make a rectangle, else an error (LR .TD r2 p.382; SVS447E); the cell takes its first square (DCF-VERIFY: DCF's recovery). | DONE (`tables.t`, `resolve/tables-diag`) |
| CWIDTHS gives one value per grid column (p.54–55); `*` and `k*` are shares of what is left (§3.31.1; LR p.381). Extra values warn and are ignored (SVS448W), missing ones are `*` (LR p.382 r3); a width that comes out zero or less is a severe error (LR p.383 r4; SVS445S, for a factor of 0 and for absolute widths no narrower than the table). No CWIDTHS = one cell, no ARRANGE = one cell per width. DCF-VERIFY (gml.tex): widths that do not add up to the table. | DONE (`resolve/tables`, `resolve/tables-diag`) |
| The per-cell attributes (HP, ALIGN, ...) take their values in **ascending cell number order** (§3.31.1: "the first value applies to the first cell"; DCF-VERIFY: with gaps in the cell numbers); missing values repeat the last one, extra ones are ignored. Abbreviations (`l c r`, `y n`) are expanded; a bad value is DSMGML015W and the default used. | DONE (`resolve/tables`) |
| `:c n` may come out of order; a cell number already filled in the row adds a `gml:cpart` to that cell (separated by a rule); an unnumbered cell takes the next free number; a full row starts an implicit new row (p.56–57). A number not in the row definition is DSMGML010E (ours; §3.32.3 "an error results") and the next free cell is taken; past the last cell of a header or footer the `:c` is ignored (DSMGML023W). | DONE (`tables.t`, `resolve/tables`) |
| CONCAT=NO keeps the cell's input lines (p.53): each input line an output line, a blank line an empty line (LR .BL p.78; §3.32.3.1): `xml:space="preserve"` and `.lb`/`.bl`/`.nl` macros while the cell is open (starter), a format-off region (dcfstarter). | DONE (`tables.t`, `dcfstarter_tables.t`) |
| `:thd`/`:tft` before the first `:row`, else ignored (DSMGML024W); their own REFID chain, apart from the rows' (§3.32.4–5; Rel 3.2 ties them to the table's). The heading repeats on each page, the footing ends each part (p.57). | DONE (`tables.t`) |
| SPLIT on `:table` and `:row` (p.55–56): no = keep with the previous row. COLUMN/PAGE (p.55) become `span`. ROTATE 0/90/180/270 on the table and cells; a rotated cell without MINDEPTH is DSMGML022W. | DONE (backends) |
| `:tcap` (one line, no tags) numbers the table and enters the list of tables; `:tdesc` follows it to `:etable` (p.58). `:tnote` is a full-width row starting "Note:" and ends the row (p.58–59). | DONE (`resolve/tables`) |
| `:tref refid` exists in Rel 3.2 ("To Tables", ch. 8 p.76; an unmatched reference p.78); `page=` as for `:figref`. `:tlist` lists the captioned tables (§3.34). | DONE (`tables.t`) |
| SHADE (`xlight light medium dark xdark`, §3.31.1, Rel 4) is checked (DSMGML015W) and carried; gml.tex does not shade, with a message. | partial (`resolve/tables-diag`) |
| Formatting (the `dcfstarter` profile): the space before and after a table is DSMPROF4's `&@sk@t`, `.1i` (SSR Figure 11, topic A.1, where ".li" is a misprint); "Table n." in hp2 before the caption; `:tdesc` joins the caption after a **colon** (p.58; §3.33.2 notes that the Rel 4 book itself, not formatted with the Starter Set, shows a period); "Note:" in hp2 starts `:tnote` (p.59). Not modelled: `&@in@t` (caption indention), `&@in@c`/`&@ir@c` (cell indention, a tenth of an inch) and the thicker outer rule `@t@thick`: gml.tex uses its own padding and one rule weight. | DONE (`dcfstarter_tables.t`, `tex/dcfstarter-tables`) |

## IBM's macro library (SH35-0050-2 Appendix C, local transcription)
The transcription in `test/dcf-real/` (gitignored, IBM copyright) runs
with `-lib test/dcf-real/members -profile .../DSMPROF3.scr`; README
"Testing against IBM's Starter Set" has the command and the open gaps.
Points settled while checking it against the scan:

| Point | Status |
|---|---|
| The `index`/`substr` lookup tables in DSM#SETV and the ordinal string in DSM#SETS (1st–31st) are consistent with the transcribed blank and dash counts. | OK |
| DSMPROF3's `@oquote`/`@cquote` are qstring-form `.se` lines: `'` followed by seven `"''` groups, unclosed.  Each doubled quote is one quote, so the value alternates `"` and `'` and DSMQUOTE/DSMHDREF's `substr &@oquote &@nest@q 1` gives `"` `'` `"` `'` for nesting levels 1–4.  Its `.gs args` is `'"' '''' '"' ''''`. | OK (`se_expr.t`) |
| `.if SYSOUT eq PAGE` (no `&`) in DSMPROF3 and `&@sK@x` in DSMEXMP are as printed. Symbol names are case-sensitive (SH35-0069 p.239: `&libsym` and `&LIBSYM` are "separate and unique symbols"; SH20-9161-3 .SE note 1: "symbol1, Symbol1, and SYMBOl1 are three distinct symbols"; LR .SE r2; only `$` names are upper case only), so the latter never matches `@sk@x`: a latent bug in IBM's listing, kept (`.sk: invalid space unit`). | OK |
| With the system symbols, `.sa/.re`, `.pi/.ix`, `.gs qatt/hctr` and the EBCDIC codes, the listing runs with no `-set`; DSMPROF3's `.go &$PDEV.f&$CHAR(0)` finds `3800f2`. The remaining diagnostics are the `.sv` device word and the `&@sK@x` above. | OK |
| IBM's `.dm NAME off` at the end of a member deletes the macro after use, so the next call reloads it from the library (SH35-0050 p.16). | DONE |

## Not yet modelled, and open questions without a row
| Point | Status |
|---|---|
| **Full stop: TeX's sentence spacing, not DCF's** (user decision 2026-11-10).  DCF adds an extra space, `.es` wide (default one word space), only where an input line ends in a full-stop character (`. ! ? :`, before a closing `"` or `)`; `.dc stop` replaces the set) (LR p.114–115, p.118, p.166–167).  We keep the white space of a line end an ordinary blank, as in XML, and let TeX's sentence spacing (`\nonfrenchspacing`) work wherever a sentence ends: `.es` sets `\xspaceskip` (gml.tex), and `.dc stop` is not modelled. | EXT (deliberate) |
| Rel 4 behaviour we know and do not have: `.tr` at output time (LR p.404 r8); `SYSPAGE`/`SYSOUT` comparands of `.if` (LR p.203); `.of` used up by the next text, skip or space line (LR p.260 r4: here it stays for the next text); the messages for `.il`/`.un` moving a line left of the page margin (LR p.206 r6, p.416 r2).  Known limits of the TeX backend: a permanent `.in` given inside a figure changes the indention after the figure too; a skip TeX later takes as the page break still counts toward a FOR/AFTER distance (see `.in`). | not yet modelled |
| Markers without a row above: a malformed `.if` condition is diagnosed and taken as false, `.an`/`.or` with no comparison is an error, label names compare case-insensitively, `.dm name off` of an undefined macro is silent (`lib/control.ml`); a quoted number in `.if` compares as characters (`lib/expr.ml`); dcfstarter's title size. | DCF-VERIFY (not in LR Rel 4) |
