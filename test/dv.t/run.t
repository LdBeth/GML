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
input is the XSLT fixture xslt/test/tex/dv.  .hr with only
a rule name draws across the column (SX26-3723 .HR: every operand is
optional).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:dr spec="thick weight 1mm" break="no"/><gml:rf><gml:sx left="R &amp; D" fill="" right="Page " pagesym="" break="yes"/></gml:rf><gml:rh><gml:lines word="ce" n="1" break="yes">Heading &amp; more, page <gml:pageno break="no"/></gml:lines>
  </gml:rh>Body text with &amp; here and a raised callout<gml:dv name="sup" font="hi1" baseline="3pt" text="1" break="no"/> in text.
  <gml:hr spec="thick" break="yes"/>After the rule.
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
  <gml:br break="yes"/><gml:rf>A <gml:dv name="tamp" text="&amp;" break="no"/> B page <gml:pageno break="no"/>
  </gml:rf></gml:doc>
