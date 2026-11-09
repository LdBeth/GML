Text variables in messages and in the separator rule (SH35-0069
p.258-261): IBM's DSMPROF3 defines &amp. &gml. &semi. as ".dv amp
text /&", ".dv gml text /:" and ".'dv semi text /;", known text that
needs no code point and no translate table and may be used anywhere.
.mg and .ty write a text variable as its text; the .mg fields are split
before that, so a delimiter in a variable is text (&sl. is "/").  A separator in a
text variable's string does not split a control word line (the second
.ty has one line from &semi. and is split only at the real ";").  In
the document a variable is the hint gml:dv.

  $ gml in.gml
  in.gml:5: +++ASSERTE &util 81 greater than 80
  [&] [:] [;]
  one;two
  three
  in.gml:9: +++NOTEI a/b
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Text <gml:dv name="amp" text="&amp;" break="no"/> more<gml:dv name="semi" text=";" break="no"/> end.
  </gml:doc>
  [8]

The Starter Set profiles define them the same way (starterset.gml).

  $ cat > release.gml <<'X'
  > .se util = 81
  > .if &util gt 80 .mg /ASSERTE/&amp.util &util greater than 80/
  > X
  $ gml -profile starter release.gml > /dev/null
  release.gml:2: +++ASSERTE &util 81 greater than 80
  [8]
