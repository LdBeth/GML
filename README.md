# GML

A processor for IBM DCF SCRIPT/VS documents with GML markup (the DCF
Release 3 dialect, SH35-0069 and the Starter Set of SH35-0050).  The
programmable layer is kept faithful: symbols, macros, `.if`/`.go`,
conditional sections, imbedding and the GML tag-to-APF machinery.  Pages
are not laid out for a 3800 printer.  The engine writes a semantic XML
tree, and XSLT 3.0 stylesheets turn it into TeX for `share/tex/gml.tex`,
for any plain TeX engine (the main output), or into HTML (beside it as
LaTeX2HTML is beside LaTeX).
Formatting control words (`.sp`, `.in`, `.ce`, `.bf` ...) become *hints*:
each hint records the new state and whether it breaks.

## Architecture

```
 doc.gml + profile (share/profile/starter.gml, dcfstarter.gml: both
    |              imbed starterset.gml)
    |
    |  gml   OCaml engine (lib/, bin/): input stack, substitution,
    |        macros, GML tags -> APFs, .xs/.xd element building, hints
    v
 doc.xml    canonical XML (urn:x-gml:canonical, hints gml:*)
    |
    |  xslt/resolve.xsl   numbering, cross-references, TOC,
    v                     figure list, table grid, index
 doc.r.xml
    |
    +----------------------------------+
    |  main path: TeX                  |  secondary path: HTML
    |                                  |
    |  xslt/tex.xsl                    |  xslt/scope.xsl   state hints -> nested scopes
    v                                  v
 doc.tex + share/tex/gml.tex        doc.s.xml
    |                                  |
    |  plain TeX: tex, pdftex,         |  xslt/html.xsl + share/html/gml.css
    |  aptex ... in passes:            v
    |  gmlpass (mk doc.pdf)         doc.html
    v
 doc.pdf / doc.dvi
```

The TeX path is the main one.  The XSLT stages do the restructuring
(the table grid, lists, numbering, the index) and TeX does the layout;
tex.xsl writes hint mode when a formatting profile such as dcfstarter
drives the layout with control words.  The engine knows nothing about
XSLT; its stages are joined only by files, so each intermediate can be
inspected.  `xslt/strip-hints.xsl` also reads `doc.r.xml` and writes
the semantic tree only (`doc.sem.xml`).

## Prerequisites

- OCaml and dune in the opam switch `gml` (stdlib and `unix` only):
  `opam switch create gml ocaml-base-compiler.5.4.1 && opam install --switch=gml -y dune`.
  Every build runs through `opam exec --switch=gml -- dune ...`.
- SaxonC-HE, the native `transform` binary at `/usr/local/bin/transform`
  (override with `SAXON=...`).
- plan9port in `/usr/local/plan9` (`mk`, `rc`) for the `mkfile`, `gmlfmt`
  and the XSLT test runner.
- A plain TeX engine (`tex`, `pdftex`, `aptex` ...) for the TeX output.

## Build and test

```
opam exec --switch=gml -- dune build
opam exec --switch=gml -- dune test      # engine cram tests (test/*.t)
./xslt/test/run                          # XSLT fixtures (xslt/test/STAGE/*.in.xml)
mk test                                  # both: mk test-ocaml, test-xslt
```

`xslt/test/run [-update] [name...]` takes `STAGE/NAME`, `NAME` or a
bare stage (`xslt/test/run tex`).  Its header (`xslt/test/run.rc`)
lists how each fixture input was generated.

## Usage

### `gml`: the engine

```
gml [-I dir]... [-share dir] [-profile file|name] [-set sym=val]...
    [-lib dir]... [-maxgo n] [-undef-tags text|element|error] [-o out.xml]
    [-pass k] [-passes n] [-aux file] [-symbols-in file] [-symbols-out file]
    input.gml
```

