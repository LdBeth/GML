Ending files, SH35-0069 p.50-51 and p.55-56.

The TABLE/TABLSYM example of p.55-56, verbatim: each .im tablsym resumes
after the .ef that ended the previous imbed; the .cs 2 include in the
ignored section 1 takes effect only after the last TABLSYM group's
.cs 1 include, when the .ef of TABLE ends the document (the table of
p.56; the leading &$TAB. makes each row a leading-tab line, hence a
break).  The formatting words (.tp .sp .fo .bx) give hints; .cs 1 is
still open when .ef ends the file.

  $ gml table
  table:17: warning: .cs 1 on without .cs 1 off (opened at table:13)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:tp action="set" stops="3ch 21ch" break="no"/><gml:sp n="2" unit="line" break="yes"/><gml:fo fill="no" align="left" overdraw="extend" break="yes"/><gml:bx action="on" spec="1ch 19ch 36ch" break="yes"/>	STATE	CAPITAL
  <gml:bx action="line" break="yes"/><gml:tp action="set" stops="3ch 21ch" break="no"/>	Alabama	Montgomery
  <gml:bx action="line" break="yes"/><gml:tp action="set" stops="3ch 21ch" break="no"/>	Alaska	Juneau
  <gml:bx action="line" break="yes"/><gml:tp action="set" stops="3ch 21ch" break="no"/>	Arizona	Phoenix
  <gml:bx action="line" break="yes"/><gml:tp action="set" stops="3ch 21ch" break="no"/>	Arkansas	Little Rock
  <gml:bx action="line" break="yes"/><gml:tp action="set" stops="3ch 21ch" break="no"/>	California	Sacramento
  <gml:bx action="off" break="yes"/><gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/><gml:sp n="2" unit="line" break="yes"/></gml:doc>
  [4]

.ef close (p.50): the next imbed reads from the beginning.  An .ef in
the profile (p.50): the rest of the profile, the epifile, is processed
after the main document.

  $ gml -profile prof merge
  profile: before the document
  short: part 1
  short: part 2
  short: part 1
  merge: done
  epifile: after the document
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>

.qu and .qq (p.51) stop processing entirely, also from an imbedded file;
the epifile is not processed.

  $ gml -profile prof -set kind=qu quit
  profile: before the document
  main: imbedding
  inner: quitting
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>

  $ gml -profile prof -set kind=qq quit
  profile: before the document
  main: imbedding
  inner: quitting
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"/>
