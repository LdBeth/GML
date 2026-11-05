GML tag scanning (SH35-0069 ch.24): off until .gs tag on; attribute
forms; a tag in a word; residual text up to the next tag; literal colons;
markup over several lines; the MCS omitted before a tag; a control word
ending the markup; .dc gml / .dc mcs.

  $ gml in.gml
  in.gml:54: error: .dc gml: invalid delimiter &
  in.gml:55: error: .dc mcs: invalid delimiter a
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">:p.not scanned
  <fig id="f1" frame="box" title="It's here" place="top">Figure text
  </fig>in<q>side</q>out
  <p>The <q>starter set</q> Profile
  Note: at 10:30, see http://example.org
  </p><fig id="f2" place="bottom">Caption line
  </fig><ol><li>one
  </li><li>two
  </li></ol><fig>id=f3.is text now
  </fig><p>bang :p. colon </p>
  <p id="x">after
  :p.not scanned with .dc gml off
  :p.off again
  </p></gml:doc>
  [8]
