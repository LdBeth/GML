.* memo-internal.gml - a full internal memo of the memo tag set
.* (share/gmlapp/memo): every tag that collects, mail addresses (a
.* name with specials, a name with non-ASCII letters, a receiver and a
.* copy without one), the subject on the next line with &amp., MEMTYPE
.* abbreviated, a link and a note in the text, :sign without a name (the
.* sender's), a postscript after it, two attachments.
:logo logoname='images/ops-logo.png'.
:security.Company Confidential
:memodate.12 March 2026
:to name='Okafor, Adaeze' email='a.okafor@example.com'.
:to name='Jürgen Weiß' email='jweiss@example.de'.
:to name='Facilities desk'.
:from name='Rosa Lindqvist' email='rosa.lindqvist@example.com'
  title='Operations Manager' dept='Site Services' phone='+46 8 555 0142'.
:cc name='M. Brennan' email='mbrennan@example.com'.
:cc name='Records office'.
:bcc email='archive@example.com'.
:subject.
Loading dock repairs &amp. delivery times
:ref.Your note of 9 March
:memotxt memtype=i.
:p.The resurfacing of the north loading dock starts on Monday and
takes about two weeks.  Deliveries move to the south gate for that
time; the revised slots are in :link href='https://intranet.example.com/docks?site=2&amp.view=week'.the
dock schedule:elink..
:note.Vehicles over 7.5 tonnes cannot use the south gate before 07:00.
:p.Please pass this on to the suppliers you deal with.
:sign.
:p.P.S. The contractor's site plan is attached.
:attach name='dock-plan.pdf'.
:attach name='slots week 12.xlsx'.
