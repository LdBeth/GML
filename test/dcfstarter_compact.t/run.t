:ol compact under dcfstarter: the skip of .75 comes before and after
the list only, not before each item.  (The value attribute reaches
f@lbeg through the &* of the single-line .dm f@ol, which must stay
unresolved when the profile defines it: starterset.gml must not leave
&* set at file level.)

  $ gml -profile dcfstarter in.gml | grep -o '<gml:sk n="0.75"[^>]*>' | wc -l | tr -d ' '
  2
