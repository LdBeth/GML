The memo tag set (share/gmlapp/memo/profile.gml: the memo application
of G544-3305 ch.2, for mail).  The tags before :memotxt only collect:
empty elements (logo to from cc bcc attach) and one-line ones (memodate
security subject ref; the text on the tag's line, or on the next one,
as :subject's here).  :memotxt holds the text and ends at :sign (or :cc
:bcc :attach), which also end the structures open in it (a :ul left
open gets DSM#RSET's DSMGML003W).

  $ gml -profile ../../share/gmlapp/memo/profile.gml in.gml
  in.gml:13 (in macro ss@msg line 25, in macro dsm#rset line 1, in macro mm@end line 1): +++DSMGML003W UL PREMATURELY ENDED BY :SIGN TAG. (page 1)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><logo logoname="logo.png"/><security>Internal Use Only</security>
  <memodate>1 June 2026</memodate>
  <to name="A. Smith" email="as@example.com" addr1="Dept. 7"/><from name="B. Jones" title="Analyst" phone="555 0100"/><subject>Budget <gml:dv name="amp" text="&amp;" break="no"/> staffing review</subject>
  <ref>Your note of 28 May</ref>
  <memotxt memtype="internal"><p>The figures are
  </p><ul><li>ready
  </li></ul></memotxt><sign/><cc name="C. Lee"/><bcc email="d@example.com"/><attach name="budget.pdf"/></gml:doc>
  [4]

MEMTYPE: INTERNAL (the default) or EXTERNAL, as little as the first
letter, in either case (G544-3305 p.8).

  $ for f in mt-i mt-e mt-ext; do gml -profile ../../share/gmlapp/memo/profile.gml $f.gml | grep -o '<memotxt[^>]*>'; done
  <memotxt memtype="internal">
  <memotxt memtype="external">
  <memotxt memtype="external">

Any other value: DSMGML015W, and the default.

  $ gml -profile ../../share/gmlapp/memo/profile.gml mt-bad.gml
  mt-bad.gml:1 (in macro ss@msg line 73, in macro mm@mtxt line 19): +++DSMGML015W letter NOT A VALID VALUE FOR MEMTYPE ATTRIBUTE OF :MEMOTXT TAG. (page 1)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><memotxt memtype="internal"><p>four
  </p></memotxt></gml:doc>
  [4]

A second :memotxt: DSMGML038W, and the tag is ignored (the text goes on
in the first).

  $ gml -profile ../../share/gmlapp/memo/profile.gml twice.gml
  twice.gml:3 (in macro mm@mtxt line 3): +++DSMGML038W :MEMOTXT TAG FOUND OUT OF SEQUENCE. (page 1)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><memotxt memtype="internal"><p>first
  </p><p>second
  </p></memotxt></gml:doc>
  [4]

&amp. in an attribute value is a plain & (in running text it is a text
variable, a gml:dv hint: :subject above), in name= and in a :link
address alike.

  $ gml -profile ../../share/gmlapp/memo/profile.gml amp.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><to name="Smith &amp; Sons" email="orders@example.com"/><link href="https://example.com/?a=1&amp;b=2">Order form</link>
  </gml:doc>

Text before :memotxt is outside the memo's text: :memotxt ends the
paragraph it would otherwise sit in.

  $ gml -profile ../../share/gmlapp/memo/profile.gml before.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><p>Before the text.
  </p><memotxt memtype="internal"><p>The text.
  </p></memotxt></gml:doc>
