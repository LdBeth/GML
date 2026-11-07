Layout mode streams the TeX to the layout engine while the document is
built: each query (&$PN, &$LC) sends what is known so far, in whole
lines.  -layout-fake is the layout driver with a fake engine (pn = 1 +
lines/50, lc = 50 - lines mod 50 of the TeX source so far), and -tex
keeps the source as sent, with a comment line after each answer.
Apart from those lines it is the batch output (gml -tex): queries in
open provisional elements, line scopes, footnotes, between growing text
lines, before a .ct continuation, in format-off text.

  $ gml -tex batch.tex in.gml
  $ gml -layout-fake -tex fake.tex in.gml
  $ grep -c '^%gml:query' fake.tex
  19
  $ grep -v '^%gml:query' fake.tex | diff batch.tex -
  $ grep -n '^%gml:query' fake.tex | head -5
  4:%gml:query pn=1
  7:%gml:query lc=48
  9:%gml:query lc=47
  12:%gml:query lc=45
  14:%gml:query lc=44

The one known difference: a line scope that a query sends before an
element splits it goes without more=yes; \gmllinesmore (gml-layout.tex)
before its \gmlendlines gives it afterwards.

  $ gml -tex batch.tex patch.gml
  $ gml -layout-fake -tex fake.tex patch.gml
  $ grep -v '^%gml:query' fake.tex | diff batch.tex -
  4,5c4,5
  < \gmlbeginlines{ce}{n=2,break=yes,more=yes}Centered one
  < before \gmlendlines{}\gmlstart{hp1}{}\gmlbeginlines{ce}{cont=yes,more=yes}a phrase\gmlendlines{}\gmlend{hp1}\gmlbeginlines{ce}{cont=yes} after\gmlendlines{}
  ---
  > \gmlbeginlines{ce}{n=2,break=yes}Centered one
  > before \gmllinesmore \gmlendlines{}\gmlstart{hp1}{}\gmlbeginlines{ce}{cont=yes,more=yes}a phrase\gmlendlines{}\gmlend{hp1}\gmlbeginlines{ce}{cont=yes} after\gmlendlines{}
  [1]

Without layout mode &$PN and &$LC are the neutral constants, 1 and 60.

  $ printf '.se x = &$PN\n.se y = &$LC\n&x &y\n' > c.gml
  $ gml -tex - c.gml | grep '^1'
  1 60
