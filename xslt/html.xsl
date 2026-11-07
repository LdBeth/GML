<?xml version="1.0" encoding="UTF-8"?>
<!--
  html.xsl - scoped GML XML -> HTML5.

  Input: the output of scope.xsl (resolve.xsl -> scope.xsl): the Starter
  Set elements, the resolve.xsl vocabulary (num/anchor/nest/callout
  attributes, gml:num, gml:pageref, gml:toc-entries, gml:figlist-entries,
  gml:index-entries), gml:scope wrappers for the formatting state, and the
  event hints of lib/hints.ml.  Output: one HTML5 document (method html,
  version 5, UTF-8) styled by share/html/gml.css.  Every element written
  has a class "gml-NAME" (plain p, li, dt, dd excepted) so the stylesheet,
  or a user stylesheet importing this one, can restyle it.

  Parameters
    css           href of the stylesheet to link (default "gml.css"; ""
                  = no link).  Copy share/html/gml.css next to the HTML,
                  or point css at it.
    css-inline    "yes" = embed the CSS in a <style> element instead of
                  linking it, read with unparsed-text() from css-file.
    css-file      the CSS file read by css-inline=yes (default
                  ../share/html/gml.css relative to this stylesheet).
    lang          html/@lang (default "en").
    title         html <title>; default: the text of the first :title,
                  else of the first heading, else "Document".
    footnotes     where the collected footnotes go: "document" (default:
                  one list at the end of the document) or "chapter" (a list
                  before each h0/h1 for the footnotes of the chapter it
                  ends, and at the end of each document section).
    pageref       gml:pageref (HTML has no pages): "none" (default) =
                  nothing; "link" = a "§" link to the target after the
                  reference.  Index page references are always written,
                  as links numbered 1, 2, ... within each entry.
    lit-abstract, lit-preface   the headings generated for :abstract and
                  :preface (DSMABSTR/DSMPREF print "Abstract"/"Preface";
                  "" = none).
    lit-note      the label of :note (DSMNOTE: "Note:" in highlight 2).
    lit-footnotes heading of the footnote list ("" = none, the default).
    ul-identifiers  the bullets of :ul by nesting depth (cycling; blanks
                  or commas separate them); l-identifier: the :l label.
    table-width   the nominal width of a table whose rows use different
                  cwidths and that has no width= (a DCF width, "6.5i").

  Element mapping:
    gml:doc -> html/head/body/main; gdoc -> article (sec= -> p.gml-sec);
    frontm body appendix backm -> section.gml-NAME; titlep -> header;
    title -> h1.gml-title; docnum date author -> p.gml-NAME; address ->
    address, aline -> div; abstract preface -> section with a generated
    h1; h0 -> h1.gml-h0 (part), h1-h6 -> h1-h6.gml-hN, gml:h -> same;
    p -> p; pc -> p.gml-pc; note -> p.gml-note; lq -> blockquote; q -> q
    (the quotation marks come from CSS quotes, nested level aware); cit
    -> cite; hp0 -> span, hp1 -> em, hp2 -> strong, hp3 -> strong>em;
    ol ul sl l -> ol/ul with explicit labels (span.gml-label; gml:num for
    ol, ul-identifiers for ul); lp -> li.gml-lp; dl gl -> dl, dthd dt gt
    -> dt, ddhd dd gd -> dd; xmp -> pre; fig -> figure (frame, place and
    width as classes), the figure body in div.gml-figbody (format off, as
    DSMFIG), figcap + figdesc -> one figcaption; fn -> sup callout +
    the collected footnote list (section.gml-footnotes); fnref hdref
    figref liref -> a href="#anchor"; toc figlist -> nav with nested
    lists of links; index -> section with letter groups; i1-i3 ih1-ih3
    iref -> empty span id=anchor; psc -> its content.
    table -> table.gml-table (span, split as classes; width= as CSS
    width) with caption (caption-side bottom: tcap span.gml-tcap +
    tdesc), colgroup (one col per grid column: absolute widths
    converted, k* a share of what remains via calc(); when the rows use
    different cwidths, the union of their column boundaries for a
    nominal width, width= or $table-width, in percent), thead (thd,
    cells th), tfoot (tft), tbody (rows, tnote as one full-width td);
    a row with subrows=k is k tr, cells with rowspan/colspan, empty
    td.gml-hole for squares no cell covers; cell hp -> class gml-hpN,
    align/valign -> text-align/vertical-align, concat=no -> white-space:
    pre-wrap, mindepth -> height, rotate/shade -> classes; gml:cpart ->
    div.gml-cpart (gml.css rules between them); rdef -> nothing; tref ->
    a; tlist -> nav like figlist.

  Hints
    gml:br       br, only between two pieces of running text (not at the
                 start or end of a block, nor next to a block).
    gml:sp/sk    an empty block of that height.
    gml:pa       an empty block with break-before: page (recto/verso for
                 odd/even; nothing for .pa on/off).  gml:cp/cc: an empty
                 block with break-after: avoid-page and data-need (CSS
                 cannot ask for "n lines left"); gml:cb: break-before:
                 column.
    gml:hr       hr.  gml:sx: a flex line, left / fill / right.
    gml:lines    ce ri: a centred / right-aligned block whose input lines
                 stay lines (white-space: pre-line); us up uc: underline /
                 uppercase spans; in ir: a block with that margin; il un:
                 a block with that first-line indent; rc: span.gml-rc.
    gml:scope    kind=block -> div (span display:block in phrasing
                 content; in a list, its CSS goes on each item instead),
                 kind=inline -> span (div in flow content), with the
                 properties as inline CSS (below); a scope with nothing
                 to say is unwrapped.  Properties with no CSS equivalent
                 are kept as data-gml-NAME.
    gml:raw backend="html" is copied unescaped; other backends dropped.
    gml:rh gml:rf (page furniture) dropped; gml:fn -> an unnumbered
    entry of the footnote list.  The device-level events (bx vr kp tc dh
    df hw rc fl is ic dr cl cd sc mc pn pl pw pm tm bm, temporary in/ir,
    hy options) have no HTML meaning and are dropped, as are sa re (the
    saved environment) and ix (the place of the index: resolve.xsl put the
    gml:index-entries after it).  gml:pi (a SCRIPT index entry) is a link
    target, like the index tags.

  Scope properties -> CSS
    in        margin-left   ir  margin-right   (state values are absolute:
              each scope writes the difference from the enclosing scope,
              calc(new - old), so nesting adds up to the DCF value)
    of        padding-left (difference) + text-indent: -of (hanging)
    ll        max-width (default: var(-\-gml-measure))
    fill=no   white-space: pre-wrap      fill=yes  white-space: normal
    align     text-align: left right center, justify ->
              var(-\-gml-justify), inside -> start, outside -> end
    overdraw  fold -> overflow-wrap: anywhere, trunc -> overflow: hidden
    tp tb     tab-size, when the stops are evenly spaced (else data only)
    ls n      line-height: calc(var(-\-gml-leading) * (1 + n))
    ls by f   line-height: calc(var(-\-gml-leading) * f)
    ls normal v  line-height: v
    font      class gml-font gml-font-NAME (gml.css styles hi0-hi3 as
              hp0-hp3, the hdN fonts, xmpfont), data-font
    hy        hyphens: auto | manual
    wz bc ws es sb ud: data-gml-NAME only.

  DCF units (lib/units.ml) -> CSS
    ch -> ch (figure space ~ the width of "0"); line -> lh (the line
    height of the element); i -> in; cm -> cm; mm -> mm; pt (points and
    picas) -> pt; dd (Didot points, ciceros) -> pt x 1.0657 (1 dd =
    0.376 mm); mh, mv, m -> em; dh, dv (device units) -> px; a mixed sum
    "4ch+1i" -> calc(4ch + 1in); an operand without a unit is ch
    (horizontal) or lh (vertical).

  Tests: xslt/test/html/NAME.in.xml were made from xslt/test/gml/html-NAME.gml
  (and starter.gml) with
    gmlfmt -to scoped -set SYSDAYOFM=13 -set SYSMONTH=06 -set SYSYEAR=1986
           -set SYSVARP=html gml/html-NAME.gml
  and copied from scope/*.out.xml for features, nesting, state, values;
  fn-chapter and params reuse fn and starter with other parameters.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:h="urn:x-gml:html"
    exclude-result-prefixes="#all">

  <xsl:include href="common.xsl"/>

  <xsl:output method="html" version="5.0" encoding="UTF-8" indent="no"
      include-content-type="no"/>

  <!-- ==== parameters ================================================== -->
  <xsl:param name="css" as="xs:string" select="'gml.css'"/>
  <xsl:param name="css-inline" as="xs:string" select="'no'"/>
  <xsl:param name="css-file" as="xs:string"
      select="string(resolve-uri('../share/html/gml.css', static-base-uri()))"/>
  <xsl:param name="lang" as="xs:string" select="'en'"/>
  <xsl:param name="title" as="xs:string" select="''"/>
  <xsl:param name="footnotes" as="xs:string" select="'document'"/>
  <xsl:param name="pageref" as="xs:string" select="'none'"/>
  <xsl:param name="lit-abstract" as="xs:string" select="'Abstract'"/>
  <xsl:param name="lit-preface" as="xs:string" select="'Preface'"/>
  <xsl:param name="lit-note" as="xs:string" select="'Note:'"/>
  <xsl:param name="lit-footnotes" as="xs:string" select="''"/>
  <xsl:param name="ul-identifiers" as="xs:string" select="'• – ◦'"/>
  <xsl:param name="l-identifier" as="xs:string" select="'*'"/>
  <xsl:param name="table-width" as="xs:string" select="'6.5i'"/>

  <xsl:variable name="nbsp" select="'&#xA0;'"/>
  <xsl:variable name="ul-ids" select="tokenize(normalize-space(translate($ul-identifiers, ',', ' ')), ' ')"/>
  <xsl:variable name="chapter-notes" as="xs:boolean" select="$footnotes = 'chapter'"/>

  <!-- ==== the vocabulary ============================================== -->
  <!-- Element names an importing stylesheet handles itself (user tags):
       redefine this variable there so they are not reported as unknown. -->
  <xsl:variable name="h:extra-known" as="xs:string*" select="()"/>
  <xsl:variable name="h:known" select="('gdoc', 'frontm', 'body', 'appendix', 'backm',
      'titlep', 'title', 'docnum', 'date', 'author', 'address', 'aline', 'abstract', 'preface',
      'toc', 'figlist', 'index', 'h0', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'p', 'pc', 'note', 'lq', 'q', 'cit', 'hp0', 'hp1', 'hp2', 'hp3',
      'ol', 'ul', 'sl', 'l', 'dl', 'gl', 'li', 'lp', 'dt', 'dd', 'dthd', 'ddhd', 'gt', 'gd',
      'xmp', 'fig', 'figcap', 'figdesc', 'fn', 'fnref', 'hdref', 'figref', 'liref',
      'i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref', 'psc',
      'rdef', 'table', 'thd', 'tft', 'row', 'c', 'tnote', 'tcap', 'tdesc', 'tref', 'tlist')"/>
  <!-- gml: elements written as something -->
  <xsl:variable name="h:gml-used" select="('doc', 'scope', 'lines', 'br', 'sp', 'sk', 'pa',
      'cp', 'cc', 'cb', 'hr', 'sx', 'h', 'fn', 'rh', 'rf', 'raw', 'num', 'pageref',
      'toc-entries', 'toc-entry', 'entry-text', 'figlist-entries', 'figlist-entry',
      'tlist-entries', 'tlist-entry', 'cpart', 'dv', 'pi',
      'index-entries', 'index-group', 'index-entry', 'index-term', 'see')"/>
  <!-- hint mode: a formatting profile wrote the text, numbers and labels
       (gml:hint-mode, common.xsl; as tex.xsl's auto mode) -->
  <xsl:variable name="h:hint-mode" as="xs:boolean" select="gml:hint-mode(/)"/>
  <!-- gml: hints with no HTML meaning: dropped (the state hints too, in
       case the input was not scoped) -->
  <xsl:variable name="h:gml-dropped" select="('bx', 'vr', 'kp', 'tc', 'dh', 'df', 'hw', 'rc',
      'fl', 'is', 'ic', 'dr', 'cl', 'cd', 'sc', 'mc', 'pn', 'pl', 'pw', 'pm', 'tm', 'bm',
      'in', 'ir', 'hy', 'of', 'll', 'fo', 'nf', 'ju', 'tp', 'tb', 'ls', 'wz', 'bc',
      'bf', 'pf', 'ws', 'es', 'sb', 'ud', 'query', 'tcmark', 'sa', 're', 'ix')"/>
  <xsl:variable name="h:lists" select="('ol', 'ul', 'sl', 'l', 'dl', 'gl')"/>
  <xsl:variable name="h:index-tags" select="('i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>
  <!-- elements written inline (phrasing) -->
  <xsl:variable name="h:inline-tags" select="('q', 'cit', 'hp0', 'hp1', 'hp2', 'hp3', 'fn',
      'fnref', 'hdref', 'figref', 'liref', 'tref', 'i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>

  <xsl:function name="h:unknown" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="if (namespace-uri($e) = 'urn:x-gml:canonical')
        then not(local-name($e) = ($h:gml-used, $h:gml-dropped))
        else namespace-uri($e) != '' or not(local-name($e) = ($h:known, $h:extra-known))"/>
  </xsl:function>

  <xsl:function name="h:no-ns" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="$n instance of element() and namespace-uri($n) = ''"/>
  </xsl:function>

  <!-- does this node render as inline content? (for gml:br and for the
       blank text between elements) -->
  <xsl:function name="h:inline" as="xs:boolean">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="if (empty($n)) then false()
        else if ($n instance of text()) then normalize-space($n) != ''
        else if (not($n instance of element())) then false()
        else if (h:no-ns($n) and local-name($n) = $h:inline-tags) then true()
        else if ($n/self::gml:scope) then $n/@kind = 'inline'
        else if ($n/self::gml:lines) then $n/@word = ('us', 'up', 'uc', 'rc')
        else if ($n/self::gml:raw) then $n/@backend = 'html'
        else if ($n/self::gml:dv) then true()
        else h:unknown($n)"/>
  </xsl:function>

  <!-- nodes that leave nothing visible, skipped when looking for the
       neighbours of a gml:br -->
  <xsl:function name="h:invisible" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="($n instance of text() and normalize-space($n) = '')
        or (h:no-ns($n) and local-name($n) = $h:index-tags)
        or exists($n/self::gml:pi)
        or ($n/self::fn and not($n/@callout = 'yes'))
        or exists($n/(self::gml:fn | self::gml:rh | self::gml:rf))
        or ($n/self::gml:raw and not($n/@backend = 'html'))
        or ($n/self::gml:* and local-name($n) = $h:gml-dropped)"/>
  </xsl:function>

  <!-- ==== units ======================================================= -->
  <!-- one DCF term (n, unit) -> a CSS length -->
  <xsl:function name="h:term" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="unit" as="xs:string"/>
    <xsl:variable name="v" select="number($n)"/>
    <xsl:choose>
      <xsl:when test="$v = 0">0px</xsl:when>
      <xsl:when test="$unit = 'ch'"><xsl:sequence select="$n || 'ch'"/></xsl:when>
      <xsl:when test="$unit = 'line'"><xsl:sequence select="$n || 'lh'"/></xsl:when>
      <xsl:when test="$unit = 'i'"><xsl:sequence select="$n || 'in'"/></xsl:when>
      <xsl:when test="$unit = ('cm', 'mm', 'pt')"><xsl:sequence select="$n || $unit"/></xsl:when>
      <xsl:when test="$unit = 'dd'">
        <xsl:sequence select="string(round($v * 1.0657, 2)) || 'pt'"/>
      </xsl:when>
      <xsl:when test="$unit = ('mh', 'mv', 'm')"><xsl:sequence select="$n || 'em'"/></xsl:when>
      <xsl:when test="$unit = ('dh', 'dv')"><xsl:sequence select="$n || 'px'"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="$n || $unit"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- a DCF dimension ("5ch", "1.5i", "4ch+1i", "default+1i", "0") ->
       a CSS expression without calc(): "5ch", "4ch + 1in" -->
  <xsl:function name="h:expr" as="xs:string">
    <xsl:param name="d" as="xs:string"/>
    <xsl:param name="default-unit" as="xs:string"/>
    <xsl:variable name="parts" as="xs:string*">
      <xsl:analyze-string select="normalize-space($d)"
          regex="([+\-]?)\s*(default|[0-9]*\.?[0-9]+)([a-z]*)">
        <xsl:matching-substring>
          <xsl:variable name="sign" select="regex-group(1)"/>
          <xsl:variable name="len" select="if (regex-group(2) = 'default') then 'var(--gml-measure)'
              else h:term(regex-group(2), if (regex-group(3) = '') then $default-unit else regex-group(3))"/>
          <xsl:sequence select="if ($sign = '-') then '-' else '+', $len"/>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="if (empty($parts)) then '0px'
        else string-join((if ($parts[1] = '-') then '-' else '') || $parts[2]
                         || string-join(for $i in 2 to count($parts) idiv 2
                                        return ' ' || $parts[2 * $i - 1] || ' ' || $parts[2 * $i]), '')"/>
  </xsl:function>

  <xsl:function name="h:compound" as="xs:boolean">
    <xsl:param name="e" as="xs:string"/>
    <xsl:sequence select="contains($e, ' ')"/>
  </xsl:function>

  <!-- a CSS length: "0", "5ch", "calc(4ch + 1in)" -->
  <xsl:function name="h:len" as="xs:string">
    <xsl:param name="d" as="xs:string"/>
    <xsl:param name="default-unit" as="xs:string"/>
    <xsl:variable name="e" select="h:expr($d, $default-unit)"/>
    <xsl:sequence select="if ($e = '0px') then '0'
        else if (h:compound($e)) then 'calc(' || $e || ')' else $e"/>
  </xsl:function>

  <!-- the difference new - old, for an absolute state value written
       inside an element that already has the old one -->
  <xsl:function name="h:rel" as="xs:string">
    <xsl:param name="new" as="xs:string"/>
    <xsl:param name="old" as="xs:string?"/>
    <xsl:variable name="o" select="if (empty($old)) then '0px' else h:expr($old, 'ch')"/>
    <xsl:variable name="n" select="h:expr($new, 'ch')"/>
    <xsl:sequence select="if ($o = '0px') then h:len($new, 'ch')
        else if ($n = $o) then '0'
        else 'calc(' || $n || ' - ' || (if (h:compound($o)) then '(' || $o || ')' else $o) || ')'"/>
  </xsl:function>

  <xsl:function name="h:neg" as="xs:string">
    <xsl:param name="d" as="xs:string"/>
    <xsl:variable name="e" select="h:expr($d, 'ch')"/>
    <xsl:sequence select="if ($e = '0px') then '0'
        else if (h:compound($e)) then 'calc(-1 * (' || $e || '))'
        else if (starts-with($e, '-')) then substring($e, 2) else '-' || $e"/>
  </xsl:function>

  <!-- tab stops -> tab-size, when they are evenly spaced from the margin -->
  <xsl:function name="h:tab-size" as="xs:string?">
    <xsl:param name="stops" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$stops = 'default'">8</xsl:when>
      <xsl:otherwise>
        <xsl:variable name="t" select="tokenize(normalize-space($stops), ' ')"/>
        <xsl:variable name="u" select="replace($t[1], '^[0-9.]+', '')"/>
        <xsl:variable name="n" select="for $s in $t return
            if (matches($s, '^[0-9]*\.?[0-9]+[a-z]*$') and replace($s, '^[0-9.]+', '') = $u)
            then number(replace($s, '[a-z]+$', '')) else -1"/>
        <xsl:if test="$n[1] gt 0 and (every $i in 1 to count($n) satisfies $n[$i] = $i * $n[1])">
          <xsl:sequence select="if ($u = ('ch', '')) then string($n[1]) else h:len($t[1], 'ch')"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="h:line-height" as="xs:string?">
    <xsl:param name="spec" as="xs:string"/>
    <xsl:variable name="w" select="tokenize(normalize-space($spec), ' ')"/>
    <xsl:variable name="first" select="$w[1]"/>
    <xsl:choose>
      <xsl:when test="$spec = 'default'">var(--gml-leading)</xsl:when>
      <xsl:when test="$first = 'by' and $w[2] castable as xs:double">
        <xsl:sequence select="'calc(var(--gml-leading) * ' || string(xs:double($w[2])) || ')'"/>
      </xsl:when>
      <xsl:when test="$first = 'normal' and exists($w[2])">
        <xsl:sequence select="h:len($w[2], 'line')"/>
      </xsl:when>
      <xsl:when test="$first = 'normal'">var(--gml-leading)</xsl:when>
      <xsl:when test="matches($first, '^[0-9]*\.?[0-9]+(line)?$')">
        <xsl:variable name="n" select="number(replace($first, 'line$', ''))"/>
        <xsl:sequence select="if ($n = 0) then 'var(--gml-leading)'
            else 'calc(var(--gml-leading) * ' || string(1 + $n) || ')'"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- ==== scopes ======================================================= -->
  <!-- a scope whose nearest non-scope ancestor is a list: its CSS goes on
       the items -->
  <xsl:function name="h:distributed" as="xs:boolean">
    <xsl:param name="s" as="element()"/>
    <xsl:sequence select="exists($s/ancestor::*[not(self::gml:scope)][1]
                                  [h:no-ns(.) and local-name(.) = $h:lists])"/>
  </xsl:function>

  <!-- the scopes around $n in the OUTPUT: its scope ancestors, less
       those outside a footnote it is in (footnotes are written at the end)
       and those between a figure and its caption (the caption is written
       by the figure) -->
  <xsl:function name="h:outer-scopes" as="element(gml:scope)*">
    <xsl:param name="n" as="element()"/>
    <xsl:variable name="fn" select="$n/ancestor::*[self::fn or self::gml:fn][1]"/>
    <xsl:variable name="cap" select="$n/ancestor::*[self::figcap or self::figdesc][1]"/>
    <xsl:variable name="fig" select="$cap/ancestor::fig[1]"/>
    <xsl:sequence select="$n/ancestor::gml:scope[empty($fn) or . >> $fn]
                                                [empty($cap) or not(. >> $fig and . &lt;&lt; $cap)]"/>
  </xsl:function>

  <!-- the value of a margin property in force around box $s -->
  <xsl:function name="h:outer" as="xs:string?">
    <xsl:param name="s" as="element()"/>
    <xsl:param name="prop" as="xs:string"/>
    <xsl:variable name="around" select="h:outer-scopes($s)[@*[local-name() = $prop]]"/>
    <xsl:sequence select="(if ($s/self::gml:scope and h:distributed($s))
                           then $around[not(h:distributed(.))] else $around)
                          [last()]/@*[local-name() = $prop]/string()"/>
  </xsl:function>

  <!-- is a block scope written as a box?  Not when it continues running
       text without a break (its hint had break="no", or it re-opens the
       state after an inline element ended): a box would break the line. -->
  <xsl:function name="h:box" as="xs:boolean">
    <xsl:param name="s" as="element(gml:scope)"/>
    <xsl:variable name="first" select="$s/node()[not(h:invisible(.))][1]"/>
    <xsl:variable name="prev" select="$s/preceding-sibling::node()[not(h:invisible(.))][1]"/>
    <xsl:sequence select="$s/@kind = 'block' and (exists($first/self::gml:br) or not(h:inline($prev))
        or exists($s/*[not(h:inline(.) or h:invisible(.) or self::gml:br)]))"/>
  </xsl:function>

  <xsl:function name="h:font-class" as="xs:string">
    <xsl:param name="font" as="xs:string"/>
    <xsl:sequence select="'gml-font-' || replace(lower-case(tokenize(normalize-space($font), ' ')[1]),
                                                   '[^a-z0-9_\-]', '_')"/>
  </xsl:function>

  <!-- CSS declarations of a scope -->
  <xsl:function name="h:scope-css" as="xs:string*">
    <xsl:param name="s" as="element(gml:scope)"/>
    <xsl:variable name="in-xmp" select="exists($s/ancestor::xmp)"/>
    <xsl:for-each select="$s/@*">
      <xsl:variable name="v" select="string(.)"/>
      <xsl:choose>
        <xsl:when test="local-name() = 'in'">
          <xsl:sequence select="'margin-left: ' || h:rel($v, h:outer($s, 'in'))"/>
        </xsl:when>
        <xsl:when test="local-name() = 'ir'">
          <xsl:sequence select="'margin-right: ' || h:rel($v, h:outer($s, 'ir'))"/>
        </xsl:when>
        <xsl:when test="local-name() = 'of'">
          <xsl:sequence select="'padding-left: ' || h:rel($v, h:outer($s, 'of')),
                                'text-indent: ' || h:neg($v)"/>
        </xsl:when>
        <xsl:when test="local-name() = 'll'">
          <xsl:sequence select="'max-width: ' || (if ($v = 'default') then 'var(--gml-measure)'
                                                  else h:len($v, 'ch'))"/>
        </xsl:when>
        <xsl:when test="local-name() = 'fill'">
          <xsl:if test="not($in-xmp and $v = 'no')">
            <xsl:sequence select="'white-space: ' || (if ($v = 'no') then 'pre-wrap' else 'normal')"/>
          </xsl:if>
        </xsl:when>
        <xsl:when test="local-name() = 'align'">
          <xsl:if test="not($in-xmp and $v = 'left')">
            <xsl:sequence select="'text-align: ' || (if ($v = 'justify') then 'var(--gml-justify)'
                else if ($v = 'inside') then 'start' else if ($v = 'outside') then 'end' else $v)"/>
          </xsl:if>
        </xsl:when>
        <xsl:when test="local-name() = 'overdraw'">
          <xsl:sequence select="if ($v = 'fold') then 'overflow-wrap: anywhere'
              else if ($v = 'trunc') then 'overflow: hidden' else 'overflow-wrap: normal'"/>
        </xsl:when>
        <xsl:when test="local-name() = ('tp', 'tb')">
          <xsl:sequence select="h:tab-size($v) ! ('tab-size: ' || .)"/>
        </xsl:when>
        <xsl:when test="local-name() = 'ls'">
          <xsl:sequence select="h:line-height($v) ! ('line-height: ' || .)"/>
        </xsl:when>
        <xsl:when test="local-name() = 'hy'">
          <xsl:sequence select="'hyphens: ' || (if ($v = 'on') then 'auto' else 'manual')"/>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <!-- the attributes of a scope that CSS does not express -->
  <xsl:template name="h:scope-data">
    <xsl:param name="s" as="element(gml:scope)"/>
    <xsl:for-each select="$s/@*[local-name() = ('tp', 'tb', 'wz', 'bc', 'ws', 'es', 'sb', 'ud')]">
      <xsl:attribute name="data-gml-{local-name()}" select="."/>
    </xsl:for-each>
    <xsl:for-each select="$s/@font">
      <xsl:attribute name="data-font" select="."/>
    </xsl:for-each>
  </xsl:template>

  <xsl:function name="h:scope-class" as="xs:string*">
    <xsl:param name="s" as="element(gml:scope)"/>
    <xsl:sequence select="$s/@font ! ('gml-font', h:font-class(.))"/>
  </xsl:function>

  <xsl:template match="gml:scope">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:param name="item-css" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:param name="item-class" as="xs:string*" tunnel="yes" select="()"/>
    <!-- a block scope written inline keeps only what applies to text -->
    <xsl:variable name="css" select="if (@kind = 'block' and $ctx != 'list' and not(h:box(.)))
        then h:scope-css(.)[matches(., '^(white-space|line-height|tab-size|hyphens|overflow-wrap):')]
        else h:scope-css(.)"/>
    <xsl:variable name="class" select="h:scope-class(.)"/>
    <xsl:variable name="data" select="exists(@*[local-name() = ('tp', 'tb', 'wz', 'bc', 'ws', 'es', 'sb', 'ud', 'font')])"/>
    <xsl:choose>
      <xsl:when test="$ctx = 'list'">
        <xsl:apply-templates>
          <xsl:with-param name="item-css" select="$item-css, $css" tunnel="yes"/>
          <xsl:with-param name="item-class" select="$item-class, $class" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="empty($css) and empty($class) and not($data)">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <!-- div: in flow content, for a box or around block content;
             else span (display: block for a box in phrasing content) -->
        <xsl:variable name="block" select="h:box(.)"/>
        <xsl:variable name="has-blocks" select="exists(*[not(h:inline(.) or h:invisible(.) or self::gml:br)])"/>
        <xsl:element name="{if ($ctx = 'flow' and ($block or $has-blocks)) then 'div' else 'span'}">
          <xsl:attribute name="class" select="string-join(('gml-scope', $class), ' ')"/>
          <xsl:if test="exists($css) or ($block and $ctx = 'phrasing')">
            <xsl:attribute name="style" select="string-join((
                if ($block and $ctx = 'phrasing') then 'display: block' else (), $css), '; ')"/>
          </xsl:if>
          <xsl:call-template name="h:scope-data"><xsl:with-param name="s" select="."/></xsl:call-template>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- a block box: div in flow content, span display:block in phrasing
       content, li in a list -->
  <xsl:template name="h:block">
    <xsl:param name="ctx" as="xs:string"/>
    <xsl:param name="class" as="xs:string"/>
    <xsl:param name="css" as="xs:string*" select="()"/>
    <xsl:param name="content" as="item()*" select="()"/>
    <xsl:element name="{if ($ctx = 'phrasing') then 'span' else if ($ctx = 'list') then 'li' else 'div'}">
      <xsl:attribute name="class" select="$class"/>
      <xsl:if test="$ctx = 'phrasing' or exists($css)">
        <xsl:attribute name="style" select="string-join((
            if ($ctx = 'phrasing' and not($css[starts-with(., 'display:')])) then 'display: block' else (),
            $css), '; ')"/>
      </xsl:if>
      <xsl:sequence select="$content"/>
    </xsl:element>
  </xsl:template>

  <!-- ==== the document ================================================ -->
  <xsl:template match="/">
    <xsl:for-each-group select="//*[h:unknown(.)]" group-by="name()">
      <xsl:message select="'html: unknown element ' || current-grouping-key()
                           || ': written as span.gml-unknown'"/>
    </xsl:for-each-group>
    <xsl:variable name="html">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:apply-templates select="$html" mode="h:out"/>
  </xsl:template>

  <!-- ==== output pass: a newline before each block element where blank
       text is not significant (so the HTML can be read and diffed), and
       the raw HTML of gml:raw ==================================== -->
  <xsl:variable name="h:blocks" select="('head', 'body', 'main', 'article', 'section', 'header',
      'nav', 'figure', 'figcaption', 'ul', 'ol', 'dl', 'dt', 'dd', 'li', 'pre', 'p', 'blockquote',
      'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'address', 'hr', 'meta', 'title', 'link', 'style',
      'table', 'caption', 'colgroup', 'col', 'thead', 'tfoot', 'tbody', 'tr', 'td', 'th')"/>
  <xsl:variable name="h:containers" select="('html', 'head', 'body', 'main', 'article', 'section',
      'header', 'nav', 'figure', 'ul', 'ol', 'dl', 'li', 'dd', 'blockquote', 'div', 'address',
      'table', 'colgroup', 'thead', 'tfoot', 'tbody', 'tr')"/>

  <xsl:mode name="h:out" on-no-match="shallow-copy"/>
  <xsl:template mode="h:out" match="*[local-name() = $h:blocks]">
    <xsl:if test="parent::*[local-name() = $h:containers]
                  [not(ancestor-or-self::*[self::pre or contains(@class, 'gml-figbody')
                                           or contains(@style, 'white-space: pre')])]
                  and not(preceding-sibling::node()[1][self::text()][ends-with(., '&#10;')])">
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="h:out"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template mode="h:out" match="h:raw">
    <xsl:value-of select="." disable-output-escaping="yes"/>
  </xsl:template>

  <xsl:template match="gml:doc">
    <html lang="{$lang}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="generator" content="GML html.xsl"/>
        <title><xsl:value-of select="h:doc-title(.)"/></title>
        <xsl:choose>
          <xsl:when test="$css-inline = 'yes'">
            <style><xsl:text>&#10;</xsl:text><xsl:value-of select="unparsed-text($css-file)"/></style>
          </xsl:when>
          <xsl:when test="$css != ''">
            <link rel="stylesheet" href="{$css}"/>
          </xsl:when>
        </xsl:choose>
        <xsl:text>&#10;</xsl:text>
      </head>
      <body class="gml">
        <main class="gml-doc">
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
          </xsl:apply-templates>
          <xsl:sequence select="h:footnotes(if ($chapter-notes) then key('fn-chapter', 'root')
                                            else (//fn | //gml:fn))"/>
          <xsl:text>&#10;</xsl:text>
        </main>
        <xsl:text>&#10;</xsl:text>
      </body>
      <xsl:text>&#10;</xsl:text>
    </html>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:function name="h:doc-title" as="xs:string">
    <xsl:param name="doc" as="element()"/>
    <xsl:variable name="t" select="($doc//title, $doc//*[self::h0 or self::h1])[1]"/>
    <xsl:sequence select="if ($title != '') then $title
        else if ($t) then normalize-space(string-join($t//text()[not(ancestor::fn or ancestor::gml:num
                                          or ancestor::gml:raw or ancestor::gml:rh or ancestor::gml:rf
                                          or ancestor::*[local-name() = $h:index-tags])], ''))
        else 'Document'"/>
  </xsl:function>

  <!-- blank text: kept in phrasing content, and in flow content between
       two inline nodes; dropped elsewhere (between blocks, in lists) -->
  <xsl:template match="text()[normalize-space() = '']">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:if test="$ctx = 'phrasing' or ($ctx = 'flow'
                  and h:inline(preceding-sibling::node()[1]) and h:inline(following-sibling::node()[1]))">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="gdoc">
    <article class="gml-gdoc">
      <xsl:if test="normalize-space(@sec) != ''">
        <p class="gml-sec"><xsl:value-of select="@sec"/></p>
      </xsl:if>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </article>
  </xsl:template>

  <xsl:template match="frontm | body | appendix | backm">
    <section class="gml-{local-name()}">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
      <xsl:if test="$chapter-notes">
        <xsl:variable name="last" select="(.//*[self::h0 or self::h1])[last()]"/>
        <xsl:sequence select="h:footnotes(key('fn-chapter',
                              if ($last) then generate-id($last) else generate-id(.)))"/>
      </xsl:if>
    </section>
  </xsl:template>

  <!-- ==== title page ==================================================== -->
  <xsl:template match="titlep">
    <header class="gml-titlep">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </header>
  </xsl:template>

  <xsl:template match="title">
    <h1 class="gml-title">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </h1>
  </xsl:template>

  <xsl:template match="docnum | date | author">
    <p class="gml-{local-name()}">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </p>
  </xsl:template>

  <xsl:template match="address">
    <address class="gml-address">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </address>
  </xsl:template>

  <xsl:template match="aline">
    <div class="gml-aline">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>

  <xsl:template match="abstract | preface">
    <xsl:variable name="head" select="if (self::abstract) then $lit-abstract else $lit-preface"/>
    <section class="gml-{local-name()}">
      <xsl:if test="$head != ''">
        <h1 class="gml-section-title"><xsl:value-of select="$head"/></h1>
      </xsl:if>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </section>
  </xsl:template>

  <!-- ==== headings ====================================================== -->
  <xsl:template match="h0 | h1 | h2 | h3 | h4 | h5 | h6">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:if test="$chapter-notes and (self::h0 or self::h1)">
      <xsl:variable name="s" select="h:section(.)"/>
      <xsl:variable name="prev" select="(preceding::*[self::h0 or self::h1][h:same(h:section(.), $s)])[last()]"/>
      <xsl:sequence select="h:footnotes(key('fn-chapter',
          if ($prev) then generate-id($prev) else if ($s) then generate-id($s) else 'root'))"/>
    </xsl:if>
    <xsl:call-template name="h:heading">
      <xsl:with-param name="ctx" select="$ctx"/>
      <xsl:with-param name="level" select="xs:integer(substring(local-name(), 2))"/>
      <xsl:with-param name="class" select="'gml-' || local-name()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="gml:h">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:call-template name="h:heading">
      <xsl:with-param name="ctx" select="$ctx"/>
      <xsl:with-param name="level" select="if (@level castable as xs:integer) then xs:integer(@level) else 1"/>
      <xsl:with-param name="class" select="'gml-h gml-h-' || @level"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="h:heading">
    <xsl:param name="ctx" as="xs:string"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="class" as="xs:string"/>
    <xsl:variable name="hn" select="'h' || max((1, min(($level, 6))))"/>
    <xsl:element name="{if ($ctx = 'phrasing') then 'span' else $hn}">
      <xsl:call-template name="h:id"/>
      <xsl:attribute name="class" select="$class"/>
      <xsl:if test="$ctx = 'phrasing'">
        <xsl:attribute name="role" select="'heading'"/>
        <xsl:attribute name="aria-level" select="max((1, min(($level, 6))))"/>
        <xsl:attribute name="style" select="'display: block'"/>
      </xsl:if>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template name="h:id">
    <xsl:variable name="id" select="(@anchor, @id)[1]"/>
    <xsl:if test="exists($id)"><xsl:attribute name="id" select="$id"/></xsl:if>
  </xsl:template>

  <!-- a generated number or label: the number, then a blank -->
  <xsl:template match="gml:num">
    <span class="gml-num"><xsl:apply-templates/></span>
    <xsl:text> </xsl:text>
  </xsl:template>
  <!-- hint mode: the profile wrote its own numbers and labels into the text
       ("Figure 1.", "Table 1.", "Note:"), so resolve.xsl's gml:num is
       dropped, as gml.tex does (in the toc, figlist and tlist entries too:
       their text is the caption with the profile's label) -->
  <xsl:template match="gml:num[$h:hint-mode]" priority="2"/>

  <!-- ==== paragraphs and phrases ========================================= -->
  <xsl:template match="p | pc">
    <p>
      <xsl:if test="self::pc"><xsl:attribute name="class" select="'gml-pc'"/></xsl:if>
      <xsl:call-template name="h:id"/>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </p>
  </xsl:template>

  <xsl:template match="note">
    <p class="gml-note">
      <xsl:if test="$lit-note != ''">
        <span class="gml-note-label"><xsl:value-of select="$lit-note"/></span>
        <xsl:value-of select="$nbsp"/>
      </xsl:if>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </p>
  </xsl:template>

  <xsl:template match="lq">
    <blockquote class="gml-lq">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </blockquote>
  </xsl:template>

  <xsl:template match="q | cit | hp0 | hp1 | hp2">
    <xsl:element name="{if (self::q) then 'q' else if (self::cit) then 'cite'
                        else if (self::hp1) then 'em' else if (self::hp2) then 'strong' else 'span'}">
      <xsl:attribute name="class" select="'gml-' || local-name()"/>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="hp3">
    <strong class="gml-hp3"><em>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </em></strong>
  </xsl:template>

  <!-- conditional section: its content (the engine already selected it) -->
  <xsl:template match="psc">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ==== lists ========================================================== -->
  <xsl:template match="ol | ul | sl | l">
    <xsl:element name="{if (self::ol) then 'ol' else 'ul'}">
      <xsl:attribute name="class" select="string-join(('gml-' || local-name(),
          if (@compact) then 'gml-compact' else (),
          if (@nest) then 'gml-nest-' || @nest else ()), ' ')"/>
      <xsl:call-template name="h:id"/>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'list'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dl | gl">
    <dl>
      <xsl:attribute name="class" select="string-join(('gml-' || local-name(),
          if (@compact) then 'gml-compact' else (),
          if (@break) then 'gml-break' else (),
          if (@headhi castable as xs:integer) then 'gml-headhi-' || @headhi else (),
          if (@termhi castable as xs:integer) then 'gml-termhi-' || @termhi else ()), ' ')"/>
      <xsl:if test="matches(@tsize, '^[0-9]')">
        <xsl:attribute name="style" select="'--gml-tsize: ' || h:len(@tsize, 'ch')"/>
      </xsl:if>
      <xsl:call-template name="h:id"/>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'list'" tunnel="yes"/>
      </xsl:apply-templates>
    </dl>
  </xsl:template>

  <!-- the class and style of a list item: its own, plus what the scopes
       around it in the list gave -->
  <xsl:template name="h:item-attrs">
    <xsl:param name="class" as="xs:string*"/>
    <xsl:param name="item-css" as="xs:string*"/>
    <xsl:param name="item-class" as="xs:string*"/>
    <xsl:call-template name="h:id"/>
    <xsl:if test="exists(($class, $item-class))">
      <xsl:attribute name="class" select="string-join(($class, $item-class), ' ')"/>
    </xsl:if>
    <xsl:if test="exists($item-css)">
      <xsl:attribute name="style" select="string-join($item-css, '; ')"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="li | lp">
    <xsl:param name="item-css" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:param name="item-class" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:variable name="list" select="ancestor::*[h:no-ns(.) and local-name() = $h:lists][1]"/>
    <xsl:variable name="label" as="item()*">
      <xsl:choose>
        <xsl:when test="self::lp"/>
        <xsl:when test="gml:num and $h:hint-mode"/>
        <xsl:when test="gml:num"><xsl:apply-templates select="gml:num/node()"/></xsl:when>
        <xsl:when test="$list/self::ul">
          <xsl:variable name="d" select="if ($list/@nest castable as xs:integer) then xs:integer($list/@nest)
                                         else count($list/ancestor-or-self::ul)"/>
          <xsl:value-of select="$ul-ids[($d - 1) mod count($ul-ids) + 1]"/>
        </xsl:when>
        <xsl:when test="$list/self::l"><xsl:value-of select="$l-identifier"/></xsl:when>
      </xsl:choose>
    </xsl:variable>
    <li>
      <xsl:call-template name="h:item-attrs">
        <xsl:with-param name="class" select="if (self::lp) then 'gml-lp' else ()"/>
        <xsl:with-param name="item-css" select="$item-css"/>
        <xsl:with-param name="item-class" select="$item-class"/>
      </xsl:call-template>
      <xsl:if test="exists($label)">
        <span class="gml-label"><xsl:sequence select="$label"/></span>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="node() except gml:num">
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
        <xsl:with-param name="item-css" select="()" tunnel="yes"/>
        <xsl:with-param name="item-class" select="()" tunnel="yes"/>
      </xsl:apply-templates>
    </li>
  </xsl:template>

  <xsl:template match="dt | dd | dthd | ddhd | gt | gd">
    <xsl:param name="item-css" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:param name="item-class" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:variable name="term" select="exists(self::dt | self::dthd | self::gt)"/>
    <xsl:element name="{if ($term) then 'dt' else 'dd'}">
      <xsl:call-template name="h:item-attrs">
        <xsl:with-param name="class" select="if (self::dt or self::dd) then () else 'gml-' || local-name()"/>
        <xsl:with-param name="item-css" select="$item-css"/>
        <xsl:with-param name="item-class" select="$item-class"/>
      </xsl:call-template>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="if ($term) then 'phrasing' else 'flow'" tunnel="yes"/>
        <xsl:with-param name="item-css" select="()" tunnel="yes"/>
        <xsl:with-param name="item-class" select="()" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <!-- ==== examples and figures =========================================== -->
  <xsl:template match="xmp">
    <pre class="gml-xmp">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </pre>
  </xsl:template>

  <xsl:template match="fig">
    <xsl:variable name="frame" select="(@frame, 'rule')[1]"/>
    <xsl:variable name="fclass" select="if ($frame = ('box', 'rule', 'none')) then $frame else 'char'"/>
    <xsl:variable name="caps" select=".//(figcap | figdesc)[ancestor::fig[1] is current()]"/>
    <xsl:variable name="rule" as="element()?">
      <xsl:if test="$fclass = 'char'">
        <div class="gml-frame-chars" aria-hidden="true">
          <xsl:value-of select="string-join(for $i in 1 to (200 idiv max((1, string-length($frame)))) return $frame, '')"/>
        </div>
      </xsl:if>
    </xsl:variable>
    <figure>
      <xsl:call-template name="h:id"/>
      <xsl:attribute name="class" select="string-join(('gml-fig', 'gml-frame-' || $fclass,
          @place ! ('gml-place-' || .), @width ! ('gml-width-' || .)), ' ')"/>
      <xsl:if test="$fclass = 'char'"><xsl:attribute name="data-frame" select="$frame"/></xsl:if>
      <xsl:sequence select="$rule"/>
      <div class="gml-figbody">
        <xsl:apply-templates select="node()[not(self::text()[normalize-space() = ''] and
                                                empty(following-sibling::node()[not(self::figcap or self::figdesc
                                                      or self::text()[normalize-space() = ''])]))]">
          <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
      <xsl:sequence select="$rule"/>
      <xsl:if test="$caps">
        <figcaption>
          <xsl:apply-templates select="$caps" mode="caption">
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </figcaption>
      </xsl:if>
    </figure>
  </xsl:template>

  <!-- the caption parts are written by fig, in mode caption -->
  <xsl:template match="figcap | figdesc"/>
  <xsl:template match="figcap" mode="caption">
    <span class="gml-figcap"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="figdesc" mode="caption">
    <span class="gml-figdesc" style="display: block"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- ==== tables ========================================================== -->
  <!-- DCF space units of a width (cwidths, width=, mindepth) -> CSS and
       nominal points (an inch is 72pt, a pica 12pt, a cicero 12 Didot
       points of 0.376mm, an em 10pt, a figure space (no unit) 7.2pt, a
       device unit 1/240 inch).  () if it is not a length. -->
  <xsl:function name="h:dcf-len" as="xs:anyAtomicType*">
    <xsl:param name="w" as="xs:string?"/>
    <xsl:param name="default-unit" as="xs:string"/>
    <xsl:variable name="v" select="translate(lower-case(normalize-space($w)), ',', '.')"/>
    <xsl:variable name="num" select="'([0-9]*\.?[0-9]+)'"/>
    <xsl:choose>
      <xsl:when test="matches($v, '^' || $num || '$')">
        <xsl:sequence select="if ($default-unit = 'line') then ($v || 'lh', number($v) * 12)
                              else ($v || 'ch', number($v) * 7.2)"/>
      </xsl:when>
      <xsl:when test="matches($v, '^' || $num || 'i$')">
        <xsl:variable name="n" select="replace($v, 'i$', '')"/>
        <xsl:sequence select="$n || 'in', number($n) * 72"/>
      </xsl:when>
      <xsl:when test="matches($v, '^' || $num || '(cm|mm)$')">
        <xsl:variable name="n" select="replace($v, '(cm|mm)$', '')"/>
        <xsl:sequence select="$v, number($n) * 72 div (if (ends-with($v, 'cm')) then 2.54 else 25.4)"/>
      </xsl:when>
      <xsl:when test="matches($v, '^[0-9]*[pc]([0-9]+(\.[0-9])?)?$') and $v ne 'p' and $v ne 'c'">
        <xsl:variable name="u" select="if (contains($v, 'p')) then 'p' else 'c'"/>
        <xsl:variable name="a" select="substring-before($v, $u)"/>
        <xsl:variable name="b" select="substring-after($v, $u)"/>
        <xsl:variable name="pt" select="(if ($a = '') then 0 else number($a)) * 12
                                        + (if ($b = '') then 0 else number($b))"/>
        <xsl:variable name="pt" select="if ($u = 'c') then round($pt * 1.0657, 2) else $pt"/>
        <xsl:sequence select="string($pt) || 'pt', $pt"/>
      </xsl:when>
      <xsl:when test="matches($v, '^' || $num || 'm[hv]?$')">
        <xsl:variable name="n" select="replace($v, 'm[hv]?$', '')"/>
        <xsl:sequence select="$n || 'em', number($n) * 10"/>
      </xsl:when>
      <xsl:when test="matches($v, '^[0-9]+d[hv]$')">
        <xsl:variable name="n" select="replace($v, 'd[hv]$', '')"/>
        <xsl:sequence select="$n || 'px', number($n) * 0.3"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- the factor of a "k*" width, () for an absolute one -->
  <xsl:function name="h:star" as="xs:double?">
    <xsl:param name="w" as="xs:string"/>
    <xsl:sequence select="if (matches($w, '^[0-9]*([.,][0-9]+)?\*$'))
        then (if ($w = '*') then 1 else number(translate(substring-before($w, '*'), ',', '.'))) else ()"/>
  </xsl:function>

  <xsl:function name="h:tokens" as="xs:string*">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:sequence select="tokenize(normalize-space($s), ' ')[. ne '']"/>
  </xsl:function>

  <!-- the column boundaries of a cwidths list, in nominal points, for a
       table $tw points wide: 0, then the right edge of each column -->
  <xsl:function name="h:bounds" as="xs:double*">
    <xsl:param name="cw" as="xs:string"/>
    <xsl:param name="tw" as="xs:double"/>
    <xsl:variable name="ws" select="h:tokens($cw)"/>
    <xsl:variable name="abs" select="sum(for $w in $ws return (if (empty(h:star($w))) then h:dcf-len($w, 'ch')[2] else 0, 0)[1])"/>
    <xsl:variable name="k" select="sum(for $w in $ws return (h:star($w), 0)[1])"/>
    <xsl:variable name="unit" select="if ($k = 0) then 0 else max((0, $tw - $abs)) div $k"/>
    <xsl:variable name="each" select="for $w in $ws return
        (if (exists(h:star($w))) then h:star($w) * $unit else h:dcf-len($w, 'ch')[2], 0)[1]"/>
    <xsl:sequence select="0, for $i in 1 to count($each) return round(sum(subsequence($each, 1, $i)), 2)"/>
  </xsl:function>

  <!-- The column grid of a table: one grid when all its rows share their
       cwidths (the widths as written: absolute ones converted, k* a share
       of what remains); else the union of the column boundaries of its
       row definitions, computed for a nominal width (the table's width=,
       or $table-width), the widths in percent. -->
  <xsl:function name="h:grid" as="element(grid)">
    <xsl:param name="t" as="element()"/>
    <xsl:variable name="cws" select="distinct-values($t//row/normalize-space(@cwidths))"/>
    <xsl:variable name="tw" select="(h:dcf-len($t/@width, 'ch')[2], h:dcf-len($table-width, 'ch')[2], 468)[1]"/>
    <xsl:choose>
      <xsl:when test="count($cws) le 1">
        <xsl:variable name="ws" select="h:tokens($cws[1])"/>
        <xsl:variable name="abs" select="$ws[empty(h:star(.))] ! h:dcf-len(., 'ch')[1]"/>
        <xsl:variable name="k" select="sum($ws ! (h:star(.), 0)[1])"/>
        <grid single="yes" n="{max((count($ws), 1))}">
          <xsl:for-each select="$ws">
            <xsl:variable name="s" select="h:star(.)"/>
            <col>
              <xsl:attribute name="w" select="
                  if (empty($s)) then (h:dcf-len(., 'ch')[1], 'auto')[1]
                  else if (empty($abs)) then string(round($s div $k * 100, 2)) || '%'
                  else 'calc((100% - ' || string-join($abs, ' - ') || ') * ' || string(round($s div $k, 4)) || ')'"/>
            </col>
          </xsl:for-each>
        </grid>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="b" select="sort(distinct-values(for $c in $cws return h:bounds($c, $tw)))"/>
        <xsl:variable name="total" select="max(($b[last()], 1))"/>
        <grid single="no" n="{count($b) - 1}">
          <xsl:for-each select="2 to count($b)">
            <col w="{round(($b[current()] - $b[current() - 1]) div $total * 100, 2)}%" at="{$b[current() - 1]}" to="{$b[current()]}"/>
          </xsl:for-each>
        </grid>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- (first column, number of columns) of a cell in the table grid -->
  <xsl:function name="h:cell-cols" as="xs:integer+">
    <xsl:param name="c" as="element()"/>
    <xsl:param name="grid" as="element(grid)"/>
    <xsl:param name="tw" as="xs:double"/>
    <xsl:variable name="col" select="xs:integer($c/@col)"/>
    <xsl:variable name="span" select="xs:integer($c/@colspan)"/>
    <xsl:choose>
      <xsl:when test="$grid/@single = 'yes'"><xsl:sequence select="$col, $span"/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="b" select="h:bounds($c/../@cwidths, $tw)"/>
        <xsl:variable name="from" select="$b[$col]"/>
        <xsl:variable name="to" select="$b[$col + $span]"/>
        <xsl:variable name="first" select="count($grid/col[number(@at) lt $from]) + 1"/>
        <xsl:sequence select="$first, max((1, count($grid/col[number(@at) ge $from and number(@to) le $to])))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="table">
    <xsl:variable name="grid" select="h:grid(.)"/>
    <xsl:variable name="tw" select="(h:dcf-len(@width, 'ch')[2], h:dcf-len($table-width, 'ch')[2], 468)[1]"/>
    <xsl:variable name="caps" select="tcap | tdesc"/>
    <table>
      <xsl:call-template name="h:id"/>
      <xsl:attribute name="class" select="string-join(('gml-table', 'gml-span-' || (@span, 'page')[1],
          (@rotate[. ne '0'] ! ('gml-rotate-' || .)), (@split ! ('gml-split-' || .))), ' ')"/>
      <xsl:if test="h:dcf-len(@width, 'ch')[1]">
        <xsl:attribute name="style" select="'width: ' || h:dcf-len(@width, 'ch')[1]"/>
      </xsl:if>
      <xsl:if test="$caps">
        <caption class="gml-tcaption">
          <xsl:apply-templates select="$caps" mode="caption">
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </caption>
      </xsl:if>
      <colgroup>
        <xsl:for-each select="$grid/col">
          <col style="width: {@w}"/>
        </xsl:for-each>
      </colgroup>
      <xsl:for-each select="thd, tft">
        <xsl:element name="{if (self::thd) then 'thead' else 'tfoot'}">
          <xsl:attribute name="class" select="'gml-' || local-name()"/>
          <xsl:apply-templates select="row">
            <xsl:with-param name="grid" select="$grid" tunnel="yes"/>
            <xsl:with-param name="tw" select="$tw" tunnel="yes"/>
            <xsl:with-param name="cell" select="if (self::thd) then 'th' else 'td'" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:element>
      </xsl:for-each>
      <tbody>
        <xsl:apply-templates select="* except (thd | tft | tcap | tdesc)">
          <xsl:with-param name="grid" select="$grid" tunnel="yes"/>
          <xsl:with-param name="tw" select="$tw" tunnel="yes"/>
          <xsl:with-param name="cell" select="'td'" tunnel="yes"/>
          <xsl:with-param name="ctx" select="'table'" tunnel="yes"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <!-- A row with subrows="k" is k tr; each cell goes in the tr of its
       first subrow.  The grid squares no cell covers (a cell that is not a
       rectangle, a row definition narrower than the table grid) get an
       empty td.gml-hole, so that every cell stays in its column. -->
  <xsl:template match="table//row">
    <xsl:param name="grid" as="element(grid)" tunnel="yes"/>
    <xsl:param name="tw" as="xs:double" tunnel="yes"/>
    <xsl:param name="cell" as="xs:string" tunnel="yes" select="'td'"/>
    <xsl:variable name="row" select="."/>
    <xsl:variable name="place" as="element(p)*">
      <xsl:for-each select="c">
        <xsl:variable name="cc" select="h:cell-cols(., $grid, $tw)"/>
        <p r="{@subrow}" rs="{(@rowspan, 1)[1]}" f="{$cc[1]}" n="{$cc[2]}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="1 to max((xs:integer(@subrows), 1))">
      <xsl:variable name="s" select="."/>
      <tr class="gml-row">
        <xsl:if test="$s = 1">
          <xsl:attribute name="class" select="string-join(('gml-row', $row/@auto[. = 'yes'] ! 'gml-row-auto',
                                                           $row/@split ! ('gml-split-' || .)), ' ')"/>
        </xsl:if>
        <xsl:for-each select="1 to xs:integer($grid/@n)">
          <xsl:variable name="j" select="."/>
          <xsl:variable name="i" select="index-of($place ! (xs:integer(@r) = $s and xs:integer(@f) = $j), true())[1]"/>
          <xsl:choose>
            <xsl:when test="exists($i)">
              <xsl:apply-templates select="$row/c[$i]"/>
            </xsl:when>
            <xsl:when test="$place[xs:integer(@r) le $s and xs:integer(@r) + xs:integer(@rs) gt $s
                                   and xs:integer(@f) le $j and xs:integer(@f) + xs:integer(@n) gt $j]"/>
            <xsl:otherwise>
              <xsl:element name="{$cell}"><xsl:attribute name="class" select="'gml-hole'"/></xsl:element>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </tr>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="table//c">
    <xsl:param name="grid" as="element(grid)" tunnel="yes"/>
    <xsl:param name="tw" as="xs:double" tunnel="yes"/>
    <xsl:param name="cell" as="xs:string" tunnel="yes" select="'td'"/>
    <xsl:variable name="cc" select="h:cell-cols(., $grid, $tw)"/>
    <xsl:variable name="css" as="xs:string*">
      <xsl:choose>
        <xsl:when test="@align = ('left', 'right', 'center', 'justify')">
          <xsl:sequence select="'text-align: ' || @align"/>
        </xsl:when>
        <xsl:when test="@align = 'inside'">text-align: start</xsl:when>
        <xsl:when test="@align = 'outside'">text-align: end</xsl:when>
      </xsl:choose>
      <xsl:sequence select="'vertical-align: ' || (if (@valign = 'center') then 'middle' else (@valign, 'top')[1])"/>
      <xsl:if test="@concat = 'no'">white-space: pre-wrap</xsl:if>
      <xsl:if test="h:dcf-len(@mindepth, 'line')[1]">
        <xsl:sequence select="'height: ' || h:dcf-len(@mindepth, 'line')[1]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:element name="{$cell}">
      <xsl:call-template name="h:id"/>
      <xsl:attribute name="class" select="string-join(('gml-c',
          (@hp[. = ('1', '2', '3')] ! ('gml-hp' || .)),
          (@rotate[not(. = ('0', ''))] ! ('gml-rotate-' || replace(., '^-', 'm'))),
          (@shade[not(. = ('0', ''))] ! ('gml-shade-' || .))), ' ')"/>
      <xsl:if test="$cc[2] gt 1"><xsl:attribute name="colspan" select="$cc[2]"/></xsl:if>
      <xsl:if test="xs:integer((@rowspan, 1)[1]) gt 1"><xsl:attribute name="rowspan" select="@rowspan"/></xsl:if>
      <xsl:attribute name="data-cell" select="@n"/>
      <xsl:attribute name="style" select="string-join($css, '; ')"/>
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <!-- the parts of a repeated cell, divided by a rule (gml.css) -->
  <xsl:template match="gml:cpart">
    <div class="gml-cpart">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>

  <!-- a table note: a row of one cell as wide as the table -->
  <xsl:template match="table/tnote">
    <xsl:param name="grid" as="element(grid)" tunnel="yes"/>
    <tr class="gml-tnote">
      <td colspan="{$grid/@n}">
        <xsl:apply-templates>
          <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
        </xsl:apply-templates>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="tnote/gml:num">
    <strong class="gml-tnote-label"><xsl:apply-templates/></strong>
    <xsl:value-of select="$nbsp"/>
  </xsl:template>

  <!-- the row definitions leave nothing; the caption parts are written by table -->
  <xsl:template match="rdef"/>
  <xsl:template match="tcap | tdesc"/>
  <xsl:template match="tcap" mode="caption">
    <span class="gml-tcap"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tdesc" mode="caption">
    <span class="gml-tdesc" style="display: block"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- ==== footnotes ======================================================= -->
  <xsl:function name="h:section" as="element()?">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="$n/ancestor-or-self::*[self::frontm or self::body
                            or self::appendix or self::backm][1]"/>
  </xsl:function>

  <xsl:function name="h:same" as="xs:boolean">
    <xsl:param name="a" as="element()?"/>
    <xsl:param name="b" as="element()?"/>
    <xsl:sequence select="(empty($a) and empty($b)) or ($a is $b)"/>
  </xsl:function>

  <!-- the chapter of a footnote: the h0/h1 it follows (or is in) within
       its document section, else the section, else "root" -->
  <xsl:function name="h:chapter" as="xs:string">
    <xsl:param name="f" as="element()"/>
    <xsl:variable name="s" select="h:section($f)"/>
    <xsl:variable name="hd" select="($f/preceding::* | $f/ancestor::*)[self::h0 or self::h1]
                                     [h:same(h:section(.), $s)][last()]"/>
    <xsl:sequence select="if ($hd) then generate-id($hd) else if ($s) then generate-id($s) else 'root'"/>
  </xsl:function>

  <xsl:key name="fn-chapter" match="fn | gml:fn" use="h:chapter(.)"/>

  <xsl:function name="h:footnotes" as="element()?">
    <xsl:param name="fns" as="element()*"/>
    <xsl:if test="exists($fns)">
      <section class="gml-footnotes" role="doc-endnotes">
        <xsl:if test="$lit-footnotes != ''">
          <h2 class="gml-footnotes-title"><xsl:value-of select="$lit-footnotes"/></h2>
        </xsl:if>
        <ol class="gml-footnote-list">
          <xsl:apply-templates select="$fns" mode="footnote">
            <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
          </xsl:apply-templates>
        </ol>
      </section>
    </xsl:if>
  </xsl:function>

  <!-- where it stands: the callout (callout="no": :fnref calls it out) -->
  <xsl:template match="fn">
    <xsl:if test="@callout = 'yes'">
      <sup class="gml-fn-callout"><a href="#{@anchor}" id="{@anchor}-ref" role="doc-noteref"><xsl:value-of select="@num"/></a></sup>
    </xsl:if>
  </xsl:template>
  <xsl:template match="gml:fn"/>

  <xsl:template match="fn" mode="footnote">
    <xsl:variable name="back" select="@callout = 'yes'
        or exists(//fnref[@resolved = 'yes'][@refid = current()/@id])"/>
    <li id="{@anchor}" class="gml-footnote">
      <span class="gml-fn-num">
        <xsl:choose>
          <xsl:when test="$back">
            <a href="#{@anchor}-ref" role="doc-backlink"><xsl:value-of select="@num"/></a>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="@num"/></xsl:otherwise>
        </xsl:choose>
      </span>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="node() except gml:num"/>
    </li>
  </xsl:template>

  <xsl:template match="gml:fn" mode="footnote">
    <li class="gml-footnote gml-fn-unnumbered">
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="fnref">
    <xsl:choose>
      <xsl:when test="@resolved = 'yes'">
        <xsl:variable name="t" select="key('h:id', string(@refid))[1]"/>
        <sup class="gml-fnref">
          <a href="#{@refid}" role="doc-noteref">
            <xsl:if test="$t/@callout = 'no' and empty(preceding::fnref[@refid = current()/@refid][@resolved = 'yes'])">
              <xsl:attribute name="id" select="@refid || '-ref'"/>
            </xsl:if>
            <xsl:apply-templates/>
          </a>
        </sup>
      </xsl:when>
      <xsl:otherwise>
        <sup class="gml-fnref gml-unresolved"><xsl:apply-templates/></sup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:key name="h:id" match="*[@id]" use="string(@id)"/>

  <!-- ==== cross-references ================================================ -->
  <xsl:template match="hdref | figref | liref | tref">
    <xsl:choose>
      <xsl:when test="@resolved = 'yes'">
        <a class="gml-{local-name()}" href="#{@refid}">
          <xsl:apply-templates select="node() except gml:pageref">
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </a>
        <xsl:apply-templates select="gml:pageref"/>
      </xsl:when>
      <xsl:otherwise>
        <span class="gml-{local-name()} gml-unresolved">
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="gml:pageref">
    <xsl:if test="$pageref = 'link'">
      <xsl:text> </xsl:text>
      <a class="gml-pageref" href="#{@refid}">
        <xsl:if test="@label"><xsl:attribute name="title" select="@label"/></xsl:if>
        <xsl:text>§</xsl:text>
      </a>
    </xsl:if>
  </xsl:template>

  <!-- index tags: a link target, their text is not printed -->
  <xsl:template match="i1 | i2 | i3 | ih1 | ih2 | ih3 | iref">
    <span class="gml-ix" id="{(@anchor, @id)[1]}"/>
  </xsl:template>
  <!-- a .pi entry (SCRIPT's index word): the same link target; its index
       is the gml:index-entries resolve.xsl put after the gml:ix (which is
       only the place, dropped) -->
  <xsl:template match="gml:pi">
    <xsl:if test="@anchor"><span class="gml-ix" id="{@anchor}"/></xsl:if>
  </xsl:template>

  <!-- ==== table of contents, figure list ================================== -->
  <xsl:template match="toc | figlist | tlist | index">
    <xsl:apply-templates select="gml:toc-entries | gml:figlist-entries | gml:tlist-entries | gml:index-entries"/>
  </xsl:template>

  <xsl:template match="gml:toc-entries">
    <nav class="gml-toc">
      <h1 class="gml-toc-title"><xsl:value-of select="@title"/></h1>
      <xsl:sequence select="h:toc-nest(gml:toc-entry)"/>
    </nav>
  </xsl:template>

  <xsl:function name="h:toc-nest" as="element()?">
    <xsl:param name="entries" as="element()*"/>
    <xsl:if test="exists($entries)">
      <xsl:variable name="m" select="min($entries/xs:integer(@level))"/>
      <ol class="gml-toc-list">
        <xsl:for-each-group select="$entries" group-starting-with="*[xs:integer(@level) = $m]">
          <xsl:choose>
            <xsl:when test="xs:integer(current-group()[1]/@level) = $m">
              <li class="gml-toc-entry gml-toc-l{@level} gml-toc-{@section}">
                <a href="#{@refid}">
                  <xsl:apply-templates select="gml:num | gml:entry-text">
                    <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
                  </xsl:apply-templates>
                </a>
                <xsl:sequence select="h:toc-nest(current-group()[position() gt 1])"/>
              </li>
            </xsl:when>
            <xsl:otherwise>
              <li class="gml-toc-entry gml-toc-skip">
                <xsl:sequence select="h:toc-nest(current-group())"/>
              </li>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </ol>
    </xsl:if>
  </xsl:function>

  <xsl:template match="gml:entry-text | gml:index-term">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="gml:figlist-entries | gml:tlist-entries">
    <xsl:variable name="k" select="substring-before(local-name(), '-')"/>
    <nav class="gml-{$k}">
      <h1 class="gml-{$k}-title"><xsl:value-of select="@title"/></h1>
      <xsl:if test="gml:figlist-entry | gml:tlist-entry">
        <ol class="gml-{$k}-list">
          <xsl:for-each select="gml:figlist-entry | gml:tlist-entry">
            <li class="gml-{$k}-entry">
              <a href="#{@refid}">
                <xsl:apply-templates select="gml:num | gml:entry-text">
                  <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
                </xsl:apply-templates>
              </a>
            </li>
          </xsl:for-each>
        </ol>
      </xsl:if>
    </nav>
  </xsl:template>

  <!-- ==== index =========================================================== -->
  <xsl:template match="gml:index-entries">
    <section class="gml-index">
      <xsl:if test="normalize-space(@title)"><h1 class="gml-index-title"><xsl:value-of select="@title"/></h1></xsl:if>
      <xsl:for-each select="gml:index-group">
        <div class="gml-index-group">
          <xsl:if test="@letter != ''">
            <h2 class="gml-index-letter"><xsl:value-of select="@letter"/></h2>
          </xsl:if>
          <ul class="gml-index-list">
            <xsl:apply-templates select="gml:index-entry"/>
          </ul>
        </div>
      </xsl:for-each>
    </section>
  </xsl:template>

  <xsl:template match="gml:index-entry">
    <li class="gml-index-entry gml-index-l{@level}">
      <span class="gml-index-term">
        <xsl:apply-templates select="gml:index-term">
          <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
        </xsl:apply-templates>
      </span>
      <xsl:for-each select="gml:pageref">
        <xsl:value-of select="if (preceding-sibling::gml:pageref[1]/@range = 'start' and @range = 'end')
                              then '–' else ', '"/>
        <xsl:variable name="link" as="element()">
          <a class="gml-index-ref" href="#{@refid}">
            <xsl:value-of select="if (@text) then @text else position()"/>
          </a>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="@major = 'yes'"><strong class="gml-major"><xsl:sequence select="$link"/></strong></xsl:when>
          <xsl:otherwise><xsl:sequence select="$link"/></xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:for-each select="gml:see">
        <xsl:value-of select="if (position() = 1 and empty(../gml:pageref)) then ' ' else '. '"/>
        <span class="gml-see gml-{@kind}">
          <em class="gml-see-label"><xsl:value-of select="@label"/></em>
          <xsl:text> </xsl:text>
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </span>
      </xsl:for-each>
      <xsl:if test="gml:index-entry">
        <ul class="gml-index-list">
          <xsl:apply-templates select="gml:index-entry"/>
        </ul>
      </xsl:if>
    </li>
  </xsl:template>

  <!-- ==== hints ============================================================ -->
  <!-- a break between two pieces of running text; elsewhere a block
       boundary already breaks the line -->
  <xsl:template match="gml:br">
    <xsl:if test="h:inline(preceding-sibling::node()[not(h:invisible(.))][1])
                  and h:inline(following-sibling::node()[not(h:invisible(.))][1])">
      <br/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="gml:sp | gml:sk">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:variable name="len" select="h:len(@n || @unit, 'line')"/>
    <xsl:if test="$len != '0'">
      <xsl:call-template name="h:block">
        <xsl:with-param name="ctx" select="$ctx"/>
        <xsl:with-param name="class" select="'gml-sp'"/>
        <xsl:with-param name="css" select="'height: ' || $len"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="gml:pa">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:if test="empty(@mode)">
      <xsl:call-template name="h:block">
        <xsl:with-param name="ctx" select="$ctx"/>
        <xsl:with-param name="class" select="'gml-pa'"/>
        <xsl:with-param name="css" select="'break-before: ' || (if (@side = 'odd') then 'recto'
                                           else if (@side = 'even') then 'verso' else 'page')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="gml:cp | gml:cc">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:call-template name="h:block">
      <xsl:with-param name="ctx" select="$ctx"/>
      <xsl:with-param name="class" select="'gml-' || local-name()"/>
      <xsl:with-param name="css" select="'break-after: ' || (if (self::gml:cp) then 'avoid-page' else 'avoid-column')"/>
      <xsl:with-param name="content" as="attribute()*">
        <xsl:if test="@n"><xsl:attribute name="data-need" select="h:len(@n || @unit, 'line')"/></xsl:if>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="gml:cb">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:call-template name="h:block">
      <xsl:with-param name="ctx" select="$ctx"/>
      <xsl:with-param name="class" select="'gml-cb'"/>
      <xsl:with-param name="css" select="'break-before: column'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="gml:hr">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:choose>
      <xsl:when test="$ctx = 'flow'"><hr class="gml-hr"/></xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="h:block">
          <xsl:with-param name="ctx" select="$ctx"/>
          <xsl:with-param name="class" select="'gml-hr'"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="gml:sx">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:call-template name="h:block">
      <xsl:with-param name="ctx" select="$ctx"/>
      <xsl:with-param name="class" select="'gml-sx'"/>
      <xsl:with-param name="css" select="'display: flex'"/>
      <xsl:with-param name="content" as="node()*">
        <span class="gml-sx-left"><xsl:value-of select="@left"/></span>
        <span class="gml-sx-fill" data-fill="{@fill}"/>
        <span class="gml-sx-right"><xsl:value-of select="@right"/></span>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="gml:lines">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:variable name="w" select="string(@word)"/>
    <xsl:choose>
      <xsl:when test="$w = ('us', 'up', 'uc', 'rc') or not($w = ('ce', 'ri', 'in', 'ir', 'il', 'un'))">
        <span class="gml-lines gml-{$w}">
          <xsl:if test="$w = 'rc'"><xsl:attribute name="data-rc" select="@char"/></xsl:if>
          <xsl:variable name="css" select="(
              if ($w = ('us', 'uc')) then 'text-decoration: underline' else (),
              if ($w = ('up', 'uc')) then 'text-transform: uppercase' else ())"/>
          <xsl:if test="exists($css)"><xsl:attribute name="style" select="string-join($css, '; ')"/></xsl:if>
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="css" as="xs:string*">
          <xsl:choose>
            <xsl:when test="$w = 'ce'">text-align: center; white-space: pre-line</xsl:when>
            <xsl:when test="$w = 'ri'">text-align: right; white-space: pre-line</xsl:when>
            <xsl:when test="$w = 'in' and @left">
              <xsl:sequence select="'margin-left: ' || h:rel(@left || @unit, h:outer(., 'in'))"/>
            </xsl:when>
            <xsl:when test="$w = 'ir' and @right">
              <xsl:sequence select="'margin-right: ' || h:rel(@right || @unit, h:outer(., 'ir'))"/>
            </xsl:when>
            <xsl:when test="$w = ('il', 'un') and @left">
              <xsl:sequence select="'text-indent: ' || h:rel(@left || @unit, h:outer(., 'in'))"/>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="h:block">
          <xsl:with-param name="ctx" select="if ($ctx = 'list') then 'flow' else $ctx"/>
          <xsl:with-param name="class" select="'gml-lines gml-' || $w"/>
          <xsl:with-param name="css" select="$css"/>
          <xsl:with-param name="content" as="node()*">
            <xsl:apply-templates/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="gml:raw[@backend = 'html']">
    <h:raw><xsl:value-of select="."/></h:raw>
  </xsl:template>
  <xsl:template match="gml:raw | gml:rh | gml:rf"/>
  <!-- a text variable (.dv, e.g. a profile's footnote callout): its text,
       raised (sup) or lowered (sub) when it has a baseline shift -->
  <xsl:template match="gml:dv">
    <xsl:variable name="b" select="normalize-space(@baseline)"/>
    <xsl:choose>
      <xsl:when test="matches($b, '^[+]?0*(\.0*)?[a-z]*$')"><xsl:value-of select="@text"/></xsl:when>
      <xsl:when test="starts-with($b, '-')"><sub><xsl:value-of select="@text"/></sub></xsl:when>
      <xsl:otherwise><sup><xsl:value-of select="@text"/></sup></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="gml:*[local-name() = $h:gml-dropped]" priority="-0.25"/>

  <!-- ==== anything else ===================================================== -->
  <xsl:template match="*" priority="-1">
    <span class="gml-unknown" data-tag="{name()}">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </span>
  </xsl:template>

</xsl:stylesheet>
