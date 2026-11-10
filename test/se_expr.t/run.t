.se: integer arithmetic, strictly from left to right with no operator
taking precedence (1 + 2 * 4 + 6 is 18, LR p.340 r8), operators + - * /
only and no parentheses (p.339), a sign only before the first number
(5+-3 is invalid, p.341 r12), no blanks needed around an operator
(p.340 r10); character values, null value, substr and index with their
operands omitted (p.337-338; the rest of the line after index's second
string is ignored, p.339), an unquoted string of more than 16
characters is an error (p.341 r14), bad expressions (the symbol is not
set).  A value with blanks must be in quotes (p.338): warned about, and
taken as written.  A single number is kept as written (.se 3z = 00,
SH35-0069 p.269), an arithmetic result loses its leading zeros.  (.se t
= (1 + 2) * 3 is a character value with blanks, so it sets t: the
"Unchanged" line shows it.)  The qstring form (.se name 'string) takes
the rest of the line as written, quotes not doubled (a doubled quote is
still one, read left to right: DSMPROF3's @oquote), less one closing
quote (LR p.338: 'Mrs. O'Grady's Cat'); a value without = or a quote is
not in the syntax (LR p.337) and is warned about.

  $ gml in.gml
  in.gml:12: warning: .se s2: a value with blanks must be in quotes
  in.gml:13: warning: .se s3: a value with blanks must be in quotes
  in.gml:15: warning: .se s5: = or a quoted value expected
  in.gml:25: error: .se t: bad expression '1 +': operand expected
  in.gml:26: error: .se t: bad expression '5+-3': a sign is allowed only before the first number
  in.gml:27: error: .se t: bad expression '7 // 3': operand expected before /
  in.gml:28: warning: .se t: a value with blanks must be in quotes
  in.gml:29: error: .se t: bad expression '1 / 0': division by zero
  in.gml:30: error: .se t: bad expression '1 2 + 3': operator expected
  in.gml:31: error: .se t: bad expression '* 3': operand expected before *
  in.gml:32: error: .se t: abcdefghijklmnopq: an unquoted string has at most 16 characters (put it in quotes)
  in.gml:33: error: .se t: 123456789123456789: an unquoted string has at most 16 characters (put it in quotes)
  in.gml:34: error: .se: symbol name expected
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">a=18 b=7 c=3 d=-3 e=-1 f=4 g=007 h=8 i=12
  [quoted string] [abc def] [it is 18] [no equals sign] [plain words] [] [2010] [abcdefghijklmnop] [whole string] [0] [0]
  Incremented: 19
  Unchanged: (1 + 2) * 3
  [Mrs. O'Grady's Cat] [trailing blanks kept  ] [Mrs. O'Grady's Cat]
  [&quot;'&quot;'&quot;']
  </gml:doc>
  [8]
