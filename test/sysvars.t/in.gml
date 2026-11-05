Line &$LINE of &$FILE.
.ty line &$line
Separator [&U'&$CW.] page &$PN ret &$RET
.dc cw #
Separator now [&U'&$CW.]
.dc cw off
Separator off [&U'&$CW.]
.dc cw ;
Split here [&$CW.] by the extended symbol rule (p.257)
Date &$DATE time &$TIME
.se $line = 1
.se $mine = ok
User dollar symbol: &$mine
GML [&$GML.] [&$EGML.] env &$ENV su &$SU lnum &$LNUM
.dc cont +
Continuation [&$CONT.]
DATE: &SYSMONTH./&SYSDAYOFM./&SYSYEAR
TIME: &SYSHOUR.:&SYSMINUTE.:&SYSSECOND
Day of week &SYSDAYOFW., of year &SYSDAYOFY., lower case &sysyear
.se SYSDAYOFM = &SYSDAYOFM + 0
.se d3 = Tuesday
.se m11 = November
&d&SYSDAYOFW.., &m&SYSMONTH.. &SYSDAYOFM., 20&SYSYEAR..