- `-profile starter` loads the shipped Starter Set profile from the share
  directory (a file `starter` or `starter.gml` in the current directory
  comes first): `-share dir`, else `$GML_SHARE`, else `share/gml` next to the
  executable, else the share directory of the build.  Its tag set is the
  Release 3 Starter Set plus the tables of Release 3.2 (SH20-9186-06
  ch.7): `:rdef` row definitions (CWIDTHS, ARRANGE for spanning cells,
  per-cell HP/ALIGN/VALIGN/CONCAT/ROTATE/MINDEPTH), `:table :thd :tft
  :row :c :tnote :tcap :tdesc`, `:tref` and `:tlist`; resolve.xsl works
  out the cell grid, numbering and captions, and the HTML and TeX
  stages draw ruled tables (fixtures from `xslt/test/gml/tables.gml`).
  The part that does not depend on the output is shared with the
  formatting profile `dcfstarter` (below): `share/profile/starterset.gml`,
  which both profiles imbed (`.im starterset`).  It holds the delimiters,
  the text symbols (`&gml.`, `&amp.`, `&semi.`, `&rbl.`, the quotation
  marks `&oqq.` `&cqq.` `&oq.` `&cq.`), `&date` and `&time`, `:psc`
  (selected by `SYSVARP`), the message catalogue, the out-of-context
  handling and the decisions of the table tags (row definitions, cell
  numbers, CONCAT=NO); its macros and state are named `ss@...`.  `.im`
  looks in the working directory and the `-I` directories first, so a
  file `starterset.gml` there would shadow the shipped one.
- `-set SYSVARH=yes` sets a symbol, as DCF's `SYSVAR` options do.
- `-lib dir` (repeatable, searched in order) adds a symbol and macro
  library, as DCF's `LIB` option does: a member is the file `dir/NAME` or
  `dir/NAME.scr` (NAME in upper case), used by `.dm name lib`,
  `.se name lib`, and with `.ly on|mac|sym` for unresolved macros, APFs
  and symbols.
