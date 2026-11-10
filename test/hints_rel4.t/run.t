Rel 4 operand rules (SH35-0070-07, "LR").  .dv (p.157-159): FONT or
BASELINE and TEXT exclude each other, the last one given counting
(r12); the name is at most 10 characters and not an array.  .bf with
no font restarts the current font, saved for .pf; "=" restarts it
quietly when none of the list is usable (p.75-77).  .hr with no
operands repeats the previous rule (r6, repeat="yes"); a rule name
needs a displacement (p.192).  .dh (p.136-138): HANG and TCIN take one
value, TFONT and FONT a font (FONT may be the last word, with none);
OJ is OUTSIDE (r8); hy and tind are not .dh options.  .rh/.rf ODD or
EVEN limit a definition or an action to those pages (p.310-314).

  $ gml in.gml
  in.gml:3: error: .dv longername1: a name of at most 10 characters expected
  in.gml:4: error: .dv arr(1): an array symbol is not allowed
  in.gml:13: error: .hr thin: a rule name needs a horizontal displacement
  in.gml:14: warning: .dh 2: unknown option hy (ignored)
  in.gml:14: warning: .dh 2: unknown option tind (ignored)
  in.gml:14: warning: .dh 2: unknown option 2 (ignored)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Variables <gml:dv name="a" text="plain" break="no"/> and <gml:dv name="b" baseline="2pt" text="raised" break="no"/>.
  <gml:bf font="" initial="yes" restart="yes" break="no"/><gml:bf font="hi2" restart="yes" break="no"/><gml:pf initial="yes" break="no"/><gml:pf initial="yes" break="no"/><gml:hr repeat="yes" break="yes"/><gml:hr spec="1i 3i" break="yes"/><gml:hr repeat="yes" break="yes"/><gml:dh level="2" spec="hang 3 tcin 2 tfont hi1 font hd2 us oj autohy hy tind 2" break="no"/><gml:dh level="3" spec="font" break="no"/><gml:rh action="cancel" page="even" break="yes"/><gml:rf page="odd" break="yes">Odd footing
  </gml:rf></gml:doc>
  [8]
