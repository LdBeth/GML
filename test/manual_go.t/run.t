.go and labels, SH35-0069 p.264-265: in a macro "the search for labels
always begins at the top of the macro", so with a label written twice
.go always reaches the first one; in a file the search goes forward from
the .go, then wraps to the top of the file.

  $ gml in.gml
  first here (n=0)
  second here
  first here (n=1)
  first there
  second there (k=1)
  first there
  second there (k=2)
  done
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
