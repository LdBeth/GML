Index counter (SH35-0069 p.256-257): element 0, &x(0) = &x, says which
element .se x() = v sets next.  A null value counts as 0, so the append
makes element 1 (the Starter Set nulls title arrays with .gs vars and
then appends; DCF-VERIFY).  A value that is not a number is an error
(p.257).

  $ gml in.gml
  in.gml:19: error: .se: index counter &n is not a number
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[one, two] counter 2
  [alpha, beta] counter 2
  [c, d] counter 4
  [abc]
  </gml:doc>
  [8]
