.gs tag on
.xd tagname closedby=tagname
.dm tagname on
.gs attval id as *xyz
.gs attval place
.* a processed attribute is deleted from the stack: ID is null now
.gs attval id
id=&ID place=&PLACE local=&*xyz
.if '&PLACE.' eq 'Des Moines' .th [it is Des Moines]
.dm off
:tagname id='fred' place='Des Moines'.
.* an attribute not given sets the null string
:tagname id=bob.
.* no names: all the stacked attributes; NOT: all but those listed
.xd all empty
.dm all on
.gs attval not b
a=&A b=&B c=&C
.gs attval
b=&B
.dm off
.se B = old
:all a=1 b=2 c=3.
