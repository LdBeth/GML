.sa [name] / .re [name] save and restore the formatting environment
(LR p.323, p.309; Table 25 p.451): of what it holds the engine tracks
the indention, offset, line length, format mode, hyphenation, the font
stack, the .tr table, the .dc characters CONT CW GML MCS PS, and the
.ce .ri .us .up .uc lines (the number left, or ON).  They are the hints
gml:sa / gml:re; .re is followed by the hints that set again each part
that changes, with restore="yes" (.pf for the fonts pushed since the
.sa), so a backend need not know gml:re.  The unnamed environments are
a stack: .re takes the most recent one off; a named one is kept apart:
.re name restores it and drops nothing.  With no unnamed environment
saved, .re restores the initial values (p.309 r2).  .re breaks when
the format mode or the centring changes (r3, r4).  A footnote saves the
environment and clears the offset; .fn off restores it without hints
(but those of the revision codes, test/rc.t).
.fv is a hint.  A temporary indention until changed (.in h 0) is part
of the indention saved, and &$IN gives it (LR p.211 r4: permanent and
temporary components; a FOR/AFTER distance and a pending .il/.un are
gml.tex's, which saves them at gml:sa).

  $ gml in.gml
  in.gml:30: warning: .re NOSUCH: no environment saved with this name
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:in left="2" unit="ch" break="yes"/><gml:bf font="body" break="no"/>Main teXt X.
  <gml:sa break="no"/><gml:in left="5" unit="ch" delta="+3" break="yes"/><gml:ll length="5" unit="i" break="yes"/><gml:fo fill="no" align="left" overdraw="extend" break="yes"/><gml:hy mode="on" break="no"/><gml:bf font="hi1" break="no"/><gml:bf font="hi2" break="no"/>Saved x.
  <gml:re break="yes"/><gml:in left="2" unit="ch" restore="yes" break="no"/><gml:ll length="default" restore="yes" break="no"/><gml:fo fill="yes" align="justify" overdraw="extend" restore="yes" break="no"/><gml:hy mode="off" restore="yes" break="no"/><gml:pf font="hi1" restore="yes" break="no"/><gml:pf font="body" restore="yes" break="no"/>Restored X.
  <gml:sa name="OUTER" break="no"/><gml:of offset="4" unit="ch" break="yes"/><gml:sa break="no"/><gml:ir right="1" unit="ch" break="yes"/><gml:sa name="INNER" break="no"/><gml:ir right="2" unit="ch" break="yes"/><gml:re name="OUTER" break="no"/><gml:of offset="0" unit="ch" restore="yes" break="no"/><gml:ir right="0" unit="ch" restore="yes" break="no"/>After outer.
  <gml:re name="INNER" break="no"/><gml:of offset="4" unit="ch" restore="yes" break="no"/><gml:ir right="1" unit="ch" restore="yes" break="no"/>After inner.
  <gml:re break="no"/><gml:ir right="0" unit="ch" restore="yes" break="no"/>After unnamed.
  <gml:re break="no"/><gml:in left="0" unit="ch" restore="yes" break="no"/><gml:of offset="0" unit="ch" restore="yes" break="no"/><gml:pf initial="yes" restore="yes" break="no"/>Initial values.
  <gml:in left="6" unit="ch" break="yes"/><gml:of offset="1" unit="ch" break="yes"/><gml:fn>Footnote.
  <gml:in left="9" unit="ch" break="yes"/></gml:fn><gml:in left="7" unit="ch" delta="+1" offset="0" break="yes"/><gml:fv spec="justify" break="no"/><gml:lines word="ce" n="on" break="yes"><gml:sa break="no"/></gml:lines>Page symbol % not centred.
  <gml:re break="yes"/><gml:lines word="ce" n="on" break="no">Page symbol # centred again.
  </gml:lines><gml:in left="10" unit="ch" break="yes"/>Temporary indention until changed, 10
  <gml:sa break="no"/><gml:in left="8" unit="ch" break="yes"/>Indention 8
  <gml:re break="no"/><gml:in left="10" unit="ch" restore="yes" break="no"/>Back at the temporary one, 10
  </gml:doc>
  [4]
