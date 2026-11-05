Attribute functions (SH35-0069 p.235-239): &E' &L' &U' &W' &T' &V', the
base-26 &A'/&a', the roman &R'/&r' and the hexadecimal &X'.  The operand
is the symbol or string up to the next period or blank.  &L' of an
undefined symbol is the length of its name as written; a character
string has no value (&V' is null, &E' is 0); &T' is N or C.  &DH' &DV'
&AD' &SW' &SD' need an output device: 0, with one warning each.  A name
followed by a quote is neither a reference nor an attribute (p.232).

  $ gml in.gml
  in.gml:14: warning: &DH' has no meaning without an output device; 0 is used
  in.gml:14: warning: &SD' has no meaning without an output device; 0 is used
  in.gml:14: warning: &SW' has no meaning without an output device; 0 is used
  in.gml:14: warning: &AD' has no meaning without an output device; 0 is used
  in.gml:14: warning: &DV' has no meaning without an output device; 0 is used
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">E: 1 0 1 0
  L: 5 7 0 7
  U: HELLO HELLO!
  W: 5
  T: C N C N C
  V: [42] [-7] [Hello] []
  A: B Z AA AB AAC ab CRXO 0 0
  R: LXXXVII lxxxvii MCMLXXXVI MMMCMXCIX ?MXX M?XX 0 0
  X: [ABC] [0] [0] DATA--TRANSFORM
  Device: 0 0 0 0 0 0
  Not attributes: &amp;q's &amp;s'Hello
  </gml:doc>
  [4]
