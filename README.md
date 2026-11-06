# GML

A processor for IBM DCF SCRIPT/VS documents with GML markup (the DCF
Release 3 dialect, SH35-0069 and the Starter Set of SH35-0050).  The
programmable layer is kept faithful: symbols, macros, `.if`/`.go`,
conditional sections, imbedding and the GML tag-to-APF machinery.  Pages
are not laid out for a 3800 printer.  The output is a semantic XML tree,
and XSLT 3.0 stylesheets turn that tree into HTML, plain TeX or XSL-FO.
Formatting control words (`.sp`, `.in`, `.ce`, `.bf` ...) become *hints*
in the tree: each hint records the new state and whether it breaks.

## Architecture

```
 doc.gml + profile (share/profile/starter.gml)
    |
    |  gml   OCaml engine (lib/, bin/): input stack, substitution,
    v        macros, GML tags -> APFs, .xs/.xd element building, hints
 doc.xml     canonical XML (namespace urn:x-gml:canonical, hints gml:*)
    |
    |  xslt/resolve.xsl   numbering, cross-references, TOC, figure list, index
    v
 doc.r.xml ---------------+---------------------------+
    |                     |                           |
    | xslt/tex.xsl        | xslt/strip-hints.xsl      | xslt/scope.xsl  (state hints
    v                     v                           v                -> nested scopes)
 doc.tex               doc.sem.xml                 doc.s.xml
 + share/tex/gml.tex   (semantic tree only)           |
    |                                     +-----------+-------------+
    v                                     | xslt/html.xsl           | xslt/fo.xsl
 tex / pdftex                             v  + share/html/gml.css   v  (or fo-vendor-ah.xsl)
                                       doc.html                  doc.fo -> an XSL-FO formatter
```

The engine knows nothing about XSLT.  The stages are joined only by
files, so each intermediate can be inspected.

## Prerequisites

- OCaml and dune in the opam switch `gml` (stdlib and `unix` only):
  `opam switch create gml ocaml-base-compiler.5.4.1 && opam install --switch=gml -y dune`.
  Every build runs through `opam exec --switch=gml -- dune ...`.
- SaxonC-HE, the native `transform` binary at `/usr/local/bin/transform`
  (override with `SAXON=...`).
- plan9port in `/usr/local/plan9` (`mk`, `rc`) for the `mkfile`, `gmlfmt`
  and the XSLT test runner.
- TeX (`tex` or `pdftex`, plain format) for the TeX output.
- An XSL-FO formatter for PDF (none is included; see the limitations).

## Build and test

```
opam exec --switch=gml -- dune build
opam exec --switch=gml -- dune test      # engine cram tests (test/*.t)
./xslt/test/run                          # XSLT fixtures (xslt/test/STAGE/*.in.xml)
mk test                                  # both: mk test-ocaml, mk test-xslt
```

`xslt/test/run [-update] [name...]` takes `STAGE/NAME`, `NAME` or a
bare stage (`xslt/test/run tex`).  Its header (`xslt/test/run.rc`)
lists how each fixture input was generated.

## Usage

### `gml`: the engine

```
gml [-I dir]... [-share dir] [-profile file|name] [-set sym=val]...
    [-lib dir]... [-maxgo n] [-undef-tags text|element|error] [-o out.xml] input.gml
```

- `-profile starter` loads the shipped Starter Set profile from the share
  directory: `-share dir`, else `$GML_SHARE`, else `share/gml` next to the
  executable, else the share directory of the build.  Its tag set is the
  Release 3 Starter Set plus the tables of Release 3.2 (SH20-9186-06
  ch.7): `:rdef` row definitions (CWIDTHS, ARRANGE for spanning cells,
  per-cell HP/ALIGN/VALIGN/CONCAT/ROTATE/MINDEPTH), `:table :thd :tft
  :row :c :tnote :tcap :tdesc`, `:tref` and `:tlist`; resolve.xsl works
  out the cell grid, numbering and captions, and the HTML, XSL-FO and
  TeX stages draw ruled tables (fixtures from `xslt/test/gml/tables.gml`).
