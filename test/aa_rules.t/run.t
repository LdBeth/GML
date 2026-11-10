.aa tag apf (rules) endapf (rules) (LR p.62-63): an association keeps
its rules when .gs rules changes, and a new APF given without rules
keeps the old ones; = keeps the APF, () takes the current rules; NULL
or . is no processing; OFF deletes the association, the class mapping
applies; .gs snap shows it.

  $ gml in.gml
  in.gml:30: info: .gs snap: rules (att novat stop nomsg noelem) (noatt novat stop nomsg)
  in.gml:30: info: .gs snap: hd: (class mapping) (att novat stop nomsg noelem), end tag: hd2 (noatt novat stop nomsg)
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">[hd: 0 ]
  big.Frozen
  [hd2: 0 ]
  big.Kept
  [hd2: 1 big]
  Current
  Null
  Dot
  [hd: 0 ]
  big.Class
  [hd: 0 ]
  Start
  [hd2: 0 ]
  </gml:doc>
