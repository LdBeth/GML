.im/.ap parameters (LR p.68, p.208-209): the global symbols &0 and &1
to &14, tokenized like macro parameters ('18-7' is one token).  Every
.im/.ap resets &1 to &14 and sets &0 to the number of non-null tokens,
even 0; % leaves its token unset; a token is cut to 8 characters; more
than 16 tokens on the line (two fewer for a file name in parentheses)
are warned about.  There is one set of locals for everything that is
not a macro (SH35-0069 p.276), so the imbedded file sees the imbedding
file's locals.  A file-id in parentheses is the real file name (p.50).

  $ gml in.gml
  in.gml:6: warning: .im: token abcdefghij longer than 8 characters; truncated
  in.gml:7: warning: .im: more than 16 tokens on the line; the rest are ignored
  in.gml:8: warning: .im: more than 16 tokens on the line; the rest are ignored
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">part: n=4 1=[George] 2=[125] 3=[$21.50] 4=[18-7] 5=[&amp;5.] mine=main local
  after: 4 parameters, George ... 18-7, mine=main local
  part: n=0 1=[&amp;1.] 2=[&amp;2.] 3=[&amp;3.] 4=[&amp;4.] 5=[&amp;5.] mine=main local
  part: n=1 1=[&amp;1.] 2=[second] 3=[&amp;3.] 4=[&amp;4.] 5=[&amp;5.] mine=main local
  part: n=1 1=[abcdefgh] 2=[&amp;2.] 3=[&amp;3.] 4=[&amp;4.] 5=[&amp;5.] mine=main local
  part: n=14 1=[1] 2=[2] 3=[3] 4=[4] 5=[5] mine=main local
  part: n=12 1=[1] 2=[2] 3=[3] 4=[4] 5=[5] mine=main local
  part: n=1 1=[last] 2=[&amp;2.] 3=[&amp;3.] 4=[&amp;4.] 5=[&amp;5.] mine=main local
  </gml:doc>
  [4]
