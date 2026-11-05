.ms on
.* SH35-0050 p.16: a macro that ends itself after the first run
.dm dsm#xlst on
.dm dsm#xlst(&$LNUM.) /.me
.ty cross reference listing
.dm off
.dsm#xlst
.dsm#xlst
.ty (second call ended at once)
.* p.16: a macro removing one of its lines
.dm dsm#setx /.ty heading: &*1 ids
.dm dsm#xrfh on
.dm dsm#xrfh(&$LNUM.) off &$CW..dsm#setx H
.ty entry &*1
.dm off
.dsm#xrfh one
.dsm#xrfh two
.dsm#xrfh three
.* p.181 (DSM#DUPL): line 40 removes line 60 when &SYSVARD is no
.dm dsm#dupl on
.if &$PN eq 0 .me
.ty fl dump
.* DUPLEX - EJECT TO EVEN PAGE. NOT DUPLEX - REMOVE THE EJECT LINE
.dm dsm#dupl(&$LNUM.) off &$CW..se *a = &$LNUM + 20
.dm dsm#dupl(&$LNUM.) off &$CW..if &SYSVARD eq no .dm dsm#dupl(&*a.) off
.ty pa (to an odd page)
.ty pa nostart
.dm off
.se SYSVARD = no
.dsm#dupl
.ty second call:
.dsm#dupl
.* p.17: setting the caller's local symbol (DSM@RFID, p.195)
.dm dsm@rfid on
.me .se *id '&*1
.dm off
.dm dsmhdref on
.dsm@rfid &*1
.ty the caller's *id is &*id
.dm off
.dsmhdref intro
.* p.194 (DSM#YESN), with the OCR's quotes restored
.dm dsm#yesn on
.se @ = index '-YES-NO-' '-&U'&*1.-'
.if &@ eq 0 .se @ = 1
.me .se *yesno = substr 'yes no' &@ 3
.dm off
.dm attr on
.dsm#yesn &*1
.ty &*1 gives &*yesno
.dm off
.attr yes
.attr No
.attr maybe
