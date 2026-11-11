What gml.tex shares with the engine (share/tex/gml-shared.tex, made by
gmlshare from lib/shared.ml; test/shared.t shows it), and what cannot
be shared as data: the TeX that uses it.

  $ export TEXINPUTS=../../share/tex:
  $ alias gmlshare=../../bin/gmlshare.exe
  $ gmlshare xml -o shared.xml

The file TeX reads is the one gmlshare makes (the promoted copy is
current):

  $ gmlshare tex | cmp - ../../share/tex/gml-shared.tex && echo current
  current

gml.tex has every hint of the engine, or lists it as not implemented
or as never a hint in TeX (\gmlcheckshared):

  $ tex -interaction nonstopmode check.tex | grep '^GML:'
  GML: shared: ok

The name encoding of the aux file: \gml@enc on the t:name form of each
test vector of the engine (Aux.tex_name, Aux.enc), and the symbols of
an anchor and a question (Aux.anchor_name, Aux.query_name) as gml.tex
makes them:

  $ sed -n 's/.*<vector plain="[^"]*" tex="\([^"]*\)" enc="\([^"]*\)".*/\\vec{\1}{\2}/p' shared.xml > vectors.tex
  $ sed -n 's/.*<symbol role="\([a-z]*\)" plain="\([^"]*\)" value="\([^"]*\)".*/\\sym{\1}{\2}{\3}/p' shared.xml >> vectors.tex
  $ tex -interaction batchmode enc.tex > /dev/null
  $ cat enc.out
  17 names, 0 wrong

The aux file: a line for each prefix of the engine, all for the same
key, is read as the anchor's and the auto reference's and no other
(\gml@auxname compares three characters); the new file starts with the
engine's first line, and the anchors and the question are written
under the engine's symbol names:

  $ sed -n "s/.*<prefix role=\"\([a-z]*\)\" value=\"\([^\"]*\)\".*/.se \2x@1 = '\1'/p" shared.xml > aux.gmlaux
  $ cat aux.gmlaux
  .se pa@x@1 = 'anchor'
  .se pq@x@1 = 'query'
  .se pr@x@1 = 'pageref'
  .se px@x@1 = 'tagset'
  $ tex -interaction batchmode aux.tex > /dev/null
  $ cat aux.out
  pg@x@1: anchor
  rpg@x@1: pageref
  $ sed -n 's/.*<header file="aux" value="\([^"]*\)".*/\1/p' shared.xml > header
  $ head -1 aux.gmlaux | cmp - header && echo same header
  same header
  $ for v in $(sed -n 's/.*<symbol role="[a-z]*" plain="[^"]*" value="\([^"]*\)".*/\1/p' shared.xml)
  > do grep -q "^\.se $v = " aux.gmlaux && echo "$v written"
  > done
  pq@1@12@3 written
  pa@gml@tc@1 written
  pa@fig#2D1 written

The units in sp (1in is 4736286sp in TeX): the engine's Didot point is
37/2500in (a cicero 0.1776in, 841164.5sp exactly; TeX's 0.1776in
rounds the decimal first), a device unit 1/240in; p and c are the
compound forms (3p6: 42 points, 2c4: 28 Didot points), m is mh:

  $ tex -interaction batchmode units.tex > /dev/null
  $ cat units.out
  1i = 4736286sp
  1cm = 1864679sp
  1mm = 186467sp
  72pt = 4736286sp
  240dh = 4736286sp
  240dv = 4736286sp
  12dd = 841164sp
  -1.5dd = -105145sp
  TeX 1in = 4736286sp
  TeX 0.1776in = 841150sp
  TeX 1cm = 1864679sp
  TeX 42bp = 2762833sp
  3p6 = 2762830sp
  2c4 = 1962716sp
  120dh = 2368143sp
  2m = 2mh: yes
