The symbol examples of SH35-0069 chapter 21, verbatim (the OCR blank in
"&printer .." is removed): termination by blank or period (p.229, p.232),
"&prodname," and "&AAA," are not references (p.232, p.234), compound
symbols (p.233), &E' and &L' (p.236), &V' and &L'&V' (p.237), right to
left resolution: &a.&b = TIMOTHY, &L'&a.&b = 2K, &L'&a&b = 3 (p.238),
&&x (p.256), and the zero padding with &&L'&num.z.&num (p.269).

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">Our publisher uses the IBM 1403 Printer for output.
  Our publisher uses the IBM 1403 Printer.
  This list ends with an apple.
  The name of our product is Whizbanger, which is scheduled
  for shipment on June 13th, 1986.
  Without the period, &amp;prodname, is a character string.
  This is the first try.
  I have defined the symbols &amp;AAA, &amp;BBB, &amp;CCC, and others
  The result is 1.
  0
  15
  5
  Belinda 8 &amp;b.linda 8
  &amp;c.linda / linda / []
  TIMOTHY / 2K / 3
  4
  00123
  00007
  </gml:doc>