- `-o file` writes the XML there; without it, to standard output.
- `-pass k -passes n -aux file -symbols-in file -symbols-out file`: one
  pass of a multi-pass run (`&$PASS`, `&$TWO`; page questions answered
  from TeX's aux file; the symbols carried between passes).  See
  "Passes (`gmlpass`)", which runs them.
- The return code follows DCF: 0, or 4 after warnings, 8 after errors.

From the source tree:
`opam exec --switch=gml -- dune exec -- gml -share share -profile starter doc.gml`.

### `gmlfmt`: the whole pipeline to standard output

```
./gmlfmt [-to xml|resolved|scoped|semantic|html|tex] [-profile p]
         [-tagset t] [-set name=value]... [-p name=value]... [-I dir]... in.gml
```

`-set` goes to gml and to every stylesheet.  `-p` goes to the
stylesheets only, e.g. `./gmlfmt -to html -set SYSVARH=yes -p h1-prefix=Chapter doc.gml`.
`-to html`, `scoped` and `semantic` also give gml `-set '$LDEV=HTML'`
(the logical device, for a profile that chooses by it; to gml only),
before the `-set` options.
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
| `doc.html` | `doc.s.xml` | html.xsl |
| `doc.tex` | `doc.r.xml` | tex.xsl |
| `doc.texrun` | `doc.tex` | one run of `$TEX` (default tex) with `share/tex` on TEXINPUTS |
| `doc.pdf` | `doc.gml` | `gmlpass -n $PASSES -tex $TEXENGINE` (default 4, pdftex): see [Passes](#passes-gmlpass) |
| `doc.dvi` | `doc.gml` | the same with `$TEX` |
| `test`, `test-ocaml`, `test-xslt` | | the test suites |

```
SETS='SYSVARH=yes SYSVARP=draft' mk doc.html     # -set for gml and the stylesheets
mk "XSLTFLAGS='h1-prefix=Chapter'" doc.html      # stylesheet parameters only
```

mk does not know when `SETS` change: remove the intermediates
(`doc.xml`, `doc.r.xml` ...) first.  For one TeX run (`doc.texrun`),
run it twice: page references are read from `doc.gmlaux` on the second
run; `doc.pdf` and `doc.dvi` make the passes.

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
  Starter Set APFs in `starter.gml` (DSMPROF3's names; the shared ones
  are `ss@...` in `starterset.gml`) are ordinary macros: override them
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
  `strip-hints.xsl`, `html.xsl`, `tex.xsl`, used instead of the stock
  stylesheets.  An override normally does `xsl:import` of the
  stock one by relative path (e.g. `../../xslt/html.xsl` from a bundle
  in `share/tagset/NAME`) and adds or overrides template rules.  An
  optional `tagset.tex` is passed to tex.xsl as `tex-tagset`, which
  writes `\def\gmltagset{path}` before `\input gml`; gml.tex inputs it at
  its end, before `gmllocal.tex` (so the most local file wins).  For
  hint mode (a formatting profile) it gives its elements styles with
  `\gmldefhstart`/`\gmldefhend`.
  A bundle's profile may choose its master by the logical device, as
  DCF profiles do: `.if &$LDEV eq HTML` imbed `starter` (the semantic
  profile, for the HTML), else `dcfstarter` (the formatting profile,
  for pages).  The HTML paths give gml `-set '$LDEV=HTML'`: `gmlfmt -to
  html` (and `scoped`, `semantic`) does it itself, a mkfile adds it to
  `GMLFLAGS` (not `SETS`: those also go to every stylesheet, and
  `$LDEV` is not a parameter name); gmlpass and the other stages keep
  gml's default device (`3800N6`).  Such a profile defines what it
  relies on itself (not a master's internal symbols such as starter's
  `&@blk`), and its tags that need elements under dcfstarter say so in
  their `.aa` rules (`elem`, for the start and the end tag: the
  profile's default rules are `noelem`).
- **HTML.** Every element has a class `gml-NAME`.  Restyle
  `share/html/gml.css` or replace it (parameters `css`, `css-inline`,
  `css-file`).
- **XSLT.** Write a stylesheet that does `xsl:import` of a stage and
  overrides its template rules (the bundle `examples/notes/` has
  examples).  An importer of html.xsl that handles its own tags redefines the variable
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
  leads to `starterset.gml` (the files the profile imbeds are searched
  too).
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
conditional text with `.if`/`.go` driven by `-set audience=internal`, a
user-defined tag `:warn level=n` whose APF uses `.gs attval` and `.gs
insert`, with an `.xd` model, and math (`:m`, `:fml` numbered displays,
`:fmlref`).  The tags are handled per backend without touching the
shipped files, by the tag set `examples/notes/`: its `profile.gml`
defines them, its stylesheets import the stock stages and add rules for
them, and `tagset.tex` styles them for TeX.  One document, one profile
per application: `profile.gml` imbeds `starter` for the logical device
HTML (`-set '$LDEV=HTML'`, given by `gmlfmt -to html` and the examples'
mkfile), so the HTML is the semantic profile's, and `dcfstarter`
otherwise, so `release.pdf` (gmlpass) is the formatting profile's: there
`:warn` is laid out by its APF with control words, like `:note`, and
the math elements have hint-mode styles in `tagset.tex`.

`examples/dcfdemo.gml` shows the formatting profile (see
[below](#formatting-profile-dcfstarter)): every Starter Set tag
including the tables, with the TOC, the lists of figures and tables,
cross-references in both directions and an index.

`examples/tategaki.gml` is a Japanese document set vertically
(tategaki) by ApTeX, with the tag set `examples/tate/` (PDF only):
`profile.gml` is dcfstarter with Japanese literals (図, 表, 目次, the
quotation marks 「」『』, the date as 1986年6月13日), a title page that
fits the vertical page, paragraphs indented one character (`.il 1mh`),
less space around the headings (`.dh`: across the lines here), and the
ruby tags, the bases and readings
interleaved as in HTML: `:ruby.日:rt.に:ert.本:rt.ほん:eruby.` (`.xd rt
closedby=rt`: a reading is closed by the next `:rt` and by `:eruby`, so
`:ert` is written only before the next base text)
(elements: their rules say `elem`).  `tex.xsl` pairs each `:rt` with
the text before it and works out the placement after pxrubrica: a
reading centred on its base (spread 1:2:1 over a longer base of two or
more characters), the bases at their natural width, so that a long
reading (承/うけたまわ) overhangs the characters around it instead of
spacing the base, and the readings of one ruby moved apart as little
as they can be where they would overlap (東京/とうきょう).  The widths
come from the passes: the profile numbers each `:rt`, TeX writes the
measured widths of each base and reading to the aux file (`.se
rb@w(k)`, `.se rb@r(k)`, in sp), and the next pass's profile puts them
on the `:rt` (`.xa bw= rw=`) for tex.xsl; on the first pass they are
estimated from the characters.  `tex.xsl` also writes Japanese text as
it is, in UTF-8 (the CJK blocks, which upTeX reads as kanji), not as
`\gmlchar{n}`.  `tagset.tex` (a pTeX engine only) makes
the main vertical list tate (A5, 44 characters to the line), ships each
page in a horizontal box so that the running heading and footing (the
page number) stay horizontal, both at the top of the page, sets the
footnotes horizontally at the foot of the page with their marks upright
in the vertical line (tate-chu-yoko), centres
Latin letters on the vertical line (`\tbaselineshift`), selects with
every Latin font switch the mincho or gothic Japanese fonts that go
with it (an input line end after a kanji is no word space, pTeX's
rule; pTeX puts `\xkanjiskip` between Japanese and Latin), and sets
each reading in
half-size type against its base, to its right in a vertical line, in
a box of no size (one ruby is not broken across lines).
`../gmlpass -tex aptex -tagset ./tate -o out tategaki.gml` in examples/, or `mk
out/tategaki.pdf`.

`examples/mkfile` makes everything in `examples/out/` (`cd examples &&
mk`, or `mk -a` to redo it all): for release.gml the engine XML
(`release.xml`), resolved, scoped and semantic XML, HTML for both
audiences, plain TeX (one pass, element mode) and the typeset
`release.pdf`; for dcfdemo.gml `dcfdemo.pdf` and `dcfdemo.html`; for
tategaki.gml `tategaki.pdf` (always with aptex).  It
sets `ROOT`, `TAGSET=notes` and `OUTDIR=out/`, then includes the
project's `mkfile` for the rules and adds `-set '$LDEV=HTML'` to its
`GMLFLAGS`, so the engine XML and every stage made from it
(`release.tex` too) come from starter; the internal edition (`-set
audience=internal`), `gml.css`, the PDF files (gmlpass, in
`out/passes/`, the default device: dcfstarter) and dcfdemo.html (the
project's rules with `-profile starter`: resolve.xsl resolves the
forward references in one pass) have rules of their own.  `mk clean`
removes the TeX and pass by-products.

## DCF fidelity

`docs/dcf-notes.md` lists the SCRIPT/VS and Starter Set rules checked
against the manuals.  Each entry has a status (DONE, OK, EXT) and the
cram test that shows it.  The points that the guides leave open are
marked `DCF-VERIFY`, in the sources (`lib/`, `share/`, `xslt/`) and
in the notes.  They include how far an ignored conditional section is
"resolved", the input-versus-output line count of `.in … after n`, the
`.mg` severities, the message numbers and wording (one catalogue for
both Starter Set profiles), the EBCDIC code page (037) for hex codes, the neutral values of device system
symbols, and APF lookup under
`.ms off`.  Deliberate extensions are marked EXT: the automatic element
per tag, `&'substr(`-style functions, footnotes inside figures, and
2-digit years taken as 20xx.

## Formatting profile (dcfstarter)

`share/profile/dcfstarter.gml` (`-profile dcfstarter`) is a second
Starter Set profile.  Its tags and attributes are those of `starter`,
but its APFs format the way DSMPROF3 does: they are SCRIPT macros that
issue control words (`.sk .in .ir .of .is .bf .pf .df .dh .dr .hr .kp
.fn .rh .rf .pa .pn .sa .re`), set symbols and counters and use the
`.gs` services.  It was written from the manuals' description of the
Starter Set's behaviour (Implementation Guide SH35-0050, the GML
Starter Set reference), not from IBM's macro code; its macros are
named `f@...` and its messages are `DCFSnnnW`.  TeX is only the layout
engine: the `.df`/`.dh` at the start put `gml.tex` in hint mode, and
`.xs`/`.xe` keep just the elements that the later stages need (the
document sections, headings for the TOC, `fig`/`figcap` for the
figure list, the table elements for resolve.xsl's grid and the list of
tables).

Both profiles imbed `share/profile/starterset.gml` (see `-profile
starter` above) and so share one message catalogue (`ss@msg`): the same
condition gives the same number, `DSMGMLnnnW` under starter and
`DCFSnnnW` here (002 out of context, 003 not ended before a tag, 004
an end tag with no such structure open, 005 an end tag that does not
match the open list, 010/011 a term without a description and the
reverse, 012 a required attribute missing, 013 an ID defined twice, 014
a structure that cannot be nested, 015-019 the table checks, 020 an
undefined reference, on the last pass only).  The tags out of context
(`ss@cntx`) are dropped with DSMPROF3's attribute rules, so `:li id=x.`
loses its attribute as well.  DCF-VERIFY: the numbers and wording are
ours.

```
cd examples && ../gmlpass -set SYSVARH=yes -o out dcfdemo.gml   # out/dcfdemo.pdf

# the simple alternative: one pass (forward references give DCFS020W)
gmlfmt -to tex -profile dcfstarter -set SYSVARH=yes \
    examples/dcfdemo.gml > dcfdemo.tex
TEXINPUTS=.:share/tex: tex dcfdemo.tex
```

`examples/dcfdemo.gml` uses all of it; `cd examples && mk` makes
`out/dcfdemo.pdf` (`-n 4`, stable after pass 2) and `out/dcfdemo.html`.

`-set SYSVARH=yes` numbers the headings (`1.0`, `1.1`, ...; appendix
headings are lettered); `SYSVART=left|right|center` places the title
page.  The profile covers `:gdoc` (with `sec=`, which becomes the running
heading), the front matter (title page, abstract, preface, `:toc`,
`:figlist`, `:tlist`), body, appendix and back matter with their page numbering
and running footings, `:h0`-`:h6`, `:p :pc :note`, the five lists with
`compact`, `tsize`, `termhi`, `headhi` and `break`, `:lq`, `:xmp`,
`:fig` (`frame`, `place`), `:figcap :figdesc`, the tables of Release 3.2
(`:rdef` with `cwidths`, `arrange`, `hp`, `align`, `valign`, `concat`;
`:table :thd :tft :row :c :tnote :tcap :tdesc`, with the row
definition and cell number checks, the caption numbers and the space
around a table; the grid is resolve.xsl's, the rows, repeated header
and footer and footnotes in cells are gml.tex's), `:fn`, `:hp0`-`:hp3`,
`:cit`, `:q` (nesting), `:psc` (by `SYSVARP`), the cross-references `:hdref :figref :fnref
:liref :tref` (with `page=`), and the index tags `:i1`-`:i3 :ih1`-`:ih3 :iref`
(`pg`, `see`, `seeid`, `print`) through `.pi`.  Footnote callouts are
raised and small (a `.dv` text variable with FONT and BASELINE).  `:toc`
issues `.tc` only when the run has two passes (`&$TWO` = 1): with one
pass the table would be empty, so in the pipeline the TOC comes from
the resolve stage instead (`.xs toc`).  Tags out of context are
reported and dropped.  A reference to a target that comes later in
the document needs passes ([gmlpass](#passes-gmlpass)): in one pass it
gives `DCFS020W` and the Starter Set's "ID unknown" text; with passes
it is resolved on pass 2, with its page, and `DCFS020W` comes
only on the last pass, for an ID that does not exist.
`test/dcfstarter.t` checks its hints.

## Passes (`gmlpass`)

DCF formats a document more than once when it is asked to (the SCRIPT
options FPASSES(n) and TWOPASS, SH20-9186-06 p.126 and p.129) and puts
out only the last pass, so that forward references, a front table of
contents and page-dependent tests see the previous pass's results.
Here one pass is a gml run and a TeX run; `gmlpass` (an rc script
beside `gmlfmt`) makes them.  Without passes the page state is not
known while the document is processed: `&$PN` (and `.se x = &`,
SH35-0069 p.254) is 1 and `&$LC` is 60; a `.tc` entry carries
`anchor=` (its heading's `gml:tcmark`), and gml.tex's page references
give its page on the second TeX run.  With passes they come from TeX:

```
gmlpass [-n N] [-tex ENGINE] [-profile p | -tagset t] [-set name=value]...
        [-p name=value]... [-o DIR] doc.gml

cd examples && ../gmlpass -o out dcfdemo.gml       # out/dcfdemo.pdf
./gmlpass -tex aptex -o out examples/dcfdemo.gml
mk PROFILE=dcfstarter PASSES=4 TEXENGINE=aptex doc.pdf
```

The default is 4 passes (IBM's FPASSES limit), pdftex and `-profile
dcfstarter`; `-tex tex` makes a DVI file.  For pass k of N:

1. `gml -pass k -passes N -aux DIR/JOB.gmlaux -symbols-in DIR/JOB.sym
   -symbols-out DIR/JOB.sym.new`, then the stages to `DIR/JOB.tex`:
   the project's mkfile rules (`mk -a OUTDIR=DIR/ DIR/JOB.tex`, so
   `JOB.xml`, `JOB.r.xml` and `JOB.tex` are the files of the
   [mk table](#mk-the-pipeline-as-files); `GMLPASSFLAGS` carries the
   pass options to the gml rule);
2. ENGINE on `JOB.tex` in DIR.  `\gmlpass` in gml.tex (from the
   `\def\gmlpassno{k}\def\gmlpasses{N}` that tex.xsl puts
   before `\input gml`, from the root element's `pass=`/`passes=`)
   makes a draft before the last pass: `\pdfdraftmode=1` with pdftex,
   `\dpxoutput=0` with ApTeX (its DVI path), nothing with tex.  The
   choice is TeX's, from the TeX input, not a command-line switch;
3. `JOB.sym.new` becomes `JOB.sym`.

The first pass starts from nothing.  After a pass k >= 2 that left
`JOB.gmlaux` and the symbol file as the pass before it did, the next
pass would only repeat it: gmlpass goes straight to the last pass
(numbered N, so the profile and TeX know it is the last).  It warns
when the last pass still changed them (`-n` too small).  Its last line
names the passes it ran and the pass that found the files unchanged:
`gmlpass: out/doc.pdf (3 passes; stable after pass 2: -n 2 is
enough)`.  A forward
reference costs one pass, as in LaTeX: pass 1 does not know its
target; pass 2 knows the target's symbols (its number) and the page
TeX put the target on in pass 1 (the page provenance of the symbol
file, below); when that moved nothing, pass 2 finds the files
unchanged and is the last.  A reference asks for its own page on
every pass, so that pass 2 asks the same questions as pass 1.  When
the text that pass 2 adds ("on page n", the target's text for the
stand-in) moves a page, one more pass is needed; `page=yes` prints
the page on every pass.  `examples/dcfdemo.gml` and
`examples/release.gml` are stable after 2 (`-n 2` gives no warning;
with the default 4 gmlpass stops after 3 runs: pass 2 confirms pass
1, then the last).  The date and time are the same for
all passes (`SOURCE_DATE_EPOCH`).  The messages of the passes
before the last are kept in `DIR/JOB.passK.err`; the last pass prints
its own.

The two files between the passes are plain text in SCRIPT syntax: a
constant comment line, then `.se` lines, imbedded by the engine at the
start of the next pass (before `-set` and the profile) and, for
`JOB.gmlaux`, read by gml.tex under a catcode regime.  A symbol name
in them may be longer than ten characters.

- `JOB.gmlaux` (`-aux`): the pages of the anchors and the answers to
  the page-state questions, written by TeX (anchors and `pn` at
  shipout) and read by the next pass; the format is documented in
  gml.tex's header:

  ```
  .* gml aux
  .se pa@gml@tc@1 = 'iv'
  .se pr@1 = '3'
  .se pq@1@12@3 = 2
  ```

  `pa@` is the page of an anchor, `pr@N` gml.tex's own N-th `when=auto`
  page reference, `pq@` the answer to a question (a bare number),
  `px@` a tag set's own (written by its TeX file, read by its profile:
  the ruby widths of examples/tate); none of them is carried to
  `JOB.sym`.  The
  name after the prefix is the anchor or question id (without its
  `q`) as tex.xsl escapes it (`+code+` for a character other
  than A-Z a-z 0-9 `.` `-`), with `.` written `@` and any other
  character that is not a letter or digit as `#HH` (hexadecimal), so
  `gml.tc.1` is `pa@gml@tc@1` and `q1.12.3` is `pq@1@12@3`.  With `-aux`, every reference to `&$PN` or `&$LC` (also
  `.se x = &`) is a question: the hint `gml:query id=ID what=pn|lc`
  where it is made, `\gmlquery{ID}{pn|lc}` in the TeX (scope.xsl
  passes it, html.xsl and strip-hints.xsl drop it), answered from the
  previous pass's file (1 and 60 when it has no answer).  `pn` is the
  page number (absolute) of the page the place of the question is put
  out on, which is what a cross-reference wants of its target; `lc` is
  the lines left on the page, after the page builder ran (in a
  paragraph the lines of the paragraph in progress are not counted).
  The ID is `qF.L.N`, the N-th question on line L of input file F
  (files counted by their first question), so a decision taken
  differently on one line shifts only the ids of that line.  A `.tc`
  entry gets `page=` when the file knows its anchor.
- `JOB.sym` (`-symbols-out`, `-symbols-in`): the engine's symbol dump,
  carried to the next pass: the global symbols defined at the end of a
  pass (not the system, local, date and time symbols, nor the aux
  file's) and the TOC entries (DCF keeps its DSMUTTOC file between
  passes: a `.tc` at the front prints the previous pass's entries, TPG
  p.156), as the array `gml@toc`; the format is documented in
  lib/symbols.ml:

  ```
  .* gml symbols
  .su off
  .dc cw off
  .se fh@INTRO = 'Introduction'
  .se ss@mon(1) = 'January'
  .se gml@toc(1) = '1<TAB>1<TAB>0<TAB><TAB>1<TAB>gml.tc.1<TAB>Introduction'
  .dc cw
  .su on
  ```

  Values are always quoted, a quote doubled; `.su off` and `.dc cw
  off` keep `&` and `;` in a value as written; a line end in a value
  is written as a blank (DCF-VERIFY).  It is loaded before the profile
  runs, so `-set` and the profile's own `.se` lines win; a forward
  reference finds its target's symbols.  DCF-VERIFY: which symbols
  DCF keeps from one pass to the next.  Modern edge, the page
  provenance: a symbol that a `.se` set to the answer of the one page
  question on its line (`.se fp@ID = &$PN`, `.se x = &`) is written
  not with its value but as `.se gml@pgq(n) = 'NAME SUB ID DEFAULT'`
  (the question id and the neutral 1 or 60), and the next pass sets it
  to the answer that `JOB.gmlaux` of the same pass gives to that
  question.  So the page of a target reaches a forward reference in one
  pass (in DCF `&$PN` is the page on pass 1 already), and the file
  stays the same between two passes that ask the same questions.

`&$PASS` is k and `&$TWO` is 1 when N > 1; `&$PASSES` (not a DCF
symbol) is N.  The dcfstarter profile knows its last pass
(`ss@last` of starterset.gml, the TPG p.247 idiom generalised), gives `DCFS020W` and
the "ID unknown" texts only there, checks duplicate IDs per pass, and
issues `.tc` for `:toc` (`-set f@tcres=n` reserves n page numbers,
`.tc n`, TPG p.157).

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
still differs from IBM's output: `.cd` columns are ignored, the
table of contents is empty (DSMPROF3's `.tc` comes before the
headings, and there is one pass; see `&$PASS`), and some quotation
marks are not right yet.  The page number `&` in running headings and
footings (`\gmlpageno`, so a text `&` there stays an ampersand) and
the `.pi`/`.ix` index with its page numbers are typeset.

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

- TeX ignores `.vr .sb .ic .ud .mc` with a message, approximates `.is`
  (except `.is to` after a label at the start of a line, which is exact), and
  `.cd` multi-column layout gives one column.  `.tc` prints the entries
  collected so far in one pass, those of the previous pass with
  [gmlpass](#passes-gmlpass).
- HTML has no pages.  `gml:pageref` is dropped or becomes a link
  (`pageref=link`).  `.wz .bc .ws .es .sb .ud` survive only as
  `data-gml-*` attributes.
- Device-only control words (`.dd .it .sv .dl .uw .oc .sy .te .lo`) give
  a one-time warning.  Layout system symbols (`&$PN` = 1, `&$LC` = 60,
  `&DH'` ... = 0) return neutral values in one pass; with passes
  (`gml -aux`, gmlpass) `&$PN` and `&$LC` come from TeX.
- `gmlfmt` is an rc script.  plan9port rc cannot run a script named by
  a relative path such as `dir/gmlfmt`, so start it with a path that
  begins with `/` or `./`.  `xslt/test/run` has a
  small sh launcher for this reason.
