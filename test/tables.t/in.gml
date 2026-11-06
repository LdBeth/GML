:gdoc.
:body.
:c.a cell before any table
:rdef id=Grid arrange='1 1 2'
arrange='3 4 2' cwidths='2i 1i *' concat='yes y no yes'.
:rdef cwidths='*'.
:p.Text before the table
:table column refid=grid id=grid page wide.
:thd.
:c.Head:c 4.Four
:ethd.
:row.
:c 2.second, given first
:c.
kept
  as typed
:c.joined
lines
:c 9.no such cell: the next one, cell 1 of a new row
:c.cell 2
:tnote.A note ends the row.:etnote.
:c.out of context
:row refid=nosuch.
:c.unknown definition
:tft.
:c.late footer
:etft.
:tcap.The caption
:tdesc.The description.
:etable.
:table refid=grid.
:row.
:c.open at a heading
:h1.Heading
:p.:tref. and :tref refid=grid..
:tlist.
:egdoc.
