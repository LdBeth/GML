Control inside macros: .me (with an operand; outside a macro, LR p.245),
.go loops, .if/.th/.el and the long forms .then/.else (LR p.395, p.164),
recursion, .ef in a macro ends the calling file.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">before me
  not reached when stopped
  before me
  after me stop
  count 1
  count 2
  count 3
  one
  (then)
  not one
  (else)
  down 3
  down 2
  down 1
  bottom
  up 1
  up 2
  up 3
  sub before
  quitting
  back in main
  outside a macro the line is processed
  </gml:doc>
