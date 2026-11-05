.ms on
.se n = 0
.dm twice on
.go here
...here
.ty first here (n=&n)
.se n = &n + 1
.if &n gt 1 .me
...here
.ty second here
.go here
.dm off
.twice
.* in a file the search goes forward from the .go
.se k = 0
...there
.ty first there
.go there
...there
.se k = &k + 1
.ty second there (k=&k)
.if &k lt 2 .go there
.ty done
