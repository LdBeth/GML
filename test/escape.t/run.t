XML special characters are escaped.

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">a &lt; b &amp; c &gt; d &quot;quoted&quot; 'apos'
  </gml:doc>

-o writes to a file:

  $ gml -o out.xml in.gml && cat out.xml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">a &lt; b &amp; c &gt; d &quot;quoted&quot; 'apos'
  </gml:doc>
