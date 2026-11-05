.ms on
.se *top 'top level'
.se g = 1
.dm inner on
inner sees 1=&*1 top=&*top loc=&*loc g=&g
.se *loc 'inner local'
.se g = 3
.dm off
.dm outer on
.se *loc 'outer local'
.se g = 2
.inner from-outer
outer after call loc=&*loc 1=&*1 g=&g
.dm off
.outer from-top
after: loc=&*loc top=&*top g=&g 1=&*1
