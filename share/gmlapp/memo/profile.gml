.* ------------------------------------------------------------------------
.* profile.gml -- the "memo" tag set: the GML memo application of DCF
.* Release 3.2 (GML Applications Guide G544-3305-00, chapter 2: IBM's
.* profile DSMMPROF, which imbeds DSMPROF3), as a SEMANTIC profile for
.* one application: mail.  Used through  gmlfmt -app memo ...  (the
.* bundle share/gmlapp/memo): html.xsl writes the memo as the HTML of a
.* mail message, mail.xsl the description of the message (headers,
.* HTML, files) that emacs/gml-mail.el makes a Wanderlust draft of.
.*
.* The memo tags (G544-3305 p.6-9), with the Starter Set tags for the
.* text:
.*   :logo logoname='file'                 the logo (an image file)
.*   :to name= company= addr1= addr2=      a receiver (one tag for each)
.*   :from name= addr1= addr2= phone= dept= title=    the sender
.*   :memodate.text   :security.text   :subject.text   :ref.text
.*                    one line each: on the tag's line, or the next
.*   :memotxt memtype=internal|external.   the text of the memo follows
.*   :sign.name       ends the text; the name of the signature
.*   :cc name= addr1= addr2=               the copy list (one tag each)
.* As in IBM's profile the tags before :memotxt only collect: here each
.* is an element, and html.xsl writes them where the memo shows them.
.* A memo is not inside :gdoc (G544-3305 p.10, p.12).
.*
.* EXT, for mail (none of these is in G544-3305):
.*   email='address' on :to :from :cc      the mail address, for the
.*                    To, From and Cc fields of the message
.*   :bcc name= email=                     a blind copy: the Bcc field
.*                    only, never in the text
.*   :attach name='file'                   a file sent with the message
.*   :link href='url'.text:elink.          a hypertext link, in the text
.*   :cc (and :bcc, :attach) may also come before :memotxt, with the
.*                    other tags that collect.
.* Not here: the date of a memo without :memodate (IBM: the current
.* date; a mail message has its Date field), and the page layout that
.* MEMTYPE selects (html.xsl shows the address blocks of an external
.* memo only).
.*
.* Messages are IBM's +++DSMGMLnnnW (SH35-0048-09): 015 for a MEMTYPE
.* that is neither INTERNAL nor EXTERNAL (the default is used:
.* INTERNAL, G544-3305 p.8), 038 for a second :memotxt (ignored).
.* DCF-VERIFY: which messages DSMMPROF itself issues (the Applications
.* Guide's Appendix A is not transcribed).
.* ------------------------------------------------------------------------
.im starter
.*
.* ---- state --------------------------------------------------------------
.* mm@txt: 0 before :memotxt, 1 after it
.se mm@txt = 0
.*
.* ---- element models -----------------------------------------------------
.* the tags that collect are empty elements; one after the text ends
.* what is open there (&@str: starter's open text structures), and so
.* the text of the memo; :memotxt ends what text before it left open
.xd logo empty
.xd to empty
.xd from empty
.xd cc empty closes=&@str
.xd bcc empty closes=&@str
.xd attach empty closes=&@str
.xd memodate eol
.xd security eol
.xd subject eol
.xd ref eol
.xd sign eol closes=&@str
.xd memotxt closes=&@str closedby=sign,cc,bcc,attach
.xd link inline
.*
.* ---- APFs ---------------------------------------------------------------
.dm mm@nul /.*/
.* :memotxt [memtype=internal|external] (a minimum of I or E, p.8)
.dm mm@mtxt on
.gs attval memtype as *m
.if &mm@txt eq 0 .go ok
.mg /&ss@mp.038W/&$GML.MEMOTXT TAG FOUND OUT OF SEQUENCE. (page &$PN)/
.me
...ok
.se mm@txt = 1
.se *t = internal
.if &L'&*m eq 0 .go st
.se *u '&U'&*m
.se *k = &L'&*u
.if &*k gt 8 .go bad
.se *i = substr INTERNAL 1 &*k
.se *e = substr EXTERNAL 1 &*k
.if 'x&*u.' eq 'x&*i.' .go st
.if 'x&*u.' ne 'x&*e.' .go bad
.se *t = external
.go st
...bad
.ss@msg 15 &*m MEMTYPE
...st
.xs memotxt memtype=&*t
.dm off
.* :sign, :cc ... after the text: the structures open there end
.* (DSM#RSET: its messages, the Starter Set's bookkeeping)
.dm mm@end /.dsm#rset/
.*
.* ---- the tag-to-APF mapping ---------------------------------------------
.aa logo mm@nul
.aa to mm@nul
.aa from mm@nul
.aa memodate mm@nul (noatt)
.aa security mm@nul (noatt)
.aa subject mm@nul (noatt)
.aa ref mm@nul (noatt)
.aa memotxt mm@mtxt (noelem)
.aa sign mm@end (noatt)
.aa cc mm@end
.aa bcc mm@end
.aa attach mm@end
.aa link mm@nul mm@nul
