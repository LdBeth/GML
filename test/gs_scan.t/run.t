.gs scan / .gs copy / .gs insert on the residual text; symbols in the
residual text are substituted before the APF runs (SH35-0050 p.10).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[heading: The Title]
  [residual of length 10]
  First Line
  of the Title
  [no residual]
  See Figure 7 for details.
  [the count is 0]
  now the count is 1
  </gml:doc>

The residual text ends at the next tag on the line (SH35-0050 p.9: "the
residual text scanning is ended by another GML tag"; the Starter Set
forbids tags in a heading, SH20-9186-06 p.13): .gs scan gets the text
before it, and the tag and the rest of the line are processed after the
APF, as text.

  $ cat > tags.gml <<'X'
  > .gs tag on
  > .dc gml : : e
  > .dm hd on
  > .gs scan *t
  > [heading: &*t ]
  > .dm off
  > .aa hd hd
  > .aa hp1 hp1 ehp1
  > .dm hp1 /.bf hi1
  > .dm ehp1 /.pf
  > :hd.A :hp1.bold:ehp1. title
  > X
  $ gml tags.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><hd/>[heading: A  ]
  <hp1><gml:bf font="hi1" break="no"/>bold</hp1><gml:pf initial="yes" break="no"/> title
  </gml:doc>
