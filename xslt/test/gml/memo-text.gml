.* memo-text.gml - the Starter Set inside :memotxt, written for mail
.* by share/gmlapp/memo/html.xsl: nested ordered and unordered lists
.* (native markers), a list part, a compact list, a simple list, a
.* definition list with headings and termhi, a glossary list, a table
.* with a heading and a note, footnotes (one referred to again by
.* :fnref), an example, a long quotation, nested quotations, headings
.* (one level down), a cross-reference (written as text), links (one
.* without text).
:subject.Notes on the migration
:memotxt.
:h1 id=plan.Plan
:p.The migration has :q.three :q.short:eq. stages:eq., each with its own
:hp2.go/no-go:ehp2. check:fn id=check.Held at 09:00 on the day.:efn..
:ol.
:li.Freeze the old system.
:ol.
:li.Announce the freeze.
:li.Stop the batch jobs.
:eol.
:li.Copy the data.
:lp.This takes most of the weekend.
:li.Switch over.
:eol.
:ul.
:li.Owners
:ul compact.
:li.Data team
:li.Network team
:eul.
:li.Reviewers
:eul.
:sl.
:li.Room 4.12
:li.Bridge line 3
:esl.
:h2.Terms
:dl termhi=1.
:dthd.Term
:ddhd.Meaning
:dt.Freeze
:dd.No changes are made to the old system.
:dt.Cut-over
:dd.The moment the new system takes the traffic.
:edl.
:gl.
:gt.RPO
:gd.How much data we can afford to lose.
:egl.
:rdef id=r cwidths='3* 1*'.
:table refid=r.
:thd.
:c.Stage:c.Hours
:ethd.
:row.
:c.Copy:c.30
:row.
:c.Switch over:c.2
:tnote.Estimates from the rehearsal.
:etnote.
:etable.
:p.The copy job is started with:
:xmp.
copyjob --from old-db --to new-db \
        --parallel 8 --verify
:exmp.
:lq.
:p.Plan for the copy to take twice as long as the rehearsal.
:p.Last year's note
:elq.
:p.See :hdref refid=plan. for the stages, the check:fnref refid=check.
again, :hp1.and:ehp1. :cit.The Runbook:ecit.:fn.Version 3.:efn..
Status is on :link href='https://status.example.net/migration'.the status page:elink.
and :link href='https://status.example.net/'.:elink..
