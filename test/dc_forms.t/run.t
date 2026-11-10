.dc forms (LR p.112-115): ".dc gml c e1 e2" gives c and e1e2 (".dc gml
: : e" is ':' and ':e'); ".dc gml c e" gives c and e; ".dc gml c" alone
gives no end-tag delimiter (end tags not recognized: ++eol. is a + and
the start tag eol); the end-tag delimiter may also be one two-character
operand that starts with c
(DSMPROF3's ".dc gml : :e"); characters in hexadecimal; X'40' is OFF
for GML and CW; a period is not a GML delimiter.  An option given with
no value restores its initial value (LR p.114).

  $ gml in.gml
  in.gml:14: warning: element li implicitly closed by end tag :eol
  in.gml:24: warning: element li implicitly closed by end tag %ol
  one line;.ty no separator
  in.gml:49: error: .dc gml: invalid delimiter .
  in.gml:57: error: .dc gml: end-tag delimiter : is the tag delimiter
  in.gml:71: warning: element p not closed at end of input
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[:] [:e]
  <ol><li>alpha
  </li></ol>[!] [!x]
  [!] [%]
  <ol><li>beta
  </li></ol>[+] []
  <eol/>delta +<eol/>
  [:] [::]
  [|] [::]
  []
  [:] [:e]
  <p>gamma
  v=1 w=2
  cont [+]
  cont []
  x/y
  x, y
  </p></gml:doc>
  [8]
