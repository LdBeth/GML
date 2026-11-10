.* memo.gml - a memo sent as mail: the memo tag set (share/gmlapp/memo,
.* GML Applications Guide G544-3305 ch.2, with the mail extensions).
.*   ../gmlfmt -app memo -to html memo.gml   the HTML, for a browser
.*   ../gmlfmt -app memo -to mail memo.gml   a line describing the
.*                                              message, then its HTML
:security.Internal
:memodate.10 November 2026
:to name='Daniel Osei' email='d.osei@example.com'.
:to name='Marta Kowalczyk' email='m.kowalczyk@example.com'.
:from name='Hana Kobayashi' email='h.kobayashi@example.com'
  title='IT Services Lead' dept='Infrastructure' phone='555 0144'.
:cc name='Facilities Office' email='facilities@example.com'.
:subject.Weekend backup window moves to Sunday
:ref.Change request CR-2291
:memotxt memtype=internal.
:p.From the weekend of 21 November, the full backup of the file
servers runs on Sunday from 01:00 to 05:00 instead of Saturday night.
The Saturday window clashes with the new month-end batch jobs, which
both slowed down when they ran at the same time.
:p.What this means for your teams:
:ol.
:li.Shared drives are read-only during the window; files can still be
opened, but not saved.
:li.Restore requests made over the weekend are handled on Monday
morning, as before.
:li.Laptops are not affected: their nightly backup does not change.
:eol.
:p.The retention rules stay as they are.  As the storage policy puts
it:
:lq.
:p.Every full backup is kept for twelve weeks, and the last one of
each quarter for seven years.
:elq.
:p.The updated schedule and the reasons for the change are on the
:link href='https://intranet.example.com/it/backup-schedule'.backup
schedule page:elink..  If the new window is a problem for any of your
systems, let me know by Friday so that we can plan around it.
:sign.
