.* dcfstarter-tables.gml - the Starter Set tables formatted by
.* -profile dcfstarter (hint mode): the profile's skips, "Table n." and
.* "Note:" labels, the tdesc colon and a CONCAT=NO cell as a format-off
.* region, around the elements resolve.xsl turns into the grid; a list
.* of tables, a backward and a forward :tref.
:gdoc.
:frontm.
:tlist.
:body.
:h1.Tables
:p.The timetable is :tref refid=sched..
:rdef id=planet cwidths='6* 5p *' hp='2 0' align='l r c'.
:rdef id=phead cwidths='6* 5p *' hp=2 align=c valign=bot.
:table id=planets refid=planet column split=yes.
:thd refid=phead.
:c.Planet:c.Moons:c.Notes
:ethd.
:tft refid=phead.
:c.Planet:c.Moons:c.Notes
:etft.
:row.
:c.Mercury:c.0:c.Closest to the Sun.
:row split=no.
:c 3.Our home, given first.
:c 1.Earth
:c 2.1
:row.
:c.Mars:c.2:c.Two small moons.:fn.Both were found in 1877.:efn.
:tnote.Moon counts change.
:etnote.
:tcap.Some planets
:tdesc.Three of the eight.
:etable.
:rdef id=sched arrange='1 1 2' arrange='3 4 2'
cwidths='2i 2i 1.5i' concat='y y n y'.
:table id=sched refid=sched width='5.5i'.
:row.
:c.Morning
:c.Afternoon
:c 4.Lab work
:c 3.
first line
  second line, indented
:tcap.A timetable
:etable.
:p.The planets are in :tref refid=planets page=yes..
:egdoc.
