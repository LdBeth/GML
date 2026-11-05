:gdoc.
:frontm.
:titlep.
:title.Test
:etitlep.
:toc.
:figlist.
:preface.
:h1.Preface head
:p.Pre.
:body.
:h1 id=intro.Introduction
:p.Text.:fn id=fa.Footnote with id.:efn. More:fn.Plain footnote.:efn.
See :fnref refid=fa..
:ol.
:li id=l1.one
:li.two
:ol.
:li id=l2.two-a
:ul.
:li.bullet
:ol.
:li id=l3.deep
:eol.
:eul.
:eol.
:eol.
:p.Ref :liref refid=l2. and :liref refid=nope. and :hdref refid=sub page=yes. :hdref refid=bad..
:h2 id=sub.Sub :hp1.section:ehp1.
:fig id=f1.
body
:figcap.First fig
:efig.
:fig.
:figcap.Second
:figdesc.desc
:efig.
:p.:figref refid=f1. :figref refid=f1 page=no. :figref refid=zz..
:i1 id=ia.Apple
:i2 id=ib.Red
:i3.Deep
:i1 pg=major.banana
:ih1 see='Apple'.Fruit
:ih1 seeid=ia.Pome
:iref refid=ia.
:iref refid=ib pg=start.
:i2 refid=ia.Green
.in 5
:p.indented
.bf hi1
font
:h3.Third
:h4.Fourth
:h5.Fifth
:appendix.
:h1 id=appa.Extra
:h2.Appsub
:backm.
:index.
:egdoc.
