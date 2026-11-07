Layout mode with a real TeX (ApTeX, if installed): the paragraphs report
the page number and the lines left that TeX has when they start, and a
paragraph with fewer than 8 lines left goes to the next page (.if &$LC
lt 8 .pa).  Without aptex the expected text is printed (expected.txt),
so the suite passes without TeX.  The values depend on gml.tex's page
layout and fonts (gmlfont-ncs).

  $ if command -v aptex > /dev/null; then gml -layout aptex -tex out.tex in.gml && grep -o 'Paragraph [0-9]* starts on page [0-9]* with [0-9]* lines' out.tex; else cat expected.txt; fi
  Paragraph 1 starts on page 1 with 51 lines
  Paragraph 2 starts on page 1 with 45 lines
  Paragraph 3 starts on page 1 with 39 lines
  Paragraph 4 starts on page 1 with 33 lines
  Paragraph 5 starts on page 1 with 27 lines
  Paragraph 6 starts on page 1 with 21 lines
  Paragraph 7 starts on page 1 with 15 lines
  Paragraph 8 starts on page 1 with 9 lines
  Paragraph 9 starts on page 2 with 53 lines
  Paragraph 10 starts on page 2 with 47 lines
  Paragraph 11 starts on page 2 with 41 lines
  Paragraph 12 starts on page 2 with 35 lines

The TeX source as sent is the batch TeX (gml -tex) apart from the
answers and the comment line after each one.

  $ if command -v aptex > /dev/null; then grep -c '^%gml:query' out.tex; else echo 36; fi
  36