- `-set SYSVARH=yes` sets a symbol, as DCF's `SYSVAR` options do.
- `-lib dir` (repeatable, searched in order) adds a symbol and macro
  library, as DCF's `LIB` option does: a member is the file `dir/NAME` or
  `dir/NAME.scr` (NAME in upper case), used by `.dm name lib`,
  `.se name lib`, and with `.ly on|mac|sym` for unresolved macros, APFs
  and symbols.
- The return code follows DCF: 0, or 4 after warnings, 8 after errors.

From the source tree:
`opam exec --switch=gml -- dune exec -- gml -share share -profile starter doc.gml`.

### `gmlfmt`: the whole pipeline to standard output

```
./gmlfmt [-to xml|resolved|scoped|semantic|html|tex|fo] [-profile p]
         [-tagset t] [-set name=value]... [-p name=value]... [-I dir]... in.gml
```

`-set` goes to gml and to every stylesheet.  `-p` goes to the
stylesheets only, e.g. `./gmlfmt -to html -set SYSVARH=yes -p h1-prefix=Chapter doc.gml`.
It uses the project's gml with `-share <root>/share`, so edits to
`share/profile/starter.gml` take effect at once.  Set `GML`, `SAXON` or
`GMLROOT` to use other tools.

`-tagset t` selects a tag set (see Customising): a bundle directory when
`t` contains a `/` or `share/tagset/t` exists, otherwise the profile
`share/profile/t.gml` (the same as `-profile t`).  An explicit
`-profile` overrides the bundle's `profile.gml`, in either order.

### `mk`: the pipeline as files

Run mk in the project root.  A target may be any path:

| target | made from | by |
|---|---|---|
| `doc.xml` | `doc.gml` | gml -profile `$PROFILE` (default starter) |
| `doc.r.xml` | `doc.xml` | resolve.xsl |
| `doc.s.xml` / `doc.sem.xml` | `doc.r.xml` | scope.xsl / strip-hints.xsl |
| `doc.html` / `doc.fo` | `doc.s.xml` | html.xsl / fo.xsl |
| `doc.tex` | `doc.r.xml` | tex.xsl |
| `doc.dvi` | `doc.tex` | `$TEX` (default tex) with `share/tex` on TEXINPUTS |
| `doc.pdf` | `doc.fo` | `$FOP`, which must be given: `mk FOP=fop doc.pdf` |
| `test`, `test-ocaml`, `test-xslt` | | the test suites |
| `fo-check` | `$FOFILES` | `xslt/test/fo/check`: structural XSL-FO checks |

```
SETS='SYSVARH=yes SYSVARP=draft' mk doc.html     # -set for gml and the stylesheets
mk "XSLTFLAGS='h1-prefix=Chapter'" doc.html      # stylesheet parameters only
mk 'FOFILES=doc.fo' fo-check                     # makes doc.fo if need be, then checks it
```

mk does not know when `SETS` change: remove the intermediates
(`doc.xml`, `doc.r.xml` ...) first.  For TeX, run tex twice: page
references are read from `doc.ref` on the second run.

The stylesheet parameters (`SYSVARS`/`SYSVARD`/`SYSVART` page layouts,
`paper`, fonts, literals, `css`, `footnotes`, `pageref`, `tex-preamble`
...) are documented at the top of each stylesheet.

## Customising

- **Profiles.** `-profile file` imbeds any file before the input.  The
  shipped profile directory is last on the `.im` path, so a profile can
  start with `.im starter` and then redefine things, the way DCF
  profiles imbedded DSMPROF3.  A `.ef` in a profile makes the rest of the
  profile run after the document (the epifile).
- **Tags and APFs.** `.aa tag apf (rules) endapf (rules)` maps a tag to
  its application processing function: a `.dm` macro or a control word.
  The rules are `att noatt vat novat stop step msg nomsg elem noelem`.
  The `.gs` services are `tag`, `rules`, `prefix`, `exatt`, `attval`,
  `scan`, `copy` and `insert`.  Every tag opens an element of its own name
  unless its rules say `noelem`; the APF's output goes inside it.  The
  Starter Set APFs in `starter.gml` are ordinary macros: override them
  in your own profile.
