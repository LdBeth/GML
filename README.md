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
    [-maxgo n] [-undef-tags text|element|error] [-o out.xml] input.gml
```

- `-profile starter` loads the shipped Starter Set profile from the share
  directory: `-share dir`, else `$GML_SHARE`, else `share/gml` next to the
  executable, else the share directory of the build.
- `-set SYSVARH=yes` sets a symbol, as DCF's `SYSVAR` options do.
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
  [eol] [inline|block]` gives an element model for implicit closing.
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
  `gmlfont-NAME.tex` when present.
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

## Example

`examples/release.gml` is a Starter Set document (release notes) that
also uses the programmable layer: symbols and arithmetic (`&version`,
`&nextmin`), an array (`&platforms(*)`), a counting macro (`.change`),
conditional text with `.if`/`.go` driven by `-set audience=internal`, and
a user-defined tag `:warn level=n` whose APF uses `.gs attval` and `.gs
insert`, with an `.xd` model.  The tag is styled per backend without
touching the shipped files: `examples/release-html.xsl` and
`examples/release-fo.xsl` import html.xsl / fo.xsl, and
`examples/gmllocal.tex` styles it for TeX.

`examples/build` regenerates everything in `examples/out/`: the engine
XML (`release.xml`), resolved, scoped and semantic XML, HTML for both
audiences, XSL-FO, plain TeX and the typeset `release.pdf`.

## DCF fidelity

`docs/dcf-notes.md` lists the SCRIPT/VS and Starter Set rules checked
against the manuals.  Each entry has a status (DONE, OK, EXT) and the
cram test that shows it.  The points that the guides leave open are
marked `DCF-VERIFY`: 50 in the sources (`lib/`, `share/`, `xslt/`)
and 11 in the notes.  They include how far an ignored conditional section is
"resolved", the input-versus-output line count of `.in … after n`, the
`.mg` severities, the DSMGML message numbers and wording, `.tr` hex
codes taken as code points rather than EBCDIC, and APF lookup under
`.ms off`.  Deliberate extensions are marked EXT: the automatic element
per tag, `&'substr(`-style functions, footnotes inside figures, and
2-digit years taken as 20xx.

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
- TeX ignores `.vr .sb .is .ic .ud .dr .mc .dh` with a message, and
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
