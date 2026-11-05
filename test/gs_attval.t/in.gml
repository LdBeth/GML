.gs tag on
.xd tagname closedby=tagname
.dm tagname on
.gs attval id place
.gs attval id as *xyz
id=&ID place=&PLACE local=&*xyz
.if '&PLACE.' eq 'Des Moines' .th [it is Des Moines]
.dm off
:tagname id='fred' place='Des Moines'.
.* an attribute not given sets the null string
:tagname id=bob.
