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

An unquoted value that is not a single word of name characters is
taken all the same, with a warning: LR p.186 wants it quoted.

  $ cat > lax.gml <<'X'
  > .gs tag on
  > .dm fig /.gs attval width id/[&WIDTH &ID.]
  > :fig width=1-2 id=ok depth=3i.
  > X
  $ gml lax.gml
  lax.gml:3: warning: tag :fig: value of width=1-2 should be quoted (LR p.186)
  lax.gml:3: warning: element fig not closed at end of input
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><fig width="1-2" id="ok" depth="3i">[1-2 ok]
  </fig></gml:doc>
  [4]
