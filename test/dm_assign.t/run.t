.dm name x and .dm name(n) x (LR p.143): x, one alphanumeric character
alone, is the symbol &x that gets the current value of the macro or of
its line n (null if there is no such line).  The whole macro is its
lines joined by the control word separator (DCF-VERIFY: the manual says
only "the current value"), so on a control word line the value runs the
lines again: .ty [&z.] types two lines.  Two or more characters are a
delimiter and a line (.dm m ab: the line "b").  An undefined macro is an
error.

  $ gml in.gml > /dev/null
  [.ty one
  two]
  [.ty two]
  []
  [b]
  in.gml:11: error: .dm nosuch q: macro nosuch is not defined
  [8]
