.* release.gml -- an example GML Starter Set document that also uses the
.* SCRIPT/VS programmable layer: symbols, arithmetic, arrays, macros,
.* conditional text and a user-defined tag.
.*
.* Build:  ./gmlfmt -to html examples/release.gml
.*         ./gmlfmt -to html -set audience=internal examples/release.gml
.*
.* ---- document symbols --------------------------------------------------
.se product = 'Widget Server'
.se major = 4
.se minor = 2
.se version = &major..&minor
.se nextmin = &minor + 1
.se platforms() = 'z/OS'
.se platforms() = 'z/VM'
.se platforms() = 'Linux on Z'
.* -set audience=internal on the command line overrides this default
.if &E'&audience eq 0 .se audience = customer
.*
.* ---- a counter macro: numbers the "changes" in this release ------------
.se nchg = 0
.dm change on
.se nchg = &nchg + 1
:li.&*
.dm off
.*
.* ---- a user-defined tag: :warn level=n.text :ewarn. ---------------------
.* The APF reads its attribute with .gs attval; the element <warn level=..>
.* is opened automatically and the residual text goes inside it.
.dm warnapf on
.gs attval level as *lv
.if &L'&*lv eq 0 .se *lv = 1
.if &*lv gt 1 .gs insert Important:&rbl.
.if &*lv eq 1 .gs insert Note:&rbl.
.dm off
.dm ewarnapf on
.dm off
.aa warn warnapf ewarnapf
.* element model: a warning is a block, so it ends an open paragraph
.xd warn closes=p
.*
:gdoc sec='&audience.'
:frontm
:titlep
:title.&product. &version.
:title.Release Notes
:docnum.GC00-&major.&minor.00
:date.
:author.The Widget Team
:etitlep
:abstract
:p.This document describes &product. Version &version.,
which runs on &platforms(*).
:toc
:figlist
:body
:h1 id=over.Overview
:p.&product. &version. is a maintenance release.
It contains the changes listed in :hdref refid=changes..
:i1.&product.
:i2.version &version.
.* conditional text: .th/.el govern one line each, so skip with .go
.if &audience ne internal .go public
:p.:hp2.Internal readers::ehp2. the code freeze for
&major..&nextmin is planned for next quarter.
.go endaud
...public
:p.Contact your representative for the support schedule.
...endaud
:h1 id=changes.Changes in &version.
:p.The following changes were made:
:ol
.change Faster start-up:fn id=fn1.Measured on a cold system.:efn.
.change New :q.quiet:eq. start option
.change Fixes for the problems listed in :figref refid=probs.
:eol
:p.This release has &nchg. changes
(see footnote :fnref refid=fn1.).
:warn level=2.Back up the configuration before you upgrade.
:ewarn.
:h2 id=cfg.Configuration
:p.The configuration file now accepts these keywords:
:dl
:dt.timeout
:dd.Seconds to wait for a client (default 30).
:i1.timeout keyword
:dt.quiet
:dd.Suppresses the start-up banner.
:i1.quiet keyword
:edl
:p.An example:
:xmp.
  server  main
    timeout 45
    quiet
:exmp.
:fig id=probs frame=box.
:ul compact
:li.WS0012: crash on empty request
:li.WS0019: wrong date in log
:eul
:figcap.Problems fixed in &version.
:efig
:h2.Platforms
:p.Supported platforms:
:sl
:li.&platforms(1)
:li.&platforms(2)
:li.&platforms(3)
:esl
:warn.All platforms need the latest service level.
:ewarn.
:backm
:index
:egdoc
