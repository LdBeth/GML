An ignored conditional section (:psc with a PROC that does not match
SYSVARP; the profile's .cs 9) leaves nothing in the tree: its tags and
macros are resolved (SH35-0069 p.268), so the APF of :mytag runs and
sets &seen, but the automatic elements (:p, :ol, :li) and the
APF's .xs/.xe output are dropped, and the :p before it is not closed by
the :p inside it.

  $ gml -profile starter -set SYSVARP=html in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body><p>before
  </p><p>after; seen=yes
  </p></body></gdoc></gml:doc>

With a matching PROC the section is processed.

  $ gml -profile starter -set SYSVARP=tex in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gdoc><body><p>before
  </p><p>only for tex
  <mark n="1"/></p><ol><li>item
  </li></ol><gml:sp n="2" unit="line" break="yes"/><p>after; seen=yes
  </p></body></gdoc></gml:doc>
