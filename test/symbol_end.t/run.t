Where a symbol reference ends (SH35-0069 p.232; SH20-9161-3 "How
SCRIPT/VS substitutes"): at a blank, at a period (removed) or at the
end of the line; after any other character it is not a reference at all
("&prodname," is not substituted).  The control word separator is no
exception: substitution comes before the separator scan (p.258), so
"&t;.br" leaves &t as written, and "&t.;.br" is the way to write it
(IBM's macros do the same, e.g. DSMLISTM's ".dm @termhi /.se @hi@l =
&*1/", whose &*1 must not be substituted when the line is read).

An attribute applies to the symbol or string after it "up to the next
delimiter (period or blank)" (p.238).  In "&E'&fh&*k." the period ends
&*k, so the operand of &E' is the string "&fhAB]" up to the next blank,
the bracket included: write "&*k.." to end both.

&$TAG is the name of the last tag, &$TAGD its delimiter, &$GML or
&$EGML (p.251): for :efig with ".dc gml : : e" (end-tag delimiter
":e") that is "fig" and ":e".

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[1] [0 [1]
  &amp;t<gml:br break="yes"/>TEXT<gml:br break="yes"/>after
  <fig>[fig start ]
  </fig>[fig end (2 characters) ]
  </gml:doc>
