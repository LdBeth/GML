.ms on
.* p.264
.se street = Broadway
.if &street eq Broadway .se branch = Commercial
.if &street ne Broadway .se branch = Warehouse
.ty branch=&branch
.se street = Main
.if &street eq Broadway
.th .se branch = Commercial
.el .se branch = Warehouse
.ty branch=&branch
.* p.265: the comparison is preserved across macro calls and imbeds
.dm notes on
.if a eq b
.th .ty notes: its own comparison is false
.dm off
.se job = chimney-sweep
.if &job eq chimney-sweep
.th .ty sp 2
.th .notes height of roof
.el .ty us salary
.el .ty in 5
.el .im salary &job
.th .ty sp 2
.el .ty sp 4
.se job = clerk
.if &job eq chimney-sweep
.th .notes height of roof
.el .im salary &job
.th .ty wrong: the .if of salary does not count here
.el .ty sp 4
.* p.265
.se city = Fayetteville
.se state = Arkansas
.if x&city = xFayetteville .an x&state = xArkansas .se zip = 72701
.ty zip=&zip
.dm carpool /.ty carpool for &*
.se city = Warrensburg
.if x&city eq xCleveland .or x&city eq xWarrensburg
.th .carpool &city
.el .se city =
.* p.266
.se a =
.if &a = ON .go next
.if /&a = /ON .go next
.ty not skipped
...next
.se a = ON
.if /&a = /ON .go next2
.ty skipped
...next2
.* p.267: with .su off the comparands are substituted one by one
.se needle = 'Rachel MG'
.se haystack = 'Parking Lot'
.if &needle eq &haystack .th .ty lost
.su off
.if &needle eq &haystack .th .ty lost
.el .ty not lost
.su on
