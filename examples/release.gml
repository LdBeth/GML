.* release.gml -- an example GML Starter Set document that also uses the
.* SCRIPT/VS programmable layer: symbols, arithmetic, arrays, macros,
.* conditional text, a loop, and the user-defined tags of the notes tag
.* set in examples/notes/ (:warn, and math: :m, :fml, :fmlref).
.*
.* Build:  ./gmlfmt -tagset examples/notes -to html examples/release.gml
.*         ./gmlfmt -tagset examples/notes -to html -set audience=internal \
.*                  examples/release.gml
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
which runs on &platforms(*)..
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
:p.Contact your sales representative for the support schedule.
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
:p.:hp2.All:ehp2. :hp1.of
this sentence is high:hp3.light:ehp3.ed:ehp1..
Be careful when placing the high:hp3.
light
:ehp3.ed
phrase tags in your text or you :hp1.will:ehp1. get
unexpected spacing results.
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
.* ---- capacity planning: SCRIPT computes the numbers in the formulas ---
.* .se does integer arithmetic; the .go loop sums the warm-up times
.* 1+2+...+n, so the formulas show values the formatter computed.
.se rate = 250
.se workers = 8
.se peak = &rate * &workers
.se load = 1600
.se util = &load * 100 / &peak
.se shards = 12
.se warm = 0
.se k = 0
...warmup
.se k = &k + 1
.se warm = &warm + &k
.if &k lt &shards .go warmup
.se perday = &peak * 86400
:h2 id=cap.Capacity planning
:p.Each worker thread of &product. &version. serves about
:m.r = &rate.:em. requests per second, so a server with
:m.w = &workers.:em. workers handles at most
:fml id=thru.T = w \cdot r = &workers. \cdot &rate. = &peak.
:efml.
requests per second, or &perday. requests a day.
:p.At start-up the &shards. cache shards are warmed one after another,
and shard :m.k:em. takes :m.k:em. seconds, so the warm-up takes
:fml id=warm.\sum_{k=1}^{&shards.} k = {&shards.(&shards.+1)\over 2} = &warm.\ {\rm s}
:efml.
before the server accepts requests.
:p.Plan the offered load :m.\lambda:em. so that the utilisation
:m.\rho:em. stays at or below 0.8.
With :m.\lambda = &load.:em. requests per second and :m.T:em. from
:fmlref refid=thru.,
:fml id=util.\rho = {\lambda \over T} = {&load. \over &peak.} = 0.&util. \le 0.8
:efml.
If :m.\rho:em. in :fmlref refid=util. rises above the limit, add workers:
by :fmlref refid=thru. each one adds &rate. requests per second.
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