- **Elements.** Our output control words are `.xs name a=v` (start),
  `.xe [name]` (end), `.xa a=v` (set attributes) and `.xr backend /text/`
  (raw backend text).  `.xd name [closes=a,b] [closedby=x,y] [empty]
  [eol] [noid] [inline|block]` gives an element model for implicit closing
  (`noid`: its `id` is not a document id, as for `:rdef`).
- **TeX.** `share/tex/gml.tex` reads `gmllocal.tex` from TEXINPUTS at
  its end.  Redefine styles there with `\gmldefstart{h1}{...}`,
  `\gmldefend`, `\gmldefhint{sp}{...}`, `\gmldeflines`, `\gmldefnum`,
  `\gmldefchar` and `\gmldeffont`.  The tex.xsl parameters
  `tex-input`/`tex-preamble` load your own macro file or preamble.
- **TeX fonts.** Fonts come from a scheme file `gmlfont-NAME.tex`
  (shipped: `ncs` New Century Schoolbook, the default; `cm` Computer
  Modern) that fills slots with `\gmlfontname{rm}{pncr7t}` ... and
  `\gmlfontsize{10pt}`.  Per document or run: `gmlfmt -p tex-fonts=cm`,
  `\def\gmlfonts{cm}` before `\input gml`, or `\gmlusefonts{cm}` in
  `gmllocal.tex`.  Per engine: a file `gmlfont-NAME-ENGINE.tex`
  (ENGINE = `tex`, `pdftex`, `luatex`, `xetex`) is preferred over
  `gmlfont-NAME.tex` when present.  The slots are `rm it sl bf bi tt`
  (body), `hd` (headings) and `ti` (the `:title`, default `hd`);
  `gmlfont-ncs.tex` lists one per line, so a face is switched by editing
  its line.  One slot can also be changed on top of a scheme, e.g. in
  `gmllocal.tex`: `\gmlfontname{ti}{pncbi7t}\gmlusefonts{}`.
- **Tag sets.** A tag set bundle is a directory (`share/tagset/NAME`, or
  any path given to `gmlfmt -tagset`) holding `profile.gml` (required:
  the gml profile, e.g. `.im starter` and then the bundle's own tags;
  the directory is also on the `.im` path, after the `-I` dirs) and
  optionally stage overrides `resolve.xsl`, `scope.xsl`,
  `strip-hints.xsl`, `html.xsl`, `fo.xsl`, `tex.xsl`, used instead of
  the stock stylesheets.  An override normally does `xsl:import` of the
  stock one by relative path (e.g. `../../xslt/html.xsl` from a bundle
  in `share/tagset/NAME`) and adds or overrides template rules.  An
  optional `tagset.tex` is passed to tex.xsl as `tex-tagset`, which
  writes `\def\gmltagset{path}` before `\input gml`; gml.tex inputs it at
  its end, before `gmllocal.tex` (so the most local file wins).
- **HTML.** Every element has a class `gml-NAME`.  Restyle
  `share/html/gml.css` or replace it (parameters `css`, `css-inline`,
  `css-file`).
- **XSLT.** Write a stylesheet that does `xsl:import` of a stage and
  overrides its template rules.  `xslt/fo-vendor-ah.xsl` is the example:
  it fills the hook modes of fo.xsl with Antenna House extensions.  An
  importer of html.xsl that handles its own tags redefines the variable
  `h:extra-known` (namespace `urn:x-gml:html`) so they are not reported as
  unknown.

## Emacs

`emacs/gml-mode.el` is a major mode for `.gml` files (Emacs 29 or later):

```elisp
(add-to-list 'load-path "/path/to/GML/emacs")
(require 'gml-mode)
(add-hook 'gml-mode-hook #'flymake-mode)   ; diagnostics from the gml engine
```

- **Highlighting** of control words by kind (programmable, formatting,
  file, unknown), macro calls, `.dm`/`.se`/`.aa` definitions, labels,
  tags and their attributes, symbols (`&x.`, `&*1`, `&L'`), the `;`
  separator and `:xmp` examples.  `.*` and `.cm` are comments; `M-;`
  (un)comments whole lines.
- **Filling** never joins control word lines, never fills `:xmp` or
  one-line tags (`:h1`, `:dt`, `:i1` ... and any `.xd NAME eol`), never
  breaks inside a tag or before a `.`, and does not indent, since a
  leading blank is a break in SCRIPT/VS.
