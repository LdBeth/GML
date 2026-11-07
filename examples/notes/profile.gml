.* profile.gml -- the "notes" tag set: the Starter Set plus a :warn tag.
.* Used through  ./gmlfmt -tagset examples/notes ...  which runs
.* gml -profile notes/profile.gml -I notes; the other files of this
.* bundle (html.xsl, tagset.tex) style :warn in each output.
.im starter
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
.* The automatic elements <m>, <fml>, <fmlref> do the work; the APFs are
.* empty.  The bundle's resolve.xsl numbers the equations, tex.xsl passes
.* the math to TeX unescaped, html.xsl hands it to KaTeX.
.dm mathapf on
.dm off
.aa m mathapf mathapf
.aa fml mathapf mathapf
.aa fmlref mathapf
.xd m inline
.* only the top of the element stack is examined, so whatever ends a
.* paragraph must end an open equation first (and a new :fml the old one)
.xd fml closedby=&@blk.,fml
.xd fmlref empty
