The control word separator examples of SH35-0069 p.40-44 and the extended
symbol rule of p.257-258, verbatim.  The blank after a two-character
control word name is optional (.cecenter = .ce center).  A control word
line is split at each separator; a text line only where the separator is
followed by a control word, and the text before it is continued without a
word space ("an underscored word.").  The .' modifier keeps the separators
of its own line only: after the extended symbol rule split
".'ce Note this; The symbol &BR starts ..." in three, the third part is
split again.  ". 'ce" (with a blank, as OCR has it) is a text line.  The
formatting words (.ce .sk .fo .in .us .br) give hints and gml:lines
scopes, which show how the lines were split.

  $ gml in.gml
  doc3 would be imbedded
  Note this
  Note this; The symbol 
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:lines word="ce" n="1" break="yes">center this line</gml:lines>
  <gml:sk n="1" unit="line" break="yes"/><gml:lines word="ce" n="on" break="yes"><gml:sk n="0.5" unit="i" break="yes"/><gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/><gml:in left="10" unit="mh" break="yes"/>an <gml:lines word="us" n="on" break="no">underscored</gml:lines> word.
  a separator; not followed by a control word; is text
  . 'ce Center this line.
  </gml:lines><gml:lines word="ce" n="1" break="yes">centered line; one line.</gml:lines>
  This is line one.
  <gml:br break="yes"/>This is line two.
  <gml:br break="yes"/><gml:lines word="ce" n="1" break="yes">Note this</gml:lines>
   The symbol 
  <gml:br break="yes"/> starts with a semicolon.
  <gml:lines word="ce" n="1" break="yes">Note this; The symbol </gml:lines>
  <gml:br break="yes"/> starts with a semicolon.
   The symbol 
  <gml:br break="yes"/> starts with a semicolon.
  <gml:br break="yes"/> starts with a semicolon.
  </gml:doc>