- **Structure:** `C-c C-t` inserts a tag (and its end tag, wrapping the
  region), `C-c C-e` closes the innermost open structure (`.aa` tags
  with an end APF count), `C-c C-d` inserts a `.dm NAME on` ... `.dm off`
  macro.  Outline and imenu follow the headings; imenu also lists
  macros, labels, `.aa` tags and ids.
- **Completion** of tags, attributes, control words, macros and symbols;
  **eldoc** for control words and Starter Set tags.
- **xref** (`M-.`) on a macro call, `&symbol`, `.go` label,
  `refid=` value, tag or `.im` file name.  Definitions are looked up in
  the buffer, then in the imbedded files and the profile, so `&date`
  leads to `starter.gml`.
- **Flymake** runs the engine on the buffer (`-I` the file's directory)
  and reports its errors and warnings; `C-c C-c` runs `gmlfmt` into
  `doc.html` (`C-u C-c C-c` asks for the `-to` stage) with the messages
  in a compilation buffer; `C-c C-v` previews the HTML in a browser.

Inside the project the tools are found automatically: the `gml` built in
`_build` with `-share share`, and `./gmlfmt`.  Elsewhere set `gml-root`,
or `gml-program` and `gml-gmlfmt-program`.  `gml-profile` and
`gml-symbols` (an alist for `-set`, safe as a file-local variable) are
passed to both.

## Example

`examples/release.gml` is a Starter Set document (release notes) that
also uses the programmable layer: symbols and arithmetic (`&version`,
`&nextmin`), an array (`&platforms(*)`), a counting macro (`.change`),
conditional text with `.if`/`.go` driven by `-set audience=internal`, and
a user-defined tag `:warn level=n` whose APF uses `.gs attval` and `.gs
insert`, with an `.xd` model.  The tag is styled per backend without
touching the shipped files, by the tag set `examples/notes/`: its
`profile.gml` defines the tag, its stylesheets import the stock stages
and add rules for it, and `tagset.tex` styles it for TeX.

`examples/mkfile` makes everything in `examples/out/` (`cd examples &&
mk`, or `mk -a` to redo it all): the engine XML (`release.xml`),
resolved, scoped and semantic XML, HTML for both audiences, XSL-FO, plain
TeX and the typeset `release.pdf`.  It sets `ROOT`, `TAGSET=notes` and
`OUTDIR=out/`, then includes the project's `mkfile` for the rules; only
the internal edition (`-set audience=internal`), `gml.css` and the
pdftex runs have rules of their own.

## DCF fidelity

`docs/dcf-notes.md` lists the SCRIPT/VS and Starter Set rules checked
against the manuals.  Each entry has a status (DONE, OK, EXT) and the
cram test that shows it.  The points that the guides leave open are
marked `DCF-VERIFY`: 81 in the sources (`lib/`, `share/`, `xslt/`)
and 30 in the notes.  They include how far an ignored conditional section is
"resolved", the input-versus-output line count of `.in … after n`, the
`.mg` severities, the DSMGML message numbers and wording, the EBCDIC
code page (037) for hex codes, the neutral values of device system
symbols, and APF lookup under
`.ms off`.  Deliberate extensions are marked EXT: the automatic element
per tag, `&'substr(`-style functions, footnotes inside figures, and
2-digit years taken as 20xx.

## Testing against IBM's Starter Set

Appendix C of the Implementation Guide (SH35-0050-2) prints IBM's whole
Starter Set macro library: the DSMPROF3 profile and its 123 APFs and
helper macros.  Unlike `share/profile/starter.gml`, which builds the
semantic tree, IBM's macros format through control words, so they test
the formatting hints and the TeX mapping of `gml.tex` end to end.

The listing is IBM's copyrighted code, so its transcription is kept
locally in `test/dcf-real/` (gitignored): `members/NAME.scr`, one file
per library member, and `pages.txt`, a page map with the spots read
with doubt.  To run it, use the library and the profile:

```
gml -share share -lib test/dcf-real/members \
    -profile test/dcf-real/members/DSMPROF3.scr xslt/test/gml/starter.gml
```

Device and command-option system symbols (`&$PDEV`, `&$CHAR`, `&$SYS`,
`&$PASS`, ...) have neutral defaults (a 3800 with TEXT and BOLD fonts);
`-set '$NAME=value'` overrides any of them.  Running IBM's macros needed:

- DCF's macro libraries (`-lib`, `.ly`, `.dm name lib`, `.se name lib`),
  `.gs args`/`.gs vars`, the `.dc gml : : e` form, null array counters;
- the system symbols, `.sa`/`.re`, `.pi`/`.ix`, `.fv`, `.gs hctr`,
  `.gs qatt`, and `.ct` continuation;
- EBCDIC (code page 037) for `&X'..'`, `.tr` and `.dc` hex codes;
- *provisional* elements: a tag with no end APF and no `.xd` model
  becomes an empty marker unless its own end tag closes it, since IBM's
  profile defines no element models;
- in TeX, a *hint mode* (`tex-mode=auto|elements|hints`, chosen
  automatically when `.df`/`.dh`/`.dr` come before the first element)
  where the element styles of `gml.tex` step aside and the profile's
  control words do the formatting; named `.dr` rules in `.bx` and
  `.hr`; `.df` fonts (overstrike as bold, underscore as italic, `up` as
  upper case, `type(...)` by family and size); and `.dh`.

All of these have cram tests or XSLT fixtures of their own.  The run
now ends with one warning (`.sv`) and one error, IBM's own `.sk &@sK@x`
(symbol names are case-sensitive), and TeX runs without errors.  What
still differs from IBM's output: `&` (the page number) in running
footings comes out literally, `.pi`/`.ix` index entries are not yet
typeset by TeX, `.cd` columns are ignored, and the TOC and some
quotation marks are not right yet.

The SH35-0070 Language Reference, which defines most of these, has no
English copy online.  The other references, kept in the project root
and gitignored, are the Text Programmer's Guide (SH35-0069-3), the
Implementation Guide (SH35-0050-2), the Text Programmer's Quick
Reference (SX26-3723-5: control word syntax and system symbols) and
the Release 2 User's Guide (SH20-9161-3: control word and `.gs`
service descriptions, before Release 3), all from
<http://www.bitsavers.org/pdf/ibm/370/DCF/>.  A Hebrew translation of
SH35-0070-2 is on archive.org (item `ibm-hdcf-3-manual-1986`); its page
images are readable, though its OCR text is not.

