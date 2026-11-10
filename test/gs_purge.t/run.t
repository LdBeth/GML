.gs purge / .gs purgemsg [[NOT] name ...] (LR p.185): delete stacked
attributes, PURGEMSG with a message naming them; .gs exatt NOT.

  $ gml in.gml
  in.gml:13 (in macro t3 line 2): warning: .gs purgemsg: attributes purged: B='2' C='x y'
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[B APF: 2]
  [C APF: 3]
  [B APF: 2]
  [A APF: 1]
  [C APF: 3]
  </gml:doc>
  [4]
