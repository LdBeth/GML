&'func(args) built-in functions (REXX-like semantics; our extension, they
are not in SH35-0069).  The line is substituted right to left, so the
arguments are substituted before the call; a reference ends only at a
blank, a period, a ) or the end of the line (p.232, p.256), hence &s., in the
arguments.  The call splits them at top-level commas; quotes delimit
arguments that contain blanks or commas.  A failing call is left as
written.

  $ gml in.gml
  in.gml:17: error: &'left: 1 argument given, 2 to 3 expected
  in.gml:17: error: &'substr: x is not a number
  in.gml:17: error: unknown function &'nosuch
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">length=11
  substr=[World] [ell] [bc***]
  index=5 8 0
  left=[Hello] [ab..] right=[World] [  ab]
  upper=HELLO WORLD lower=hello world partial=aBCDef
  strip=[pad] [pad  ] [  pad] [pad]
  copies=ababab []
  delstr=Hello World abc
  insert=[XYabc] [aXYbc] [abc--XY-]
  word=World [] words=3
  min=-2 max=7
  nested=HELL
  comma in quotes=3
  computed=22
  bad=&amp;'nosuch(1) &amp;'substr(abc,x) &amp;'left(abc)
  </gml:doc>
  [8]
