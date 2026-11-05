The implicit control words of SH35-0069 p.281: natively a leading blank
(.lb) or a leading tab (.lt) gives a break and the line is text with the
blank or tab; .dm lb /.* and .dm lt /.* make them ordinary characters
(the line is still processed as text after the macro); macros named nl
and bl are invoked for a null and a blank line, with the line as &*; a
macro lb receives the line as &*.  With .ms off the native functions
come back.  A native null line adds nothing.

  $ gml in.gml
  null line seen ()
  blank line seen (   )
  leading blank line:   after
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">First line
  <gml:br break="yes"/>  leading blank: a break
  <gml:br break="yes"/>	leading tab: a break
  Now
    the blank is an ordinary one
  	and so is the tab
  before
    after
  <gml:br break="yes"/>  native again
  </gml:doc>
