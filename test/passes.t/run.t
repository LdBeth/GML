Formatting in passes with -profile dcfstarter (SCRIPT's TWOPASS and
FPASSES(n), SH20-9186-06 p.126, p.129): the engine side of gmlpass,
with the TeX runs between the passes replaced by aux files written by
hand.  Each pass is gml -pass k -passes n -aux JOB.gmlaux
-symbols-in/-symbols-out.

Pass 1 of 2: the forward references are not known yet; the profile
prints a stand-in (the ID) and no message (DSMGML013W waits for the last
pass, ss@last); the .tc of :toc (&$TWO = 1) is empty; every &$PN is
a question (gml:query, <?pn ID> in the TeX), answered with the neutral
1 (no aux file yet).  A reference asks for its own page (q1.6.1-3)
whether its ID is known or not, so that pass 2 asks the same
questions.  The root element has pass= and passes=, which
tex.xsl writes as \def\gmlpassno{1}\def\gmlpasses{2} before \input gml.

  $ gml -profile dcfstarter -pass 1 -passes 2 -aux in.gmlaux -symbols-out p1.sym -o p1.xml in.gml
  $ grep -o '<gml:doc [^>]*>' p1.xml
  <gml:doc xmlns:gml="urn:x-gml:canonical" pass="1" passes="2">
  $ grep -c tcentry p1.xml
  0
  [1]
  $ grep -o 'See.*\|Back.*\|<gml:query [^>]*>' p1.xml
  <gml:query id="q1.5.1" what="pn" break="no"/>
  See <gml:query id="q1.6.1" what="pn" break="no"/>“later”, <gml:query id="q1.6.2" what="pn" break="no"/>pic and <gml:query id="q1.6.3" what="pn" break="no"/>“nosuch”.
  <gml:query id="q1.7.1" what="pn" break="no"/>
  <gml:query id="q1.10.1" what="pn" break="no"/>
  Back to <gml:query id="q1.12.1" what="pn" break="no"/>“Introduction”.

The symbol file has the cross-reference symbols (fh@ID text, fg@ID
number) and the TOC entries; the pages (fp@ID, fq@ID), set to the
answer of a question (.se fp@ID = &$PN), travel as that question
(gml@pgq: name, subscript, question id, neutral default), and the next
pass gives them the answer TeX wrote for it (lib/symbols.ml, the page
provenance).  The per-pass state (the ID stamps of f@dfid, ss@last,
the texts of the last reference) is removed at :egdoc, so two passes
in the same state write the same file.

  $ grep '^.se f[hpgq]@\|gml@toc\|gml@pgq\|^.se [hg]@\|ss@last\|f@pgt\|f@ut' p1.sym
  .se fg@PIC = '1'
  .se fh@INTRO = 'Introduction'
  .se fh@LATER = 'Later'
  .se gml@pgq(1) = 'fp@INTRO 0 q1.5.1 1'
  .se gml@pgq(2) = 'fp@LATER 0 q1.7.1 1'
  .se gml@pgq(3) = 'fq@PIC 0 q1.10.1 1'
  .se gml@toc(1) = '1	1	0		1	gml.tc.1	Introduction'
  .se gml@toc(2) = '1	1	0		1	gml.tc.2	Later'

TeX's answers (written by hand here): the pages of the anchors and of
the questions; Later and the figure are on page 2.

  $ cat > in.gmlaux <<'EOT'
  > .* gml aux
  > .se pa@gml@tc@1 = '1'
  > .se pa@gml@tc@2 = '2'
  > .se pq@1@5@1 = 1
  > .se pq@1@6@1 = 1
  > .se pq@1@6@2 = 1
  > .se pq@1@6@3 = 1
  > .se pq@1@7@1 = 2
  > .se pq@1@10@1 = 2
  > .se pq@1@12@1 = 2
  > EOT

Pass 2 of 2, the last: the symbols of pass 1 resolve the forward
references, with the pages TeX gave their targets in pass 1 (fp@LATER
and fq@PIC are the answers to q1.7.1 and q1.10.1: 2, not pass 1's
neutral 1); the .tc prints the entries of pass 1 with the pages of
their anchors; the reference to an ID that does not exist gives
DSMGML013W and the Starter Set's text, now.  The references ask the
questions of pass 1, no other, and the symbol file is that of pass 1
(with these answers TeX would write the same aux file: gmlpass would
stop after two passes).  The duplicate-ID check does not mistake the
carried symbols for a second definition.

  $ gml -profile dcfstarter -pass 2 -passes 2 -aux in.gmlaux -symbols-in p1.sym -symbols-out p2.sym -o p2.xml in.gml 2>&1 | sed 's/ (in macro[^)]*)//'
  in.gml:6: +++DSMGML013W ID 'nosuch' NOT DEFINED, REFERENCE NOT RESOLVED. (page 1)
  $ grep -o '<gml:tcentry [^>]*>\|See.*\|Back.*' p2.xml
  <gml:tcentry level="1" text="Introduction" dot="yes" page="1" break="yes"/>
  <gml:tcentry level="1" text="Later" dot="yes" page="2" break="yes"/>
  See <gml:query id="q1.6.1" what="pn" break="no"/>“Later” on page 2, <gml:query id="q1.6.2" what="pn" break="no"/>Figure 1 on page 2 and <gml:query id="q1.6.3" what="pn" break="no"/>“Heading ID unknown”.
  Back to <gml:query id="q1.12.1" what="pn" break="no"/>“Introduction” on page 1.
  $ cmp p1.sym p2.sym && echo same
  same

In one pass (no -pass/-passes) nothing changes: DSMGML013W for every
forward reference, with the one-pass text, and :toc leaves the list to
resolve.xsl (an empty toc element).

  $ gml -profile dcfstarter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:6: +++DSMGML013W ID 'later' NOT DEFINED OR A FORWARD REFERENCE IN ONE PASS. (page 1)
  in.gml:6: +++DSMGML013W ID 'pic' NOT DEFINED OR A FORWARD REFERENCE IN ONE PASS. (page 1)
  in.gml:6: +++DSMGML013W ID 'nosuch' NOT DEFINED OR A FORWARD REFERENCE IN ONE PASS. (page 1)
  $ gml -profile dcfstarter in.gml 2>/dev/null | grep -o '<toc/>'
  <toc/>
