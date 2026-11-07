The symbol file of the pass model (gml -symbols-out / -symbols-in,
lib/symbols.ml Symbols.dump, lib/toc.ml Toc.dump): the symbols that
are defined at the end of a pass, for the next one.  It is SCRIPT
source, imbedded by the next pass: a constant first line, .su off and
.dc cw off (a value with & or ; is taken as written), one .se line per
symbol and per array element, sorted, the value always quoted with a
quote in it doubled, then .dc cw and .su on.  Not written: local
symbols, system symbols, the date and time symbols (set by every pass,
they would make two passes differ).  The TOC entries follow as the
array gml@toc (DCF keeps its DSMUTTOC file between passes, TPG p.156),
their fields separated by tabs.

  $ cat > in.gml <<'EOT'
  > .se b = two
  > .se a = 'one
  > .se arr(1) = x
  > .se arr(2) = y
  > .se *loc = local
  > .se tab = a&$TAB.b
  > .se bs = 'c:\dir
  > .se amp = 'R&&D'
  > .se q = 'it''s'
  > .'se semi = 'x;y'
  > .se gone = 1
  > .se gone off
  > .h1 Heading
  > .pt A line
  > EOT
  $ gml -symbols-out in.sym in.gml > /dev/null
  $ cat in.sym
  .* gml symbols
  .su off
  .dc cw off
  .se a = 'one'
  .se amp = 'R&&D'
  .se arr = '2'
  .se arr(1) = 'x'
  .se arr(2) = 'y'
  .se b = 'two'
  .se bs = 'c:\dir'
  .se q = 'it''s'
  .se semi = 'x;y'
  .se tab = 'a	b'
  .se gml@toc(1) = '1	1	0		1	gml.tc.1	Heading'
  .se gml@toc(2) = 'pt	0	0		1	gml.tc.2	A line'
  .dc cw
  .su on

-symbols-in loads them before the profile and the document run: a
symbol of the previous pass is defined (a forward reference finds it),
-set and every .se of this pass win.  "All array index counters are
reset to zero for the second pass but the individual elements are not
reset" (TPG p.256): &arr is 0, &arr(2) is y, and .se arr() = v sets
element 1 again.

  $ cat > use.gml <<'EOT'
  > .se b = again
  > &a &b &arr(2) &arr &tab &bs
  > .se arr() = z
  > &arr(1) &arr(2) &arr
  > &q &semi. &$PASS
  > EOT
  $ gml -symbols-in in.sym -set a=cmd use.gml | grep -A2 again
  <gml:doc xmlns:gml="urn:x-gml:canonical">cmd again y 0 a	b c:\dir
  z y 1
  it's x;y 1

The value with & is loaded as written (substitution is off while the
file is imbedded) and dumped again unchanged; so is every other line
(only the counter of arr is reset).

  $ gml -symbols-in in.sym -symbols-out again.sym in.gml > /dev/null
  $ diff in.sym again.sym
  $ printf '.se arr = 7\n' > c.gml
  $ gml -symbols-in in.sym -symbols-out c.sym c.gml > /dev/null
  $ grep "amp\|arr = " c.sym
  .se amp = 'R&&D'
  .se arr = '7'

A line end in a value cannot be written in a .se line: it becomes a
blank (DCF-VERIFY).

  $ gml -set 'nl=a
  > b' -symbols-out nl.sym c.gml > /dev/null
  $ grep nl nl.sym
  .se nl = 'a b'

The TOC entries of the previous pass are what a .tc prints (one at the
start of the document: TWOPASS, TPG p.156), the page from the anchor
in the aux file when it has it.

  $ printf '.tc\n.h1 Heading\n' > front.gml
  $ printf ".* gml aux\n.se pa@gml@tc@1 = '7'\n" > front.gmlaux
  $ gml -symbols-in in.sym -aux front.gmlaux front.gml | grep -o '<gml:tcentry [^>]*>'
  <gml:tcentry level="1" text="Heading" dot="yes" page="7" break="yes"/>
  <gml:tcentry level="pt" text="A line" dot="yes" anchor="gml.tc.2" break="yes"/>

Without the file (the first pass) the .tc at the start is empty; a
symbol file that does not exist is the same.  The file is SCRIPT: what
is not a .se line is processed as such (here a text line), and a .se
line with a bad name is an error (and the document is not processed).

  $ gml front.gml | grep -c tcentry
  0
  [1]
  $ gml -symbols-in none.sym front.gml | grep -c tcentry
  0
  [1]
  $ printf ".se ok = 'yes'\nsome text\n.se b-d = 'x'\n" > junk.sym
  $ printf '&ok\n' > j.gml
  $ gml -symbols-in junk.sym j.gml
  junk.sym:3: error: .se: invalid symbol name b-
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">some text
  </gml:doc>
  [8]

A pass's number: -pass K -passes N set &$PASS and &$TWO (1 when N > 1;
SCRIPT's TWOPASS and FPASSES(n), SH20-9186-06 p.126, p.129) and
&$PASSES (not DCF: the n of FPASSES); the root element carries them for
tex.xsl.

  $ printf '&$PASS &$TWO &$PASSES\n' > p.gml
  $ gml p.gml | tail -2
  <gml:doc xmlns:gml="urn:x-gml:canonical">1 0 1
  </gml:doc>
  $ gml -pass 2 -passes 3 p.gml | tail -2
  <gml:doc xmlns:gml="urn:x-gml:canonical" pass="2" passes="3">2 1 3
  </gml:doc>
  $ gml -pass 4 -passes 3 p.gml
  gml: error: -pass 4 -passes 3: expected 1 <= k <= n
  usage: gml [-I dir]... [-lib dir]... [-share dir] [-profile file|name] [-set sym=val]... [-maxgo n] [-undef-tags text|element|error] [-o out.xml] [-pass k] [-passes n] [-aux file] [-symbols-in file] [-symbols-out file] input.gml
  [8]
