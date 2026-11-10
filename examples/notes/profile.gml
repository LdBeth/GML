.* profile.gml -- the "notes" tag set: the Starter Set plus a :warn tag
.* and math.  Used through  ./gmlfmt -app examples/notes ...  (or
.* gmlpass, or mk TAGSET=...), which runs gml -profile notes/profile.gml
.* -I notes; the other files of this bundle (resolve.xsl, html.xsl,
.* tex.xsl, tagset.tex) handle the tags in each output.
.*
.* ---- the master profile: chosen by the logical device -----------------
.* One document, one profile per application: the HTML is made from the
.* semantic profile starter (its elements, resolve.xsl and html.xsl do
.* the work), the pages from the formatting profile dcfstarter (its APFs
.* issue control words, TeX runs in hint mode).  The HTML paths (gmlfmt
.* -to html, the examples' mkfile) give gml -set '$LDEV=HTML'; anything
.* else (gmlpass, a PDF) has gml's default device, so dcfstarter.
.* n@sem is 1 under starter, 0 under dcfstarter: the APFs below test it.
.se n@sem = 0
.if &$LDEV eq HTML .se n@sem = 1
.if &n@sem eq 1 .im starter
.if &n@sem eq 0 .im dcfstarter
.*
.* ---- a user-defined tag: :warn level=n.text :ewarn. ---------------------
.* The APF reads its attribute with .gs attval.
.* starter:     the element <warn level=..> is opened automatically, the
.*              label is inserted into the residual text (.gs insert),
.*              which goes inside it; tagset.tex and html.xsl style it.
.* dcfstarter:  no element (the profile's default rules say noelem): the
.*              APF lays it out with control words, like the profile's
.*              :note (IG Figure 5: skip .75; the label in hp2, .bf hi2)
.*              and indented 2 on each side as an example is, through
.*              the profile's absolute margins &f@tm/&f@rm (restored by
.*              :ewarn).
.dm warnapf on
.gs attval level as *lv
.if &L'&*lv eq 0 .se *lv = 1
.if &n@sem eq 0 .go fmt
.if &*lv gt 1 .gs insert Important:&rbl.
.if &*lv eq 1 .gs insert Note:&rbl.
.me
...fmt
.se n@wtm = &f@tm
.se n@wrm = &f@rm
.se f@tm = &f@tm + 2
.se f@rm = &f@rm + 2
.sk .75
.in &f@tm
.ir &f@rm
.bf hi2
.if &*lv gt 1 Important:
.if &*lv eq 1 Note:
.pf
.dm off
.dm ewarnapf on
.if &n@sem eq 1 .me
.se f@tm = &n@wtm
.se f@rm = &n@wrm
.in &f@tm
.ir &f@rm
.sk .75
.dm off
.aa warn warnapf ewarnapf
.* element model (starter): a warning is a block, so it ends an open
.* paragraph
.xd warn closes=p
.*
.* ---- math: :m.TeX:em. inline, :fml id=x.TeX:efml. display, ----------
.* ---- :fmlref refid=x. ------------------------------------------------
.* The math is written in plain-TeX notation and is ordinary residual
.* text: symbols ARE substituted (so values computed by SCRIPT can appear
.* in a formula) and tags are scanned, which is what ends it at :em. or
.* :efml.  So a colon directly followed by a letter must not appear
.* in the math: write \colon (or ": x" with a blank) instead.  An "&"
.* followed by a blank stays a literal "&".
.*   :m.  inline math.
.*   :fml display math, numbered (1), (2) ... in document order unless
.*        num=no; it stays inside the current paragraph (TeX's $$ needs
.*        that).  :efml. may be omitted when the equation ends the
.*        paragraph: whatever closes the paragraph closes it too.
.*   :fmlref refid=x.  "(n)", the number of :fml id=x (resolve.xsl).
.* The elements <m>, <fml>, <fmlref> do the work under both masters,
.* so the rules say elem for the start and the end tag: dcfstarter's
.* default rules say noelem (without an element, :fmlref would leave
.* nothing for resolve.xsl to fill and the math would be plain text).
.* The APFs are empty.  The bundle's resolve.xsl numbers the equations,
.* tex.xsl passes the math to TeX unescaped, tagset.tex typesets it (in
.* element and in hint mode), html.xsl hands it to KaTeX.
.dm mathapf on
.dm off
.aa m mathapf (elem) mathapf (elem)
.aa fml mathapf (elem) mathapf (elem)
.aa fmlref mathapf (elem)
.xd m inline
.* only the top of the element stack is examined, so whatever ends a
.* paragraph must end an open equation first (and a new :fml the old
.* one).  n@blk: the block structures, the list of starter's internal
.* @blk, copied (dcfstarter has no @blk).  Under dcfstarter only those
.* that the profile makes elements of (headings, sections, fig, table
.* ...) can close an equation, so write :efml. there.
.se n@blk 'p,pc,note,lp,li,dthd,ddhd,dt,dd,gt,gd,ol,ul,sl,dl,gl,l,lq,xmp,fig,figcap,figdesc,table,thd,tft,row,c,tnote,tcap,tdesc,tlist,address,h0,h1,h2,h3,h4,h5,h6,titlep,frontm,abstract,preface,toc,figlist,body,appendix,backm,index
.xd fml closedby=&n@blk.,fml
.xd fmlref empty
