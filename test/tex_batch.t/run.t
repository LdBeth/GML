gml -tex writes the document as TeX for share/tex/gml.tex in hint mode
(lib/be_tex.ml, the OCaml port of xslt/tex.xsl for a formatting
profile): \def\gmlmode{hints}, the hints with their parsed .df/.dh/.dr
keys, words of an upper-case font (.df ... up) wrapped in \gmlupword,
.us words in \gmlusword, line scopes split by an element (more=yes on
all but the last piece), TeX specials and non-ASCII as \gmlchar, tab
lines, format-off text kept line by line with its blanks, and running
titles holding the page number symbol as \gmlrundyn (typeset at every
page).  In running title text the page number symbol is the hint
gml:pageno, split off before .tr translation, so &amp. (X'08 translated
to "&") stays a text ampersand (SH35-0069 p.234, p.259); in the fields
of a .sx there it is \gmlpageno, the other characters (translated) are
text, so \& is always an ampersand.  With -tex no
XML is written unless -o is given.

  $ gml -tex - in.gml
  \def\gmlmode{hints}
  \input gml
  \gmlbegindocument%
  \gmlhint{df}{name=bold,spec=font BOLD,break=no,font=bold}\gmlhint{df}{name=caps,spec=font BOLD up,break=no,up=yes,font=bold}\gmlhint{df}{name=face,spec=type('Helvetica Bold' 12 bold),break=no,face=helvetica bold,family=sans,size=12,bold=yes}\gmlhint{dr}{spec=thin weight 0.2mm,break=no,rule=thin,weight=0.2mm}\gmlhint{dh}{level=1,spec=font caps spaf 2 nbr,break=no,font=caps,spaf=2line,runin=yes}Plain text, then a skip.
  \gmlhint{sp}{n=2,unit=line,break=yes}%
  \gmlhint{bf}{font=caps,break=no}\gmlupword{upper} \gmlupword{case} \gmlupword{words} \gmlupword{here}
  \gmlhint{pf}{initial=yes,break=no}back to normal.
  \gmlstart{gml:h}{level=1,break=yes,text=A Heading}%
  \gmlhint{tcmark}{anchor=gml.tc.1,break=no}\gmlupword{A} \gmlupword{Heading}\gmlend{gml:h}%
  
  Text after the heading.
  \gmlbeginlines{ce}{n=2,break=yes,more=yes}before \gmlendlines{}\gmlstart{hp1}{}\gmlbeginlines{ce}{cont=yes,more=yes}a phrase\gmlendlines{}\gmlend{hp1}\gmlbeginlines{ce}{cont=yes} after
  and a second line\gmlendlines{}
  \gmlbeginlines{us}{n=on,break=no}\gmlusword{under} \gmlusword{scored}
  \gmlendlines{}Specials: \$ \& \# \% \gmlchar{123} \gmlchar{125} \gmlchar{92} \gmlchar{94} \gmlchar{95} \gmlchar{126} \gmlchar{60} \gmlchar{62} \gmlchar{124} \gmlchar{34} -{}- -{}-{}- caf\gmlchar{233}
  \gmltabline{Tab\gmltab separated\gmltab line}
  \gmlhint{fo}{fill=no,align=left,overdraw=extend,break=yes}%
  \ \ preformatted\ \ \ text
  
  \ \ after\ a\ blank\ line
  \gmlhint{fo}{fill=yes,align=justify,overdraw=extend,break=yes}%
  \gmlstart{gml:rf}{}%
  \gmlrundyn{\gmlhint{sx}{left=Left \& Right,fill=,right=Page \gmlpageno{},pagesym=\gmlchar{57344},break=yes}%
  }\gmlend{gml:rf}%
  \gmlstart{gml:rh}{}%
  \gmlrundyn{Page \gmlhint{pageno}{break=no} of the heading; \& is a text ampersand
  }\gmlend{gml:rh}%
  %
  \gmlenddocument
  \bye

&$PN and &$LC are the neutral constants, 1 and 60 (Ctx.page_query, the
hook for a planned pass model with an aux file written by TeX).

  $ printf '.se x = &$PN\n.se y = &$LC\n.se z = &\n&x &y &z\n' > c.gml
  $ gml -tex - c.gml | grep '^1'
  1 60 1
