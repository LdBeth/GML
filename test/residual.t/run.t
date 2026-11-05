Residual text (SH35-0050 p.7): up to the next tag or the end of the
line, the next line when the markup ends a line; it is literal.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><h1>[h1 residual=(The )]
  The <hp1>[hp1 residual=(starter set)]
  starter set</hp1>[ehp1 residual=( Profile)]
   Profile
  </h1><titlep>[titlep]
  <title>[title residual=(First Line)]
  First Line
  of the Title
  </title></titlep><hp1>[hp1 residual=(.sp 3)]
  .sp 3</hp1>[ehp1 residual=()]
  
  <hp1>[hp1 residual=(  indented)]
    indented</hp1>[ehp1 residual=()]
  
  </gml:doc>
