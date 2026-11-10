The system symbols of the SCRIPT command options, the output device and
the page (SH35-0069 Figure 15, p.242-244; SX26-3723).  There is no
device: they are neutral, as for a 3800 printer under CMS, one pass,
with the INDEX option; -set overrides any of them.  &$CHAR(n) is the
CHARS option, an array: element 0 the number of fonts (p.178, p.242);
a missing font is null (SH20-9161-3 .DH).  &$FNAM is the current file
name.  &$IN &$IR &$OF &$LL are in figure spaces (1/10 inch here).
&$RB (EBCDIC 41, the no-break space) and &$PS ("&") come from .dc rb
and .dc ps; their hex codes are EBCDIC.

  $ gml in.gml
  in.gml:16: error: .se: system symbol &$PDEV is read-only
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Device 3800 3800N6 FILE, release 3.0.0 on CMS, pass 1 two 0
  Index 1 lib 0 unf 0 print ON bind 0 0
  File IN; fonts 2: [TEXT] [BOLD] [] [TEXT, BOLD]
  <gml:in left="5" unit="ch" break="yes"/><gml:ir right="1" unit="i" break="yes"/><gml:of offset="2" unit="ch" break="yes"/><gml:ll length="6.5" unit="i" break="yes"/>In 5 ir 10 of 2 ll 65 cl 65 pl 66 pw 85 lc 60
  Blank [ ] page symbol [&amp;] kp OFF vr OFF
  Now [~] [#]
  Hex [ ] default [&amp;]
  Two fonts.
  </gml:doc>
  [8]

  $ gml -set '$PDEV=4250' -set '$CHAR=GT10 GB10 GI10' -set '$pass=2' in.gml 2>&1 | sed -n '3,5p'
  <gml:doc xmlns:gml="urn:x-gml:canonical">Device 4250 3800N6 FILE, release 3.0.0 on CMS, pass 2 two 0
  Index 1 lib 0 unf 0 print ON bind 0 0
  File IN; fonts 3: [GT10] [GB10] [GI10] [GT10, GB10, GI10]

&$FNAM has at most 8 characters (LR p.446, Table 21).

  $ printf '&$FNAM\n' > averylongname.gml
  $ gml averylongname.gml | sed -n 2p
  <gml:doc xmlns:gml="urn:x-gml:canonical">AVERYLON
