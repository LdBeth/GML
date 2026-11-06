.gs tag on
.xd fig closedby=fig
.dm id /[ID APF: &*1.]
.dm frame /[FRAME APF: &*1.]
.dm idf /[IDF APF: &*1.]
.* all stacked attributes, by APFs named after them
.dm fig /.gs exatt
:fig id=fred place=inline frame=box.
.* selected attributes; AS names the APF; a missing attribute is skipped
.dm fig /.gs exatt frame id as idf width
:fig id=fred2 place=inline frame=box.
.* processed attributes leave the stack
.dm fig /.gs exatt id/.gs exatt id/[done]
:fig id=once.
.* the previous tag's attributes are purged by the next tag
.dm keep on
.dm off
.xd keep empty
.dm p /.gs exatt/[p done]
.xd p closedby=fig
:keep id=k.:p.
.* a native control word as attribute APF
.dm fig /.gs exatt ty
:fig ty='to stderr'.
.* a repeated attribute: once per occurrence, each with its own value
.dm arr /[ARR: &*1.]
.dm fig /.gs exatt arr
:fig arr=one id=x arr='two too'.
.dm fig /.gs exatt
:fig arr=1 arr=2.
