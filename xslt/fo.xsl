<?xml version="1.0" encoding="UTF-8"?>
<!--
  fo.xsl - scoped GML XML -> XSL-FO 1.1.

  Input: the output of resolve.xsl -> scope.xsl (gml:doc; numbering,
  references, TOC, figure list and index already worked out; the
  set-until-changed formatting state already nested in gml:scope).
  Output: plain XSL-FO 1.1, no vendor extensions.  Vendor extensions go
  in a stylesheet that imports this one and fills in the hook modes
  (see the end of this file, and fo-vendor-ah.xsl).

  The layout follows the Starter Set for page printers (DSMPROF3, the
  3820/4250 definitions; SH35-0050 cited as IG p.n): fonts from IG
  Figure 6 and the DSMPROF3 listing (p.224), indents and skips from IG
  Figure 5 (p.21), headings from IG Figure 14 (p.77), the title page from
  DSM#TIPG (p.51), running heading and footing from DSMPROF3 item 31
  (p.26), page layouts from DSM#STYL (pp.32-34).

  ==== Parameters (the SYSVARs as in DCF, given with -set or -p) =========
    SYSVARS   one | two | offset (or off): the body layout (IG p.30).
              The front matter is one column (offset when the body is
              offset); the back matter (and so the index) is always two
              columns (DSMBACKM, DSMINDEX).
    SYSVARD   no | yes: duplex.  yes: mirrored margins, h0/h1 aligned
              outside and starting on an odd page, odd and even running
              footings (IG p.26).
    SYSVART   right | left | center | no: the title page alignment, or no
              title page.
    paper     letter | a4 (page-width / page-height override it).
    Lengths are FO lengths ("1in", "25mm"); see the xsl:param list below.

  ==== Page masters and page sequences =================================
    gml-title             the title page: region-body only (DSM#TIPG
                          suppresses the running heading and footing).
    gml-odd-N gml-even-N  N = 1 or 2 columns: region-body (column-count
                          N, column-gap = gutter), region-before
                          (running heading), region-after (running
                          footing); odd/even masters differ in margins
                          (duplex) and region names.
    gml-pages-N           page-sequence-master: odd-or-even alternatives.
    One page-sequence per document section, in document order:
      titlep    master gml-title, folio i (counted in the front matter)
      frontm    gml-pages-1, roman folios (format "i")
      body      gml-pages-1 / -2 (SYSVARS), arabic, restarting at 1
      appendix  as body, arabic, continuing
      backm     gml-pages-2, arabic, continuing
    Content outside any section element makes a body-style sequence.
    force-page-count is "auto" in duplex (sections start on odd pages)
    and "no-force" otherwise.

  Running heading and footing (fo:static-content)
    Without .rh/.rf in the document: the heading is the security
    classification (gdoc sec=) centred in the @rh font; the footing is
    the short heading (fo:retrieve-marker "gml-shead": set by the title
    page (stitle= or the title), abstract, preface, toc, figlist, index
    and every h0/h1 (stitle= or the heading text), the last one on the
    page) on the left and the page number on the right; in duplex odd
    pages as that, even pages the page number on the left and the
    document short title on the right.  With .rh/.rf (gml:rh, gml:rf),
    they replace the default: each definition is an fo:marker
    (gml-rh-odd/-even, gml-rf-odd/-even, both unless page=odd|even),
    retrieved with retrieve-boundary="document", so a definition lasts
    until the next one, across sections, as in DCF.  An fo:marker must
    be an initial child of a block, so a definition inside running text
    attaches to the start of the enclosing block (the paragraph).

  ==== Units (DCF dimension -> FO length) ===============================
    Every DCF value is converted to points by this table, except em
    units, which stay em (relative to the font where they are used):
      ch    $ch-width (default 5pt: the figure space of the 10-point body
            font; the Starter Set's indents are counted in it)
      line  $line-height (default 12pt: the body line spacing)
      i 72pt; cm 28.3465pt; mm 2.83465pt; pt 1pt;
      dd    Didot points: 0.376mm = 1.06583pt
      dh dv device units: 1/240 in = 0.3pt
      mh mv em
    A mixed sum ("4ch+1i", "default+1i") is summed term by term.  When it
    has an em part the result is an XSL-FO expression (XSL 1.1 section
    5.9: an AdditiveExpr of lengths is a valid property value, e.g.
    "68pt + 1em"); otherwise a plain "NNpt".  Indents are computed here,
    as absolute start-indent / end-indent values, never with
    inherited-property-value(), so the output does not depend on a
    formatter's expression support except for em sums.

  ==== Formatting state (gml:scope) =====================================
    kind="block" -> fo:block; kind="inline" -> fo:inline, or fo:block
    when it contains block content (a font set before :p. scopes the
    paragraph).  Block properties:
      in  -> start-indent = base + (in - in0) + of, where base is the
             start of the enclosing GML structure and in0 the .in value
             in force when it started (a DCF .in counts from the page
             margin, but the engine does not know the indention of the
             Starter Set's lists; so a change is applied relative to the
             structure, the way the Starter Set macros applied .in +n).
      of  -> start-indent + of, text-indent = -of (a hanging indent; FO
             text-indent is inherited, so every paragraph in the scope
             hangs).
      ir  -> end-indent likewise.  ll -> end-indent + (column width - ll)
             ("default+1i": end-indent - 1in).
      fill=no -> linefeed-treatment="preserve" white-space-collapse=
             "false" white-space-treatment="preserve", wrap-option
             "no-wrap" (overdraw extend|trunc) or "wrap" (fold).  In a
             no-fill block a newline that ends the block (or comes just
             before or after a nested block) is dropped.
      align -> text-align (left start, right end, center, justify,
             inside, outside).
      ls  -> line-height: "by F" = F x $line-height; "normal X" = X; a
             bare amount v (DCF-VERIFY: .ls v adds v between lines, so
             .ls 1 is double spacing) = $line-height + v; skip/space/text
             (vertical justification ranges): $line-height.
      wz  -> widows and orphans: n (.wz n), 1 (.wz off), else 2.
      tp tb (tab stops), bc (column balancing), overdraw trunc: no FO 1.1
             equivalent; ignored.
    Inline properties:
      font -> the font table (below); hy -> hyphenate; sb -> baseline-
      shift; ws "by F" -> word-spacing (F-1) x $space-width, "normal X" ->
      word-spacing X - $space-width (FO word-spacing is added to the
      normal space); es (extra space), ud (underscore definition): no
      equivalent, ignored.

  Fonts: a font name (from .bf, or the Starter Set font of an element:
  hi0-hi3 for :hp0-:hp3, hd0-hd6 for headings, figcap, xmpfont ...) is
  looked up in the .df definitions of the document (gml:df, the last one
  before the use) and then in the built-in table of DSMPROF3's page
  printer fonts.  A definition "type(14 bold italic) up us" gives
  font-size, font-weight, font-style, font-family (a typeface name),
  text-transform uppercase (up), text-decoration underline (us; uc is
  both; os is bold).  "font X" is an alias.  "initial" is the body font.

  ==== Events (hints left by scope.xsl) =================================
    gml:br      mid-paragraph: an empty <fo:block/> (it ends the current
                line; between blocks a break is implied by the structure
                and nothing is written).
    gml:sp/sk   an empty fo:block with space-before = n (line = $line-
                height); .sk and conditional .sp: space-before.
                conditionality="discard" (dropped at the top of a column),
                .sp: "retain".
    gml:pa      an empty fo:block break-before="page" (odd-page/even-page
                for .pa odd|even).  .pa n (renumber) and nostart cannot be
                expressed inside a page-sequence: the break only.
    gml:cp      conditional page eject: FO 1.1 cannot test the space left
                on a page.  Approximation: an empty block with
                keep-with-next.within-page="always" (it only stops a break
                at that point).
    gml:cc gml:cb   break-before="column".
    gml:kp      .kp on ... .kp off: every block whose start lies between
                them gets keep-with-next.within-page="always", except the
                one that contains the .kp off (so the run is kept on one
                page).  float/delay are treated like on (a floating keep
                is not expressible: fo:float moves only whole blocks).
                .kp inline v: an empty fo:block-container of that depth.
    gml:bx      .bx on/new ... .bx off/can: borders on the blocks whose
                start lies between them (start/end borders on all,
                before on the first, after on the one containing .bx
                off).  Column positions are ignored.  .bx with no operand:
                a rule.
    gml:hr      a block with a rule fo:leader.
    gml:rc      .rc n on/off: fo:change-bar-begin / -end (FO 1.1 change
                bars), change-bar-class "rcN".  gml:lines word="rc": the
                covered line between a begin and an end.
    gml:sx      split text: left, a leader of the fill character, right.
    gml:is      inline space: an fo:leader of that width.
    gml:lines   ce -> text-align center, ri -> text-align end, both with
                linefeed-treatment preserve (each input line is a line);
                us -> text-decoration underline, up -> text-transform
                uppercase, uc -> both; il -> text-indent +left, un ->
                text-indent -left.
    gml:h       a heading like hN, not numbered, not in the TOC.
    gml:fn      .fn on/off: an fo:footnote with no callout.
    gml:raw backend="fo"  parsed as XML (with the fo prefix bound to the
                XSL-FO namespace) and copied when it is well-formed and
                contains only XSL-FO elements; otherwise dropped with a
                message.  Other backends: dropped.
    Ignored (no FO 1.1 equivalent; page-level words cannot change a
    page-sequence midway): .in/.ir FOR/AFTER (temporary), .hy options,
    .hw, .tc, .dh, .df (used for the font table), .tr, .vr, .fl, .ic, .ud,
    .dr, .pn .pl .pw .pm .tm .bm, .cl .cd .sc .mc, tabs.

  ==== Elements ==========================================================
    h0-h6       blocks, keep-with-next; gml:num + space + text; h0/h1
                start a page (odd page in duplex), span both columns in
                a two-column layout (when a direct child of the flow) and
                set the gml-shead marker; h5/h6 directly followed by :p
                are run-in (an inline at the start of the paragraph).
                Offset layout: h0-h4 start at the page margin.
    p pc note   blocks, space-before .75 line (sk@p); note: "Note:" in hi2.
    lq          start/end indent +3ch, 1 line before/after, lqfont.
    xmp         start-indent +2ch, 1 line before/after, xmpfont
                (monospace 9pt), preserved lines, no wrap.
    q           quotes (“ ” alternating with ‘ ’ by nesting); cit hi1;
                hp0-hp3 hi0-hi3.
    ol ul sl dl fo:list-block, provisional-distance-between-starts = the
                list indent (IG Figure 5: ol ul sl 4ch, dl tsize= or
                10ch), label at the enclosing indent (the Starter Set
                outdents the identifier); items space-before .75 line, 0
                with compact.  ol labels: gml:num; ul: $ul-identifiers by
                nest; dl: dt (termhi=, default hi2) / dthd ddhd (headhi=,
                hi3); dl break: the description on its own line under the
                term (a block, not a list item).  Scopes between a list
                and its items are applied to the items.
    gl          not a list-block: each term (hi2) + ":" + no-break space
                + definition is a paragraph (DSMGDEF; glossary indent 0).
    fig         frame=rule (default; rules above and below), box, none,
                or a string (an fo:leader use-content rule of it above and
                below); place=top -> fo:float float="before"; inline ->
                a keep-together block in place; bottom -> FO 1.1 has no
                float to the page foot: an in-place block (vendor
                stylesheets may do better); body indented 2ch, unfilled
                ($fig-fill); figcap figcap font, figdesc figdesc font.
                A footnote inside a figure (fo:float may not contain
                fo:footnote) is written in place, in brackets.
    fn          fo:footnote: the callout (gml:num, superscript) when
                callout="yes", otherwise an empty inline (:fnref calls it
                out); the body in fnt (9pt) with its number.
    hdref figref liref   fo:basic-link to the target, with the resolved
                text; fnref a superscript link.
    gml:pageref fo:page-number-citation ref-id=refid, after the label
                ("on page").  when="auto" (print only when the target is
                on another page) is always printed: FO 1.1 cannot compare
                page numbers.  Index: major="yes" bold, text= printed
                instead of the number (still a link), a range end joined
                to its start with an en dash; references are separated by
                commas.  A refid whose target has no id in the output
                prints "?".
    toc figlist the entries as blocks with a dot leader and a
                page-number-citation, linked; TOC levels indented by
                $toc-indent per level below 1, hd0toc/hd1toc fonts.
    index       letter groups (ieh font heading, none for the "" group),
                entries indented by level with a hanging indent; See /
                See also in italics.
    i1-i3 ih1-ih3 iref   an empty fo:inline with id=anchor (an empty
                fo:block in block context).
    titlep      its own page-sequence: 2in down, the title lines (title
                font, line-height 1.2), 2in, then "Document Number"
                docnum, date, authors, addresses, the classification,
                aligned by SYSVART.
    abstract preface   a new page with an h1-style heading ("Abstract",
                "Preface"), as DSMABSTR/DSMPREF.

  ==== What plain XSL-FO 1.1 cannot say (documented approximations) =====
    pageref when=auto; .cp n; floating keeps; figures at the page foot;
    a running heading that changes in the middle of a paragraph; tabs
    (.tp/.tb); column balancing (.bc); .sc/.mc mid-page; .pa n
    renumbering; footnotes in figures; DCF's per-input-line .ce of filled
    text is done with preserved linefeeds; .kp/.bx brackets are applied to
    whole blocks.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:f="urn:x-gml:fo"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <!-- ==== parameters ================================================== -->
  <xsl:param name="SYSVARS" as="xs:string" select="'one'"/>
  <xsl:param name="SYSVARD" as="xs:string" select="'no'"/>
  <xsl:param name="SYSVART" as="xs:string" select="'right'"/>
  <xsl:param name="paper" as="xs:string" select="'letter'"/>
  <xsl:param name="page-width" as="xs:string" select="''"/>
  <xsl:param name="page-height" as="xs:string" select="''"/>
  <xsl:param name="margin-top" as="xs:string" select="'0.5in'"/>
  <xsl:param name="margin-bottom" as="xs:string" select="'0.5in'"/>
  <xsl:param name="margin-inner" as="xs:string" select="'1in'"/>
  <xsl:param name="margin-outer" as="xs:string" select="'1in'"/>
  <xsl:param name="header-extent" as="xs:string" select="'0.5in'"/>
  <xsl:param name="footer-extent" as="xs:string" select="'0.5in'"/>
  <!-- the gutter between columns: 4 spaces (&@gutter) -->
  <xsl:param name="gutter" as="xs:string" select="'4ch'"/>
  <xsl:param name="backm-columns" as="xs:string" select="'2'"/>
  <xsl:param name="font-family" as="xs:string" select="'serif'"/>
  <xsl:param name="mono-family" as="xs:string" select="'monospace'"/>
  <xsl:param name="font-size" as="xs:string" select="'10pt'"/>
  <!-- DCF units -->
  <xsl:param name="ch-width" as="xs:string" select="'5pt'"/>
  <xsl:param name="line-height" as="xs:string" select="'12pt'"/>
  <!-- the width of a normal word space, for .ws -->
  <xsl:param name="space-width" as="xs:string" select="'0.25em'"/>
  <xsl:param name="language" as="xs:string" select="'en'"/>
  <xsl:param name="hyphenate" as="xs:string" select="'false'"/>
  <xsl:param name="fig-fill" as="xs:string" select="'no'"/>
  <xsl:param name="toc-indent" as="xs:string" select="'2ch'"/>
  <xsl:param name="ul-identifiers" as="xs:string" select="'• – ∗ · ◦'"/>
  <xsl:param name="quotes" as="xs:string" select="'“ ” ‘ ’'"/>
  <xsl:param name="rule-width" as="xs:string" select="'0.3mm'"/>
  <!-- the footnote leader: 16 spaces (&@fnldrlen) -->
  <xsl:param name="fn-leader" as="xs:string" select="'16ch'"/>
  <xsl:param name="change-bar-offset" as="xs:string" select="'2ch'"/>
  <!-- a checking stylesheet run on the result (relative to this file), e.g.
       check=test/fo/check.xsl; its error lines become xsl:messages -->
  <xsl:param name="check" as="xs:string" select="''"/>
  <xsl:param name="check-allow-ns" as="xs:string" select="''"/>
  <!-- literals (DSM#SETS &LL@...) -->
  <xsl:param name="lit-note" as="xs:string" select="'Note:'"/>
  <xsl:param name="lit-abstract" as="xs:string" select="'Abstract'"/>
  <xsl:param name="lit-preface" as="xs:string" select="'Preface'"/>
  <xsl:param name="lit-docnum" as="xs:string" select="'Document Number'"/>

  <!-- ==== derived values ============================================== -->
  <xsl:variable name="f:duplex" as="xs:boolean" select="lower-case($SYSVARD) = 'yes'"/>
  <xsl:variable name="f:style" as="xs:string"
      select="let $s := lower-case(normalize-space($SYSVARS))
              return if ($s = ('two', '2')) then 'two'
                     else if ($s = ('offset', 'off')) then 'offset' else 'one'"/>
  <xsl:variable name="f:title-align" as="xs:string" select="lower-case(normalize-space($SYSVART))"/>
  <xsl:variable name="f:pw" as="xs:double"
      select="if ($page-width ne '') then f:pt($page-width)
              else if (lower-case($paper) = 'a4') then f:pt('210mm') else f:pt('8.5in')"/>
  <xsl:variable name="f:ph" as="xs:double"
      select="if ($page-height ne '') then f:pt($page-height)
              else if (lower-case($paper) = 'a4') then f:pt('297mm') else f:pt('11in')"/>
  <xsl:variable name="f:ch" as="xs:double" select="f:pt($ch-width)"/>
  <xsl:variable name="f:line" as="xs:double" select="f:pt($line-height)"/>
  <xsl:variable name="f:base-size" as="xs:double" select="f:pt($font-size)"/>
  <xsl:variable name="f:gap" as="xs:double" select="f:dim($gutter)[1]"/>
  <!-- the width of the text area (one column) -->
  <xsl:variable name="f:width" as="xs:double"
      select="$f:pw - f:pt($margin-inner) - f:pt($margin-outer)"/>
  <xsl:variable name="f:rule" as="xs:double" select="f:pt($rule-width)"/>
  <xsl:variable name="f:q" select="tokenize(normalize-space(translate($quotes, ',', ' ')), ' ')"/>
  <xsl:variable name="f:ul-ids" select="tokenize(normalize-space(translate($ul-identifiers, ',', ' ')), ' ')"/>
  <xsl:variable name="f:fo-ns" select="'http://www.w3.org/1999/XSL/Format'"/>

  <!-- the document: the gdoc, or the root -->
  <xsl:variable name="f:gdoc" as="element()" select="(/gml:doc/gdoc, /*)[1]"/>
  <xsl:variable name="f:has-rh" as="xs:boolean" select="exists(//gml:rh[node()])"/>
  <xsl:variable name="f:has-rf" as="xs:boolean" select="exists(//gml:rf[node()])"/>
  <xsl:variable name="f:title" as="xs:string"
      select="normalize-space(string-join((//titlep/title)[1]/(@stitle, .)[1], ''))"/>

  <xsl:key name="f:anchor" match="*[@anchor]" use="string(@anchor)"/>

  <!-- ==== lengths ===================================================== -->
  <!-- an FO length parameter ("1in", "25mm", "10pt", "2pc", "4ch") -> points -->
  <xsl:function name="f:pt" as="xs:double">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="m" select="replace(normalize-space($s), '^([+-]?[0-9]*\.?[0-9]+)\s*([a-z]*)$', '$1 $2')"/>
    <xsl:variable name="n" select="xs:double(substring-before($m, ' '))"/>
    <xsl:variable name="u" select="substring-after($m, ' ')"/>
    <xsl:sequence select="if (not(contains($m, ' '))) then 0
        else $n * (if ($u = ('in', 'i')) then 72 else if ($u = 'cm') then 28.346457
                   else if ($u = 'mm') then 2.8346457 else if ($u = 'pc') then 12
                   else if ($u = 'ch') then f:pt($ch-width) else 1)"/>
  </xsl:function>

  <!-- a DCF dimension ("4ch", "-1.5i", "4ch+1i", "0") -> (points, ems) -->
  <xsl:function name="f:dim" as="xs:double+">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:variable name="terms" as="xs:double*">
      <xsl:analyze-string select="replace(string($s), '\s+', '')"
          regex="([+-]?)([0-9]*[.,]?[0-9]+)([a-z]*)">
        <xsl:matching-substring>
          <xsl:variable name="v" select="xs:double(translate(regex-group(2), ',', '.'))
                                         * (if (regex-group(1) = '-') then -1 else 1)"/>
          <xsl:variable name="u" select="regex-group(3)"/>
          <xsl:choose>
            <xsl:when test="$u = ('mh', 'mv', 'm', 'em')"><xsl:sequence select="0, $v"/></xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$v * (
                  if ($u = ('ch', '')) then $f:ch
                  else if ($u = 'line') then $f:line
                  else if ($u = ('i', 'in')) then 72
                  else if ($u = 'cm') then 28.346457
                  else if ($u = 'mm') then 2.8346457
                  else if ($u = 'pt') then 1
                  else if ($u = 'pc') then 12
                  else if ($u = 'dd') then 1.0658268
                  else if ($u = ('dh', 'dv')) then 0.3
                  else 0), 0"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="sum($terms[position() mod 2 = 1]), sum($terms[position() mod 2 = 0])"/>
  </xsl:function>

  <!-- pair arithmetic: lengths are (points, ems) -->
  <xsl:function name="f:add" as="xs:double+">
    <xsl:param name="a" as="xs:double+"/>
    <xsl:param name="b" as="xs:double+"/>
    <xsl:sequence select="$a[1] + $b[1], $a[2] + $b[2]"/>
  </xsl:function>
  <xsl:function name="f:sub" as="xs:double+">
    <xsl:param name="a" as="xs:double+"/>
    <xsl:param name="b" as="xs:double+"/>
    <xsl:sequence select="$a[1] - $b[1], $a[2] - $b[2]"/>
  </xsl:function>
  <xsl:function name="f:num" as="xs:string">
    <xsl:param name="n" as="xs:double"/>
    <xsl:sequence select="format-number(round($n * 1000) div 1000, '0.###')"/>
  </xsl:function>
  <!-- the FO value of a pair: "12pt", "-1em", "12pt + 1em", "12pt - 1em" -->
  <xsl:function name="f:len" as="xs:string">
    <xsl:param name="a" as="xs:double+"/>
    <xsl:variable name="p" select="round($a[1] * 1000) div 1000"/>
    <xsl:variable name="e" select="round($a[2] * 1000) div 1000"/>
    <xsl:sequence select="
        if ($e = 0) then concat(f:num($p), 'pt')
        else if ($p = 0) then concat(f:num($e), 'em')
        else concat(f:num($p), 'pt ', if ($e lt 0) then '- ' else '+ ', f:num(abs($e)), 'em')"/>
  </xsl:function>
  <xsl:function name="f:pts" as="xs:string">
    <xsl:param name="n" as="xs:double"/>
    <xsl:sequence select="f:len(($n, 0))"/>
  </xsl:function>
  <!-- n lines -->
  <xsl:function name="f:lines" as="xs:string">
    <xsl:param name="n" as="xs:double"/>
    <xsl:sequence select="f:pts($n * $f:line)"/>
  </xsl:function>
  <xsl:function name="f:chs" as="xs:double+">
    <xsl:param name="n" as="xs:double"/>
    <xsl:sequence select="$n * $f:ch, 0"/>
  </xsl:function>
  <!-- a hint amount: n + unit -->
  <xsl:function name="f:amount" as="xs:double+">
    <xsl:param name="h" as="element()"/>
    <xsl:sequence select="if ($h/@n) then f:dim(concat($h/@n, if ($h/@unit = 'mixed') then '' else ($h/@unit, 'line')[1]))
                          else ($f:line, 0)"/>
  </xsl:function>
  <!-- the words of a spec attribute ("by 1.5" -> "by", "1.5") -->
  <xsl:function name="f:words" as="xs:string*">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:sequence select="tokenize(normalize-space(string($s)), ' ')"/>
  </xsl:function>
  <!-- the factor of a BY operand (.ls by f, .ws by f), kept as written -->
  <xsl:function name="f:by" as="xs:double?">
    <xsl:param name="w" as="xs:string*"/>
    <xsl:sequence select="if ($w[1] = 'by' and $w[2] castable as xs:double) then xs:double($w[2]) else ()"/>
  </xsl:function>

  <!-- ==== layout state ================================================ -->
  <!-- The state tunnelled down the tree (map):
         L in0 in of   start side: base, .in at the base, .in, .of (pairs)
         R ir0 ir      end side
         llx           end-indent added by .ll (pair)
         W             the column width (points)
         nofill overdraw  fill mode
         section cols  the page-sequence kind and its column count
         qd            :q nesting depth
         noids nofn    in a marker, TOC entry (no ids) / a float or
                       footnote (no footnotes) -->
  <xsl:function name="f:S0" as="xs:double+">
    <xsl:param name="st" as="map(*)"/>
    <xsl:sequence select="f:add($st?L, f:sub($st?in, $st?in0))"/>
  </xsl:function>
  <xsl:function name="f:E0" as="xs:double+">
    <xsl:param name="st" as="map(*)"/>
    <xsl:sequence select="f:add($st?R, f:sub($st?ir, $st?ir0))"/>
  </xsl:function>
  <xsl:function name="f:start" as="xs:string">
    <xsl:param name="st" as="map(*)"/>
    <xsl:sequence select="f:len(f:add(f:S0($st), $st?of))"/>
  </xsl:function>
  <xsl:function name="f:end" as="xs:string">
    <xsl:param name="st" as="map(*)"/>
    <xsl:sequence select="f:len(f:add(f:E0($st), $st?llx))"/>
  </xsl:function>

  <!-- entering a structure indented by $s (start) and $e (end) -->
  <xsl:function name="f:enter" as="map(*)">
    <xsl:param name="st" as="map(*)"/>
    <xsl:param name="s" as="xs:double+"/>
    <xsl:param name="e" as="xs:double+"/>
    <xsl:sequence select="map:merge((map {
        'L': f:add(f:S0($st), $s), 'in0': $st?in, 'of': (0, 0),
        'R': f:add(f:E0($st), $e), 'ir0': $st?ir }, $st), map { 'duplicates': 'use-first' })"/>
  </xsl:function>

  <!-- the state inside a gml:scope -->
  <xsl:function name="f:scope-state" as="map(*)">
    <xsl:param name="st" as="map(*)"/>
    <xsl:param name="sc" as="element(gml:scope)"/>
    <xsl:sequence select="map:merge((
        if ($sc/@in) then map { 'in': f:dim($sc/@in) } else (),
        if ($sc/@ir) then map { 'ir': f:dim($sc/@ir) } else (),
        if ($sc/@of) then map { 'of': f:dim($sc/@of) } else (),
        if ($sc/@ll) then map { 'llx': f:llx(string($sc/@ll), $st?W) } else (),
        if ($sc/@fill) then map { 'nofill': $sc/@fill = 'no' } else (),
        if ($sc/@overdraw) then map { 'overdraw': string($sc/@overdraw) } else (),
        $st), map { 'duplicates': 'use-first' })"/>
  </xsl:function>

  <xsl:function name="f:llx" as="xs:double+">
    <xsl:param name="ll" as="xs:string"/>
    <xsl:param name="W" as="xs:double"/>
    <xsl:sequence select="if (starts-with($ll, 'default')) then f:sub((0, 0), f:dim(substring-after($ll, 'default')))
                          else f:sub(($W, 0), f:dim($ll))"/>
  </xsl:function>

  <xsl:function name="f:initial-state" as="map(*)">
    <xsl:param name="section" as="xs:string"/>
    <xsl:param name="cols" as="xs:integer"/>
    <xsl:variable name="W" select="if ($cols gt 1) then ($f:width - $f:gap * ($cols - 1)) div $cols else $f:width"/>
    <xsl:variable name="off" select="if ($f:style = 'offset' and $cols = 1) then $W div 5 else 0"/>
    <xsl:sequence select="map {
        'L': ($off, 0), 'in0': (0, 0), 'in': (0, 0), 'of': (0, 0),
        'R': (0, 0), 'ir0': (0, 0), 'ir': (0, 0), 'llx': (0, 0),
        'W': $W - $off, 'margin': $off,
        'nofill': false(), 'overdraw': 'extend',
        'section': $section, 'cols': $cols, 'qd': 0,
        'noids': false(), 'nofn': false() }"/>
  </xsl:function>

  <!-- ==== fonts ======================================================= -->
  <!-- DSMPROF3, the 3820/4250 page printer definitions (IG p.224) -->
  <xsl:variable name="f:fonts" as="map(xs:string, xs:string)" select="map {
      'hi0': 'type(normal)', 'hi1': 'type(italic)', 'hi2': 'type(bold)', 'hi3': 'type(bold italic)',
      'althi1': 'us', 'althi2': 'up', 'althi3': 'uc',
      'hd0': 'type(20 bold italic)', 'hd1': 'type(20 bold)', 'hd2': 'type(18 bold italic)',
      'hd3': 'type(14 bold)', 'hd4': 'type(12 bold italic)', 'hd5': 'type(bold)', 'hd6': 'type(bold italic)',
      'hd0toc': 'type(10 bold) up', 'hd1toc': 'type(10 bold)', 'hd2toc': 'type(10)', 'hd3toc': 'type(10)',
      '@rh': 'type(bold italic 9) up', '@rf': 'type(bold 9)', 'ieh': 'type(14 bold)',
      'super': 'type(6)', 'fnt': 'type(9)',
      'title': 'type(24 bold) up', 'author': 'type(12)', 'address': 'type(10)',
      'date': 'type(11 italic)', 'docnum': 'type(10 italic)', 'titlesec': 'type(10 italic bold)',
      'figcap': 'type(9 bold)', 'figdesc': 'type(9)', 'lqfont': 'type(9)',
      'xmpfont': 'type(mono 9)' }"/>

  <!-- the definition of a font name at $ctx: the last .df before it, or the table -->
  <xsl:function name="f:font-def" as="xs:string?">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:variable name="n" select="lower-case($name)"/>
    <xsl:sequence select="(($ctx/preceding::gml:df[lower-case(@name) = $n])[last()]/string(@spec), $f:fonts($n))[1]"/>
  </xsl:function>

  <!-- the FO attributes of a font (a list of names: the first one defined) -->
  <xsl:function name="f:font" as="attribute()*">
    <xsl:param name="names" as="xs:string"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:variable name="ns" select="tokenize(normalize-space($names), ' ')"/>
    <xsl:choose>
      <xsl:when test="$ns[1] = 'initial'">
        <xsl:attribute name="font-family" select="$font-family"/>
        <xsl:attribute name="font-size" select="f:pts($f:base-size)"/>
        <xsl:attribute name="font-weight" select="'normal'"/>
        <xsl:attribute name="font-style" select="'normal'"/>
        <xsl:attribute name="text-transform" select="'none'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="def" select="(for $n in $ns return f:font-def($n, $ctx))[1]"/>
        <xsl:if test="exists($def)">
          <xsl:sequence select="f:font-spec($def, $ctx, 0)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="f:font-spec" as="attribute()*">
    <xsl:param name="spec" as="xs:string"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:param name="depth" as="xs:integer"/>
    <xsl:variable name="s" select="lower-case(normalize-space($spec))"/>
    <xsl:variable name="type" select="if (matches($s, 'type\s*\(')) then replace(replace($s, '^.*type\s*\(', ''), '\).*$', '') else ''"/>
    <xsl:variable name="rest" select="tokenize(normalize-space(replace($s, 'type\s*\([^)]*\)?', ' ')), ' ')"/>
    <xsl:variable name="tt" select="tokenize(normalize-space(translate($type, '''&quot;', '  ')), ' ')"/>
    <xsl:variable name="alias" select="$rest[index-of($rest, 'font')[1] + 1]"/>
    <xsl:if test="exists($alias) and $depth lt 5">
      <xsl:variable name="d" select="f:font-def($alias, $ctx)"/>
      <xsl:if test="exists($d)"><xsl:sequence select="f:font-spec($d, $ctx, $depth + 1)"/></xsl:if>
    </xsl:if>
    <xsl:variable name="size" select="$tt[matches(., '^[+-]?[0-9]+(\.[0-9]+)?$')][1]"/>
    <xsl:if test="exists($size)">
      <xsl:attribute name="font-size" select="f:pts(if (matches($size, '^[+-]')) then $f:base-size + xs:double($size) else xs:double($size))"/>
    </xsl:if>
    <xsl:if test="$tt = 'normal'">
      <xsl:attribute name="font-weight" select="'normal'"/>
      <xsl:attribute name="font-style" select="'normal'"/>
    </xsl:if>
    <xsl:if test="$tt = ('bold', 'demi', 'heavy') or $rest = 'os'"><xsl:attribute name="font-weight" select="'bold'"/></xsl:if>
    <xsl:if test="$tt = ('light')"><xsl:attribute name="font-weight" select="'lighter'"/></xsl:if>
    <xsl:if test="$tt = ('medium')"><xsl:attribute name="font-weight" select="'normal'"/></xsl:if>
    <xsl:if test="$tt = ('italic', 'oblique')"><xsl:attribute name="font-style" select="'italic'"/></xsl:if>
    <xsl:variable name="family" select="$tt[not(. = ('normal', 'bold', 'demi', 'heavy', 'light', 'medium', 'italic', 'oblique'))]
                                           [not(matches(., '^[+-]?[0-9]'))]"/>
    <xsl:if test="exists($family)">
      <xsl:attribute name="font-family" select="if ($family = ('mono', 'monospace', 'courier', 'prestige')) then $mono-family
                                                else string-join($family, ' ')"/>
    </xsl:if>
    <xsl:if test="$rest = ('us', 'uc')"><xsl:attribute name="text-decoration" select="'underline'"/></xsl:if>
    <xsl:if test="$rest = ('up', 'uc')"><xsl:attribute name="text-transform" select="'uppercase'"/></xsl:if>
  </xsl:function>

  <!-- ==== node kinds ================================================== -->
  <xsl:variable name="f:block-names" select="('p', 'pc', 'note', 'lq', 'xmp', 'fig', 'figcap', 'figdesc',
      'ol', 'ul', 'sl', 'dl', 'gl', 'l', 'li', 'lp', 'dt', 'dd', 'dthd', 'ddhd', 'gt', 'gd',
      'h0', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'titlep', 'title', 'docnum', 'date', 'author',
      'address', 'aline', 'abstract', 'preface', 'toc', 'figlist', 'index',
      'frontm', 'body', 'appendix', 'backm', 'gdoc', 'psc')"/>
  <xsl:variable name="f:anchor-names" select="('i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>
  <xsl:variable name="f:block-hints" select="('h', 'sp', 'sk', 'pa', 'cp', 'cc', 'cb', 'hr', 'sx')"/>
  <xsl:variable name="f:inline-hints" select="('fn', 'pageref', 'num', 'rc', 'is', 'entry-text')"/>

  <!-- block | inline | anchor | none: how a node goes into a block-only context -->
  <xsl:function name="f:kind" as="xs:string">
    <xsl:param name="n" as="node()"/>
    <xsl:choose>
      <xsl:when test="$n instance of text()">
        <xsl:sequence select="if (normalize-space($n) = '') then 'none' else 'inline'"/>
      </xsl:when>
      <xsl:when test="not($n instance of element())"><xsl:sequence select="'none'"/></xsl:when>
      <xsl:when test="$n/self::gml:scope[f:mid-text-scope(.)]"><xsl:sequence select="'inline'"/></xsl:when>
      <xsl:when test="$n/self::gml:scope">
        <xsl:sequence select="if ($n/@kind = 'block' or (some $c in $n/node() satisfies f:kind($c) = 'block'))
                              then 'block' else 'inline'"/>
      </xsl:when>
      <xsl:when test="$n/self::gml:lines">
        <xsl:sequence select="if ($n/@word = ('ce', 'ri', 'il', 'un')
                                  or (some $c in $n/node() satisfies f:kind($c) = 'block'))
                              then 'block' else 'inline'"/>
      </xsl:when>
      <xsl:when test="$n/self::gml:rh or $n/self::gml:rf"><xsl:sequence select="'anchor'"/></xsl:when>
      <xsl:when test="$n/self::gml:raw"><xsl:sequence select="f:raw-kind($n)"/></xsl:when>
      <xsl:when test="$n/self::gml:kp[@mode = 'inline' and @depth]"><xsl:sequence select="'block'"/></xsl:when>
      <xsl:when test="$n/self::gml:bx[@action = 'line']"><xsl:sequence select="'block'"/></xsl:when>
      <xsl:when test="namespace-uri($n) = 'urn:x-gml:canonical'">
        <xsl:sequence select="if (local-name($n) = $f:block-hints) then 'block'
                              else if (local-name($n) = $f:inline-hints) then 'inline' else 'none'"/>
      </xsl:when>
      <xsl:when test="local-name($n) = $f:block-names"><xsl:sequence select="'block'"/></xsl:when>
      <xsl:when test="local-name($n) = $f:anchor-names"><xsl:sequence select="'anchor'"/></xsl:when>
      <xsl:when test="local-name($n) = ('hp0', 'hp1', 'hp2', 'hp3', 'q', 'cit', 'fn',
                                         'hdref', 'figref', 'fnref', 'liref')">
        <xsl:sequence select="'inline'"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- an element that is not a Starter Set tag: by its content -->
        <xsl:sequence select="if (some $c in $n/node() satisfies f:kind($c) = 'block') then 'block' else 'inline'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- a block scope set by non-breaking hints only (tabs, .ls, .wz, .bc),
       starting in running text: an inline, so that no line break is made -->
  <xsl:function name="f:mid-text-scope" as="xs:boolean">
    <xsl:param name="sc" as="element(gml:scope)"/>
    <xsl:variable name="prev" select="$sc/preceding-sibling::node()[1]"/>
    <xsl:sequence select="$sc/@kind = 'block'
        and empty($sc/@*[not(local-name() = ('kind', 'tp', 'tb', 'bc', 'ls', 'wz'))])
        and not($sc/node()[1][self::gml:br])
        and exists($prev) and f:kind($prev) = 'inline'
        and not(some $c in $sc/node() satisfies f:kind($c) = 'block')"/>
  </xsl:function>

  <!-- the parsed content of a gml:raw backend="fo", or () -->
  <xsl:function name="f:raw" as="node()*">
    <xsl:param name="r" as="element(gml:raw)"/>
    <xsl:if test="$r/@backend = 'fo'">
      <xsl:try>
        <xsl:variable name="d" select="parse-xml(concat('&lt;gml-raw xmlns:fo=&quot;', $f:fo-ns, '&quot;&gt;', string($r), '&lt;/gml-raw&gt;'))"/>
        <xsl:sequence select="if (every $e in $d/*/descendant::* satisfies namespace-uri($e) = $f:fo-ns)
                              then $d/*/node() else ()"/>
        <xsl:catch/>
      </xsl:try>
    </xsl:if>
  </xsl:function>

  <xsl:function name="f:raw-kind" as="xs:string">
    <xsl:param name="r" as="element(gml:raw)"/>
    <xsl:variable name="c" select="f:raw($r)"/>
    <xsl:sequence select="if (empty($c)) then 'none'
        else if (every $n in $c satisfies ($n instance of element() and local-name($n) = ('block', 'block-container', 'list-block', 'table', 'table-and-caption'))
                 or ($n instance of text() and normalize-space($n) = ''))
        then 'block' else 'inline'"/>
  </xsl:function>

  <!-- the nearest ancestor of $n that writes a block for its content -->
  <xsl:function name="f:owner" as="element()?">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="$n/ancestor::*[f:kind(.) = 'block'][1]"/>
  </xsl:function>

  <!-- is this pageref target written with an id? -->
  <xsl:function name="f:citable" as="xs:boolean">
    <xsl:param name="ctx" as="node()"/>
    <xsl:param name="refid" as="xs:string"/>
    <xsl:sequence select="exists(key('f:anchor', $refid, root($ctx))[not(ancestor::gml:rh or ancestor::gml:rf)])"/>
  </xsl:function>

  <!-- .kp and .bx brackets: the opening hint whose range contains the start of $e -->
  <xsl:function name="f:open-kp" as="element()?">
    <xsl:param name="e" as="node()?"/>
    <xsl:sequence select="($e/preceding::gml:kp[not(@mode = 'inline')])[last()][@mode = ('on', 'float', 'delay')]"/>
  </xsl:function>
  <xsl:function name="f:open-bx" as="element()?">
    <xsl:param name="e" as="node()?"/>
    <xsl:sequence select="($e/preceding::gml:bx[@action = ('on', 'new', 'off', 'can')])[last()][@action = ('on', 'new')]"/>
  </xsl:function>

  <!-- ==== the document ================================================ -->
  <xsl:template match="/">
    <xsl:variable name="result">
      <fo:root font-family="{$font-family}" font-size="{f:pts($f:base-size)}"
          line-height="{f:pts($f:line)}" text-align="justify" hyphenate="{$hyphenate}"
          language="{$language}">
        <xsl:apply-templates select="." mode="f:root-attrs"/>
        <xsl:call-template name="f:layout-master-set"/>
        <xsl:call-template name="f:page-sequences"/>
      </fo:root>
    </xsl:variable>
    <xsl:sequence select="$result"/>
    <!-- check=URI: run a checking stylesheet (xslt/test/fo/check.xsl) on
         the result and report each error line with xsl:message -->
    <xsl:if test="$check ne ''">
      <xsl:variable name="check-src">
        <xsl:processing-instruction name="fo-check-allow-ns" select="$check-allow-ns"/>
        <xsl:sequence select="$result"/>
      </xsl:variable>
      <xsl:variable name="report" select="transform(map {
          
          'stylesheet-location': resolve-uri($check, static-base-uri()),
          'source-node': $check-src})?output"/>
      <xsl:for-each select="tokenize(string($report), '\n')[normalize-space()][not(matches(., '^(ok: |[0-9]+ errors$)'))]">
        <xsl:message>fo-check: <xsl:value-of select="."/></xsl:message>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template name="f:layout-master-set">
    <fo:layout-master-set>
      <fo:simple-page-master master-name="gml-title" page-width="{f:pts($f:pw)}" page-height="{f:pts($f:ph)}"
          margin-top="{$margin-top}" margin-bottom="{$margin-bottom}"
          margin-left="{$margin-inner}" margin-right="{$margin-outer}">
        <fo:region-body/>
      </fo:simple-page-master>
      <xsl:for-each select="1, 2">
        <xsl:variable name="n" select="."/>
        <xsl:for-each select="'odd', 'even'">
          <xsl:variable name="mirror" select=". = 'even' and $f:duplex"/>
          <fo:simple-page-master master-name="gml-{.}-{$n}" page-width="{f:pts($f:pw)}" page-height="{f:pts($f:ph)}"
              margin-top="{$margin-top}" margin-bottom="{$margin-bottom}"
              margin-left="{if ($mirror) then $margin-outer else $margin-inner}"
              margin-right="{if ($mirror) then $margin-inner else $margin-outer}">
            <fo:region-body margin-top="{$header-extent}" margin-bottom="{$footer-extent}">
              <xsl:if test="$n gt 1">
                <xsl:attribute name="column-count" select="$n"/>
                <xsl:attribute name="column-gap" select="f:pts($f:gap)"/>
              </xsl:if>
            </fo:region-body>
            <fo:region-before region-name="gml-before-{.}" extent="{$header-extent}"/>
            <fo:region-after region-name="gml-after-{.}" extent="{$footer-extent}"/>
          </fo:simple-page-master>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:for-each select="1, 2">
        <fo:page-sequence-master master-name="gml-pages-{.}">
          <fo:repeatable-page-master-alternatives>
            <fo:conditional-page-master-reference master-reference="gml-odd-{.}" odd-or-even="odd"/>
            <fo:conditional-page-master-reference master-reference="gml-even-{.}" odd-or-even="even"/>
          </fo:repeatable-page-master-alternatives>
        </fo:page-sequence-master>
      </xsl:for-each>
    </fo:layout-master-set>
  </xsl:template>

  <!-- the section of a top-level node ('' for whitespace) -->
  <xsl:function name="f:section" as="xs:string">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="s" select="($n/descendant-or-self::*[self::frontm or self::body or self::appendix or self::backm])[1]"/>
    <xsl:sequence select="if ($n instance of text() and normalize-space($n) = '') then ''
                          else if ($s) then local-name($s) else 'body'"/>
  </xsl:function>

  <xsl:template name="f:page-sequences">
    <xsl:variable name="title" select="$f:gdoc//titlep[not($f:title-align = 'no')][1]"/>
    <xsl:if test="$title">
      <fo:page-sequence master-reference="gml-title" format="i"
          force-page-count="{if ($f:duplex) then 'auto' else 'no-force'}">
        <xsl:apply-templates select="$title" mode="f:page-sequence-attrs">
          <xsl:with-param name="kind" select="'titlep'"/>
        </xsl:apply-templates>
        <fo:flow flow-name="xsl-region-body">
          <xsl:apply-templates select="$title" mode="f:title-page">
            <xsl:with-param name="st" tunnel="yes" select="f:initial-state('titlep', 1)"/>
          </xsl:apply-templates>
        </fo:flow>
      </fo:page-sequence>
    </xsl:if>
    <!-- sections are found through gml:scope wrappers; adjacent loose
         content goes with the body -->
    <xsl:for-each-group select="$f:gdoc/node()[f:section(.) ne '']" group-adjacent="
        if (self::gml:scope and count(descendant::*[self::frontm or self::body or self::appendix or self::backm]) gt 1)
        then generate-id() else f:section(.)">
      <xsl:choose>
        <xsl:when test="self::gml:scope and count(descendant::*[self::frontm or self::body or self::appendix or self::backm]) gt 1">
          <!-- a scope around several sections: one sequence per section,
               the scope applied inside each -->
          <xsl:for-each select="descendant::*[self::frontm or self::body or self::appendix or self::backm]">
            <xsl:call-template name="f:page-sequence">
              <xsl:with-param name="kind" select="local-name()"/>
              <xsl:with-param name="nodes" select="."/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="f:page-sequence">
            <xsl:with-param name="kind" select="current-grouping-key()"/>
            <xsl:with-param name="nodes" select="current-group()"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
    <xsl:if test="empty($f:gdoc/node()[f:section(.) ne ''])">
      <!-- an empty document: a page-sequence needs a flow with a block -->
      <fo:page-sequence master-reference="gml-pages-1">
        <fo:flow flow-name="xsl-region-body"><fo:block/></fo:flow>
      </fo:page-sequence>
    </xsl:if>
  </xsl:template>

  <xsl:template name="f:page-sequence">
    <xsl:param name="kind" as="xs:string"/>
    <xsl:param name="nodes" as="node()*"/>
    <xsl:variable name="cols" as="xs:integer"
        select="if ($kind = 'backm') then xs:integer(($backm-columns[. castable as xs:integer], '2')[1])
                else if ($kind = ('body', 'appendix') and $f:style = 'two') then 2 else 1"/>
    <xsl:variable name="st" select="f:initial-state($kind, min(($cols, 2)))"/>
    <fo:page-sequence master-reference="gml-pages-{min(($cols, 2))}"
        format="{if ($kind = 'frontm') then 'i' else '1'}"
        force-page-count="{if ($f:duplex) then 'auto' else 'no-force'}">
      <xsl:if test="$kind = 'body' and not($nodes[1]/preceding::body)">
        <xsl:attribute name="initial-page-number" select="'1'"/>
      </xsl:if>
      <xsl:if test="$kind = 'frontm' and not(exists($f:gdoc//titlep[not($f:title-align = 'no')]))">
        <xsl:attribute name="initial-page-number" select="'1'"/>
      </xsl:if>
      <xsl:apply-templates select="($nodes/descendant-or-self::*[local-name() = $kind], $nodes[1])[1]" mode="f:page-sequence-attrs">
        <xsl:with-param name="kind" select="$kind"/>
      </xsl:apply-templates>
      <xsl:call-template name="f:static-content"/>
      <fo:flow flow-name="xsl-region-body">
        <xsl:variable name="content" as="element()*">
          <xsl:call-template name="f:flow-content">
            <xsl:with-param name="nodes" select="$nodes"/>
            <xsl:with-param name="st" tunnel="yes" select="$st"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:sequence select="$content"/>
        <xsl:if test="empty($content)"><fo:block/></xsl:if>
        <!-- change bars still open at the end of the flow -->
        <xsl:for-each select="distinct-values(($nodes/descendant-or-self::gml:rc[@mode = 'on'])/string(@code))">
          <xsl:variable name="code" select="."/>
          <xsl:variable name="last" select="($nodes/descendant-or-self::gml:rc[@code = $code][@mode = ('on', 'off')])[last()]"/>
          <xsl:if test="$last/@mode = 'on'">
            <fo:block><fo:change-bar-end change-bar-class="rc{$code}"/></fo:block>
          </xsl:if>
        </xsl:for-each>
      </fo:flow>
    </fo:page-sequence>
  </xsl:template>

  <!-- the content of a flow: sections are transparent; a gml:scope around
       a section is applied as a block around its content; the title page
       is written in its own sequence -->
  <xsl:template name="f:flow-content">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:for-each select="$nodes">
      <xsl:choose>
        <xsl:when test="self::frontm or self::body or self::appendix or self::backm or self::gdoc">
          <xsl:call-template name="f:blocks">
            <xsl:with-param name="nodes" select="node()[not(self::titlep[not($f:title-align = 'no')])]"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="f:blocks">
            <xsl:with-param name="nodes" select="."/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- ==== running heading and footing ================================= -->
  <xsl:template name="f:static-content">
    <xsl:for-each select="'odd', 'even'">
      <xsl:variable name="side" select="."/>
      <fo:static-content flow-name="gml-before-{$side}">
        <xsl:choose>
          <xsl:when test="$f:has-rh">
            <fo:block>
              <fo:retrieve-marker retrieve-class-name="gml-rh-{$side}" retrieve-boundary="document"/>
            </fo:block>
          </xsl:when>
          <xsl:otherwise>
            <fo:block text-align="center" text-align-last="center">
              <xsl:sequence select="f:font('@rh', $f:gdoc)"/>
              <xsl:value-of select="$f:gdoc/@sec"/>
            </fo:block>
          </xsl:otherwise>
        </xsl:choose>
      </fo:static-content>
      <fo:static-content flow-name="gml-after-{$side}">
        <xsl:choose>
          <xsl:when test="$f:has-rf">
            <fo:block>
              <fo:retrieve-marker retrieve-class-name="gml-rf-{$side}" retrieve-boundary="document"/>
            </fo:block>
          </xsl:when>
          <xsl:otherwise>
            <fo:block text-align="justify" text-align-last="justify" space-before="{f:lines(1)}">
              <xsl:sequence select="f:font('@rf', $f:gdoc)"/>
              <xsl:choose>
                <xsl:when test="$f:duplex and $side = 'even'">
                  <fo:page-number/>
                  <fo:leader leader-pattern="space"/>
                  <xsl:value-of select="$f:title"/>
                </xsl:when>
                <xsl:otherwise>
                  <fo:retrieve-marker retrieve-class-name="gml-shead"
                      retrieve-position="last-starting-within-page" retrieve-boundary="document"/>
                  <fo:leader leader-pattern="space"/>
                  <fo:page-number/>
                </xsl:otherwise>
              </xsl:choose>
            </fo:block>
          </xsl:otherwise>
        </xsl:choose>
      </fo:static-content>
    </xsl:for-each>
    <fo:static-content flow-name="xsl-footnote-separator">
      <fo:block text-align="start" text-align-last="start">
        <fo:leader leader-pattern="rule" leader-length="{f:len(f:dim($fn-leader))}"
            rule-thickness="{$rule-width}"/>
      </fo:block>
    </fo:static-content>
  </xsl:template>

  <!-- a gml-shead marker with this text -->
  <xsl:template name="f:shead">
    <xsl:param name="text" as="xs:string"/>
    <fo:marker marker-class-name="gml-shead"><xsl:value-of select="normalize-space($text)"/></fo:marker>
  </xsl:template>

  <!-- the markers of .rh/.rf definitions owned by $owner, among $nodes -->
  <xsl:template name="f:markers">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="owner" as="element()?"/>
    <xsl:variable name="defs" select="$nodes/descendant-or-self::*[self::gml:rh or self::gml:rf]
                                          [empty($owner) or f:owner(.) is $owner]"/>
    <xsl:for-each select="'rh', 'rf'">
      <xsl:variable name="w" select="."/>
      <xsl:for-each select="'odd', 'even'">
        <xsl:variable name="side" select="."/>
        <xsl:variable name="d" select="$defs[local-name() = $w][not(@page) or lower-case(@page) = $side]
                                          [node() or @action = 'cancel'][last()]"/>
        <xsl:if test="$d">
          <fo:marker marker-class-name="gml-{$w}-{$side}">
            <xsl:if test="$d/node()">
              <fo:block text-align="{if ($w = 'rh') then 'center' else 'start'}">
                <xsl:sequence select="f:font(if ($w = 'rh') then '@rh' else '@rf', $d)"/>
                <xsl:apply-templates select="$d/node()">
                  <xsl:with-param name="st" tunnel="yes" select="f:initial-state('marker', 1)
                      => map:put('noids', true()) => map:put('nofn', true())"/>
                </xsl:apply-templates>
              </fo:block>
            </xsl:if>
          </fo:marker>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- ==== block-only contexts ========================================= -->
  <!-- $nodes in a context that accepts only blocks (fo:flow): runs of
       inline content are wrapped in an fo:block; anchors alone become
       empty blocks with an id; markers go in an empty block. -->
  <xsl:template name="f:blocks">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:for-each-group select="$nodes" group-adjacent="f:kind(.) = 'block'">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:apply-templates select="current-group()"/>
        </xsl:when>
        <xsl:when test="some $n in current-group() satisfies f:kind($n) = 'inline'">
          <fo:block>
            <xsl:call-template name="f:markers">
              <xsl:with-param name="nodes" select="current-group()"/>
              <xsl:with-param name="owner" select="f:owner(current-group()[1])"/>
            </xsl:call-template>
            <xsl:apply-templates select="current-group()"/>
          </fo:block>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="current-group()[self::gml:rh or self::gml:rf]">
            <fo:block>
              <xsl:call-template name="f:markers">
                <xsl:with-param name="nodes" select="current-group()"/>
                <xsl:with-param name="owner" select="()"/>
              </xsl:call-template>
            </fo:block>
          </xsl:if>
          <xsl:for-each select="current-group()[@anchor][not($st?noids)]">
            <fo:block id="{@anchor}"/>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <!-- ==== common block attributes ===================================== -->
  <!-- id, keeps and boxes for a block written for element $e -->
  <xsl:template name="f:block-attrs">
    <xsl:param name="e" as="element()" select="."/>
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:if test="$e/@anchor and not($st?noids)">
      <xsl:attribute name="id" select="$e/@anchor"/>
    </xsl:if>
    <xsl:variable name="kp" select="f:open-kp($e)"/>
    <xsl:if test="$kp and not(f:open-kp($e/..) is $kp)
                  and exists($e/following::*[not(self::gml:kp or self::gml:bx)][f:open-kp(.) is $kp][not(f:open-kp(..) is $kp)])">
      <xsl:attribute name="keep-with-next.within-page" select="'always'"/>
    </xsl:if>
    <xsl:variable name="bx" select="f:open-bx($e)"/>
    <xsl:if test="$bx and not(f:open-bx($e/..) is $bx)">
      <xsl:variable name="b" select="concat($rule-width, ' solid')"/>
      <xsl:attribute name="border-start" select="$b"/>
      <xsl:attribute name="border-end" select="$b"/>
      <xsl:attribute name="padding-start" select="'2pt'"/>
      <xsl:attribute name="padding-end" select="'2pt'"/>
      <xsl:if test="empty($e/preceding::*[not(self::gml:kp or self::gml:bx)][f:open-bx(.) is $bx][not(f:open-bx(..) is $bx)][. >> $bx])">
        <xsl:attribute name="border-before" select="$b"/>
        <xsl:attribute name="padding-before" select="'2pt'"/>
      </xsl:if>
      <xsl:if test="empty($e/following::*[not(self::gml:kp or self::gml:bx)][f:open-bx(.) is $bx][not(f:open-bx(..) is $bx)])">
        <xsl:attribute name="border-after" select="$b"/>
        <xsl:attribute name="padding-after" select="'2pt'"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="f:nofill-attrs">
    <xsl:param name="wrap" as="xs:boolean" select="false()"/>
    <xsl:attribute name="linefeed-treatment" select="'preserve'"/>
    <xsl:attribute name="white-space-collapse" select="'false'"/>
    <xsl:attribute name="white-space-treatment" select="'preserve'"/>
    <xsl:attribute name="wrap-option" select="if ($wrap) then 'wrap' else 'no-wrap'"/>
  </xsl:template>

  <!-- ==== text ======================================================== -->
  <xsl:template match="text()">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:choose>
      <xsl:when test="$st?nofill">
        <xsl:variable name="t" select="if (f:at-block-start(.)) then replace(., '^\n', '') else string(.)"/>
        <xsl:value-of select="if (f:at-block-end(.)) then replace($t, '\n$', '') else $t"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- in no-fill text, is $n followed (preceded) by a block boundary? -->
  <xsl:function name="f:at-block-end" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="next" select="$n/following-sibling::node()[not(f:kind(.) = ('none', 'anchor')) or self::gml:br][1]"/>
    <xsl:sequence select="if ($next) then f:kind($next) = 'block' or exists($next/self::gml:br)
                          else if ($n/parent::*[f:kind(.) = 'inline']) then f:at-block-end($n/..) else true()"/>
  </xsl:function>
  <xsl:function name="f:at-block-start" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="prev" select="$n/preceding-sibling::node()[not(f:kind(.) = ('none', 'anchor')) or self::gml:br][1]"/>
    <xsl:sequence select="if ($prev) then f:kind($prev) = 'block' or exists($prev/self::gml:br)
                          else false()"/>
  </xsl:function>

  <!-- ==== state scopes ================================================ -->
  <xsl:template match="gml:scope">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="st2" select="f:scope-state($st, .)"/>
    <xsl:choose>
      <xsl:when test="f:kind(.) = 'block'">
        <fo:block>
          <xsl:call-template name="f:block-attrs"/>
          <xsl:sequence select="f:scope-block-attrs(., $st2)"/>
          <xsl:sequence select="f:scope-inline-attrs(.)"/>
          <xsl:call-template name="f:markers">
            <xsl:with-param name="nodes" select="node()"/>
            <xsl:with-param name="owner" select="."/>
          </xsl:call-template>
          <xsl:apply-templates>
            <xsl:with-param name="st" tunnel="yes" select="$st2"/>
          </xsl:apply-templates>
        </fo:block>
      </xsl:when>
      <xsl:otherwise>
        <fo:inline>
          <xsl:sequence select="f:scope-inline-attrs(.)"/>
          <xsl:sequence select="f:scope-inherited-attrs(., $st2)[local-name() = 'line-height']"/>
          <xsl:apply-templates>
            <xsl:with-param name="st" tunnel="yes" select="$st2"/>
          </xsl:apply-templates>
        </fo:inline>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- the block properties of a scope, $st2 being the state inside it -->
  <xsl:function name="f:scope-block-attrs" as="attribute()*">
    <xsl:param name="sc" as="element(gml:scope)"/>
    <xsl:param name="st2" as="map(*)"/>
    <xsl:if test="$sc/(@in, @of)">
      <xsl:attribute name="start-indent" select="f:start($st2)"/>
    </xsl:if>
    <xsl:if test="$sc/@of">
      <xsl:attribute name="text-indent" select="f:len(f:sub((0, 0), $st2?of))"/>
    </xsl:if>
    <xsl:if test="$sc/(@ir, @ll)">
      <xsl:attribute name="end-indent" select="f:end($st2)"/>
    </xsl:if>
    <xsl:sequence select="f:scope-inherited-attrs($sc, $st2)"/>
  </xsl:function>

  <!-- the inherited block properties of a scope (also usable on a list item) -->
  <xsl:function name="f:scope-inherited-attrs" as="attribute()*">
    <xsl:param name="sc" as="element(gml:scope)"/>
    <xsl:param name="st2" as="map(*)"/>
    <xsl:if test="$sc/@fill = 'no'">
      <xsl:call-template name="f:nofill-attrs">
        <xsl:with-param name="wrap" select="$st2?overdraw = 'fold'"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$sc/@fill = 'yes'">
      <xsl:attribute name="linefeed-treatment" select="'treat-as-space'"/>
      <xsl:attribute name="white-space-collapse" select="'true'"/>
      <xsl:attribute name="white-space-treatment" select="'ignore-if-surrounding-linefeed'"/>
      <xsl:attribute name="wrap-option" select="'wrap'"/>
    </xsl:if>
    <xsl:if test="$sc/@overdraw and not($sc/@fill) and $st2?nofill">
      <xsl:attribute name="wrap-option" select="if ($st2?overdraw = 'fold') then 'wrap' else 'no-wrap'"/>
    </xsl:if>
    <xsl:if test="$sc/@align">
      <xsl:attribute name="text-align" select="f:align($sc/@align)"/>
    </xsl:if>
    <xsl:if test="$sc/@ls">
      <!-- .ls by f | normal v | v (v more per line); SKIP, SPACE, TEXT
           (vertical justification ranges) and default: the base -->
      <xsl:variable name="w" select="f:words($sc/@ls)"/>
      <xsl:attribute name="line-height" select="
          if (exists(f:by($w))) then f:pts(f:by($w) * $f:line)
          else if ($w[1] = 'normal' and exists($w[2])) then f:len(f:dim($w[2]))
          else if (matches($w[1], '^[0-9]')) then f:pts($f:line + f:dim($w[1])[1])
          else f:pts($f:line)"/>
    </xsl:if>
    <xsl:if test="$sc/@wz">
      <!-- .wz on|off|n: off = no widow control -->
      <xsl:variable name="n" select="if ($sc/@wz castable as xs:integer) then xs:integer($sc/@wz)
                                     else if ($sc/@wz = 'off') then 1 else 2"/>
      <xsl:attribute name="widows" select="$n"/>
      <xsl:attribute name="orphans" select="$n"/>
    </xsl:if>
  </xsl:function>

  <xsl:function name="f:align" as="xs:string">
    <xsl:param name="a" as="xs:string"/>
    <xsl:sequence select="if ($a = 'left') then 'start' else if ($a = 'right') then 'end'
                          else if ($a = ('center', 'justify', 'inside', 'outside')) then $a else 'start'"/>
  </xsl:function>

  <!-- the inline properties of a scope -->
  <xsl:function name="f:scope-inline-attrs" as="attribute()*">
    <xsl:param name="sc" as="element(gml:scope)"/>
    <xsl:if test="$sc/@font">
      <xsl:sequence select="f:font($sc/@font, $sc)"/>
    </xsl:if>
    <xsl:if test="$sc/@hy">
      <xsl:attribute name="hyphenate" select="if ($sc/@hy = 'on') then 'true' else 'false'"/>
    </xsl:if>
    <xsl:if test="$sc/@sb">
      <xsl:attribute name="baseline-shift" select="if ($sc/@sb = 'default') then 'baseline' else f:len(f:dim($sc/@sb))"/>
    </xsl:if>
    <xsl:if test="$sc/@ws">
      <!-- .ws by f | normal h; word-spacing is the change from the space -->
      <xsl:variable name="w" select="f:words($sc/@ws)"/>
      <xsl:variable name="sw" select="f:dim($space-width)"/>
      <xsl:attribute name="word-spacing" select="
          if (exists(f:by($w))) then f:len(($sw[1] * (f:by($w) - 1), $sw[2] * (f:by($w) - 1)))
          else if ($w[1] = 'normal' and exists($w[2])) then f:len(f:sub(f:dim($w[2]), $sw))
          else 'normal'"/>
    </xsl:if>
  </xsl:function>

  <!-- ==== line scopes (gml:lines) ===================================== -->
  <xsl:template match="gml:lines[@word = ('ce', 'ri', 'il', 'un')] | gml:lines[f:kind(.) = 'block']">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <fo:block>
      <xsl:call-template name="f:block-attrs"/>
      <xsl:choose>
        <xsl:when test="@word = ('ce', 'ri')">
          <xsl:attribute name="text-align" select="if (@word = 'ce') then 'center' else 'end'"/>
          <xsl:attribute name="text-align-last" select="if (@word = 'ce') then 'center' else 'end'"/>
          <xsl:attribute name="linefeed-treatment" select="'preserve'"/>
        </xsl:when>
        <xsl:when test="@word = 'il'">
          <xsl:attribute name="text-indent" select="f:len(f:dim(concat(@left, @unit[. ne 'mixed'])))"/>
        </xsl:when>
        <xsl:when test="@word = 'un'">
          <xsl:attribute name="text-indent" select="f:len(f:sub((0, 0), f:dim(concat(@left, @unit[. ne 'mixed']))))"/>
        </xsl:when>
      </xsl:choose>
      <xsl:call-template name="f:lines-inline"/>
    </fo:block>
  </xsl:template>

  <xsl:template match="gml:lines">
    <xsl:call-template name="f:lines-inline"/>
  </xsl:template>

  <xsl:template name="f:lines-inline">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="st2" select="if (@word = ('ce', 'ri')) then map:put($st, 'nofill', true()) else $st"/>
    <xsl:choose>
      <xsl:when test="@word = ('us', 'up', 'uc')">
        <fo:inline>
          <xsl:if test="@word = ('us', 'uc')"><xsl:attribute name="text-decoration" select="'underline'"/></xsl:if>
          <xsl:if test="@word = ('up', 'uc')"><xsl:attribute name="text-transform" select="'uppercase'"/></xsl:if>
          <xsl:apply-templates/>
        </fo:inline>
      </xsl:when>
      <xsl:when test="@word = 'rc'">
        <fo:change-bar-begin change-bar-class="rc-{generate-id()}" change-bar-style="solid"
            change-bar-width="{$rule-width}" change-bar-offset="{f:len(f:dim($change-bar-offset))}"/>
        <xsl:apply-templates/>
        <fo:change-bar-end change-bar-class="rc-{generate-id()}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates>
          <xsl:with-param name="st" tunnel="yes" select="$st2"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==== events ====================================================== -->
  <xsl:template match="gml:br">
    <fo:block/>
  </xsl:template>

  <xsl:template match="gml:sp | gml:sk">
    <fo:block space-before="{f:len(f:amount(.))}"
        space-before.conditionality="{if (self::gml:sk or @conditional = 'yes') then 'discard' else 'retain'}"/>
  </xsl:template>

  <xsl:template match="gml:pa">
    <fo:block break-before="{if (@side = 'odd') then 'odd-page' else if (@side = 'even') then 'even-page' else 'page'}"/>
  </xsl:template>

  <xsl:template match="gml:cp">
    <fo:block keep-with-next.within-page="always"/>
  </xsl:template>

  <xsl:template match="gml:cc | gml:cb">
    <fo:block break-before="column"/>
  </xsl:template>

  <xsl:template match="gml:kp[@mode = 'inline' and @depth]">
    <fo:block-container block-progression-dimension="{f:len(f:dim(tokenize(@depth, '\s+')[1]))}"
        keep-together.within-page="always">
      <fo:block/>
    </fo:block-container>
  </xsl:template>

  <xsl:template match="gml:hr | gml:bx[@action = 'line']">
    <fo:block text-align="start" text-align-last="justify" line-height="{$rule-width}" space-before="2pt" space-after="2pt">
      <fo:leader leader-pattern="rule" rule-thickness="{$rule-width}"/>
    </fo:block>
  </xsl:template>

  <xsl:template match="gml:rc[@mode = 'on']">
    <fo:change-bar-begin change-bar-class="rc{@code}" change-bar-style="solid"
        change-bar-width="{$rule-width}" change-bar-offset="{f:len(f:dim($change-bar-offset))}"/>
  </xsl:template>
  <xsl:template match="gml:rc[@mode = 'off']">
    <xsl:variable name="code" select="@code"/>
    <xsl:if test="(preceding::gml:rc[@code = $code][@mode = ('on', 'off')])[last()]/@mode = 'on'">
      <fo:change-bar-end change-bar-class="rc{@code}"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="gml:sx">
    <fo:block text-align="justify" text-align-last="justify">
      <xsl:value-of select="@left"/>
      <fo:leader leader-pattern="{if (normalize-space(@fill) = '') then 'space' else 'use-content'}">
        <xsl:value-of select="@fill"/>
      </fo:leader>
      <xsl:value-of select="@right"/>
    </fo:block>
  </xsl:template>

  <xsl:template match="gml:is[matches(@spec, '^[+-]?[0-9.,]+[a-z]*$')]">
    <fo:leader leader-pattern="space" leader-length="{f:len(f:dim(@spec))}"/>
  </xsl:template>

  <!-- control-word headings -->
  <xsl:template match="gml:h">
    <xsl:call-template name="f:heading">
      <xsl:with-param name="level" select="xs:integer((@level[. castable as xs:integer], 1)[1])"/>
    </xsl:call-template>
  </xsl:template>

  <!-- .fn on/off: a footnote with no callout -->
  <xsl:template match="gml:fn">
    <xsl:call-template name="f:footnote">
      <xsl:with-param name="callout" select="()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="gml:raw">
    <xsl:variable name="c" select="f:raw(.)"/>
    <xsl:if test="@backend = 'fo' and empty($c)">
      <xsl:message>fo.xsl: gml:raw backend="fo" dropped: not well-formed XSL-FO: <xsl:value-of select="."/></xsl:message>
    </xsl:if>
    <xsl:sequence select="$c"/>
  </xsl:template>

  <!-- everything else in the gml namespace (state hints already gone,
       page-level and device words, .rh/.rf handled as markers) -->
  <xsl:template match="gml:*" priority="-1"/>
  <xsl:template match="gml:rh | gml:rf | gml:kp | gml:bx | gml:df"/>
  <xsl:template match="comment() | processing-instruction()"/>

  <!-- an element that is not a Starter Set tag: a block or an inline wrapper -->
  <xsl:template match="*" priority="-2">
    <xsl:choose>
      <xsl:when test="f:kind(.) = 'block'">
        <fo:block>
          <xsl:call-template name="f:block-attrs"/>
          <xsl:apply-templates/>
        </fo:block>
      </xsl:when>
      <xsl:otherwise>
        <fo:inline><xsl:apply-templates/></fo:inline>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==== sections met inside the flow ================================= -->
  <xsl:template match="frontm | body | appendix | backm | gdoc | psc">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="abstract | preface">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="title" select="if (self::abstract) then $lit-abstract else $lit-preface"/>
    <fo:block>
      <xsl:call-template name="f:block-attrs"/>
      <fo:block break-before="{if ($f:duplex) then 'odd-page' else 'page'}">
        <xsl:sequence select="f:heading-attrs(1, .)"/>
        <xsl:call-template name="f:shead"><xsl:with-param name="text" select="$title"/></xsl:call-template>
        <xsl:value-of select="$title"/>
      </fo:block>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <!-- ==== title page =================================================== -->
  <xsl:template match="titlep" mode="f:title-page">
    <xsl:variable name="align" select="if ($f:title-align = ('left', 'center')) then
                                         (if ($f:title-align = 'left') then 'start' else 'center') else 'end'"/>
    <fo:block text-align="{$align}" text-align-last="{$align}" hyphenate="false">
      <xsl:call-template name="f:shead"><xsl:with-param name="text" select="$f:title"/></xsl:call-template>
      <fo:block space-before="2in" space-before.conditionality="retain" line-height="1.2">
        <xsl:sequence select="f:font('title', .)"/>
        <xsl:for-each select=".//title">
          <fo:block><xsl:apply-templates/></fo:block>
        </xsl:for-each>
      </fo:block>
      <fo:block space-before="2in">
        <xsl:for-each select=".//docnum">
          <fo:block space-before="{f:lines(1)}">
            <xsl:sequence select="f:font('docnum', .)"/>
            <xsl:value-of select="$lit-docnum"/>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
          </fo:block>
        </xsl:for-each>
        <xsl:for-each select=".//date">
          <fo:block space-before="{f:lines(1)}">
            <xsl:sequence select="f:font('date', .)"/>
            <xsl:apply-templates/>
          </fo:block>
        </xsl:for-each>
        <xsl:for-each select=".//author">
          <fo:block space-before="{f:lines(if (preceding-sibling::author) then 0 else 1)}">
            <xsl:sequence select="f:font('author', .)"/>
            <xsl:apply-templates/>
          </fo:block>
        </xsl:for-each>
        <xsl:for-each select=".//address">
          <fo:block space-before="{f:lines(1)}">
            <xsl:sequence select="f:font('address', .)"/>
            <xsl:for-each select="aline">
              <fo:block><xsl:apply-templates/></fo:block>
            </xsl:for-each>
          </fo:block>
        </xsl:for-each>
        <xsl:if test="normalize-space($f:gdoc/@sec)">
          <fo:block space-before="{f:lines(1)}">
            <xsl:sequence select="f:font('titlesec', .)"/>
            <xsl:value-of select="$f:gdoc/@sec"/>
          </fo:block>
        </xsl:if>
      </fo:block>
      <!-- index tags and other anchors on the title page -->
      <xsl:for-each select=".//*[@anchor]">
        <fo:block id="{@anchor}"/>
      </xsl:for-each>
    </fo:block>
  </xsl:template>

  <!-- title page elements met elsewhere (no title page, SYSVART=no) -->
  <xsl:template match="titlep">
    <xsl:if test="not(. is ($f:gdoc//titlep[not($f:title-align = 'no')])[1])">
      <fo:block>
        <xsl:call-template name="f:block-attrs"/>
        <xsl:apply-templates select="*"/>
      </fo:block>
    </xsl:if>
  </xsl:template>
  <xsl:template match="title | docnum | date | author">
    <fo:block>
      <xsl:call-template name="f:block-attrs"/>
      <xsl:sequence select="f:font(local-name(), .)"/>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
  <xsl:template match="address">
    <fo:block space-before="{f:lines(1)}">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:apply-templates select="aline"/>
    </fo:block>
  </xsl:template>
  <xsl:template match="aline">
    <fo:block><xsl:apply-templates/></fo:block>
  </xsl:template>

  <!-- ==== headings ===================================================== -->
  <xsl:template match="h0 | h1 | h2 | h3 | h4 | h5 | h6">
    <xsl:variable name="level" select="xs:integer(substring(local-name(), 2))"/>
    <xsl:choose>
      <xsl:when test="$level ge 5 and f:run-in-p(.)"/>
      <xsl:otherwise>
        <xsl:call-template name="f:heading">
          <xsl:with-param name="level" select="$level"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- the :p that an h5/h6 runs into -->
  <xsl:function name="f:run-in-p" as="element()?">
    <xsl:param name="h" as="element()"/>
    <xsl:sequence select="$h/following-sibling::node()[not(self::text()[normalize-space() = ''])][1][self::p]"/>
  </xsl:function>

  <xsl:function name="f:heading-attrs" as="attribute()*">
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="ctx" as="node()"/>
    <xsl:sequence select="f:font(concat('hd', $level), $ctx)"/>
    <xsl:attribute name="keep-with-next.within-column" select="'always'"/>
    <xsl:attribute name="hyphenate" select="'false'"/>
    <xsl:attribute name="text-align" select="if ($level le 1 and $f:duplex and $f:style ne 'offset') then 'outside' else 'start'"/>
    <xsl:attribute name="text-align-last" select="if ($level le 1 and $f:duplex and $f:style ne 'offset') then 'outside' else 'start'"/>
    <xsl:attribute name="text-indent" select="'0pt'"/>
    <xsl:choose>
      <xsl:when test="$level le 1">
        <xsl:attribute name="space-before" select="'1.3in'"/>
        <xsl:attribute name="space-before.conditionality" select="'retain'"/>
        <xsl:attribute name="space-after" select="'14pt'"/>
      </xsl:when>
      <xsl:when test="$level le 4">
        <xsl:attribute name="space-before" select="('20pt', '18pt', '14pt')[$level - 1]"/>
        <xsl:attribute name="space-before.conditionality" select="'discard'"/>
        <xsl:attribute name="space-after" select="'11pt'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="space-before" select="f:lines(0.75)"/>
        <xsl:attribute name="space-before.conditionality" select="'discard'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template name="f:heading">
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <fo:block>
      <xsl:call-template name="f:block-attrs"/>
      <xsl:sequence select="f:heading-attrs($level, .)"/>
      <xsl:if test="$level le 1 and $st?section ne 'titlep'">
        <xsl:attribute name="break-before" select="if ($f:duplex) then 'odd-page' else 'page'"/>
      </xsl:if>
      <xsl:if test="$level le 1 and $st?cols gt 1 and parent::*[self::body or self::appendix or self::backm or self::frontm or self::gdoc]">
        <xsl:attribute name="span" select="'all'"/>
      </xsl:if>
      <xsl:if test="$level le 4 and $f:style = 'offset'">
        <xsl:attribute name="start-indent" select="'0pt'"/>
      </xsl:if>
      <xsl:if test="$level le 1 and not($st?noids)">
        <xsl:call-template name="f:shead">
          <xsl:with-param name="text" select="(@stitle, string-join(node()[not(self::gml:num)]/string(), ''))[1]"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:call-template name="f:markers">
        <xsl:with-param name="nodes" select="node()"/>
        <xsl:with-param name="owner" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="gml:num">
    <xsl:apply-templates/>
    <xsl:if test="parent::*[matches(local-name(), '^h[0-6]$') or self::figcap or self::gml:toc-entry or self::gml:figlist-entry]">
      <xsl:text>&#xA0; </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- ==== paragraphs ================================================== -->
  <xsl:template match="p | pc">
    <fo:block space-before="{f:lines(0.75)}" space-before.conditionality="discard">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:call-template name="f:markers">
        <xsl:with-param name="nodes" select="node()"/>
        <xsl:with-param name="owner" select="."/>
      </xsl:call-template>
      <xsl:variable name="h" select="preceding-sibling::node()[not(self::text()[normalize-space() = ''])][1]
                                        [self::h5 or self::h6]"/>
      <xsl:if test="$h and f:run-in-p($h) is current()">
        <xsl:apply-templates select="$h" mode="f:run-in"/>
      </xsl:if>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="h5 | h6" mode="f:run-in">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <fo:inline keep-with-next.within-line="always">
      <xsl:if test="@anchor and not($st?noids)"><xsl:attribute name="id" select="@anchor"/></xsl:if>
      <xsl:sequence select="f:font(concat('hd', substring(local-name(), 2)), .)"/>
      <xsl:apply-templates/>
    </fo:inline>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="note">
    <fo:block space-before="{f:lines(0.75)}" space-before.conditionality="discard">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:call-template name="f:markers">
        <xsl:with-param name="nodes" select="node()"/>
        <xsl:with-param name="owner" select="."/>
      </xsl:call-template>
      <fo:inline>
        <xsl:sequence select="f:font('hi2', .)"/>
        <xsl:value-of select="$lit-note"/>
      </fo:inline>
      <xsl:text>&#xA0;</xsl:text>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="lq">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="st2" select="f:enter($st, f:chs(3), f:chs(3))"/>
    <fo:block space-before="{f:lines(1)}" space-after="{f:lines(1)}" space-before.conditionality="discard"
        start-indent="{f:start($st2)}" end-indent="{f:end($st2)}" text-indent="0pt">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:sequence select="f:font('lqfont', .)"/>
      <xsl:call-template name="f:markers">
        <xsl:with-param name="nodes" select="node()"/>
        <xsl:with-param name="owner" select="."/>
      </xsl:call-template>
      <xsl:apply-templates>
        <xsl:with-param name="st" tunnel="yes" select="$st2"/>
      </xsl:apply-templates>
    </fo:block>
  </xsl:template>

  <xsl:template match="xmp">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="st2" select="f:enter($st, f:chs(2), (0, 0)) => map:put('nofill', true())"/>
    <fo:block space-before="{f:lines(1)}" space-after="{f:lines(1)}" space-before.conditionality="discard"
        start-indent="{f:start($st2)}" text-indent="0pt" text-align="start" hyphenate="false">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:sequence select="f:font('xmpfont', .)"/>
      <xsl:call-template name="f:nofill-attrs"/>
      <xsl:call-template name="f:markers">
        <xsl:with-param name="nodes" select="node()"/>
        <xsl:with-param name="owner" select="."/>
      </xsl:call-template>
      <xsl:apply-templates>
        <xsl:with-param name="st" tunnel="yes" select="$st2"/>
      </xsl:apply-templates>
    </fo:block>
  </xsl:template>

  <!-- ==== highlighting, quotes ========================================= -->
  <xsl:template match="hp0 | hp1 | hp2 | hp3 | cit">
    <fo:inline>
      <xsl:sequence select="f:font(if (self::cit) then 'hi1' else concat('hi', substring(local-name(), 3)), .)"/>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>

  <xsl:template match="q">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="odd" select="$st?qd mod 2 = 0"/>
    <fo:inline>
      <xsl:value-of select="$f:q[if ($odd) then 1 else 3]"/>
      <xsl:apply-templates>
        <xsl:with-param name="st" tunnel="yes" select="map:put($st, 'qd', $st?qd + 1)"/>
      </xsl:apply-templates>
      <xsl:value-of select="$f:q[if ($odd) then 2 else 4]"/>
    </fo:inline>
  </xsl:template>

  <!-- ==== cross-references ============================================= -->
  <xsl:template match="hdref | figref | liref">
    <xsl:choose>
      <xsl:when test="@resolved = 'yes' and f:citable(., string(@refid))">
        <fo:basic-link internal-destination="{@refid}">
          <xsl:apply-templates/>
        </fo:basic-link>
      </xsl:when>
      <xsl:otherwise>
        <fo:inline><xsl:apply-templates/></fo:inline>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="fnref">
    <xsl:variable name="target" select="key('f:anchor', string(@refid))[self::fn]"/>
    <xsl:choose>
      <xsl:when test="@resolved = 'yes' and $target and f:citable(., string($target/@anchor))">
        <fo:basic-link internal-destination="{$target/@anchor}">
          <xsl:call-template name="f:callout"/>
        </fo:basic-link>
      </xsl:when>
      <xsl:otherwise><xsl:call-template name="f:callout"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="f:callout">
    <xsl:param name="text" select="string(.)"/>
    <fo:inline baseline-shift="super">
      <xsl:sequence select="f:font('super', .)"/>
      <xsl:value-of select="$text"/>
    </fo:inline>
  </xsl:template>

  <xsl:template match="gml:pageref">
    <xsl:if test="@label">
      <xsl:text> </xsl:text>
      <xsl:value-of select="@label"/>
      <xsl:text>&#xA0;</xsl:text>
    </xsl:if>
    <xsl:call-template name="f:page-citation"/>
  </xsl:template>

  <xsl:template name="f:page-citation">
    <xsl:choose>
      <xsl:when test="not(f:citable(., string(@refid)))">
        <xsl:text>?</xsl:text>
      </xsl:when>
      <xsl:when test="@text">
        <fo:basic-link internal-destination="{@refid}"><xsl:value-of select="@text"/></fo:basic-link>
      </xsl:when>
      <xsl:when test="@major = 'yes'">
        <fo:inline font-weight="bold"><fo:page-number-citation ref-id="{@refid}"/></fo:inline>
      </xsl:when>
      <xsl:otherwise>
        <fo:page-number-citation ref-id="{@refid}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==== index tags =================================================== -->
  <xsl:template match="i1 | i2 | i3 | ih1 | ih2 | ih3 | iref">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:if test="@anchor and not($st?noids)">
      <fo:inline id="{@anchor}"/>
    </xsl:if>
  </xsl:template>

  <!-- ==== footnotes ==================================================== -->
  <xsl:template match="fn">
    <xsl:call-template name="f:footnote">
      <xsl:with-param name="callout" select="if (@callout = 'no') then () else string(gml:num)"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="f:footnote">
    <xsl:param name="callout" as="xs:string?"/>
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="id" select="if (@anchor and not($st?noids)) then string(@anchor) else ()"/>
    <xsl:choose>
      <xsl:when test="$st?nofn">
        <!-- in a float, footnote or marker: in place, in brackets -->
        <fo:inline>
          <xsl:if test="$id"><xsl:attribute name="id" select="$id"/></xsl:if>
          <xsl:if test="exists($callout)"><xsl:call-template name="f:callout"><xsl:with-param name="text" select="$callout"/></xsl:call-template></xsl:if>
          <xsl:text> [</xsl:text>
          <xsl:apply-templates select="node()[not(self::gml:num)]"/>
          <xsl:text>]</xsl:text>
        </fo:inline>
      </xsl:when>
      <xsl:otherwise>
        <fo:footnote>
          <fo:inline>
            <xsl:if test="$id"><xsl:attribute name="id" select="$id"/></xsl:if>
            <xsl:if test="exists($callout)">
              <xsl:call-template name="f:callout"><xsl:with-param name="text" select="$callout"/></xsl:call-template>
            </xsl:if>
          </fo:inline>
          <fo:footnote-body>
            <xsl:variable name="st2" select="f:initial-state($st?section, 1)
                => map:put('W', $st?W) => map:put('nofn', true()) => map:put('noids', $st?noids)"/>
            <fo:block start-indent="{f:pts($st?margin)}" end-indent="0pt" text-indent="0pt"
                text-align="justify" space-before="{f:lines(0.5)}" keep-together.within-page="always">
              <xsl:sequence select="f:font('fnt', .)"/>
              <xsl:if test="gml:num">
                <xsl:call-template name="f:callout"><xsl:with-param name="text" select="string(gml:num)"/></xsl:call-template>
                <xsl:text> </xsl:text>
              </xsl:if>
              <xsl:apply-templates select="node()[not(self::gml:num)]">
                <xsl:with-param name="st" tunnel="yes" select="$st2"/>
              </xsl:apply-templates>
            </fo:block>
          </fo:footnote-body>
        </fo:footnote>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==== figures ====================================================== -->
  <xsl:template match="fig">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="frame" select="lower-case(normalize-space((@frame, 'rule')[1]))"/>
    <xsl:variable name="place" select="lower-case(normalize-space((@place, 'top')[1]))"/>
    <xsl:variable name="float" select="$place = 'top' and not($st?nofn)"/>
    <xsl:variable name="pad" select="if ($frame = 'none') then 0 else 2"/>
    <xsl:variable name="bw" select="if ($frame = ('box', 'rule')) then $f:rule else 0"/>
    <xsl:variable name="edge" select="$st?margin + (if ($frame = 'box') then $bw + $pad else 0)"/>
    <!-- DSMFIG resets the indention to zero: the figure is at the column edges -->
    <xsl:variable name="st2" select="map:merge((map {
        'L': ($edge + 2 * $f:ch, 0), 'in0': $st?in, 'of': (0, 0),
        'R': (if ($frame = 'box') then $bw + $pad else 0, 0), 'ir0': $st?ir, 'llx': (0, 0),
        'nofill': $fig-fill = 'no', 'nofn': true() }, $st), map { 'duplicates': 'use-first' })"/>
    <xsl:variable name="block">
      <fo:block start-indent="{f:pts($edge)}" end-indent="{f:pts(if ($frame = 'box') then $bw + $pad else 0)}"
          text-indent="0pt" keep-together.within-page="always">
        <xsl:call-template name="f:block-attrs"/>
        <xsl:if test="not($float)">
          <xsl:attribute name="space-before" select="f:lines(1)"/>
          <xsl:attribute name="space-after" select="f:lines(1)"/>
          <xsl:if test="$st?cols gt 1 and not(@width = 'column') and parent::*[self::body or self::appendix or self::backm]">
            <xsl:attribute name="span" select="'all'"/>
          </xsl:if>
        </xsl:if>
        <xsl:if test="$float">
          <xsl:attribute name="space-after" select="f:lines(1)"/>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$frame = 'box'">
            <xsl:attribute name="border" select="concat($rule-width, ' solid')"/>
            <xsl:attribute name="padding" select="concat($pad, 'pt')"/>
          </xsl:when>
          <xsl:when test="$frame = 'rule'">
            <xsl:attribute name="border-before" select="concat($rule-width, ' solid')"/>
            <xsl:attribute name="border-after" select="concat($rule-width, ' solid')"/>
            <xsl:attribute name="padding-before" select="concat($pad, 'pt')"/>
            <xsl:attribute name="padding-after" select="concat($pad, 'pt')"/>
          </xsl:when>
        </xsl:choose>
        <xsl:if test="not($frame = ('box', 'rule', 'none'))">
          <xsl:call-template name="f:char-rule"><xsl:with-param name="s" select="@frame"/></xsl:call-template>
        </xsl:if>
        <fo:block start-indent="{f:start($st2)}">
          <xsl:if test="$fig-fill = 'no'"><xsl:call-template name="f:nofill-attrs"/></xsl:if>
          <xsl:apply-templates select="node()[not(self::figcap or self::figdesc)]">
            <xsl:with-param name="st" tunnel="yes" select="$st2"/>
          </xsl:apply-templates>
        </fo:block>
        <xsl:apply-templates select="figcap | figdesc">
          <xsl:with-param name="st" tunnel="yes" select="map:put($st2, 'nofill', false())"/>
        </xsl:apply-templates>
        <xsl:if test="not($frame = ('box', 'rule', 'none'))">
          <xsl:call-template name="f:char-rule"><xsl:with-param name="s" select="@frame"/></xsl:call-template>
        </xsl:if>
      </fo:block>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$float">
        <fo:float float="before">
          <xsl:apply-templates select="." mode="f:float-attrs"/>
          <xsl:sequence select="$block/node()"/>
        </fo:float>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="f:fig-in-place">
          <xsl:with-param name="block" select="$block/node()"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- a figure placed where it stands (inline, bottom) -->
  <xsl:template match="fig" mode="f:fig-in-place">
    <xsl:param name="block" as="node()*"/>
    <xsl:sequence select="$block"/>
  </xsl:template>

  <!-- a rule made of a character string (frame='...') -->
  <xsl:template name="f:char-rule">
    <xsl:param name="s" as="xs:string"/>
    <fo:block text-align="start" text-align-last="justify" start-indent="inherit" white-space-collapse="false">
      <fo:leader leader-pattern="use-content"><xsl:value-of select="$s"/></fo:leader>
    </fo:block>
  </xsl:template>

  <xsl:template match="figcap">
    <fo:block space-before="{f:lines(0.5)}" text-align="start">
      <xsl:sequence select="f:font('figcap', .)"/>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="figdesc">
    <fo:block text-align="start">
      <xsl:sequence select="f:font('figdesc', .)"/>
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <!-- ==== lists ======================================================== -->
  <!-- the items of a list and the stray nodes among them, through scopes -->
  <xsl:function name="f:list-seq" as="node()*">
    <xsl:param name="list" as="element()"/>
    <xsl:sequence select="$list//node()[ancestor::*[not(self::gml:scope)][1] is $list][not(self::gml:scope)]"/>
  </xsl:function>

  <!-- the scopes between a list and an item, outermost first -->
  <xsl:function name="f:scope-chain" as="element(gml:scope)*">
    <xsl:param name="n" as="node()"/>
    <xsl:param name="list" as="element()"/>
    <xsl:sequence select="$n/ancestor::gml:scope[. >> $list]"/>
  </xsl:function>

  <xsl:function name="f:list-indent" as="xs:double+">
    <xsl:param name="list" as="element()"/>
    <xsl:sequence select="if ($list/@tsize) then f:dim($list/@tsize)
                          else f:chs(if ($list/self::dl) then 10 else 4)"/>
  </xsl:function>

  <xsl:template match="ol | ul | sl | dl | l">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="list" select="."/>
    <xsl:variable name="seq" select="f:list-seq(.)"/>
    <xsl:variable name="ind" select="f:list-indent(.)"/>
    <xsl:variable name="compact" select="exists(@compact)"/>
    <xsl:variable name="dlbreak" select="self::dl and exists(@break)"/>
    <xsl:choose>
      <xsl:when test="$dlbreak">
        <fo:block space-before="{f:lines(0.75)}" space-after="{f:lines(0.75)}" space-before.conditionality="discard"
            start-indent="{f:start($st)}" text-indent="0pt">
          <xsl:call-template name="f:block-attrs"/>
          <xsl:for-each-group select="$seq" group-starting-with="dt | dthd">
            <xsl:variable name="st-item" select="fold-left(f:scope-chain(current-group()[1], $list), $st, f:scope-state#2)"/>
            <xsl:for-each select="current-group()[self::dt or self::dthd]">
              <fo:block keep-with-next.within-page="always" start-indent="{f:start($st-item)}">
                <xsl:if test="not($compact)"><xsl:attribute name="space-before" select="f:lines(0.75)"/></xsl:if>
                <xsl:call-template name="f:block-attrs"/>
                <xsl:sequence select="f:font(f:term-font($list, exists(self::dthd)), $list)"/>
                <xsl:apply-templates/>
              </fo:block>
            </xsl:for-each>
            <xsl:variable name="st-body" select="f:enter($st-item, $ind, (0, 0))"/>
            <xsl:for-each select="current-group()[not(self::dt or self::dthd)][f:kind(.) ne 'none']">
              <fo:block start-indent="{f:start($st-body)}">
                <xsl:if test="self::ddhd"><xsl:sequence select="f:font(f:term-font($list, true()), $list)"/></xsl:if>
                <xsl:apply-templates select=".">
                  <xsl:with-param name="st" tunnel="yes" select="$st-body"/>
                </xsl:apply-templates>
              </fo:block>
            </xsl:for-each>
          </xsl:for-each-group>
        </fo:block>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="items" as="element()*">
          <xsl:for-each-group select="$seq" group-starting-with="li | lp | dt | dthd
              | dd[not(preceding-sibling::*[1][self::dt])] | ddhd[not(preceding-sibling::*[1][self::dthd])]">
            <xsl:variable name="g" select="current-group()"/>
            <xsl:if test="some $n in $g satisfies f:kind($n) ne 'none'">
              <xsl:variable name="st-item" select="fold-left(f:scope-chain($g[1], $list), $st, f:scope-state#2)"/>
              <xsl:variable name="label-start" select="f:S0($st-item)"/>
              <xsl:variable name="st-body" select="f:enter($st-item, $ind, (0, 0))"/>
              <xsl:variable name="item" select="$g[self::li or self::lp or self::dt or self::dthd or self::dd or self::ddhd][1]"/>
              <fo:list-item>
                <xsl:if test="not($compact)">
                  <xsl:attribute name="space-before" select="f:lines(0.75)"/>
                </xsl:if>
                <xsl:for-each select="f:scope-chain($g[1], $list)">
                  <xsl:sequence select="f:scope-inherited-attrs(., $st-item), f:scope-inline-attrs(.)"/>
                </xsl:for-each>
                <xsl:if test="$item">
                  <xsl:call-template name="f:block-attrs"><xsl:with-param name="e" select="$item"/></xsl:call-template>
                </xsl:if>
                <fo:list-item-label start-indent="{f:len($label-start)}" end-indent="label-end()" text-indent="0pt">
                  <fo:block>
                    <xsl:choose>
                      <xsl:when test="$item/self::li and $list/self::ol">
                        <xsl:apply-templates select="$item/gml:num/node()"/>
                      </xsl:when>
                      <xsl:when test="$item/self::li and $list/self::ul">
                        <xsl:value-of select="$f:ul-ids[(xs:integer(($list/@nest[. castable as xs:integer], 1)[1]) - 1) mod count($f:ul-ids) + 1]"/>
                      </xsl:when>
                      <xsl:when test="$item/self::li and $list/self::l">*</xsl:when>
                      <xsl:when test="$item/self::dt or $item/self::dthd">
                        <fo:inline>
                          <xsl:sequence select="f:font(f:term-font($list, exists($item/self::dthd)), $list)"/>
                          <xsl:apply-templates select="$item/node()">
                            <xsl:with-param name="st" tunnel="yes" select="$st-item"/>
                          </xsl:apply-templates>
                        </fo:inline>
                      </xsl:when>
                    </xsl:choose>
                  </fo:block>
                </fo:list-item-label>
                <fo:list-item-body start-indent="{f:start($st-body)}" text-indent="0pt">
                  <fo:block>
                    <xsl:for-each select="$g[not(self::text()[normalize-space() = ''])]">
                      <xsl:choose>
                        <xsl:when test="self::li or self::lp or self::dd">
                          <xsl:call-template name="f:markers">
                            <xsl:with-param name="nodes" select="node()"/>
                            <xsl:with-param name="owner" select="."/>
                          </xsl:call-template>
                          <xsl:apply-templates select="node()[not(self::gml:num)]">
                            <xsl:with-param name="st" tunnel="yes" select="$st-body"/>
                          </xsl:apply-templates>
                        </xsl:when>
                        <xsl:when test="self::ddhd">
                          <fo:inline>
                            <xsl:sequence select="f:font(f:term-font($list, true()), $list)"/>
                            <xsl:apply-templates>
                              <xsl:with-param name="st" tunnel="yes" select="$st-body"/>
                            </xsl:apply-templates>
                          </fo:inline>
                        </xsl:when>
                        <xsl:when test="self::dt or self::dthd"/>
                        <xsl:otherwise>
                          <xsl:apply-templates select=".">
                            <xsl:with-param name="st" tunnel="yes" select="$st-body"/>
                          </xsl:apply-templates>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </fo:block>
                </fo:list-item-body>
              </fo:list-item>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:variable>
        <xsl:if test="exists($items)">
          <fo:list-block space-before="{f:lines(0.75)}" space-after="{f:lines(0.75)}"
              space-before.conditionality="discard"
              start-indent="{f:start($st)}" text-indent="0pt"
              provisional-distance-between-starts="{f:len($ind)}" provisional-label-separation="{f:pts($f:ch)}">
            <xsl:call-template name="f:block-attrs"/>
            <xsl:sequence select="$items"/>
          </fo:list-block>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- the font of definition terms (termhi=, default 2) or headings (headhi=, 3) -->
  <xsl:function name="f:term-font" as="xs:string">
    <xsl:param name="list" as="element()"/>
    <xsl:param name="head" as="xs:boolean"/>
    <xsl:variable name="v" select="if ($head) then ($list/@headhi, $list/@hhi, '3')[1] else ($list/@termhi, $list/@thi, '2')[1]"/>
    <xsl:sequence select="concat('hi', $v)"/>
  </xsl:function>

  <!-- glossary lists: "term: definition" paragraphs (DSMGDEF) -->
  <xsl:template match="gl">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="list" select="."/>
    <fo:block space-before="{f:lines(0.75)}" space-after="{f:lines(0.75)}" space-before.conditionality="discard">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:for-each-group select="f:list-seq(.)" group-starting-with="gt | gd[not(preceding-sibling::*[1][self::gt])]">
        <xsl:if test="some $n in current-group() satisfies f:kind($n) ne 'none'">
          <xsl:variable name="st-item" select="fold-left(f:scope-chain(current-group()[1], $list), $st, f:scope-state#2)"/>
          <fo:block start-indent="{f:start($st-item)}" text-indent="0pt">
            <xsl:if test="not($list/@compact)"><xsl:attribute name="space-before" select="f:lines(0.75)"/></xsl:if>
            <xsl:for-each select="current-group()">
              <xsl:choose>
                <xsl:when test="self::gt">
                  <fo:inline>
                    <xsl:sequence select="f:font(concat('hi', ($list/@termhi, $list/@thi, '2')[1]), $list)"/>
                    <xsl:apply-templates/>
                    <xsl:text>:</xsl:text>
                  </fo:inline>
                  <xsl:text>&#xA0;</xsl:text>
                </xsl:when>
                <xsl:when test="self::gd or self::lp">
                  <xsl:apply-templates>
                    <xsl:with-param name="st" tunnel="yes" select="$st-item"/>
                  </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select=".">
                    <xsl:with-param name="st" tunnel="yes" select="$st-item"/>
                  </xsl:apply-templates>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </fo:block>
        </xsl:if>
      </xsl:for-each-group>
    </fo:block>
  </xsl:template>

  <!-- list parts met outside their list (the list templates take them) -->
  <xsl:template match="li | lp | dt | dd | dthd | ddhd | gt | gd">
    <fo:block>
      <xsl:call-template name="f:block-attrs"/>
      <xsl:apply-templates select="node()[not(self::gml:num)]"/>
    </fo:block>
  </xsl:template>

  <!-- ==== table of contents, figure list ============================== -->
  <xsl:template match="toc | figlist">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="title" select="string((gml:toc-entries, gml:figlist-entries)[1]/@title)"/>
    <fo:block break-before="{if ($f:duplex) then 'odd-page' else 'page'}">
      <xsl:call-template name="f:block-attrs"/>
      <fo:block>
        <xsl:sequence select="f:heading-attrs(1, .)"/>
        <xsl:call-template name="f:shead"><xsl:with-param name="text" select="$title"/></xsl:call-template>
        <xsl:value-of select="$title"/>
      </fo:block>
      <xsl:apply-templates select="gml:toc-entries/gml:toc-entry | gml:figlist-entries/gml:figlist-entry">
        <xsl:with-param name="st" tunnel="yes" select="map:put($st, 'noids', true()) => map:put('nofn', true())"/>
      </xsl:apply-templates>
    </fo:block>
  </xsl:template>

  <xsl:template match="gml:toc-entry | gml:figlist-entry">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="level" select="xs:integer((@level[. castable as xs:integer], 2)[1])"/>
    <xsl:variable name="ind" select="f:dim($toc-indent)"/>
    <fo:block text-align="justify" text-align-last="justify" text-indent="0pt"
        start-indent="{f:len(f:add(f:S0($st), ($ind[1] * max((0, $level - 1)), $ind[2] * max((0, $level - 1)))))}"
        end-indent="{f:pts(3 * $f:ch)}" last-line-end-indent="{f:pts(-3 * $f:ch)}">
      <xsl:if test="self::gml:figlist-entry or $level le 1">
        <xsl:attribute name="space-before" select="f:lines(if ($level le 1) then 0.75 else 0.25)"/>
      </xsl:if>
      <xsl:sequence select="f:font(if (self::gml:figlist-entry) then 'hd2toc' else concat('hd', min(($level, 3)), 'toc'), .)"/>
      <xsl:apply-templates select="." mode="f:toc-attrs"/>
      <xsl:variable name="link" select="f:citable(., string(@refid))"/>
      <xsl:choose>
        <xsl:when test="$link">
          <fo:basic-link internal-destination="{@refid}">
            <xsl:apply-templates select="gml:num, gml:entry-text/node()"/>
          </fo:basic-link>
        </xsl:when>
        <xsl:otherwise><xsl:apply-templates select="gml:num, gml:entry-text/node()"/></xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
      <fo:leader leader-pattern="dots"/>
      <xsl:text> </xsl:text>
      <xsl:for-each select="gml:pageref">
        <xsl:call-template name="f:page-citation"/>
      </xsl:for-each>
    </fo:block>
  </xsl:template>

  <!-- ==== index ======================================================== -->
  <xsl:template match="index">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="title" select="string(gml:index-entries/@title)"/>
    <fo:block break-before="{if ($f:duplex) then 'odd-page' else 'page'}">
      <xsl:call-template name="f:block-attrs"/>
      <xsl:if test="$st?cols gt 1 and parent::*[self::body or self::appendix or self::backm]">
        <xsl:attribute name="span" select="'all'"/>
      </xsl:if>
      <xsl:sequence select="f:heading-attrs(1, .)"/>
      <xsl:call-template name="f:shead"><xsl:with-param name="text" select="$title"/></xsl:call-template>
      <xsl:value-of select="$title"/>
    </fo:block>
    <xsl:apply-templates select="gml:index-entries/gml:index-group">
      <xsl:with-param name="st" tunnel="yes" select="map:put($st, 'noids', true()) => map:put('nofn', true())"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="gml:index-group">
    <fo:block text-align="start" hyphenate="false">
      <xsl:if test="normalize-space(@letter)">
        <fo:block keep-with-next.within-column="always" space-before="{f:lines(1)}"
            space-before.conditionality="discard" space-after="{f:lines(0.5)}">
          <xsl:sequence select="f:font('ieh', .)"/>
          <xsl:value-of select="@letter"/>
        </fo:block>
      </xsl:if>
      <xsl:apply-templates select="gml:index-entry"/>
    </fo:block>
  </xsl:template>

  <xsl:template match="gml:index-entry">
    <xsl:param name="st" tunnel="yes" as="map(*)"/>
    <xsl:variable name="level" select="xs:integer((@level[. castable as xs:integer], 1)[1])"/>
    <xsl:variable name="hang" select="2 * $f:ch"/>
    <fo:block start-indent="{f:len(f:add(f:S0($st), ((($level - 1) * 2 * $f:ch) + $hang, 0)))}"
        text-indent="{f:pts(-$hang)}">
      <xsl:if test="$level = 1"><xsl:attribute name="keep-with-next.within-column" select="if (gml:index-entry) then 'always' else 'auto'"/></xsl:if>
      <xsl:apply-templates select="." mode="f:index-attrs"/>
      <xsl:apply-templates select="gml:index-term/node()"/>
      <xsl:for-each select="gml:pageref">
        <xsl:choose>
          <xsl:when test="@range = 'end' and preceding-sibling::gml:pageref[1][@range = 'start']">
            <xsl:text>–</xsl:text>
          </xsl:when>
          <xsl:otherwise><xsl:text>, </xsl:text></xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="f:page-citation"/>
      </xsl:for-each>
      <xsl:for-each select="gml:see">
        <xsl:value-of select="if (preceding-sibling::gml:pageref or preceding-sibling::gml:see) then '. ' else ' '"/>
        <fo:inline font-style="italic"><xsl:value-of select="@label"/></fo:inline>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
      </xsl:for-each>
    </fo:block>
    <xsl:apply-templates select="gml:index-entry"/>
  </xsl:template>

  <!-- ==== hooks for vendor stylesheets (empty here) ==================== -->
  <!-- each adds attributes to the FO element it is applied in -->
  <xsl:mode name="f:root-attrs" on-no-match="deep-skip"/>
  <xsl:mode name="f:page-sequence-attrs" on-no-match="deep-skip"/>
  <xsl:mode name="f:float-attrs" on-no-match="deep-skip"/>
  <xsl:mode name="f:toc-attrs" on-no-match="deep-skip"/>
  <xsl:mode name="f:index-attrs" on-no-match="deep-skip"/>

</xsl:stylesheet>
