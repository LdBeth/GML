.do begin / .do end groups: a false condition whose object is .do begin
skips the whole group, tracking nested groups (also through the
separator); nothing inside a skipped group is executed.  .do end restores
the condition state, so .el after a group refers to the .if that opened
it.

  $ gml in.gml
  after group (separator remainder after .do end)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">group one line 1
  group one line 2
  else group runs, a=1
  inner else after inner group
  plain group
  th group
  </gml:doc>
