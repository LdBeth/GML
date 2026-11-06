.ct text (SH35-0069 p.48) continues the previous text without a word
space; its text is an input line, so a continuation character at its
end continues it in turn (IBM's DSMFDESC: ".ct :&$RB.&$RB.&$CONT").

  $ gml in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">First partand the restjoined to this line.
  Plain line.
  </gml:doc>
