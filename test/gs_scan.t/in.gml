.gs tag on
.gs rules (noelem)
.* .gs scan removes the residual text into a symbol
.dm h1 on
.gs scan head
[heading: &head.]
.dm off
:h1.The Title
.* .gs copy leaves it to be processed
.dm title on
.gs copy t
.if &L'&t eq 0 .th [no residual]
.el [residual of length &L'&t.]
.dm off
:title.
First Line
of the Title
:title.
.* .gs insert puts text before the residual text
.dm figref /.gs insert Figure 7
See :figref. for details.
.* symbols in the residual text were substituted before the APF ran
.se count = 0
.dm xxx on
.se count = &count + 1
.gs scan *line
[&*line.]
.dm off
:xxx.the count is &count
now the count is &count
