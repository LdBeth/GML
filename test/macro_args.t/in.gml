.ms on
.dm show on
all=[&*.] n=&*0
1=[&*1.] 2=[&*2.] 3=[&*3.]
.dm off
.show a b c
.show
.show one 'two words' three
.show 'it''s' x
.* operators and parentheses delimit tokens and are tokens (p.253)
.show 1+2 (x)
.* % is a null token (p.276)
.show a % b
.* there are no keyword arguments
.show color=red
.* arguments are substituted before the call
.se v = 42
.show &v &v.x
.* the separator ends the call line
.show a;after the call
.* &* keeps the leading blanks after the blank that ends the name
.show   spaced
.* &$LINE inside a macro is the line of the call
.su off
.dm where /line=&$LINE
.su on
.where
