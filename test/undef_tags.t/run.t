A tag without APF: text with an error message unless .gs tag onno (the
default, -undef-tags text), an element (-undef-tags element), or always
an error (-undef-tags error).

  $ gml in.gml
  in.gml:4: error: no APF for tag :zz; treated as text
  in.gml:4: error: no APF for tag ::b; treated as text
  in.gml:6: warning: element p not closed at end of input
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p>Known tag, then :zz id=1.unknown and a::b.
  quiet :zz.
  </p></gml:doc>
  [8]

  $ gml -undef-tags element in.gml
  in.gml:4: warning: no APF for tag :zz; emitted as an element
  in.gml:4: warning: no APF for tag ::b; emitted as an element
  in.gml:4: warning: end tag ::b: element b is not open
  in.gml:6: warning: element zz not closed at end of input
  in.gml:6: warning: element zz not closed at end of input
  in.gml:6: warning: element p not closed at end of input
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p>Known tag, then <zz id="1">unknown and a
  quiet <zz>
  </zz></zz></p></gml:doc>
  [4]

  $ gml -undef-tags error in.gml
  in.gml:4: error: no APF for tag :zz
  in.gml:4: error: no APF for tag ::b
  in.gml:6: error: no APF for tag :zz
  in.gml:6: warning: element p not closed at end of input
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p>Known tag, then :zz id=1.unknown and a::b.
  quiet :zz.
  </p></gml:doc>
  [8]
