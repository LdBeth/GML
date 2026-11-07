Plain text lines become text in the root element.  A null line (.nl,
p.281) only cancels a continuation; it adds no text.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Hello world.
  Second line.
  After blank.
  </gml:doc>

-profile is imbedded before the input; -set is accepted (used from phase 2).

  $ gml -profile prof -set a=1 -set b=x=y in.gml
  profile ran
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">profile text
  Hello world.
  Second line.
  After blank.
  </gml:doc>

Bad usage:

  $ gml -set nope in.gml
  gml: error: -set nope: expected sym=val
  usage: gml [-I dir]... [-lib dir]... [-share dir] [-profile file|name] [-set sym=val]... [-maxgo n] [-undef-tags text|element|error] [-o out.xml] [-tex file] [-tex-fonts name] input.gml
  [8]
  $ gml
  gml: error: no input file
  usage: gml [-I dir]... [-lib dir]... [-share dir] [-profile file|name] [-set sym=val]... [-maxgo n] [-undef-tags text|element|error] [-o out.xml] [-tex file] [-tex-fonts name] input.gml
  [8]
