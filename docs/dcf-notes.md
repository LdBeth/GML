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
| Attributes `&E' &L' &T' &V' &W' &U' &A'/&a'` (base 26) `&R'/&r'` (roman) `&X'` (hex). `&DH' &DV' &AD' &SW' &SD'` are device-dependent: 0 here, with a one-time warning (p.235–238). | DONE (`attrfuncs.t`) |
| `&SYSYEAR &SYSMONTH &SYSDAYOFM &SYSDAYOFW &SYSDAYOFY &SYSHOUR &SYSMINUTE &SYSSECOND`, zero-padded, settable (p.240–241); `&$GML &$EGML &$CW &$CONT &$SU &$LNUM &$TAB &$ENV`(= BODY) `&$PN`(= 1) (p.246–247). | DONE (`sysvars.t`) |
| `.se p = &` = the page number (p.254), here 1; `.dv` is not supported. | DONE (`manual_macros.t`, FIGNUM) |

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

## Files (ch. 4)
| Rule | Status |
|---|---|
| `.im`/`.ap` semantics, Figure 4 (p.49–51); MASTER/FILEA/FILEB/FILEC (p.49). | OK (`manual_fig4_ap.t`, `manual_master.t`) |
| `(long.name)` in parentheses = the real file name (p.50). `.dd` is not supported. | DONE (`imbed_args.t`) |
| Imbed/append parameters are the **global** symbols `&0` (count) … `&14` (p.252–253); they are set only when parameters are given (DCF-VERIFY). | DONE (`imbed_args.t`) |
| `.ef`: re-imbedding resumes after the `.ef`; `.ef close` restarts from the top (p.50). `.ef` in the profile: the rest is the *epifile*, processed after the main document (p.50). | DONE (`manual_ef.t`, `ef.t`) |
| `.qu` / `.qq` stop processing, also from an imbedded file; the epifile is not processed (p.51). | DONE (`manual_ef.t`) |

## GML (ch. 24): see the Phase 4 rework (`.aa`, `.gs`, `.dc gml/mcs`)
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
| `.tr` (p.207) real translate table; a lone char goes to a blank; hex codes are code points written as UTF-8 (DCF: EBCDIC). | DCF-VERIFY (`hints_tr.t`) |
| `.h0`–`.h6`: `gml:h level=n` closed at the end of the line. | DONE (`hints_flow.t`) |
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
