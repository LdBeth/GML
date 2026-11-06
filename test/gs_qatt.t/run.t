.gs qatt sym name ... (SH20-9161-3 p.266): the attributes of the list
that are not on the attribute stack become the elements of sym, in
order; when all are present sym is undefined (IBM's DSMFTNT tests
&E'&*q after ".gs qatt *q id").

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Missing 1: refid
  Missing 1: id
  Missing 2: id, refid
  All present.
  </gml:doc>
