System symbols (SH35-0069 p.240-251): the &$ ones are computed and
read-only, in either case; &$GML &$EGML &$CW &$CONT come from .dc, &$ENV
is BODY (no keeps or footnotes), &$LNUM the line number.  The date and
time symbols (LR p.443, Table 17): &$YEAR, the year in 4 digits, is a
system symbol; &SYSYEAR ... &SYSSECOND are ordinary global symbols,
upper case, zero-padded, set once (&SYSDAYOFW 1 is Sunday); .se
SYSDAYOFM = &SYSDAYOFM + 0 drops the zero; the compound date of
SH35-0069 p.247.  There is no &$DATE or &$TIME in DCF.  SOURCE_DATE_EPOCH fixes the clock
(UTC): 1700000000 is Tuesday, 14 November 2023, 22:13:20.

  $ SOURCE_DATE_EPOCH=1700000000 gml in.gml
  line 2
  in.gml:11: error: .se: system symbol &$LINE is read-only
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Line 1 of in.gml
  Separator [;] page 1 ret 0
  Separator now [#]
  Separator off []
  Split here [
  ] by the extended symbol rule (p.257)
  Year 2023, not &amp;$DATE or &amp;$TIME
  User dollar symbol: ok
  GML [:] [::] env BODY su ON lnum 14
  Continuation [+]
  DATE: 11/14/23
  TIME: 22:13:20
  Day of week 3, of year 318, lower case &amp;sysyear
  Tuesday, November 14, 2023.
  </gml:doc>
  [8]
