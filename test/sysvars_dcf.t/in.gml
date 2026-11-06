Device &$PDEV &$LDEV &$OUT., release &$DCF on &$SYS., pass &$PASS two &$TWO
Index &$INDX lib &$LIB unf &$UNF print &$PRT bind &$BE &$BO
File &$FNAM.; fonts &$CHAR(0): [&$CHAR(1)] [&$CHAR(2)] [&$CHAR(3)] [&$CHAR(*)]
.in 5
.ir 1i
.of 2
.ll 6.5i
In &$IN ir &$IR of &$OF ll &$LL cl &$CL pl &$PL pw &$PW lc &$LC
Blank [&$RB.] page symbol [&$PS.] kp &$KP vr &$VR
.dc rb ~
.dc ps #
Now [&$RB.] [&$PS.]
.dc rb 40
.dc ps
Hex [&$RB.] default [&$PS.]
.se $PDEV = 4250
.if &$PDEV eq 3800 .go f&$CHAR(0)
...f2
Two fonts.
