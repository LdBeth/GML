.aa explicit mapping (tag and end-tag APFs), .gs prefix class mapping,
direct mapping to a macro or a native control word, rules on .aa,
noelem, removing an association, errors; a tag without APF is text.

  $ gml in.gml
  in.gml:20: error: no APF for tag :note; treated as text
  in.gml:23: error: no APF for tag :note; treated as text
  hello World
  in.gml:41: error: no APF for tag :fig; treated as text
  in.gml:43: error: .aa: invalid tag name 1x
  in.gml:44: error: .aa: unknown rule bogus
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><fig>[figure APF]
  Caption
  </fig>[end of figure]
  after
  <note>[class APF]
  Text
  </note>:note.Text again
  :note.no start APF
  [end class APF]
  <ol compact="compact" break="Break">ol: n=2 1=compact 2=Break
  </ol>ol: n=1 1=compact 2=
  :fig.no longer mapped
  </gml:doc>
  [8]
