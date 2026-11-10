Control words checked against the Rel 4 Language Reference: .mg
/code/message/ (a single field is the code, shown as with MESSAGE(ID);
the last letter gives the return code, p.246); .dm name(n) with n from
0, one final delimiter dropped and an omitted line a null line, .dm
name alone a null macro (p.142); .AND for .AN (p.66); the unit m is MH
on either axis (p.58).

  $ gml in.gml
  in.gml:2: +++ Your terminal is on.
  in.gml:3: +++W Your terminal is smoking.
  in.gml:4: +++1e Your terminal is on fire.
  in.gml:5: +++I
  in.gml:6: +++
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical">first
  second
  a/b
  after the null macro
  and: both true
  <gml:sp n="2" unit="mh" break="yes"/></gml:doc>
  [8]