## Known limitations

- **XSL-FO is not render-tested.** No FO formatter is installed, so
  `doc.fo` is checked only structurally (`mk fo-check`, and the fo
  fixtures run `xslt/test/fo/check.xsl`).  `mk doc.pdf` needs `FOP=...`.
- Plain XSL-FO 1.1 cannot express some things, so fo.xsl approximates
  them:
  - `when=auto` page references and `.cp n`;
  - floating keeps and figures at the page foot;
  - a running heading that changes in the middle of a paragraph;
  - tabs (`.tp`/`.tb`) and column balancing (`.bc`);
  - `.sc`/`.mc` in mid-page and `.pa n` renumbering;
  - footnotes in figures (written in place, in brackets);
  - `.kp`/`.bx` brackets, which are applied to whole blocks.

  fo.xsl also ignores the temporary `.in`/`.ir` (FOR/AFTER), `.vr`,
  `.ic`, `.ud`, `.dr`, the page-layout words and `.cd`.
- TeX ignores `.vr .sb .ic .ud .mc .pi .ix` with a message, approximates `.is`, and
  `.cd` multi-column layout gives one column.  `.tc` is ignored: the TOC
  comes from `:toc`.
- HTML has no pages.  `gml:pageref` is dropped or becomes a link
  (`pageref=link`).  `.wz .bc .ws .es .sb .ud` survive only as
  `data-gml-*` attributes.
- Device-only control words (`.dd .it .sv .dl .uw .oc .sy .te .lo`) give
  a one-time warning.  Layout system symbols (`&$PN` = 1, `&DH'` ... =
  0) return neutral values.
- `gmlfmt` and `xslt/test/fo/check` are rc scripts.  plan9port rc cannot
  run a script named by a relative path such as `dir/gmlfmt`, so start
  them with a path that begins with `/` or `./`.  `xslt/test/run` has a
  small sh launcher for this reason.
