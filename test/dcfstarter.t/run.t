The formatting profile -profile dcfstarter (share/profile/dcfstarter.gml):
its APFs are SCRIPT macros, so the output is mostly hint nodes.  The
.df/.dh/.dr definitions come first (that puts the TeX side in hint
mode); the :body. starts page 1 in arabic numbers with a running
footing that carries the page number symbol (pagesym); the h1 starts
a page (.pa before the new footing) and is issued with .h1 inside an h1
element (unnumbered: SYSVARH is not set); list items
are an .of hanging indention with the label set by .is to; the dl term
column comes from tsize; the footnote is called out by a raised 1 (a
.dv text variable with a font and a baseline shift); the figure
is a floating box (.kp float) with a bold "Figure 1." caption; and the
references resolve to "Figure 1" and the item identifier "1.".

  $ gml -profile dcfstarter -set SYSDAYOFM=13 -set SYSMONTH=06 -set SYSYEAR=1986 in.gml
  <?xml version="1.0" encoding="UTF-8"?>
  <gml:doc xmlns:gml="urn:x-gml:canonical"><gml:df name="hi0" spec="type(normal)" break="no"/><gml:df name="hi1" spec="type(italic)" break="no"/><gml:df name="hi2" spec="type(bold)" break="no"/><gml:df name="hi3" spec="type(bold italic)" break="no"/><gml:df name="hd0" spec="type(bold 20 italic)" break="no"/><gml:df name="hd1" spec="type(bold 20)" break="no"/><gml:df name="hd2" spec="type(bold 18 italic)" break="no"/><gml:df name="hd3" spec="type(bold 14)" break="no"/><gml:df name="hd4" spec="type(bold 12 italic)" break="no"/><gml:df name="hd5" spec="type(bold)" break="no"/><gml:df name="hd6" spec="type(bold italic)" break="no"/><gml:df name="title" spec="type(bold 24)" break="no"/><gml:df name="xmp" spec="type('courier')" break="no"/><gml:df name="f@sup" spec="type(7)" break="no"/><gml:dr spec="f@frule" break="no"/><gml:dr spec="f@fnrule weight 0.2mm" break="no"/><gml:dh level="0" spec="pa spbf 1.3i spaf 5 font hd0 up nohy left nto" break="no"/><gml:dh level="1" spec="pa spbf 1.3i spaf 3 font hd1 up nohy left" break="no"/><gml:dh level="2" spec="skbf 3 spaf 2 font hd2 up nohy left" break="no"/><gml:dh level="3" spec="skbf 3 spaf 2 font hd3 nohy left" break="no"/><gml:dh level="4" spec="skbf 3 spaf 2 font hd4 nohy left" break="no"/><gml:dh level="5" spec="skbf 1 nbr font hd5 nohy" break="no"/><gml:dh level="6" spec="skbf 1 nbr font hd6 nohy" break="no"/><gml:fn kind="leader"><gml:sp n="1" unit="line" break="yes"/><gml:hr spec="f@fnrule 0ch for 16ch" break="yes"/></gml:fn><gml:rf><gml:bf font="hi0" break="no"/><gml:sx left="" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><body><gml:dh level="0" spec="tc" break="no"/><gml:dh level="1" spec="tc" break="no"/><gml:dh level="2" spec="tc" break="no"/><gml:dh level="3" spec="tc" break="no"/><gml:dh level="4" spec="tc" break="no"/><gml:pa page="1" break="yes"/><gml:pn spec="arabic" break="no"/><gml:rf><gml:bf font="hi0" break="no"/><gml:sx left="" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:pa break="yes"/><gml:rf><gml:bf font="hi0" break="no"/><gml:sx left="Introduction" fill="" right="&amp;" pagesym="&amp;" break="yes"/><gml:pf initial="yes" break="no"/></gml:rf><h1 id="intro"><gml:h level="1" break="yes"><gml:tcmark anchor="gml.tc.1" break="no"/>Introduction</gml:h>
  </h1><gml:sk n="0.75" unit="line" break="yes"/>Text with <gml:bf font="hi2" break="no"/>bold<gml:pf initial="yes" break="no"/> and a note.<gml:dv name="f@fnc" font="f@sup" baseline="3pt" text="1" break="no"/>
  <gml:fn><gml:sp n="1" unit="line" break="yes"/><gml:dv name="f@fnc" font="f@sup" baseline="3pt" text="1" break="no"/>
  A footnote.</gml:fn>
  <gml:sk n="0.75" unit="line" break="yes"/><gml:in left="4" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:sk n="0.75" unit="line" break="yes"/><gml:in left="0" unit="ch" break="yes"/><gml:of offset="4" unit="ch" break="yes"/>1.
  <gml:is spec="to 4ch min 1ch blank" break="no"/>first
  <gml:sk n="0.75" unit="line" break="yes"/><gml:in left="0" unit="ch" offset="0" break="yes"/><gml:of offset="4" unit="ch" break="yes"/>2.
  <gml:is spec="to 4ch min 1ch blank" break="no"/>second
  <gml:in left="0" unit="ch" offset="0" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:sk n="0.75" unit="line" break="yes"/><gml:sk n="0.75" unit="line" break="yes"/><gml:in left="8" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:sk n="1" unit="line" break="yes"/><gml:in left="0" unit="ch" break="yes"/><gml:of offset="8" unit="ch" break="yes"/><gml:bf font="hi2" break="no"/>GML
  <gml:pf initial="yes" break="no"/><gml:is spec="to 8ch min 1ch blank" break="no"/>markup
  <gml:in left="0" unit="ch" offset="0" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:sk n="0.75" unit="line" break="yes"/><gml:sk n="1" unit="line" break="yes"/><fig frame="box" place="top"><gml:kp mode="float" break="yes"/><gml:in left="2" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:fo fill="no" align="left" overdraw="extend" break="yes"/><gml:bf font="figfont" restart="yes" break="no"/>picture
  <gml:pf initial="yes" break="no"/><gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/><gml:sk n="1" unit="line" break="yes"/><figcap><gml:bf font="hi2" break="no"/>Figure 1.
  <gml:pf initial="yes" break="no"/>A caption</figcap><gml:fo fill="yes" align="justify" overdraw="extend" break="yes"/><gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/><gml:kp mode="off" break="yes"/></fig><gml:sk n="0.75" unit="line" break="yes"/>See Figure 1 and item 1.
  <gml:in left="0" unit="ch" break="yes"/><gml:ir right="0" unit="ch" break="yes"/></body></gml:doc>

Tags out of context are reported and dropped, their text is kept, and a
list end tag must match the open list.

  $ gml -profile dcfstarter ctx.gml > /dev/null
  ctx.gml:3 (in macro ss@msg line 3, in macro ss@cntx line 1): +++DCFS002W Tag :li is out of context and is ignored.
  ctx.gml:4 (in macro ss@msg line 3, in macro ss@cntx line 1): +++DCFS002W Tag :figcap is out of context and is ignored.
  ctx.gml:7 (in macro ss@msg line 12, in macro f@elst line 5, in macro f@eul line 1): +++DCFS005W Tag :eul does not match the open list :ol.
  [4]
