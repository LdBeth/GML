.dc gml forms (SH35-0069 p.289): ".dc gml : : e" gives ':' and ':e', the
end-tag delimiter written as the tag delimiter and a second character;
one two-character operand; one character; none (doubled).  An option
given last with no value restores its default (DCF-VERIFY).

  $ gml in.gml
  in.gml:14: warning: element li implicitly closed by end tag :eol
  in.gml:24: warning: element li implicitly closed by end tag %ol
  in.gml:39: error: .dc gml: end-tag delimiter : is the tag delimiter
  in.gml:53: warning: element p not closed at end of input
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[:] [:e]
  <ol><li>alpha
  </li></ol>[!] [!x]
  [!] [%]
  <ol><li>beta
  </li></ol>[+] [++]
  [:] [::]
  [:] [:e]
  <p>gamma
  v=1 w=2
  cont [+]
  cont []
  x/y
  x, y
  </p></gml:doc>
  [8]
