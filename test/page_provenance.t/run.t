The page provenance of carried symbols (lib/ctx.ml page_syms,
lib/control.ml .se, lib/symbols.ml dump, lib/aux.ml resolve_pages).
A global symbol that .se sets to the answer of the one page question
asked on its line (.se fp = &$PN, .se fp = &) is written to the symbol
file not with its value but as the question: an element of gml@pgq,
"NAME SUB ID DEFAULT".  The next pass, given the aux file TeX wrote in
the same pass (-aux), sets it to TeX's answer to that question (the
default when there is none), before the profile and the document run.
So a forward reference to a page is right on pass 2: the page comes
from TeX(1), not from the answer pass 1 had (the neutral 1, then
TeX(1) in pass 2, the forward reference in pass 3).

Pass 1: no aux file yet; every question is answered 1.

  $ cat > in.gml <<'EOT'
  > Forward: &fp &fp2 &arr(2) &y &none &two &three &st &plus &gone..
  > .se fp = &$PN
  > .se fp2 = &
  > .se arr(2) = &$PN
  > .su off
  > .se y = &$PN
  > .su on
  > .se none = &$PN
  > .se two = &$PN.;.se three = &$PN
  > .se st = &$PN
  > .se st = 9
  > .se plus = &$PN + 1
  > .se gone = &$PN
  > .se gone off
  > .se *loc = &$PN
  > Backward: &fp..
  > EOT
  $ gml -pass 1 -passes 2 -aux in.gmlaux -symbols-out p1.sym in.gml | grep -o 'Forward.*\|Backward.*'
  Forward: &amp;fp &amp;fp2 &amp;arr(2) &amp;y &amp;none &amp;two &amp;three &amp;st &amp;plus &amp;gone..
  Backward: 1.

The symbols set to an answer and nothing else travel as their
question: fp and fp2 (.se x = & is a reference to &$PN, p.254), an
array element (arr(2)), a .se that substitutes its own operands with
.su off (y).  Not: two questions on one line (two, three: the whole
line is substituted before the .se in front of the separator runs,
p.271, so which one is whose is not known), a value that is not the
answer (plus), a symbol set again (st) or removed (gone), a local
symbol (*loc: not carried).

  $ grep '^.se' p1.sym
  .se arr = '2'
  .se plus = '2'
  .se st = '9'
  .se three = '1'
  .se two = '1'
  .se gml@pgq(1) = 'arr 2 q1.4.1 1'
  .se gml@pgq(2) = 'fp 0 q1.2.1 1'
  .se gml@pgq(3) = 'fp2 0 q1.3.1 1'
  .se gml@pgq(4) = 'none 0 q1.8.1 1'
  .se gml@pgq(5) = 'y 0 q1.6.1 1'

TeX's answers to pass 1's questions (written by hand here; none for
q1.8.1, the place TeX did not reach, say).

  $ cat > in.gmlaux <<'EOT'
  > .* gml aux
  > .se pq@1@2@1 = 3
  > .se pq@1@3@1 = 3
  > .se pq@1@4@1 = 4
  > .se pq@1@6@1 = 5
  > .se pq@1@9@1 = 6
  > .se pq@1@9@2 = 6
  > .se pq@1@10@1 = 6
  > .se pq@1@12@1 = 7
  > .se pq@1@13@1 = 7
  > .se pq@1@15@1 = 7
  > EOT

Pass 2: the forward reference sees the pages of pass 1's TeX (none:
the default 1); the symbols without a provenance have their values of
pass 1.  gml@pgq is gone once it is used.

  $ gml -pass 2 -passes 2 -aux in.gmlaux -symbols-in p1.sym -symbols-out p2.sym in.gml | grep -o 'Forward.*\|Backward.*'
  Forward: 3 3 4 5 1 1 1 9 2 &amp;gone..
  Backward: 3.

The questions are those of pass 1, so the provenance entries are the
same, though the answers changed: only the symbols without one differ
(gmlpass compares the symbol files of two passes to stop).

  $ diff p1.sym p2.sym
  5c5
  < .se plus = '2'
  ---
  > .se plus = '8'
  7,8c7,8
  < .se three = '1'
  < .se two = '1'
  ---
  > .se three = '6'
  > .se two = '6'
  [1]

-symbols-in without -aux: every symbol with a provenance gets its
default, as on pass 1.

  $ gml -symbols-in p1.sym in.gml | grep -o 'Forward.*'
  Forward: 1 1 1 1 1 1 1 9 2 &amp;gone..

A value that changed after the .se by another way than .se (here .se
x lib, which loads a library member: not the answer any more) is
written as a value; .se x() (by the counter, p.256) records nothing.

  $ mkdir lib
  $ printf 'eleven\n' > lib/LIBP
  $ cat > lib.gml <<'EOT'
  > .se libp = &$PN
  > .se libp lib
  > .se cnt(1) = &$PN
  > .se cnt = 0
  > .se cnt() = &$PN
  > EOT
  $ gml -lib lib -aux in.gmlaux -symbols-out lib.sym lib.gml > /dev/null
  $ grep '^.se' lib.sym
  .se cnt = '1'
  .se cnt(1) = '1'
  .se libp = 'eleven'
