:psc under -profile dcfstarter selects by SYSVARP, as under starter
(starterset.gml's ss@psc: conditional section 9): the text of a :psc
is processed when one of the PROC names is &SYSVARP, or when it has no
PROC.  Without SYSVARP (null) only the :psc without PROC is kept.

  $ gml -profile dcfstarter -set SYSVARP=tex in.gml | sed 's/<[^>]*>//g' | grep .
  before
  only for tex
  for every processor
  after

  $ gml -profile dcfstarter -set SYSVARP=pdf in.gml | sed 's/<[^>]*>//g' | grep .
  before
  for html or pdf
  for every processor
  after

  $ gml -profile dcfstarter in.gml | sed 's/<[^>]*>//g' | grep .
  before
  for every processor
  after
