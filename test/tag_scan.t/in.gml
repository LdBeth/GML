.* GML scanning is off until .gs tag on
:p.not scanned
.gs tag on
.* empty APFs: only the automatic elements show
.dm p on
.dm off
.dm q on
.dm off
.dm eq on
.dm off
.dm fig on
.dm off
.dm ol on
.dm off
.dm li on
.dm off
.xd p closedby=p,fig,ol
.xd li closedby=li
.* attribute forms: name=value, blanks around =, quoted with doubled quote
:fig id=f1 frame = box title='It''s here' place=top.Figure text
::fig.
.* a tag in the middle of a word does not break it
in:q.side::q.out
.* residual text runs up to the next tag
:p.The :q.starter set::q. Profile
.* colons that do not start a tag name are text
Note: at 10:30, see http://example.org
.* markup over several lines, residual text on the next line
:fig
id=f2
place = bottom.
Caption line
::fig.
.* the MCS can be omitted before another tag
:ol
:li.one
:li.two
::ol.
.* a control word ends the markup
:fig
.* comment
id=f3.is text now
::fig.
.* other delimiters
.dc gml ! !e
!p.bang :p. colon !ep.
.dc gml : ::
.dc mcs >
:p id=x>after
.dc mcs .
.dc gml off
:p.not scanned with .dc gml off
.dc gml :
.dc gml &
.dc mcs a
.gs tag off
:p.off again
