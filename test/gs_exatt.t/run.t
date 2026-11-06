.gs exatt: all stacked attributes or selected ones, AS apf, missing
attributes skipped, processed attributes leave the stack, the next tag
purges the stack, a control word as attribute APF; an attribute given
twice is processed once per occurrence, with its own value.

  $ gml in.gml
  in.gml:8 (in macro fig line 1): warning: .gs exatt: no APF place for attribute place
  to stderr
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><fig id="fred" place="inline" frame="box">[ID APF: fred]
  [FRAME APF: box]
  </fig><fig id="fred2" place="inline" frame="box">[FRAME APF: box]
  [IDF APF: fred2]
  </fig><fig id="once">[ID APF: once]
  [done]
  <keep id="k"/><p>[p done]
  </p></fig><fig ty="to stderr"/><fig id="x" arr="two too">[ARR: one]
  [ARR: two too]
  </fig><fig arr="2">[ARR: 1]
  [ARR: 2]
  </fig></gml:doc>
  [4]
