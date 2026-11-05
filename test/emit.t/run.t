.xs/.xe/.xa/.xr/.xd and their errors.

  $ gml in.gml
  in.gml:8: warning: .xr html: text after the closing delimiter ignored
  in.gml:18: error: .xe section: element section is not open (no element is open)
  in.gml:21: error: .xe list: element b, opened inside list, must be closed first (open: b, list)
  in.gml:24: error: .xe list: element list is not open (no element is open)
  in.gml:25: error: .xe: no element is open
  in.gml:26: error: .xa x: no element is open
  in.gml:27: error: .xs: invalid name 1bad
  in.gml:28: error: .xs: name=value expected at 'attr'
  in.gml:29: error: .xd foo: unknown option frob
  in.gml:30: error: .xr tex: delimited text expected
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><section id="s1" title="A &quot;quoted&quot; title"><para class="lead">Text in a paragraph.
  </para><gml:raw backend="tex">\vskip 1in</gml:raw><gml:raw backend="html">&lt;hr&gt;</gml:raw><item>first
  </item><item>second
  <sep/></item></section><list><b/></list></gml:doc>
  [8]
