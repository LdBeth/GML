:gdoc sec='Confidential'.
:frontm.
:titlep.
:title stitle='Layout'.FO Layout
:title.Second Title Line
:docnum.GML-0001
:date.June 13th, 1986
:author.A. Writer
:author.B. Writer
:address.
:aline.1 Main St
:aline.Anytown
:eaddress.
:etitlep.
:abstract.
:p.The abstract.
:preface.
:p.The preface.
:toc.
:figlist.
:body.
:h0 stitle='Part'.Part One
:h1 id=ch1 stitle='Short'.First Chapter
:p.A paragraph with :hp0.hp0:ehp0., :hp1.hp1:ehp1., :hp2.hp2:ehp2., :hp3.hp3:ehp3.,
:cit.a citation:ecit. and :q.outer :q.inner:eq. quote:eq..
:i1 id=ix1.layout
:i2.pages
:i1 pg=major.major entry
:iref refid=ix1 pg=start.
:p.A footnote:fn id=fn1.With an id.:efn. called out by :fnref refid=fn1. and
another:fn.Plain.:efn..
:h2 id=sec2.Second Level
:p.See :hdref refid=sec2 page=yes., :figref refid=fbox. and :liref refid=item2..
:fig id=fbox frame=box place=inline.
Boxed figure
  second line
:figcap.A boxed inline figure
:figdesc.Its description.
:efig.
:fig frame=none place=bottom.
Bottom figure, no frame
:figcap.A bottom figure
:efig.
:fig frame='*-'.
Top figure, character rule
:figcap.A top figure:fn.Footnote in a figure.:efn.
:efig.
:fig width=column.
Column-wide figure
:efig.
:ol.
:li.first
:li id=item2.second
:eol.
:h3.Third Level
:h4.Fourth Level
:h5.Run-in five
:p.The paragraph after a run-in heading.
:h6.Alone six
:note.A note.
:lq.
A long quotation.
:elq.
:xmp.
example  line
:exmp.
:iref refid=ix1 pg=end.
:appendix.
:h1 id=appa.First Appendix
:h2.Appendix section
:p.Text :i1 see='layout'.design.
:backm.
:h1.Glossary
:p.Back matter text.
:index.
:egdoc.
