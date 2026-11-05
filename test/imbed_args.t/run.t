.im/.ap parameters (SH35-0069 p.252-253): the global symbols &0 (their
number) and &1 to &14, tokenized like macro parameters ('18-7' is one
token).  An imbed without parameters leaves them alone; unused ones are
dropped.  There is one set of locals for everything that is not a macro
(p.276), so the imbedded file sees the imbedding file's locals.  A file-id
in parentheses is the real file name (p.50).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">part: n=4 1=[George] 2=[125] 3=[$21.50] 4=[18-7] 5=[&amp;5.] mine=main local
  after: 4 parameters, George ... 18-7, mine=main local
  part: n=4 1=[George] 2=[125] 3=[$21.50] 4=[18-7] 5=[&amp;5.] mine=main local
  part: n=1 1=[last] 2=[&amp;2.] 3=[&amp;3.] 4=[&amp;4.] 5=[&amp;5.] mine=main local
  </gml:doc>
