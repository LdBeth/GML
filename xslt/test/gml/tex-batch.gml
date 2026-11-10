.* hints, definitions with parsed keys, upper-case fonts
.df bold font BOLD
.df caps font BOLD up
.df face type('Helvetica Bold' 12 bold)
.dr thin weight 0.2mm
.dh 1 font caps spaf 2 nbr
Plain text, then a skip.
.sp 2
.bf caps
upper case words here
.pf
back to normal.
.h1 A Heading
Text after the heading.
.* line scopes: .ce with an element inside (a continuation), .us
.gs tag on
.dm hp1 /.*
.dm ehp1 /.*
.aa hp1 hp1 ehp1
.ce 2
before :hp1.a phrase::hp1. after
and a second line
.us on
under scored
.us off
.* escaping, tab lines, format off
Specials: $ & # % { } \ ^ _ ~ < > | " -- --- caf&X'51.
Tab	separated	line
.fo off
  preformatted   text

  after a blank line
.fo on
.* a running footing with the page number symbol and a text ampersand
.* (translated with the table of the definition, LR p.404 r4)
.se amp = &X'08
.tr 08 &
.rf on
.tr 08 &
.sx /Left &amp. Right//Page &/
.rf off
.rh on
.tr 08 &
Page & of the heading; &amp. is a text ampersand
.rh off
