.im: name as-is, implicit .gml extension, subdirectory, -I search path,
missing file.

  $ gml -I incdir in.gml
  in.gml:5: error: .im: file nosuch not found
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">before
  part text
  after part, same line
  deep text
  from -I
  after
  </gml:doc>
  [8]

Without -I the file is not found:

  $ gml in.gml > /dev/null
  in.gml:4: error: .im: file inc not found
  in.gml:5: error: .im: file nosuch not found
  [8]

Imbed nesting is limited:

  $ gml loop.gml | grep -c self
  loop.gml:2: error: .im: imbed nesting deeper than 64; .im loop ignored
  64
