.* tables.gml - the Starter Set table tags (Rel 3.2, SH20-9186-06 ch.7):
.* row definitions with CWIDTHS (* widths) and ARRANGE (spanning cells),
.* header and footer, caption and description, a table note, cells out
.* of order, repeated, wrapped to a new row and concat=no, references and
.* the list of tables, rows of two definitions in one table, a footnote
.* in a cell, and two mistakes (a cell that is not a rectangle, a cell
.* number that does not exist).
:gdoc.
:frontm.
:tlist.
:body.
:h1 id=tabs.Tables
:p.The planets are in :tref refid=planets., the timetable is
:tref refid=sched page=yes., and :tref refid=steps. has no caption.
:rdef id=planet cwidths='6* 3p *' hp='2 0' align='l r c'.
:rdef id=phead cwidths='6* 3p *' hp=2 align=c valign=bot.
:table id=planets refid=planet column split=yes.
:thd refid=phead.
:c.Planet:c.Moons:c.Notes
:ethd.
:tft refid=phead.
:c.Planet:c.Moons:c.Notes
:etft.
:row.
:c.Mercury
:c.0
:c.Closest to the Sun.
:row refid=planet.
:c.Venus:c.0:c.It turns the other way.
:row split=no.
:c 3.Our home; these cells are given out of order.
:c 1.Earth
:c 2.1
:row.
:c.Mars:c.2:c.Two small moons.:fn.Both were found in 1877.:efn.
:c.Jupiter:c.95:c.The largest; this row was started by the cell after the last one.
:tnote.Moon counts change as new moons are found.
:etnote.
:row.
:c.Saturn:c.146
:tcap.Some planets of the solar system
:tdesc.Only five of the eight planets are listed;
the last row leaves its third cell empty.
:etable.
:rdef id=sched arrange='1 1 2'
arrange='3 4 2'
arrange='5 5 5'
cwidths='2i 2i 1.5i' align='c l l r c' valign='top top center' concat='y y n y'.
:table id=sched refid=sched width='5.5i'.
:row.
:c.Morning session
:c.Afternoon, in room :hp1.4:ehp1. only
:c 4.Lab work
:c 3.
first line
  second line, indented
third line
:c 5.All day: the registration desk is open.
:tcap.A timetable with spanning cells
:etable.
:rdef id=two cwidths='1i *' hp='1 0'.
:table id=steps refid=two.
:row.
:c 1.Steps
:c 2.Unpack the box.
:c 2.Read the leaflet.
:c 2.Switch it on.
:tnote.The second cell is repeated: its parts are divided by rules.
:etnote.
:row.
:c.Result:c.It works.
:etable.
:rdef id=wide cwidths='2i *' hp=1.
:rdef id=four cwidths='1i 1i * *'.
:table refid=wide width='6i'.
:row.
:c.Two row definitions:c.so the grid has the columns of both
:row refid=four.
:c.a:c.b:c.c:c.d
:etable.
:rdef id=bad arrange='1 2 2 / 2 2 3' cwidths='* * *'.
:table refid=bad.
:row.
:c.one:c.two:c.three
:c 9.nine
:etable.
:egdoc.
