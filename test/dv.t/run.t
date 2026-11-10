.dv (SH35-0069 p.258-261; SX26-3723 .DV: name [FONT f] [BASELINE b]
/string, or name [TEXT] /string) defines a text variable: "known text"
that needs no code point or translate table, may be used anywhere (a
heading, a running heading or footing) and may have a font and a
baseline shift.  Where it is used it is the hint gml:dv (text=, font=,
baseline= normalised: "p3" is 3 points); in a running footing it is
text, not the page number symbol.  A .sx in a running heading or
footing marks the page number symbol (pagesym=, the fields split
around it), which tex.xsl writes as \gmlpageno, and every other
character, a translated &amp. too, as text (\&): the TeX of this
input is the XSLT fixture xslt/test/tex/dv.  A running heading or
footing is translated with the initial table as changed inside it
(LR p.404 r4), so each definition has its own .tr 02 50; &amp., a
global symbol, is a reference replaced per page (gml:symref, LR
p.316) whose value is translated with that table and is text the
backend never splits, so pagesym= is "&" itself.  .hr thick left right
draws a rule across the column; a rule name needs at least one
horizontal displacement (LR p.192).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:dr spec="thick weight 1mm" break="no"/><gml:rf break="yes"><gml:sx left="R amp&amp; D" fill="" right="Page &amp;" pagesym="&amp;" break="yes"/></gml:rf><gml:rh break="yes"><gml:lines word="ce" n="1" break="yes">Heading <gml:symref name="amp">&amp;</gml:symref> more, page <gml:pageno break="no"/></gml:lines>
  </gml:rh>Body text with &amp; here and a raised callout<gml:dv name="sup" font="hi1" baseline="3pt" text="1" break="no"/> in text.
  <gml:hr spec="thick left right" break="yes"/>After the rule.
  <gml:pa break="yes"/>Second page.
  </gml:doc>

The string of a text variable is substituted like any symbol value, so
IBM's DSMPROF3 can define its list item labels under .su off (".dv
@id@l@o1 /&@item#.."); a plain .dv (no FONT, BASELINE or TEXT) is a
symbol, so its value may also be a control word line.  The TEXT form
is known text: "&" from it is not the page number symbol.

  $ cat > plain.gml <<'X'
  > .se n = 3
  > .su off
  > .dv lab /&n..
  > .dv cw /.br
  > .dv tamp text /&
  > .su on
  > Item &lab
  > &cw
  > .rf on
  > A &tamp. B page &
  > .rf off
  > X
  $ gml plain.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Item 3.
  <gml:br break="yes"/><gml:rf break="yes">A <gml:symref name="tamp"><gml:dv name="tamp" text="&amp;" break="no"/></gml:symref> B page <gml:pageno break="no"/>
  </gml:rf></gml:doc>
