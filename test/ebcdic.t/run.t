Hexadecimal codes are EBCDIC, as in DCF: &X'..' (SH35-0069 p.238-239),
the .tr operands (p.207) and the .dc values (p.254) are translated to
Unicode with code page 037 (lib/ebcdic.ml), except B0-B9, the
superscript digits of the 1403 and 3800 text fonts that IBM's DSM#SUPR
translates footnote numbers to (SH35-0050).  So 40 is a blank, 41 the
required blank, 4A the cent sign; .tr f1 f1 (EBCDIC "1" to itself) ends
a .tr 1 b1; .dc cont 03 is the character &X'03.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Letters HELLO digits 1986 specials [.&lt;(+|&amp;!$*);¬]
  Blank [ ] required blank [ ] cent ¢ not ¬ bar |
  Superscripts ⁰¹²³⁴⁵⁶⁷⁸⁹ accents àé; braces {}
  Bullet ®
  Note ¹²
  Note 12
  Array x, y
  Joinedhere
  </gml:doc>
