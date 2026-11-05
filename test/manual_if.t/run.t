The .if family examples of SH35-0069 p.264-267: .th/.el use the most
recent comparison in the current file or macro, preserved across macro
calls and imbeds (p.265; formatting words of the manual's example are
shown with .ty); .an/.or; a null comparand and the prefix technique
(p.266); with .su on, symbols holding blanks break a comparison, with
.su off each comparand is substituted on its own (p.267; the manual does not show how &needle is set, we use
'Rachel MG' to keep the blank).

  $ gml in.gml
  branch=Commercial
  branch=Warehouse
  sp 2
  sp 2
  salary for clerk
  sp 4
  zip=72701
  carpool for Warrensburg
  in.gml:44: error: .if: invalid comparison operator ON
  not skipped
  in.gml:55: error: .if: invalid comparison operator MG
  not lost
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
  [8]
