.rc (LR p.301-306): the engine keeps the revision code state (the
nine definitions, the codes on, ADJUST, ALIGN; part of the active
environment, r7) and puts out what it resolves to.  A definition puts
out nothing.  gml:rc state="on" code char [font] whenever the active
code changes, also when the OFF of the active code brings back the one
stacked under it (r5); state="off" when no code is left.  The OFF of a
code stacked but not active takes it off the stack and puts out
nothing.  .rc n ON/OFF and .rc * c mark the next line: a gml:lines
scope.  ADJUST [h] [LEFT|RIGHT] (h 2 by default) and ALIGN [a] (LEFT by
default) are hints as given.  .rc n alone defines a blank, .rc * alone
marks with one; "+" and "-" are characters, not signs.

DCF messages (SH35-0048), each ignoring the word: 515 W for an ON of
the active code or an OFF of a code not on; 516 W for a definition of
a code on (active or stacked; r6); 517 W for a tenth ON.  A code not
defined marks with a blank, with a warning (DCF-VERIFY).

  $ gml in.gml
  in.gml:19: warning: .rc 1 on: .RC mode was on already (ignored)
  in.gml:21: warning: .rc 1 off: .RC mode was off already (ignored)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rc state="on" code="1" char="*" break="no"/><gml:rc state="on" code="2" char="?" break="no"/>It was so kind of you to come!
  <gml:rc state="on" code="1" char="*" break="no"/>Cut us another slice.
  <gml:rc state="off" break="no"/><gml:rc state="on" code="1" char="*" break="no"/><gml:rc state="on" code="2" char="?" break="no"/><gml:rc state="on" code="3" char="|" font="rcbold" break="no"/>nested three
  still three
  <gml:rc state="on" code="1" char="*" break="no"/>back to one
  <gml:rc state="off" break="no"/>plain
  <gml:rc state="on" code="1" char="*" break="no"/><gml:rc state="on" code="2" char="?" break="no"/><gml:rc state="on" code="1" char="*" break="no"/>code 1 again, over 2 over 1
  <gml:rc state="on" code="2" char="?" break="no"/>two
  <gml:rc state="on" code="1" char="*" break="no"/>one
  <gml:rc state="off" break="no"/><gml:lines word="rc" n="1" code="2" char="?" break="no">To play them such a trick.</gml:lines>
  <gml:lines word="rc" n="1" char="!" break="no">The Carpenter said nothing but</gml:lines>
  <gml:lines word="rc" n="1" code="4" char="+" font="=" break="no">plus</gml:lines>
  <gml:rc adjust="2ch" break="no"/><gml:rc adjust="4ch" break="no"/><gml:rc adjust="1i" side="left" break="no"/><gml:rc adjust="2ch" side="right" break="no"/><gml:rc align="right" break="no"/><gml:rc align="left" break="no"/><gml:rc align="inside" break="no"/><gml:rc align="outside" break="no"/><gml:rc align="outcol" break="no"/></gml:doc>
  [4]
.sa/.re and a footnote save and restore the whole state: after .re
(and after .fn off) the gml:rc hints that take a backend to the
restored state (the active code, then ADJUST per side, then ALIGN),
none when nothing differs; a definition made after the .sa is gone.

  $ gml env.gml
  env.gml:26: warning: .rc 1 on: revision code 1 is not defined; its character is a blank
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rc state="on" code="3" char="/" break="no"/><gml:sa break="no"/><gml:rc state="off" break="no"/><gml:rc adjust="6ch" break="no"/><gml:rc align="right" break="no"/><gml:re break="no"/><gml:rc state="on" code="3" char="/" break="no"/><gml:rc adjust="2ch" break="no"/><gml:rc align="left" break="no"/>on again
  <gml:sa break="no"/><gml:re break="no"/>nothing differs
  <gml:sa break="no"/><gml:rc adjust="6ch" side="left" break="no"/><gml:rc state="on" code="1" char="x" break="no"/><gml:re break="no"/><gml:rc state="on" code="3" char="/" break="no"/><gml:rc adjust="2ch" side="left" break="no"/>3 again, the left adjust back
  <gml:rc state="off" break="no"/><gml:rc adjust="6ch" break="no"/><gml:sa break="no"/><gml:rc state="on" code="3" char="/" break="no"/><gml:re break="no"/><gml:rc state="off" break="no"/><gml:rc state="on" code="3" char="/" break="no"/><gml:fn><gml:rc state="off" break="no"/><gml:rc state="on" code="1" char=" " break="no"/>in the note
  </gml:fn><gml:rc state="on" code="3" char="/" break="no"/>after the note
  </gml:doc>
  [4]
  $ gml errors.gml
  errors.gml:1: error: .rc: revision code 1 to 9 expected, not 0
  errors.gml:2: error: .rc: revision code 1 to 9 expected, not 10
  errors.gml:3: error: .rc: a revision code 1 to 9, *, ADJUST or ALIGN expected, not a
  errors.gml:4: error: .rc: a revision code 1 to 9, *, ADJUST or ALIGN expected, not +1
  errors.gml:5: error: .rc: operands expected
  errors.gml:6: error: .rc 1: one revision character expected, not ab
  errors.gml:7: error: .rc 1: FONT needs a font name
  errors.gml:8: error: .rc 1: unexpected operands y
  errors.gml:14: warning: .rc 1: invalid .RC definition: revision code 1 is on (ignored)
  errors.gml:16: warning: .rc 1: invalid .RC definition: revision code 1 is on (ignored)
  errors.gml:19: warning: .rc 1 off: .RC mode was off already (ignored)
  errors.gml:20: warning: .rc 5 off: .RC mode was off already (ignored)
  errors.gml:21: warning: .rc 5 on: revision code 5 is not defined; its character is a blank
  errors.gml:32: warning: .rc 9 on: .RC stack overflow (ignored)
  errors.gml:33: error: .rc *: one revision character expected, not ab
  errors.gml:34: error: .rc align: LEFT, RIGHT, INSIDE, OUTSIDE or OUTCOL expected, not up
  errors.gml:35: error: .rc align: LEFT, RIGHT, INSIDE, OUTSIDE or OUTCOL expected, not left right
  errors.gml:36: error: .rc adjust: invalid revision code field width -1
  errors.gml:37: error: .rc adjust: unexpected operands 3
  errors.gml:38: error: .rc adjust: invalid space unit x
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:rc state="on" code="1" char="x" break="no"/><gml:rc state="on" code="2" char="y" break="no"/><gml:rc state="on" code="1" char="x" break="no"/><gml:rc state="off" break="no"/><gml:rc state="on" code="5" char=" " break="no"/><gml:rc state="off" break="no"/><gml:rc state="on" code="1" char="x" break="no"/><gml:rc state="on" code="2" char="y" break="no"/><gml:rc state="on" code="1" char="x" break="no"/><gml:rc state="on" code="2" char="y" break="no"/><gml:rc state="on" code="1" char="x" break="no"/><gml:rc state="on" code="2" char="y" break="no"/><gml:rc state="on" code="1" char="x" break="no"/><gml:rc state="on" code="2" char="y" break="no"/><gml:rc state="on" code="3" char="z" break="no"/></gml:doc>
  [8]
