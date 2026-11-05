Macro arguments (SH35-0069 p.253, p.275-276): &* is the line after the
blank that ends the macro name, leading blanks kept; &*0 is the number of
tokens, &*1... the tokens.  Tokens are delimited by blanks, arithmetic
operators and parentheses, which are tokens themselves; a single-quoted
string is one token ('' inside is a quote); % is a null token.  There
are no keyword arguments.  The call line is substituted before the call;
the separator ends it.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">all=[a b c] n=3
  1=[a] 2=[b] 3=[c]
  all=[] n=0
  1=[] 2=[] 3=[]
  all=[one 'two words' three] n=3
  1=[one] 2=[two words] 3=[three]
  all=['it''s' x] n=2
  1=[it's] 2=[x] 3=[]
  all=[1+2 (x)] n=6
  1=[1] 2=[+] 3=[2]
  all=[a % b] n=3
  1=[a] 2=[] 3=[b]
  all=[color=red] n=1
  1=[color=red] 2=[] 3=[]
  all=[42 42x] n=2
  1=[42] 2=[42x] 3=[]
  all=[a] n=1
  1=[a] 2=[] 3=[]
  after the call
  all=[  spaced] n=1
  1=[spaced] 2=[] 3=[]
  line=27
  </gml:doc>
