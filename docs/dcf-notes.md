# DCF SCRIPT/VS semantics: findings from the manual

Sources: *SH35-0069-3, DCF SCRIPT/VS Text Programmer's Guide, Rel. 3 (Jun 1986)*,
the PDF in the project root, and *SH35-0050, DCF GML Starter Set Implementation
Guide* (cited as "SH35-0050 p.n"). Page numbers are the guides' printed pages.
Status column: **DONE** = implemented as described (with the test that shows it);
**OK** = it already matched; **EXT** = kept as an extension; otherwise the entry
explains what we do. Open questions are marked `DCF-VERIFY` in the source.

## Line processing (ch. 3, p.39–41; ch. 21, p.257–258)
The per-line order is documented at the top of `lib/interp.ml`.

| Rule | Status |
|---|---|
| **Substitution happens before the line is classified** as control word or text (p.258). Order: end of a `.dm` capture → `.do` skipping → classify (comments and labels are never substituted) → substitute → separator split → dispatch. | DONE (`order.t`) |
| *Extended symbol rule*: a symbol value that begins with the separator makes the rest of the value start a new input line, during substitution (p.257). | DONE (`sysvars.t`, `manual_separator.t`, `manual_implguide.t`) |
| On a **control word line**, the line is split at any separator; the part to the right becomes the next input line (p.40, p.258). An empty rest is dropped. | OK (`manual_separator.t`) |
| On a **text line**, the line is split only where the separator is followed by the control word indicator (optionally `'`) and a 2-char control word name; the text before is "text with continuation" (p.41). Otherwise `;` is text. | DONE (`manual_separator.t`, `separator.t`) |
| `.'xx` = no macro search **and** no separator scan; it applies only to the first line after substitution (p.41, p.258). | OK |
| **Control word names are 2 chars**; the blank after them is optional: `.cecenter` = `.ce center` (p.40). With `.ms on` and no modifier the whole run of name characters (≤10) is tried as a macro first (p.271). | DONE (`macro_shadow.t`) |
| `.*` ignores the whole line, separators included (p.44). `.cm` is an ordinary control word: its line **is** split at a separator. | DONE (`comments.t`) |
| Macros are not recognised in text lines; `.em` runs one, also under `.ms off` (p.41, p.278). `.ec` runs the native word (p.277). | DONE (`em.t`, `manual_macros.t`) |
| Continuation character `.dc cont c` (none initially) and `.ct` (p.47–48). | DONE (`manual_continuation.t`) |
| `.dc gml c [e]` (p.289): the end-tag delimiter is one character (not a tag name character, `&` or `c`), two characters of which the first is `c` (`.dc gml ! !e`), or those two written as **two operands**, `c` and the second character: the Starter Set's `.dc gml : : e` gives `:` and `:e` (p.289; SH35-0050 p.6 and the DSMPROF3 profile). Without `e` the end-tag delimiter is `c` doubled (DCF-VERIFY); a lone `c` is an error. | DONE (`dc_forms.t`) |
| `.dc OPTION` with no value, last on the line (`cw`, `cont`, `gml`, `mcs`, `asep`), restores the DCF default (`;`, none, `:`/`::`, `.`, `", "`). DCF-VERIFY: the .DC reference is in the Language Reference, which we lack; the Starter Set (DSM#XLST, DSM#WRIT) issues bare `.dc cw` and `.dc asep` to undo earlier settings, which only this reading fits. | DCF-VERIFY (`dc_forms.t`) |
| `.lb`/`.lt`/`.nl`/`.bl` implicit words (p.281): natively a leading blank/tab gives a break and the line is text; a macro of that name (with `.ms on`) is invoked with the line as `&*`, and for `.lb`/`.lt` the line is then processed as text (`.dm lb /.*` makes the blank ordinary). | DONE (`manual_implicit.t`) |

## Symbols (ch. 21)
| Rule | Status |
|---|---|
| Names up to 10 chars from letters, digits, `@ # $` (p.42, p.229); a longer name is an error. A name may start with a digit (`&3z`, p.269). | DONE (`symbols.t`) |
| **Symbol names are case-sensitive** (p.239); names beginning with `$` are not (p.241). | DONE (`symbols.t`, `manual_symbols.t`) |
| A reference ends at a blank, a period (consumed), end of line, or `)` (needed by `.se array(&elem)` of p.256). `&prodname,` is **not** substituted (p.232). `&` or `(` continues the reference. | DONE (`symbols.t`, `manual_symbols.t`) |
| Resolution is **right to left** (p.233, p.238, p.256); values are rescanned; a runaway is stopped (10 000 steps, 100 000 chars). | DONE (`manual_symbols.t`, `diag.t`) |
| Undefined global: left as written. Undefined local (`*`): null, only when the current source is a macro (p.253, p.276). | DONE (`macro_locals.t`) |
| One set of locals per macro call, plus one set for when no macro is the current source (p.276); files have no scope of their own. | DONE (`macro_locals.t`, `imbed_args.t`) |
| `.su on|off|n` (n = the next n lines, then off). Initially on. `.se` lines (outside quotes) and `.if` comparands are substituted even with `.su off` (p.230, p.267). | DONE (`su.t`, `manual_if.t`) |
| `.se x = 'str'`, `.se x 'str` (closing quote optional), `.se x = 25`, arithmetic `&a + 1`, `-&n`; leading zeros go from arithmetic results (p.230, p.241). A **single number is kept as written** (`.se 3z = 00`, p.269): only an expression with an operator or parenthesis is evaluated. | DONE (`se_expr.t`, `manual_se.t`) |
| `.se x = substr STR n [len]` and `.se x = index STR SUB` (p.231). The `&'substr(` function family is not in SH35-0069. | DONE (`manual_se.t`); functions EXT (`functions.t`) |
| `.se x off` = undefined; for an array with no subscript the whole array goes. `.se x =` / `.se x = ''` = null (p.235). | OK |
| **Arrays (p.254–257):** `&x(*)` = all elements joined by the array separator (`", "`, `.dc asep`), in index order. `&x(0)` = the counter (= `&x`). `.se x() = v` appends at counter+1. A missing element of a defined array is null. Setting element n sets the counter when element 0 is numeric or unset. | DONE (`subscripts.t`, `manual_arrays.t`) |
| A **null element 0 is counter 0**: `.se x = ''` (or a null from `.gs vars`) then `.se x() = v` sets element 1, and setting element n makes n the counter. A value that is not a number is an error when the counter is needed (p.257). DCF-VERIFY: p.257 does not mention null; the Starter Set's DSMTTLEP nulls `@title`/`@author`/`@address` with `.gs vars` and then appends, which only this reading fits. | DONE (`null_counter.t`) |
| Attributes `&E' &L' &T' &V' &W' &U' &A'/&a'` (base 26) `&R'/&r'` (roman) `&X'` (hex). `&AD' &SW' &SD'` are device-dependent: 0 here, with a one-time warning (p.235–238). `&DH'`/`&DV'` give device units of a 240-pel page printer: a figure space or em 24, a line 40, an inch 240 (DCF-VERIFY: there is no device; IBM's list and footnote indents are computed with them). | DONE (`attrfuncs.t`) |
| **Hexadecimal codes are EBCDIC** (`&X'`, the `.tr` operands, the `.dc` values): translated to Unicode with code page 037 (`lib/ebcdic.ml`), so `.dc asep , 40` is a comma and a blank and `&X'41` the required blank.  DCF-VERIFY: CP037 rather than CP500 (they differ in 4A 4F 5A 5F B0 BA BB); B0–B9 are taken as the superscript digits of the 1403/3800 text fonts, which IBM's DSM#SUPR translates footnote numbers to (SH35-0050, "a 1 becomes a hex b1"); DSMPROF3's pi font code page AFTC0363 only matters for characters printed in that font. A `.tr` operand is one (UTF-8) character or two hex digits; the table is by code point. | DONE (`ebcdic.t`, `hints_tr.t`) |
| **System symbols of the device, the SCRIPT command options and the page** (SH35-0069 Figure 15, p.242–244; SX26-3723): there is no device, so they are neutral, as for a 3800 under CMS, one pass, with the INDEX option: `&$PDEV`=3800 `&$LDEV`=3800N6 `&$OUT`=FILE `&$DCF`=3.0 `&$SYS`=CMS `&$PASS`=1 `&$TWO &$UNF &$BE &$BO`=0 `&$INDX`=1 `&$LIB` (1 with `-lib`) `&$PRT`=ON `&$PARM`; `&$CHAR(n)` the CHARS fonts, an array (element 0 the count, a missing font null): TEXT and BOLD, so DSMPROF3 takes its 3800f2 font set (p.178–179); `&$FNAM` the current file name in upper case without extension; `&$RB` (`.dc rb`, EBCDIC 41 = U+00A0) and `&$PS` (`.dc ps`, `&`); `&$IN &$IR &$OF &$LL &$CL` in figure spaces of 1/10 inch, `&$PL`=66 `&$PW`=85 `&$LC`=60 (live in layout mode, below), the margins 0, `&$KP &$VR`=OFF, `&$LST`=0, `&$BS` backspace.  `-set '$NAME=v'` overrides any system symbol (`-set '$CHAR=f1 f2 ...'` the font list), so IBM's Starter Set runs with no `-set`. DCF-VERIFY: every neutral value. | DONE (`sysvars_dcf.t`) |
| `&SYSYEAR &SYSMONTH &SYSDAYOFM &SYSDAYOFW &SYSDAYOFY &SYSHOUR &SYSMINUTE &SYSSECOND`, zero-padded, settable (p.240–241); `&$GML &$EGML &$CW &$CONT &$SU &$LNUM &$TAB &$ENV`(= BODY) `&$PN`(= 1; live in layout mode, below) (p.246–247). | DONE (`sysvars.t`) |
| Layout mode (`gml -layout aptex`, `lib/layout.ml`): `&$PN` (the page number, p.246) and `&$LC` (the lines left in the column, SX26-3723) are asked of TeX running alongside (`Ctx.page_query`), after the document so far has been sent to it; `&$PN` is `\pageno`, `&$LC` (`\pagegoal`-`\pagetotal`)/`\baselineskip` (`\vsize`/`\baselineskip` on an empty page).  Without `-layout` they stay 1 and 60.  DCF-VERIFY: in the middle of a paragraph TeX has not yet counted its lines (DCF has formatted them, the partial line included); `&$PN` under `.pn roman`. | DONE (`layout_stream.t`, `layout_aptex.t`), DCF-VERIFY |
| `.se p = &` = the page number (p.254), here 1 (in layout mode the page TeX is on, as `&$PN`); `.dv` is not supported. | DONE (`manual_macros.t`, FIGNUM; `layout_stream.t`) |

## Logic (ch. 22)
| Rule | Status |
|---|---|
| `.if c1 op c2 target`; ops `= eq`, `¬= ne`, `> gt`, `< lt`, `>= ge`, `<= le`; blank padding (p.264). The first token is always comparand 1: a null comparand is an error ("invalid comparison operator", p.266). | DONE (`if.t`, `manual_if.t`) |
| `.th`/`.el` use the most recent comparison in the current file or macro, preserved across macro calls and imbeds (p.265): each frame has its own. | DONE (`manual_if.t`) |
| `.an` / `.or` (p.265). An `.an`/`.or` object of a condition is processed whatever its result, so `.if a .or b` works when `a` is false. | DONE (`manual_if.t`) |
| `.go` in a macro searches from the **top** of the macro; in a file forward, then from the top (p.265). | DONE (`manual_go.t`, `go.t`) |
| `.cs n on|off|ignore|include` (p.267–268): sections are included unless ignored; inside an ignored section only `.cs n on/off`, macro calls (whose lines are processed) and GML tags are processed; `.cs n ignore/include` there has no effect (TABLE example, p.55–56). | DONE (`manual_cs.t`, `manual_ef.t`) |
| "Macros and GML tags are resolved" (p.268) in an ignored section: the macros invoked from it (frames that were not on the stack when it began, e.g. the APFs of its tags) run in full, so their symbol side effects happen, but the document builder is muted: no elements (automatic or `.xs`), hints, raw output or text, and no implicit closes, so the tree is as if the section were absent. DCF-VERIFY: the extent of "resolved". | DONE (`starter_psc.t`) |

## Macros (ch. 23)
| Rule | Status |
|---|---|
| **`.ms` is off initially** (p.271). With it off, the first 2 chars are the control word. | DONE (tests add `.ms on`) |
| Single-line form `.dm name /a/b/`: the line **is** substituted when `.su on` (p.274). | DONE (`macro_def.t`, `manual_macros.t`) |
| Inline `.dm name on … .dm off`: no substitution or tag scan of the body; `.dm off` must be in column 1 without modifier (p.272); a nested inline `.dm x on` ends the outer definition; single-line/subscripted `.dm` in a body are body lines (p.280). | DONE (`macro_def.t`, `manual_macros.t`) |
| Subscripted form `.dm name(n) /line`, `.dm name() /line` (step 10); runs in subscript order; patches single lines; `.dm name(n) off` removes one (p.273, SH35-0050 p.16). Inline and single-line definitions are numbered 10, 20, … ; `&$LNUM` in a macro is the line's subscript (SH35-0050 p.16). | DONE (`manual_macros.t`, `manual_implguide.t`) |
| A running macro reads its definition **live**: a change to a later line takes effect in the same call (SH35-0050 p.181, DSM#DUPL), a change to a line already read at the next call (p.16). | DONE (`manual_implguide.t`) |
| Names ≤10 chars, case-insensitive; a macro may redefine a 2-letter control word (p.275). | OK |
| `&*` = everything after the blank after the macro name; `&*0` = token count; tokens delimited by blanks, arithmetic operators and parentheses (which are tokens); `'quoted'` is one token; `%` is a null token (p.253, p.276). No keyword arguments. (p.276 says `&*0` = 4 for `.insert filea 10 % fileb 15` but lists five tokens; we count five.) | DONE (`macro_args.t`, `manual_macros.t`) |
| Locals saved and restored across nested calls (p.276). | OK |
| `.me [line]`: the line runs in the caller, substituted with the macro's symbols (p.277, SH35-0050 p.17). | DONE (`manual_macros.t`, `manual_implguide.t`) |
| `.ec .xx`, `.em .xx` (p.277–278). | DONE (`em.t`, `manual_macros.t`) |
| GML APF lookup finds the macro whatever `.ms` says (a tag is not a control word line). | DCF-VERIFY (`gmlproc.ml`) |
| **Macro and symbol libraries** (p.239–240, p.281–283): `-lib dir` (repeatable, searched in order; DCF's LIB option takes up to eight). A member is the file `dir/NAME` or `dir/NAME.scr`, NAME the member name in upper case (≤ 8 characters, p.282; a longer name is never searched, DCF-VERIFY). A macro member is the whole body (no `.dm` line, p.283); a symbol member's value is its first line (p.282 note 63), trailing blanks removed (DCF-VERIFY: record padding). | DONE (`library.t`) |
| `.ly on|off|mac|sym`, initially OFF (p.240, p.282–283): ON searches for unresolved macros and symbols, MAC macros only, SYM symbols only. An unresolved macro is a control word line (`.ms on`, no modifier) whose long name is neither a macro nor a control word name, an `.aa`/class/direct APF that is neither a macro nor native, or the target of `.em`; the library is tried before the two-character native word, so `.dsmgdoc` is the macro DSMGDOC, not `.ds mgdoc` (DCF-VERIFY). Unresolved symbols: global, non-system names during substitution, the member name in upper case (`&libsym` and `&LIBSYM` both come from LIBSYM, p.240). What is found is defined, so the next use does not search (p.282); members are read once and misses are remembered. `.ly` alone = ON (DCF-VERIFY). | DONE (`library.t`) |
| `.dm name lib` / `.se name lib`: fetched whatever `.ly` says, replacing any definition (p.282); a missing member is an error. | DONE (`library.t`) |
| `.dm name off` outside a definition **deletes** the macro (SH35-0050 p.16, "Reclaiming Space"): the next call fetches the real macro from the library again, so a member that ends with `.dm name off` runs on every call; one that redefines itself as `.dm name /.*` runs once. | DONE (`library.t`) |

## Files (ch. 4)
| Rule | Status |
|---|---|
| `.im`/`.ap` semantics, Figure 4 (p.49–51); MASTER/FILEA/FILEB/FILEC (p.49). | OK (`manual_fig4_ap.t`, `manual_master.t`) |
| `(long.name)` in parentheses = the real file name (p.50). `.dd` is not supported. | DONE (`imbed_args.t`) |
| Imbed/append parameters are the **global** symbols `&0` (count) … `&14` (p.252–253); they are set only when parameters are given (DCF-VERIFY). | DONE (`imbed_args.t`) |
| `.ef`: re-imbedding resumes after the `.ef`; `.ef close` restarts from the top (p.50). `.ef` in the profile: the rest is the *epifile*, processed after the main document (p.50). | DONE (`manual_ef.t`, `ef.t`) |
| `.qu` / `.qq` stop processing, also from an imbedded file; the epifile is not processed (p.51). | DONE (`manual_ef.t`) |

## GML (ch. 24): see the Phase 4 rework (`.aa`, `.gs`, `.dc gml/mcs`)
`.gs args v1 v2 ...` sets the argument symbols of the current macro (or of
the file): `&*1 ...`, `&*0` (count), `&*` (the operand string), destroying
the previous `&*n` (SH35-0050 p.17); `.gs args` alone undefines them (p.29
item 34). Values are blank-separated; `'quoted values'` may hold blanks,
`''` is null, a doubled quote is one quote; `.gs args &* x` appends.
`.gs vars n1 n2 ...` sets n1 to `&*1`, n2 to `&*2` ... (p.17: "totally
equivalent to" `.se n1 'v1` ...). DCF-VERIFY: blank-only tokenization
(`-1`, `a-b` stay one value, unlike macro operands), a name beyond the
last value gets null, `.gs args` alone also undefines `&*0` (`gs_args.t`).
`.gs qatt sym name ...` (SH20-9161-3 p.266): the listed attributes that
are not on the attribute stack become the elements of `sym`; when all are
present `sym` is undefined (DSMFTNT tests `&E'&*q`; DCF-VERIFY)
(`gs_qatt.t`).  `.gs hctr [n | n1.n2...]` (p.266–268, `lib/headctr.ml`):
a single number steps that level and resets the ones below, a dotted value
sets the counter (letters for alphabetic positions, `A.0`) and the next
heading at its deepest nonzero level takes that value, nothing
reinitialises it; `&xref` gets the counter to that level, `&xref(n)` each
position (DSMHEAD1 prefixes appendix headings with `&xref(1)`). DCF-VERIFY:
that a step at the level just set does not increment (it gives IBM's
"Appendix A") (`gs_hctr.t`).
`.gs exatt`: an attribute given more than once on a tag is processed once
for each occurrence, with its own value (`:rdef` repeats ARRANGE, one
grid row each, SH20-9186-06 p.54; DCF-VERIFY) (`gs_exatt.t`).
`.xd name noid` (EXT): the element's `id` is not a document id, so it is
not checked for duplicates (`:rdef id` names a row definition)
(`tables.t`).
**Provisional elements:** a tag with no end tag (its `.aa` names no end
APF and there is no `eNAME` APF) and no `.xd` model has nothing to close
its automatic element (IBM's profile has no models; its `:p :li :dt
:figref` ... have no end tags).  If it is closed by anything but its own
end tag it is left empty, a marker, with what followed it after it; an end
tag that does close it keeps the content inside (DCF-VERIFY)
(`provisional.t`).  An end tag with an APF closes its element after the
APF when a `.fn`/`.rh`/`.rf` flow is open inside it, since the APF ends the
flow (IBM's `:efn` → DSMEFTNT `.fn off`) (`provisional.t`).
`.gt`/`.ga` are Waterloo SCRIPT, not DCF. `&$TAG`-style attribute access in
APFs: `.gs attval` sets `&NAME` (uppercase) or the AS name as written.

## Formatting hints (Phase 5, `lib/hints.ml`)
Formatting control words do not format: each becomes a `gml:NAME` hint
carrying the new state, the operand and `break="yes|no"`.  The table in
`hints.ml` lists every word, its break behaviour and its attributes.

| Rule | Status |
|---|---|
| Space units (p.44–46, Figure 3): `n` / `n.dd` / `n,dd`, `i`, `cm`, `mm`, `pN`/`NpM` (points), `cN`/`NcM` (Didot points), `m` (em of the axis), `dh`/`dv`; unqualified = lines (vertical) or characters (horizontal).  Normalised to `n` + `unit`, never converted. | DONE (`hints_units.t`) |
| `.us`/`.up`, font words, `.hy`/`.hw`, `.tp`/`.tb`, `.kp n` do not break; `.in`/`.ir` break unless NOBREAK (p.78, p.81). | DONE (`hints_break.t`) |
| `.in +n`/`-n` relative to the current value; `.in` alone = 0; a mixed-unit sum is kept as `3ch+1i` (unit="mixed"). | DONE (`hints_state.t`) |
| "The offset remains in effect until changed by another offset or indent control word" (Figure 6, p.80): a permanent `.in` ends the `.of` offset; its hint carries `offset="0"` (scope.xsl, gml.tex). DCF-VERIFY: a temporary `.in … for` keeps it; `.ir` does not end it. | DONE (`hints_offset.t`) |
| Only space-unit operands are normalised in a `spec`: the factors of `.ls`/`.ws`/`.es` `BY` (and `.ls SKIP/SPACE/TEXT`, p.92–93, p.106, p.114), the `.wz`/`.pn`/`.fl`/`.bc` operands and the `.cd` column count stay as written. | DONE (`hints_spec.t`) |
| Line-counted words (`.ce`, `.ri`, `.us`, `.up`, `.uc`, `.il`, `.un`, `.in/.ir … after n / for n`, `.rc * c`) are `gml:lines` scopes over the input text lines they cover; elements inside a scope split it (`cont="yes"`); FOR/AFTER amounts not in lines stay as attributes. | DONE (`hints_lines.t`) |
| `.in x after n`: the first n lines keep the old indent (p.79).  DCF-VERIFY: whether lines are input or output lines; here input text lines. | DCF-VERIFY |
| `.li` (p.89) literal mode: control words, tags and implicit words off; symbols still substituted. | DONE (`hints_li.t`) |
| `.tr` (p.207) real translate table; a lone char goes to a blank; hex codes are EBCDIC (see Symbols). | DCF-VERIFY (`hints_tr.t`) |
| `.sa [name]` / `.re [name]` (SH20-9161-3 p.110; SX26-3723): save and restore the environment the engine tracks (indention, offset, line length, format mode, hyphenation, the font stack, SH35-0069 p.179, and the `.tr` table; not the page control area).  Hints `gml:sa`/`gml:re` (with `name`), and after `gml:re` the ordinary hints for each part that changes, with `restore="yes"` (`.pf` for fonts pushed since the `.sa`), so backends need not know `gml:re`.  `.re name` drops the environments saved after it. DCF-VERIFY: none of them breaks; the named form. | DONE (`hints_env.t`) |
| A footnote saves the environment and clears the offset; `.fn off` restores it, without hints (SH20-9161-3 p.110). | DONE (`hints_env.t`) |
| `.fv top|bottom|center|justify` (SH35-0069 p.111): hint `gml:fv spec`, no break (DCF-VERIFY). | DONE (`hints_env.t`) |
| `.pi [start|end|order|ref] [key /k1/k2/k3/] /t1[/t2[/t3[/page]]]` (SH35-0069 p.213–218, SH20-9161-3 p.297): hint `gml:pi` with `t1`–`t3`, `k1`–`k3`, `start/end/order="yes"`, `page="text"` or `pageref="no"` (null fourth term; absent or the page number symbol = current page), `see` (REF: the last term). Ignored unless `&$INDX` = 1. `.ix [n] [name|control|/]` (SH20-9161-3 p.291): hint `gml:ix [reserve] [title]`, a control-word operand is processed in place of the heading. resolve.xsl builds the index from the `gml:pi` (merging terms by their upper case, SH35-0069 p.218) and puts each `.ix`'s entries after its `gml:ix` (fixture `resolve/index-pi`). | DONE (`index_pi.t`) |
| `.dh n num/nonum` and the head-level counter (SH20-9161-3 p.247, p.266–268): an `.hn` of a NUM level gets `num="1.0"` / `"1.2.1"`; see `.gs hctr`. | DONE (`gs_hctr.t`) |
| `.ct text`: the text is an input line, so a continuation character at its end continues it (IBM's DSMFDESC `.ct :&$RB.&$RB.&$CONT`, which left a stray `&X'03`, shown as U+FFFD, in the output). | DONE (`ct_cont.t`) |
| `.h0`–`.h6`: `gml:h level=n` closed at the end of the line. | DONE (`hints_flow.t`) |
| The page number symbol (`.dc ps`, `&$PS`, default `&`) "is replaced, wherever it appears in the running heading and footing, with the current page number" (SH35-0069 p.125; p.128, p.259): in the text of an open `gml:rh`/`gml:rf` it is split off as the hint `gml:pageno`, before `.tr` translation, so `&amp.` (X'08 translated to `&`, p.234 and its note 60) stays text; a `.sx` there whose fields hold it gets `pagesym=` (the symbol).  tex.xsl and be_tex write such a heading or footing as `\gmlrundyn{...}`, which gml.tex typesets again at every page with the hints made local (the environment is saved and restored around a running heading, p.128 note 37).  DCF-VERIFY: gml.tex also makes every `\&` in it the page number (for the `.sx` fields), so a text ampersand there still prints as the page number in TeX. | DONE (`tex_batch.t`), DCF-VERIFY |
| Device words (`.dd .it .sv .dl .uw .oc .sy .te .lo`) warn once each. | DONE (`hints_flow.t`) |
| `.mg /id/text/`: severity from the last character of the id (W 4, E 8, S/T stop). | DCF-VERIFY (`starter_context.t`) |
| A null line in fill mode adds no text (p.281: `.nl` cancels a continuation); a blank line is `.sp 1`. | DCF-VERIFY (`text.t`) |
| `.bf … =` restart, `.dv` font, `.rh`/`.rf` page selection: kept as attributes, not interpreted. | DCF-VERIFY |

## Starter Set profile (`share/profile/starter.gml`)
Modelled on DSMPROF3 (SH35-0050 Figure 7): `.aa` mappings of every Starter
Set tag, `.xd` implicit-close models, DSM#CNTX/DSM#RSET messages through
`.mg`, `:xmp` verbatim (`xml:space="preserve"` + `.fo off`).  `&date` is
built like DSM#SETS ("June 13th, 1986").  `-profile starter` searches
`-share dir`, `$GML_SHARE`, then `share/gml` near the executable (or the
source tree's `share` from `_build`); that profile directory is also
last on the `.im` path so a user profile can `.im starter` (p.297).
DCF-VERIFY: message numbers and wording of DSMGML00n are approximations.
`:q` nests (`&@nest@q`, DSMQUOTE/DSMEQUOT, SH35-0050 p.125); APF macros
that read state at call time use the inline `.dm` form, since a
single-line `.dm` is substituted when it is defined (p.274).  **EXT:** a
footnote has its own flag `&@fn` instead of `&@state = N`, so `:fn` is
allowed inside `:fig`/`:xmp` (DSMFTNT refuses it there because keeps and
floats exclude footnotes, SH35-0050 p.129; the tree has no such
conflict) (`starter_nesting.t`).

## Tables (SH20-9186-06 ch. 7, p.51–71; SH20-9187-06 §3.31–3.36)
The Rel 3.2 tag set: `:rdef :table :thd :tft :row :c :tcap :tdesc :tnote
:tref :tlist`.  The profile checks attributes and context; `xslt/resolve.xsl`
assigns cells to the ARRANGE grid (see its header); the backends lay out the
result.

| Rule | Status |
|---|---|
| `:rdef` holds HP ALIGN CONCAT VALIGN ROTATE MINDEPTH ARRANGE CWIDTHS (p.52–54, §3.31.1). Its `id` names a row definition, not a cross-reference target: `.xd rdef noid`, so a table may share it. | DONE (`tables.t`) |
| ARRANGE may be repeated, one grid row per attribute (p.54, p.66); the engine joins the values with ` / `. A cell number must make a rectangle; otherwise resolve reports it and the cell takes its first square (DCF-VERIFY: what DCF does). | DONE (`tables.t`, `resolve/tables-diag`) |
| CWIDTHS gives one value per grid column (p.54–55); `*` and `k*` are shares of what is left (DCF-VERIFY: Rel 3.2 lists `*` only for an equal share). No CWIDTHS = one cell, no ARRANGE = one cell per width. | DONE (`resolve/tables`) |
| The per-cell attributes (HP, ALIGN, ...) take their values in **ascending cell number order** (DCF-VERIFY: the manual says "for each cell"); missing values repeat the last one. Abbreviations (`l c r`, `y n`) are expanded; a bad value is reported and the default used. | DONE (`resolve/tables`) |
| `:c n` may come out of order; a cell number already filled in the row adds a `gml:cpart` to that cell (separated by a rule); an unnumbered cell takes the next free number; a full row starts an implicit new row (p.56–57). A number not in the row definition is reported and treated as unnumbered. | DONE (`tables.t`, `resolve/tables`) |
| CONCAT=NO keeps the cell's input lines (p.53): `xml:space="preserve"` and a `.lb` macro while the cell is open, as for `:xmp`; blank lines are dropped (DCF-VERIFY). | DONE (`tables.t`) |
| `:thd`/`:tft` before the first `:row`; their own REFID chain, apart from the rows' (§3.32.4–5; Rel 3.2 ties them to the table's). The heading repeats on each page, the footing ends each part (p.57). | DONE (`tables.t`) |
| SPLIT on `:table` and `:row` (p.55–56): no = keep with the previous row. COLUMN/PAGE (p.55) become `span`. ROTATE 0/90/180/270 on the table and cells. | DONE (backends) |
| `:tcap` (one line, no tags) numbers the table and enters the list of tables; `:tdesc` follows it to `:etable` (p.58). `:tnote` is a full-width row starting "Note:" and ends the row (p.58–59). | DONE (`resolve/tables`) |
| `:tref refid` exists in Rel 3.2 ("To Tables", ch. 8 p.76; an unmatched reference p.78); `page=` as for `:figref`. `:tlist` lists the captioned tables (§3.34). | DONE (`tables.t`) |
| SHADE (`xlight light medium dark xdark`, §3.31.1) is Rel 4 only. | EXT |

## IBM's macro library (SH35-0050-2 Appendix C, local transcription)
The transcription in `test/dcf-real/` (gitignored, IBM copyright) runs
with `-lib test/dcf-real/members -profile .../DSMPROF3.scr`; README
"Testing against IBM's Starter Set" has the command and the open gaps.
Points settled while checking it against the scan:

| Point | Status |
|---|---|
| The `index`/`substr` lookup tables in DSM#SETV and the ordinal string in DSM#SETS (1st–31st) are consistent with the transcribed blank and dash counts. | OK |
| DSMPROF3's `@oquote`/`@cquote` strings are `'` followed by seven `"''` groups (alternating `"` and `'`, single quotes doubled, unclosed string); its `.gs args` is `'"' '''' '"' ''''`. | OK |
| `.if SYSOUT eq PAGE` (no `&`) in DSMPROF3 and `&@sK@x` in DSMEXMP are as printed. Symbol names are case-sensitive (SH35-0069 p.239: `&libsym` and `&LIBSYM` are "separate and unique symbols"; SH20-9161-3 .SE note 1: "symbol1, Symbol1, and SYMBOl1 are three distinct symbols"; only `$` names are upper case only), so the latter never matches `@sk@x`: a latent bug in IBM's listing, kept (`.sk: invalid space unit`). | OK |
| With the system symbols, `.sa/.re`, `.pi/.ix`, `.gs qatt/hctr` and the EBCDIC codes, the listing runs with no `-set`; DSMPROF3's `.go &$PDEV.f&$CHAR(0)` finds `3800f2`. The remaining diagnostics are the `.sv` device word and the `&@sK@x` above. | OK |
| IBM's `.dm NAME off` at the end of a member deletes the macro after use, so the next call reloads it from the library (SH35-0050 p.16). | DONE |
