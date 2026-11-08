Formatting in passes with -profile dcfstarter (SCRIPT's TWOPASS and
FPASSES(n), SH20-9186-06 p.126, p.129): the engine side of gmlpass,
with the TeX runs between the passes replaced by aux files written by
hand.  Each pass is gml -pass k -passes n -aux JOB.gmlaux
-symbols-in/-symbols-out.

Pass 1 of 2: the forward references are not known yet; the profile
prints a stand-in (the ID) and no message (DCFS020W waits for the last
pass, ss@last); the .tc of :toc (&$TWO = 1) is empty; every &$PN is
a question (gml:query, \gmlquery in the TeX), answered with the neutral
1 (no aux file yet).  The root element has pass= and passes=, which
tex.xsl writes as \def\gmlpassno{1}\def\gmlpasses{2} before \input gml.

  $ gml -profile dcfstarter -pass 1 -passes 2 -aux in.gmlaux -symbols-out p1.sym -o p1.xml in.gml
  $ grep -o '<gml:doc [^>]*>' p1.xml
  <gml:doc xmlns:gml="urn:x-gml:canonical" pass="1" passes="2">
  $ grep -c tcentry p1.xml
  0
  [1]
  $ grep -o 'See.*\|Back.*\|<gml:query [^>]*>' p1.xml
  <gml:query id="q1.5.1" what="pn" break="no"/>
  See “later”, pic and “nosuch”.
  <gml:query id="q1.7.1" what="pn" break="no"/>
  <gml:query id="q1.10.1" what="pn" break="no"/>
  Back to <gml:query id="q1.12.1" what="pn" break="no"/>“Introduction”.

The symbol file has the cross-reference symbols (fh@ID text, fp@ID
page, fg@ID number, fq@ID its page) and the TOC entries; the per-pass
state (the ID stamps of f@dfid, ss@last) is removed at :egdoc, so
two passes in the same state write the same file.

  $ grep '^.se f[hpgq]@\|gml@toc\|^.se [hg]@\|ss@last' p1.sym
  .se fg@PIC = '1'
  .se fh@INTRO = 'Introduction'
  .se fh@LATER = 'Later'
  .se fp@INTRO = '1'
  .se fp@LATER = '1'
  .se fq@PIC = '1'
  .se gml@toc(1) = '1	1	0		1	gml.tc.1	Introduction'
  .se gml@toc(2) = '1	1	0		1	gml.tc.2	Later'

TeX's answers (written by hand here): the pages of the anchors and of
the questions; Later and the figure are on page 2.

  $ cat > in.gmlaux <<'EOT'
  > .* gml aux
  > .se pa@gml@tc@1 = '1'
  > .se pa@gml@tc@2 = '2'
  > .se pq@1@5@1 = 1
  > .se pq@1@7@1 = 2
  > .se pq@1@10@1 = 2
  > .se pq@1@12@1 = 2
  > EOT

Pass 2 of 2, the last: the symbols of pass 1 resolve the forward
references (the page of Later is still pass 1's, 1: it comes right a
pass later, which is why gmlpass makes 3 by default); the .tc prints
the entries of pass 1 with the pages of their anchors; the reference
to an ID that does not exist gives DCFS020W and the Starter Set's
text, now.  A reference that resolves asks a question of its own
(q1.6.1, q1.6.2): only the ids of its line change.  The duplicate-ID
check does not mistake the carried symbols for a second definition.

  $ gml -profile dcfstarter -pass 2 -passes 2 -aux in.gmlaux -symbols-in p1.sym -symbols-out p2.sym -o p2.xml in.gml 2>&1 | sed 's/ (in macro[^)]*)//'
  in.gml:6: +++DCFS020W Reference to nosuch is undefined.
  $ grep -o '<gml:tcentry [^>]*>\|See.*\|Back.*' p2.xml
  <gml:tcentry level="1" text="Introduction" dot="yes" page="1" break="yes"/>
  <gml:tcentry level="1" text="Later" dot="yes" page="2" break="yes"/>
  See <gml:query id="q1.6.1" what="pn" break="no"/>“Later”, <gml:query id="q1.6.2" what="pn" break="no"/>Figure 1 and “Heading ID unknown”.
  Back to <gml:query id="q1.12.1" what="pn" break="no"/>“Introduction” on page 1.
  $ grep '^.se f[pq]@' p2.sym
  .se fp@INTRO = '1'
  .se fp@LATER = '2'
  .se fq@PIC = '2'

With the page of Later known (a third pass would read p2.sym), the
reference says where it is.

  $ printf '.se pq@1@6@1 = 1\n.se pq@1@6@2 = 1\n' >> in.gmlaux
  $ gml -profile dcfstarter -pass 2 -passes 2 -aux in.gmlaux -symbols-in p2.sym in.gml 2>/dev/null | grep -o 'See.*'
  See <gml:query id="q1.6.1" what="pn" break="no"/>“Later” on page 2, <gml:query id="q1.6.2" what="pn" break="no"/>Figure 1 on page 2 and “Heading ID unknown”.

In one pass (no -pass/-passes) nothing changes: DCFS020W for every
forward reference, with the one-pass text, and :toc leaves the list to
resolve.xsl (an empty toc element).

  $ gml -profile dcfstarter in.gml 2>&1 >/dev/null | sed 's/ (in macro[^)]*)//'
  in.gml:6: +++DCFS020W Reference to later is undefined or forward (one pass).
  in.gml:6: +++DCFS020W Reference to pic is undefined or forward (one pass).
  in.gml:6: +++DCFS020W Reference to nosuch is undefined or forward (one pass).
  $ gml -profile dcfstarter in.gml 2>/dev/null | grep -o '<toc/>'
  <toc/>
