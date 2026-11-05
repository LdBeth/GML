Local symbols: each call has its own scope (the caller's locals and
arguments are not visible inside, the callee's are gone after the
call); globals set inside are visible after.  In a macro an undefined
local is null; outside macros (one more set of locals, SH35-0069 p.276)
it is left as written.  "from-outer" is three tokens (p.253).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">inner sees 1=from top= loc= g=2
  outer after call loc=outer local 1=from g=3
  after: loc=&amp;*loc top=top level g=3 1=&amp;*1
  </gml:doc>
