A tag with no end tag (its .aa names no end APF, there is no eNAME
macro) and no .xd model gives a provisional element: nothing would
close it, so if it is closed by anything but its own end tag (an
enclosing end tag, the end of the input) it is left empty, a marker,
and what came after it follows it.  An end tag that does close it
keeps its content inside, as before (DCF-VERIFY; IBM's profile has no
models, and its :p, :li, :dt, :figref ... no end tags).  An end tag
with an APF closes its element after the APF when a .fn/.rh/.rf flow
is open inside it, since the APF ends the flow (IBM's :efn).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p/><gml:br break="yes"/>A paragraph with a <ref/>[ref]
   in it.
  <p/><gml:br break="yes"/>Second paragraph.
  <dl><gml:sp n="1" unit="line" break="yes"/><term/><gml:br break="yes"/>One
  <term/><gml:br break="yes"/>Two
  </dl><gml:sp n="1" unit="line" break="yes"/><wrap>wrapped text</wrap>
  After.
  <note><gml:fn>A note in a footnote flow</gml:fn></note>
  Done.
  </gml:doc>
