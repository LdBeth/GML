The .se examples of SH35-0069 p.230-235 and p.241, verbatim: numbers,
strings with the closing quote optional and double quotes kept, case
(&text1 and &TEXT1 are two symbols), arithmetic with leading zeros
removed, SUBSTR and INDEX (with .su off, the &corp operand keeps its
blanks), OFF and the null value; then the keyword validation of
SH35-0050 p.14 (Figure 3), run for three values of SYSVAR D.  (The OCR
of p.232 mixes '_' and '-' in the INDEX example; we use '_'.)

  $ gml -set SYSVARC=2 -set SYSVARD=Duplex in.gml
  prepared on a "word processing" machine
  prepared on a "word processing" machine
  25 1 / IBM 1403 Printer / IBM 1403 printer / .br / IBM 1403 Printer
  2 26 24 12 10 500 -25
  Script
  than
  3
  x=3
  cols=2
  &oldsymbol
  []
  8
  SYSVARD=yes
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
  $ gml -set SYSVARC=4 -set SYSVARD=simplex in.gml 2>&1 | grep -E "invalid|cols|SYSVARD"
  SYSVAR C invalid.
  in.gml:36: error: .se cols: substr: the start must be at least 1
  cols=&cols
  SYSVARD=no
  $ gml -set SYSVARC=1 -set SYSVARD=maybe in.gml 2>&1 | grep -E "invalid|cols|SYSVARD"
  cols=1
  SYSVARD=no 
