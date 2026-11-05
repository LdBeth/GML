The macro examples of SH35-0069 chapter 23 (p.271-280) and the BURGER
tokens of p.253.  Formatting control words of the examples (.sk, .in,
.hr, .kp, .il, .sx, .mg) are shown with .ty; the formatted text of a
symbol is ended by a period where the example puts a special character
right after it (p.232).  The real .sk words give hints.  Each subscripted example starts from a deleted
macro (.dm name off) since the manual gives them as alternatives.
- p.271: .se x = &x + 1;.se y = &x increments only x, the INCREMENT
- p.272-273: PARA and ECHO in the single-line, inline and subscripted
- p.274: COUNT, the .OF macro substituted at each call, CANBE with .or;
- p.253, p.275-276: tokens (blanks, operators and parentheses delimit,
- p.276: the &*&*i token loop; p.277: .me, .me .se *rc = 4 setting the
- p.278-279: .sk redefined with .ec, .ec .sk / .'sk run the control word,
- p.279-280: FIGNUM/FIGREF (.se x = & is the page number, 1 here) and the

  $ gml in.gml
  x=2 y=1
  x=3 y=3
  sk 
  in 3 for 2 
  On second thought,
  ---
  inline form
  ---
  sk
  in 3 for 2
  subscripted
  sk
  in 5 for 1
  kp 6
  modified
  ===
  with the modifier
  ===
  --
  numbered by 10
  --
  4
  5
  sk
  in 7 after 1
  sk
  in 9 after 1
  (pg$sym imbedded)
  5: fries|+|shake|nosauce|on a great big poppy-seed bun|
  * is fileb 10 filea no| 0 is 4, 1-5 are fileb|10|filea|no|||
  * is filea 10 % fileb 15| 0 is 5, 1-5 are filea|10||fileb|15||
  processing one
  processing two
  processing three
  sk 1
  sk 1
  hr left to right
  sk 1
  caller's *rc=4
  the file's *rc=4
  read
  write
  close
  CASE index error.
  sk 3
  il 5
  sk 3
  il 5
  Imbedding pg$sym ...
  (pg$sym imbedded)
  sx /Figure 1/ /1/
  sx /Figure 2/ /1/
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:sk n="4" unit="line" break="yes"/><gml:sk n="4" unit="line" break="yes"/>Figure 1
  Example of Aardvark's Table Manners
  ... as shown in
  Figure 1 on page 1
  Figure 1
  Figure 2
  </gml:doc>
