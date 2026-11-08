A tag-set profile that chooses its master profile by the logical device,
as DCF profiles test &$LDEV (examples/notes/profile.gml does this): the
HTML paths give gml -set '$LDEV=HTML' (gmlfmt -to html, the examples'
mkfile) and get the semantic profile starter, elements; anything else
has the default device (3800N6) and gets the formatting profile
dcfstarter, hints (a .sk before each paragraph, "Note:" in hi2).

  $ gml -profile profile.gml -set '$LDEV=HTML' in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body><p>Hello.
  </p><note>Look.
  </note></body></gdoc></gml:doc>

  $ gml -profile profile.gml in.gml | grep -o '<gml:sk[^>]*>Hello\.\|<gml:sk[^>]*><gml:bf[^>]*>Note:\|Look\.'
  <gml:sk n="0.75" unit="line" break="yes"/>Hello.
  <gml:sk n="0.75" unit="line" break="yes"/><gml:bf font="hi2" break="no"/>Note:
  Look.
