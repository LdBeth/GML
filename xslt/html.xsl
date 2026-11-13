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
                  or commas separate them).
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
    ol ul sl -> ol/ul with explicit labels (span.gml-label; gml:num for
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
    a row and its cells take what they do not state from the row's rdef
    (its gml:cell, h:ta); a row with subrows=k is k tr, cells with
    rowspan/colspan, empty td.gml-hole for squares no cell covers; cell
    hp -> class gml-hpN,
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
                 uppercase spans; rc (.rc * c, .rc n on/off): revised
                 text, ins.gml-lines.gml-rc data-rc=CHAR, as an inline
                 rc scope (below); a blank character marks nothing
                 (span.gml-lines).
    gml:scope    kind=block -> div (span display:block in phrasing
                 content; in a list, its CSS goes on each item instead),
                 kind=inline -> span (div in flow content), with the
                 properties as inline CSS (below); a scope with nothing
                 to say is unwrapped.  Properties with no CSS equivalent
                 are kept as data-gml-NAME.
    gml:raw backend="html" is copied unescaped; other backends dropped.
    gml:rh gml:rf (page furniture) dropped, and gml:symval (a new value
    of a symbol they refer to); gml:symref -> its value; gml:fn -> an unnumbered
    entry of the footnote list (kind=leader, the .fn leader definition:
    dropped, the list has its own rule).  gml:sp/sk: .sk skips that
    follow each other with nothing visible between (across scope
    boundaries) do not add up: the largest one is kept (gml.tex).  A
    gml:h (.hn) of a level defined NBR (gml:dh, accumulator h:dh) is a
    run-in heading (span.gml-runin, the text follows on the same line).
    Every other hint of the engine (gml-shared.xml, made by gmlshare from
    lib/hints.ml: h:gml-dropped) has no HTML meaning and is dropped: the
    device-level events, the page layout, the saved environment (sa re),
    ix (the place of the index: resolve.xsl put the gml:index-entries
    after it), the entries and marks of a SCRIPT .tc contents (tcentry
    tcmark: HTML has no pages; its table of contents is :toc's), and
    any hint the engine adds until this stylesheet handles it.  gml:pi (a
    SCRIPT index entry) is a link target, like the index tags.
    gml:in/gml:ir temporary="yes" (.in/.ir h FOR v1 [AFTER v2]): an
                 empty float, span.gml-in/.gml-ir aria-hidden="true" with
                 inline CSS only, before the next text (anywhere after
                 the hint, so blank space before the first text line, a
                 paragraph's top margin, does not count):
                   float, clear: left (ir: right); width: the new
                   margin less the one of the scopes around; height: v1,
                   or v2 + v1 with shape-outside: inset(v2 0 0 0)
                 The lines beside it, in that paragraph and the ones
                 after it in the same block formatting context, skips
                 included, make room for it, as DCF counts the distance.
    gml:il/gml:un .il/.un h, the next output line moved: text-indent: h
                 on its block when the line is the block's first and the
                 block has no block inside (the .il after a paragraph
                 tag; negative too, a hanging line); else, h > 0, a float
                 span.gml-il/.gml-un h wide, 1lh high, before the text;
                 nothing when a block ends or a whole one (a skip) comes
                 between the hint and the next text (the skip uses it
                 up, as in DCF), nor for a line moved left that is not
                 a block's first.  Of several before one text, the last counts.
                 These hints break: inside running text a br (the rule
                 of gml:br), the paragraph stays one block; with
                 NOBREAK the float takes the line it is in.  The output
                 pass (mode h:out) places the markers h:float and h:il
                 of the first pass, where the output blocks are known.
                 Limits: a distance in lines is n lh, the line height of
                 the text (CSS lh: 2023 browsers); a line taller than
                 that (a larger font) counts as more.  A float cannot
                 move lines out: an outdent for a distance (a FOR margin
                 left of the one around) is dropped, as is the AFTER of
                 a permanent .in (scope.xsl applies the margin at once).
                 A new .in/.ir ends a running distance in DCF; here only
                 a new FOR before any text replaces one (the float of a
                 FOR clears the earlier floats of its side), a float
                 placed is not shortened by a later margin change.  A
                 float lives in its block formatting context: a table
                 cell or a pre (overflow: auto) ends it.  A first line
                 moved left may reach into the page margin.

  Scope properties -> CSS
    in        margin-left   ir  margin-right   (state values are absolute:
              each scope writes the difference from the enclosing scope,
              calc(new - old), so nesting adds up to the DCF value)
    of        padding-left (difference) + text-indent: -of (hanging).
              DCF starts the hanging indention again after every break:
              a scope with blocks or gml:br inside is written as one
              div.gml-hang per run of text between them, each with the
              indention; and a .is to h tab after a label makes the
              label an inline block h wide (span.gml-hang-label, plus a
              no-break blank: a wider label is followed by one blank)
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
    rc        revised text (.rc; "" none, also for a blank revision
              character): the scope is written as ins (class gml-rc,
              data-rc the character) instead of div/span.  Around blocks
              (the div case) it is ins.gml-rc-block, display: block,
              and gml.css draws a rule in its left margin from its first
              line to its last; inside a paragraph (span case) it is an
              inline ins, faintly shaded (CSS cannot rule a margin per
              line).  In a list the scope's state goes on the items:
              li.gml-rc (dt, dd) data-rc, ruled outside the label.
              Limits: a revision that ends (or turns to a blank
              character) inside a block it began before still rules
              that whole block, an ancestor's rule cannot be undone; a
              different code inside a ruled block is shaded as well.
              ADJUST and ALIGN (events) are dropped.
    wz bc ws es sb ud: data-gml-NAME only.

  DCF units (lib/units.ml, by gml-shared.xml) -> CSS
    The relative units map to their CSS kin: ch -> ch (figure space ~
    the width of "0"); line -> lh (the line height of the element); mh,
    mv, m -> em.  The absolute units CSS has keep their size: i -> in;
    cm -> cm; mm -> mm; pt (points and picas) -> pt.  Every other unit
    with a size in gml-shared.xml is written in points, from its inch
    fraction there: dd (Didot points, ciceros; 37/2500 inch) x 1.0656,
    dh, dv (device units, 1/240 inch: 240dh is 72pt) x 0.3; rounded to
    two decimals.  A mixed sum "4ch+1i" -> calc(4ch + 1in); an operand
    without a unit is ch (horizontal) or lh (vertical).

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
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:h="urn:x-gml:html"
    xmlns:sh="urn:x-gml:shared"
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
      'ol', 'ul', 'sl', 'dl', 'gl', 'li', 'lp', 'dt', 'dd', 'dthd', 'ddhd', 'gt', 'gd',
      'xmp', 'fig', 'figcap', 'figdesc', 'fn', 'fnref', 'hdref', 'figref', 'liref',
      'i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref', 'psc',
      'rdef', 'table', 'thd', 'tft', 'row', 'c', 'tnote', 'tcap', 'tdesc', 'tref', 'tlist')"/>
  <!-- gml: nodes of the engine (gml-shared.xml) written as something;
       gml:rh and gml:rf, elements and hints, have a template that drops
       them -->
  <xsl:variable name="h:gml-used" select="('doc', 'lines', 'br', 'sp', 'sk', 'pa',
      'cp', 'cc', 'cb', 'hr', 'sx', 'h', 'fn', 'rh', 'rf', 'raw', 'dv', 'pi', 'symref')"/>
  <!-- the gml: vocabulary of resolve.xsl and scope.xsl -->
  <xsl:variable name="h:gml-stages" select="('scope', 'num', 'pageref',
      'toc-entries', 'toc-entry', 'entry-text', 'figlist-entries', 'figlist-entry',
      'tlist-entries', 'tlist-entry', 'cpart', 'cell',
      'index-entries', 'index-group', 'index-entry', 'index-term', 'see')"/>
  <!-- gml: hints with no HTML meaning, dropped: every other hint of
       gml-shared.xml (the state hints too, in case the input was not
       scoped).  A temporary in/ir and il/un have templates of their own
       (a marker the output pass moves to the next text), but count as
       invisible where they stand, as these do. -->
  <xsl:variable name="h:gml-dropped" as="xs:string*"
      select="$gml:hint-names[not(. = $h:gml-used)]"/>
  <xsl:variable name="h:lists" select="('ol', 'ul', 'sl', 'dl', 'gl')"/>
  <xsl:variable name="h:index-tags" select="('i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>
  <!-- elements written inline (phrasing) -->
  <xsl:variable name="h:inline-tags" select="('q', 'cit', 'hp0', 'hp1', 'hp2', 'hp3', 'fn',
      'fnref', 'hdref', 'figref', 'liref', 'tref', 'i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>

  <xsl:function name="h:unknown" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="if (namespace-uri($e) = 'urn:x-gml:canonical')
        then not(local-name($e) = ($h:gml-used, $h:gml-stages, $h:gml-dropped))
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
        else if ($n/self::gml:dv or $n/self::gml:symref) then true()
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
  <!-- The DCF units that CSS has, under its name: the relative ones
       mapped to their CSS kin, the absolute ones of the same size -->
  <xsl:variable name="h:css-units" as="map(xs:string, xs:string)" select="map {
      'ch': 'ch', 'line': 'lh', 'mh': 'em', 'mv': 'em', 'm': 'em',
      'i': 'in', 'cm': 'cm', 'mm': 'mm', 'pt': 'pt'}"/>
  <!-- points per unit of every unit with a size, from gml-shared.xml
       (lib/units.ml): the others (dd 1.0656, the device units dh dv 0.3)
       are written in points -->
  <xsl:variable name="h:unit-pt" as="map(xs:string, xs:decimal)"
      select="map:merge(for $u in $gml:unit-names return gml:unit-size($u, 'pt') ! map {$u: .})"/>

  <!-- one DCF term (n, unit) -> a CSS length -->
  <xsl:function name="h:term" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="unit" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="number($n) = 0">0px</xsl:when>
      <xsl:when test="map:contains($h:css-units, $unit)">
        <xsl:sequence select="$n || $h:css-units($unit)"/>
      </xsl:when>
      <xsl:when test="map:contains($h:unit-pt, $unit)">
        <xsl:sequence select="string(round(xs:decimal($n) * $h:unit-pt($unit), 2)) || 'pt'"/>
      </xsl:when>
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
    <xsl:sequence select="$s/@font ! ('gml-font', h:font-class(.)),
                          $s/@rc[. != ''] ! 'gml-rc'"/>
  </xsl:function>

  <xsl:template match="gml:scope">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:param name="item-css" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:param name="item-class" as="xs:string*" tunnel="yes" select="()"/>
    <xsl:param name="item-rc" as="xs:string?" tunnel="yes" select="()"/>
    <!-- revised text (.rc): the revision character, "" none -->
    <xsl:variable name="rc" select="string(@rc)"/>
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
          <xsl:with-param name="item-rc" select="if (exists(@rc)) then $rc[. != ''] else $item-rc"
              tunnel="yes"/>
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
        <!-- a hanging indention (of) over breaks: each run of text between
             them gets the indention (h:hang-runs; a scope with one run too,
             for its label), the scope keeps the rest -->
        <xsl:variable name="hang-css" select="$css[matches(., '^(padding-left|text-indent):')]"/>
        <xsl:variable name="hang" select="exists($hang-css) and $ctx = 'flow'"/>
        <xsl:variable name="css" select="if ($hang) then $css[not(. = $hang-css)] else $css"/>
        <xsl:variable name="div" select="$ctx = 'flow' and ($block or $has-blocks or $hang)"/>
        <!-- revised text is ins (transparent: a block in flow content):
             ruled in the margin around blocks (gml-rc-block), shaded
             inside a paragraph -->
        <xsl:element name="{if ($rc != '') then 'ins' else if ($div) then 'div' else 'span'}">
          <xsl:attribute name="class" select="string-join(('gml-scope', $class,
              if ($rc != '' and $div) then 'gml-rc-block' else ()), ' ')"/>
          <xsl:if test="$rc != ''"><xsl:attribute name="data-rc" select="$rc"/></xsl:if>
          <xsl:if test="exists($css) or ($block and $ctx = 'phrasing')">
            <xsl:attribute name="style" select="string-join((
                if ($block and $ctx = 'phrasing') then 'display: block' else (), $css), '; ')"/>
          </xsl:if>
          <xsl:call-template name="h:scope-data"><xsl:with-param name="s" select="."/></xsl:call-template>
          <xsl:choose>
            <xsl:when test="$hang">
              <xsl:call-template name="h:hang-runs">
                <xsl:with-param name="css" select="$hang-css"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- a block box: div in flow content, span display:block in phrasing
       content, li in a list -->
  <!-- the runs of inline content of a hanging scope, between its breaks
       (gml:br, which the run boundary replaces; blocks, written as they
       are): one div.gml-hang each, with the indention -->
  <xsl:template name="h:hang-runs">
    <xsl:param name="css" as="xs:string*"/>
    <xsl:for-each-group select="node()" group-adjacent="h:inline(.) or h:invisible(.)">
      <xsl:choose>
        <xsl:when test="current-grouping-key() and exists(current-group()[not(h:invisible(.))])">
          <div class="gml-hang" style="{string-join($css, '; ')}">
            <xsl:call-template name="h:labelled-run">
              <xsl:with-param name="nodes" select="current-group()"/>
            </xsl:call-template>
          </div>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()[not(self::gml:br)]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <!-- a run with a label: the text before a .is "to h" tab (a list item's
       identifier, a definition term) is an inline block h wide, so that
       the text after it starts at h (the hanging indention), or after one
       blank when the label is wider (the no-break blank at its end) -->
  <xsl:template name="h:labelled-run">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:variable name="is" select="($nodes[self::gml:is][matches(normalize-space(@spec), '^to ')])[1]"/>
    <xsl:variable name="before" select="$nodes[exists($is) and . &lt;&lt; $is]"/>
    <xsl:choose>
      <xsl:when test="exists($before[h:inline(.)])">
        <xsl:variable name="label" as="node()*">
          <xsl:apply-templates select="$before"/>
        </xsl:variable>
        <span class="gml-hang-label" style="display: inline-block; text-indent: 0; min-width: {h:len(tokenize(normalize-space($is/@spec), ' ')[2], 'ch')}">
          <xsl:apply-templates select="$label" mode="h:trim-end">
            <xsl:with-param name="last" select="($label/descendant-or-self::text()[normalize-space() != ''])[last()]" tunnel="yes"/>
          </xsl:apply-templates>
          <xsl:value-of select="$nbsp"/>
        </span>
        <xsl:apply-templates select="$nodes[. &gt;&gt; $is]"/>
      </xsl:when>
      <xsl:otherwise><xsl:apply-templates select="$nodes"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- a result tree without the blank space after its last text -->
  <xsl:mode name="h:trim-end" on-no-match="shallow-copy"/>
  <xsl:template match="text()" mode="h:trim-end">
    <xsl:param name="last" as="text()?" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($last) and . is $last"><xsl:value-of select="replace(., '\s+$', '')"/></xsl:when>
      <xsl:when test="normalize-space() = '' and (empty($last) or . &gt;&gt; $last)"/>
      <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

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

  <xsl:mode use-accumulators="#all"/>
  <xsl:mode name="h:out" on-no-match="shallow-copy"/>
  <xsl:template mode="h:out" match="*[local-name() = $h:blocks]">
    <xsl:if test="parent::*[local-name() = $h:containers]
                  [not(ancestor-or-self::*[self::pre or contains(@class, 'gml-figbody')
                                           or contains(@style, 'white-space: pre')])]
                  and not(preceding-sibling::node()[1][self::text()][ends-with(., '&#10;')])">
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <xsl:call-template name="h:out-copy"/>
  </xsl:template>
  <xsl:template mode="h:out" match="span[key('h:il-block', generate-id())]">
    <xsl:call-template name="h:out-copy"/>
  </xsl:template>
  <!-- an element, with the first-line indention of a .il/.un it starts
       with (added to one it has, a hanging indention's) -->
  <xsl:template name="h:out-copy">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="h:out"/>
      <xsl:variable name="style" select="string(@style)"/>
      <xsl:for-each select="key('h:il-block', generate-id())[last()]">
        <xsl:attribute name="style" select="
            if (matches($style, '(^|;)\s*text-indent:'))
            then replace($style, '((^|;)\s*)text-indent:\s*([^;]+)', '$1text-indent: calc($3 + ' || @shift || ')')
            else string-join(($style[. != ''], 'text-indent: ' || @shift), '; ')"/>
      </xsl:for-each>
      <xsl:apply-templates select="node()" mode="h:out"/>
    </xsl:copy>
  </xsl:template>

  <!-- indention for a distance, one line moved: the markers of the first
       pass (gml:in gml:ir gml:il gml:un) go to the next text -->
  <xsl:key name="h:at" match="h:float | h:il"
      use="generate-id((following::text()[normalize-space() != ''])[1])"/>
  <xsl:key name="h:il-block" match="h:il[h:il-use(.) = 'indent']"
      use="generate-id((following::text()[normalize-space() != ''])[1]/ancestor::*[h:out-block(.)][1])"/>
  <xsl:template mode="h:out" match="h:float | h:il"/>
  <xsl:template mode="h:out" match="text()[key('h:at', generate-id())]" priority="1">
    <!-- the floats of .in/.ir first: one of .il/.un is beside them -->
    <xsl:for-each select="key('h:at', generate-id())[self::h:float],
                          key('h:at', generate-id())[self::h:il][h:il-use(.) = 'float']">
      <span class="{@class}" aria-hidden="true"
            style="{if (self::h:il) then 'float: left; width: ' || @shift || '; height: 1lh' else @style}"/>
    </xsl:for-each>
    <xsl:next-match/>
  </xsl:template>

  <!-- a block box of the output -->
  <xsl:function name="h:out-block" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="local-name($e) = $h:blocks
                          or ($e/self::span and matches($e/@style, '(^|;)\s*display:\s*(block|flex)'))"/>
  </xsl:function>

  <!-- How marker $m (.il/.un) moves the next line.  The next text, skip
       or space line uses it up: none when a block ends between it and the
       next text, or a whole block (a skip, a rule) is between them, or a
       later .il/.un counts instead.  "indent" (text-indent on the block)
       when the text is the first of its block, which has no block inside
       (they would inherit it): the usual .il after a paragraph tag.
       Otherwise "float" (one line high) when it moves the line right;
       a line moved left needs text-indent, so none. -->
  <xsl:function name="h:il-use" as="xs:string">
    <xsl:param name="m" as="element(h:il)"/>
    <xsl:variable name="t" select="($m/following::text()[normalize-space() != ''])[1]"/>
    <xsl:variable name="tblocks" select="$t/ancestor::*[h:out-block(.)]"/>
    <xsl:variable name="b" select="$tblocks[last()]"/>
    <xsl:choose>
      <!-- the first of: the text, a later .il/.un, a block not around
           the text -->
      <xsl:when test="empty($t) or exists($m/ancestor::*[h:out-block(.)] except $tblocks)
                      or not($m/following::node()[. is $t or self::h:il
                             or (self::* and h:out-block(.) and not(some $b in $tblocks satisfies $b is .))][1]
                             is $t)">none</xsl:when>
      <xsl:when test="exists($b) and ($b//text()[normalize-space() != ''])[1] is $t
                      and empty($b//*[h:out-block(.)])">indent</xsl:when>
      <xsl:when test="$m/@right = 'true'">float</xsl:when>
      <xsl:otherwise>none</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template mode="h:out" match="h:raw">
    <xsl:value-of select="." disable-output-escaping="yes"/>
  </xsl:template>

  <!-- A line end between two East Asian wide characters is no space: the
       engine writes each input line end as a newline (SCRIPT/VS joins
       filled lines with a blank, and has no rule for CJK), which a browser
       would show as a space between 日本 and 語.  The rule is the segment
       break transformation of CSS Text 3 (as markdown-it-cjk-breaks):
       removed, with the blanks around it, when the characters on both
       sides are wide, fullwidth or halfwidth, and neither is Hangul
       (Korean puts spaces between its words).  The neighbours are looked
       for across inline markup, within the same block; preserved text
       (pre, white-space: pre*, figure bodies) keeps its line ends.  TeX
       needs none of this: pTeX drops such a line end itself, by its
       \kcatcode. -->
  <xsl:variable name="h:wide" as="xs:string" select="'[&#x2E80;-&#x303E;&#x3041;-&#x312F;&#x3190;-&#x33FF;&#x3400;-&#x4DBF;&#x4E00;-&#x9FFF;&#xA000;-&#xA4CF;&#xF900;-&#xFAFF;&#xFE10;-&#xFE19;&#xFE30;-&#xFE6F;&#xFF00;-&#xFF9F;&#xFFE0;-&#xFFE6;&#x20000;-&#x2FFFD;&#x30000;-&#x3FFFD;]'"/>
  <xsl:template mode="h:out" match="text()[contains(., '&#10;')]">
    <xsl:choose>
      <xsl:when test="ancestor::*[local-name() = 'pre' or contains(@class, 'gml-figbody')
                                  or contains(@style, 'white-space: pre')]">
        <xsl:value-of select="."/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="block" select="ancestor::*[local-name() = $h:blocks][1]"/>
        <xsl:variable name="texts" select="$block//text()[normalize-space() != '']"/>
        <xsl:variable name="before" select="($texts[. &lt;&lt; current()])[last()]"/>
        <xsl:variable name="after" select="($texts[. &gt;&gt; current()])[1]"/>
        <!-- one character of context on each side, removed again below -->
        <xsl:variable name="p" select="if (exists($before)) then substring($before, string-length($before)) else ' '"/>
        <xsl:variable name="n" select="if (exists($after)) then substring($after, 1, 1) else ' '"/>
        <xsl:variable name="re" select="'(' || $h:wide || ')[ &#9;]*&#10;[ &#9;]*(' || $h:wide || ')'"/>
        <!-- twice: a match takes the character after the line end, which
             may be the one before the next line end (日\n本\n語) -->
        <xsl:variable name="s" select="replace(replace($p || . || $n, $re, '$1$2'), $re, '$1$2')"/>
        <xsl:value-of select="substring($s, 2, string-length($s) - 2)"/>
      </xsl:otherwise>
    </xsl:choose>
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
                                            else (//fn | //gml:fn[not(@kind = 'leader')]))"/>
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

  <!-- .dh per level: was the level defined NBR (a run-in heading: the text
       follows on the same line)?  .dh n alone restores the default (BR). -->
  <xsl:accumulator name="h:dh" as="map(xs:string, xs:boolean)" initial-value="map{}">
    <xsl:accumulator-rule match="gml:dh" select="
        let $l := normalize-space(@level),
            $w := tokenize(lower-case(normalize-space(translate(string(@spec), '()', '  '))), ' ')[. != ''],
            $b := $w[. = ('br', 'nbr')][last()]
        return if (empty($w)) then map:remove($value, $l)
               else if (exists($b)) then map:put($value, $l, $b = 'nbr')
               else $value"/>
  </xsl:accumulator>

  <xsl:template match="gml:h">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:variable name="level" select="if (@level castable as xs:integer) then xs:integer(@level) else 1"/>
    <xsl:variable name="id" select="(@anchor, @id)[1] ! string()"/>
    <xsl:variable name="class" select="'gml-h gml-h-' || @level"/>
    <xsl:choose>
      <xsl:when test="(accumulator-before('h:dh')(string(@level)), false())[1]">
        <span class="{$class} gml-runin" role="heading" aria-level="{max((1, min(($level, 6))))}">
          <xsl:if test="exists($id)"><xsl:attribute name="id" select="$id"/></xsl:if>
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </span>
        <xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="h:heading">
          <xsl:with-param name="ctx" select="$ctx"/>
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="class" select="$class"/>
          <xsl:with-param name="id" select="$id"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="h:heading">
    <xsl:param name="ctx" as="xs:string"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="class" as="xs:string"/>
    <xsl:param name="id" as="xs:string?" select="(@anchor, @id)[1] ! string()"/>
    <xsl:variable name="hn" select="'h' || max((1, min(($level, 6))))"/>
    <xsl:element name="{if ($ctx = 'phrasing') then 'span' else $hn}">
      <xsl:if test="exists($id)"><xsl:attribute name="id" select="$id"/></xsl:if>
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
  <xsl:template match="ol | ul | sl">
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
    <xsl:param name="item-rc" as="xs:string?" tunnel="yes" select="()"/>
    <xsl:variable name="item-class" select="$item-class[not(. = 'gml-rc')], $item-rc ! 'gml-rc'"/>
    <xsl:call-template name="h:id"/>
    <xsl:if test="exists(($class, $item-class))">
      <xsl:attribute name="class" select="string-join(($class, $item-class), ' ')"/>
    </xsl:if>
    <xsl:if test="exists($item-rc)"><xsl:attribute name="data-rc" select="$item-rc"/></xsl:if>
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
        <xsl:when test="gml:num"><xsl:apply-templates select="gml:num/node()"/></xsl:when>
        <xsl:when test="$list/self::ul">
          <xsl:variable name="d" select="if ($list/@nest castable as xs:integer) then xs:integer($list/@nest)
                                         else count($list/ancestor-or-self::ul)"/>
          <xsl:value-of select="$ul-ids[($d - 1) mod count($ul-ids) + 1]"/>
        </xsl:when>
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
        <xsl:with-param name="item-rc" select="()" tunnel="yes"/>
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
        <xsl:with-param name="item-rc" select="()" tunnel="yes"/>
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
       nominal points: the absolute and device units by their sizes in
       gml-shared.xml ($h:unit-pt; [n]p[p] picas and points, [n]c[p]
       ciceros and Didot points, 12 points to the pica or cicero), the
       relative ones by this stylesheet's guess (a figure space, no
       unit, 7.2pt, a line 12pt, an em 10pt).  () if it is not a
       length. -->
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
        <xsl:sequence select="$n || $h:css-units('i'), number($n) * $h:unit-pt('i')"/>
      </xsl:when>
      <xsl:when test="matches($v, '^' || $num || '(cm|mm)$')">
        <xsl:variable name="n" select="replace($v, '(cm|mm)$', '')"/>
        <xsl:sequence select="$v, number($n) * $h:unit-pt(replace($v, '^[0-9.]+', ''))"/>
      </xsl:when>
      <xsl:when test="matches($v, '^[0-9]*[pc]([0-9]+(\.[0-9])?)?$') and $v ne 'p' and $v ne 'c'">
        <xsl:variable name="u" select="if (contains($v, 'p')) then 'p' else 'c'"/>
        <xsl:variable name="a" select="substring-before($v, $u)"/>
        <xsl:variable name="b" select="substring-after($v, $u)"/>
        <xsl:variable name="pt" select="(if ($a = '') then 0 else number($a)) * 12
                                        + (if ($b = '') then 0 else number($b))"/>
        <xsl:variable name="pt" select="round(xs:decimal($pt) * $h:unit-pt($gml:shared/sh:units/sh:unit[@compound = $u]/@name), 2)"/>
        <xsl:sequence select="string($pt) || 'pt', number($pt)"/>
      </xsl:when>
      <xsl:when test="matches($v, '^' || $num || 'm[hv]?$')">
        <xsl:variable name="n" select="replace($v, 'm[hv]?$', '')"/>
        <xsl:sequence select="$n || 'em', number($n) * 10"/>
      </xsl:when>
      <xsl:when test="matches($v, '^[0-9]+d[hv]$')">
        <xsl:variable name="n" select="replace($v, 'd[hv]$', '')"/>
        <xsl:sequence select="h:term($n, 'dh'), number($n) * $h:unit-pt('dh')"/>
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

  <!-- A table attribute of a row (cols subrows cwidths) or of a cell (n col
       colspan subrow rowspan hp align valign concat rotate mindepth shade)
       in force: its own, else, for a row that names its rdef and states
       no cwidths, that of the rdef (the last one of that id before the
       row): the k-th gml:cell for the k-th c -->
  <xsl:key name="h:rdef" match="rdef[gml:cell]" use="string(@id)"/>
  <xsl:function name="h:ta" as="attribute()?">
    <xsl:param name="e" as="element()"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:variable name="row" select="if ($e/self::c) then $e/.. else $e"/>
    <xsl:variable name="def" select="if ($row/@cwidths or empty($row/@rdef)) then ()
        else key('h:rdef', string($row/@rdef), root($row))[. &lt;&lt; $row][last()]"/>
    <xsl:sequence select="($e/@*[local-name() = $name and namespace-uri() = ''],
        (if ($e/self::c) then $def/gml:cell[count($e/preceding-sibling::c) + 1] else $def)
          /@*[local-name() = $name])[1]"/>
  </xsl:function>

  <!-- The column grid of a table: one grid when all its rows share their
       cwidths (the widths as written: absolute ones converted, k* a share
       of what remains); else the union of the column boundaries of its
       row definitions, computed for a nominal width (the table's width=,
       or $table-width), the widths in percent. -->
  <xsl:function name="h:grid" as="element(grid)">
    <xsl:param name="t" as="element()"/>
    <xsl:variable name="cws" select="distinct-values($t//row ! normalize-space(h:ta(., 'cwidths')))"/>
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
    <xsl:variable name="col" select="xs:integer(h:ta($c, 'col'))"/>
    <xsl:variable name="span" select="xs:integer(h:ta($c, 'colspan'))"/>
    <xsl:choose>
      <xsl:when test="$grid/@single = 'yes'"><xsl:sequence select="$col, $span"/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="b" select="h:bounds(string(h:ta($c/.., 'cwidths')), $tw)"/>
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
        <p r="{h:ta(., 'subrow')}" rs="{(h:ta(., 'rowspan'), 1)[1]}" f="{$cc[1]}" n="{$cc[2]}"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="1 to max((xs:integer(h:ta(., 'subrows')), 1))">
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
    <xsl:variable name="align" select="h:ta(., 'align')"/>
    <xsl:variable name="valign" select="h:ta(., 'valign')"/>
    <xsl:variable name="mindepth" select="h:ta(., 'mindepth')"/>
    <xsl:variable name="rowspan" select="h:ta(., 'rowspan')"/>
    <xsl:variable name="css" as="xs:string*">
      <xsl:choose>
        <xsl:when test="$align = ('left', 'right', 'center', 'justify')">
          <xsl:sequence select="'text-align: ' || $align"/>
        </xsl:when>
        <xsl:when test="$align = 'inside'">text-align: start</xsl:when>
        <xsl:when test="$align = 'outside'">text-align: end</xsl:when>
      </xsl:choose>
      <xsl:sequence select="'vertical-align: ' || (if ($valign = 'center') then 'middle' else ($valign, 'top')[1])"/>
      <xsl:if test="h:ta(., 'concat') = 'no'">white-space: pre-wrap</xsl:if>
      <xsl:if test="h:dcf-len($mindepth, 'line')[1]">
        <xsl:sequence select="'height: ' || h:dcf-len($mindepth, 'line')[1]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:element name="{$cell}">
      <xsl:call-template name="h:id"/>
      <xsl:attribute name="class" select="string-join(('gml-c',
          (h:ta(., 'hp')[. = ('1', '2', '3')] ! ('gml-hp' || .)),
          (h:ta(., 'rotate')[not(. = ('0', ''))] ! ('gml-rotate-' || replace(., '^-', 'm'))),
          (h:ta(., 'shade')[not(. = ('0', ''))] ! ('gml-shade-' || .))), ' ')"/>
      <xsl:if test="$cc[2] gt 1"><xsl:attribute name="colspan" select="$cc[2]"/></xsl:if>
      <xsl:if test="xs:integer(($rowspan, 1)[1]) gt 1"><xsl:attribute name="rowspan" select="$rowspan"/></xsl:if>
      <xsl:attribute name="data-cell" select="h:ta(., 'n')"/>
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

  <xsl:key name="fn-chapter" match="fn | gml:fn[not(@kind = 'leader')]" use="h:chapter(.)"/>

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

  <!-- ==== indention for a distance, one line moved (.in/.ir FOR, .il/.un) ====
       Output lines do not exist in HTML, but a vertical distance from a
       line does: an empty float of the indention's width and the
       distance's height pushes the line boxes beside it aside, across the
       paragraphs and the skips between them, as DCF counts.  The hints
       write markers (h:float, h:il) in the first pass; the output pass
       (mode h:out) puts each float before the next text (so blank space
       before the first text line, a paragraph's top margin, does not
       count) and decides .il there, where the blocks are known. -->

  <!-- a hint that counts output lines (and breaks) -->
  <xsl:function name="h:line-hint" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="exists($n/(self::gml:in | self::gml:ir)[@temporary = 'yes'][@break = 'yes']
                                 | $n/(self::gml:il | self::gml:un)[@break = 'yes'])"/>
  </xsl:function>

  <!-- the line break such a hint causes: br between two pieces of running
       text (the rule of gml:br), once for adjacent ones; the paragraph is
       not split -->
  <xsl:template name="h:line-hint-break">
    <xsl:variable name="next" select="following-sibling::node()[not(h:invisible(.))][1]"/>
    <xsl:if test="@break = 'yes'
                  and h:inline(preceding-sibling::node()[not(h:invisible(.))][1]) and h:inline($next)
                  and empty(following-sibling::*[h:line-hint(.)][. &lt;&lt; $next])">
      <br/>
    </xsl:if>
  </xsl:template>

  <!-- a DCF value + unit attribute ("3" "ch", "3ch+1i" "mixed") -->
  <xsl:function name="h:dim" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="unit" as="xs:string?"/>
    <xsl:sequence select="if ($unit = 'mixed') then $n else $n || $unit"/>
  </xsl:function>

  <!-- is margin $new to the inside of $old (CSS terms of h:expr)?  The
     difference, unit by unit: inward when no unit decreases and one
     increases; when units go both ways, the sign of a relative operand
     (delta), else inward (an absolute FOR operand adds to the permanent
     indention) -->
  <xsl:function name="h:terms" as="map(xs:string, xs:double)">
    <xsl:param name="e" as="xs:string"/>
    <xsl:variable name="t" as="map(xs:string, xs:double)*">
      <xsl:analyze-string select="$e" regex="([+\-]?)\s*([0-9]*\.?[0-9]+)([a-z]+)">
        <xsl:matching-substring>
          <xsl:sequence select="map {regex-group(3):
              (if (regex-group(1) = '-') then -1 else 1) * number(regex-group(2))}"/>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="map:merge($t, map {'duplicates': 'combine'})
                          ! map:merge(map:for-each(., function($k, $v) { map {$k: sum($v)} }))"/>
  </xsl:function>
  <xsl:function name="h:inward" as="xs:boolean">
    <xsl:param name="new" as="xs:string"/>
    <xsl:param name="old" as="xs:string"/>
    <xsl:param name="delta" as="xs:string?"/>
    <xsl:variable name="n" select="h:terms($new)"/>
    <xsl:variable name="o" select="h:terms($old)"/>
    <xsl:variable name="d" select="for $k in distinct-values((map:keys($n), map:keys($o)))
                                   return ($n($k), 0)[1] - ($o($k), 0)[1]"/>
    <xsl:sequence select="if (every $x in $d satisfies $x le 0) then false()
                          else if (every $x in $d satisfies $x ge 0) then true()
                          else not(starts-with($delta, '-'))"/>
  </xsl:function>

  <!-- a vertical distance as CSS: n lines are n lh (the line height of
       the float, which is that of the text around it) -->
  <xsl:function name="h:distance" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="unit" as="xs:string?"/>
    <xsl:sequence select="h:len(h:dim($n, $unit), 'line')"/>
  </xsl:function>

  <!-- .in/.ir h FOR v1 [AFTER v2]: the margin is @left/@right, the
       permanent one is that of the scopes around (h:outer); the float is
       the difference wide, v2 + v1 high, its shape the part after v2
       (shape-outside: inset).  Not written: an outdent (a float cannot
       move lines out), and a FOR that another .in/.ir of the same side
       replaces before any text.  A float clears the floats of its side,
       so that a new FOR does not add to one still running. -->
  <xsl:template match="gml:in[@temporary = 'yes'] | gml:ir[@temporary = 'yes']">
    <xsl:call-template name="h:line-hint-break"/>
    <xsl:variable name="side" select="if (self::gml:in) then 'left' else 'right'"/>
    <xsl:variable name="new" select="h:expr(h:dim(if (self::gml:in) then @left else @right, @unit), 'ch')"/>
    <xsl:variable name="old" select="(h:outer(., local-name()) ! h:expr(., 'ch'), '0px')[1]"/>
    <xsl:variable name="me" select="local-name()"/>
    <!-- the next text, unless another FOR of this side comes first -->
    <xsl:variable name="text" select="following::node()[self::text()[normalize-space() != '']
        or self::gml:*[local-name() = $me][@temporary = 'yes']][1][self::text()]"/>
    <xsl:if test="exists($text) and exists(@for) and h:inward($new, $old, @delta)">
      <xsl:variable name="width" select="h:rel(h:dim(if (self::gml:in) then @left else @right, @unit),
                                               h:outer(., local-name()))"/>
      <xsl:variable name="for" select="h:distance(@for, @for-unit)"/>
      <xsl:variable name="after" select="if (@after) then h:distance(@after, @after-unit) else '0'"/>
      <xsl:variable name="re" select="'^([0-9]*\.?[0-9]+)([a-z]+)$'"/>
      <xsl:variable name="height" select="
          if ($after = '0') then $for
          else if (matches($for, $re) and matches($after, $re)
                   and replace($for, $re, '$2') = replace($after, $re, '$2'))
          then string(number(replace($after, $re, '$1')) + number(replace($for, $re, '$1')))
               || replace($for, $re, '$2')
          else 'calc(' || replace($after, '^calc\((.*)\)$', '($1)') || ' + '
                       || replace($for, '^calc\((.*)\)$', '($1)') || ')'"/>
      <h:float class="gml-{$me}" style="{string-join((
          'float: ' || $side, 'clear: ' || $side, 'width: ' || $width, 'height: ' || $height,
          if ($after = '0') then () else 'shape-outside: inset(' || $after || ' 0 0 0)'), '; ')}"/>
    </xsl:if>
  </xsl:template>

  <!-- .il/.un: the shift of the next output line (signed, to the right);
       the output pass decides how (h:il-use) -->
  <xsl:template match="gml:il | gml:un">
    <xsl:call-template name="h:line-hint-break"/>
    <xsl:variable name="shift" select="h:len(h:dim(@shift, @unit), 'ch')"/>
    <xsl:if test="$shift != '0'">
      <h:il class="gml-{local-name()}" shift="{$shift}"
            right="{not(matches($shift, '^(calc\()?-'))}"/>
    </xsl:if>
  </xsl:template>

  <!-- the visible node after / before n: over the invisible nodes and
       gml:br, and through the boundaries of scopes (a skip at the end of
       a scope and one after it are consecutive) -->
  <xsl:function name="h:after" as="node()?">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="s" select="$n/following-sibling::node()[not(h:invisible(.) or self::gml:br)][1]"/>
    <xsl:sequence select="if (exists($s)) then h:first($s)
                          else if ($n/parent::gml:scope) then h:after($n/parent::gml:scope) else ()"/>
  </xsl:function>
  <xsl:function name="h:first" as="node()?">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="c" select="$n/self::gml:scope/node()[not(h:invisible(.) or self::gml:br)][1]"/>
    <xsl:sequence select="if (not($n/self::gml:scope)) then $n
                          else if (exists($c)) then h:first($c) else h:after($n)"/>
  </xsl:function>
  <xsl:function name="h:before" as="node()?">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="s" select="$n/preceding-sibling::node()[not(h:invisible(.) or self::gml:br)][1]"/>
    <xsl:sequence select="if (exists($s)) then h:last($s)
                          else if ($n/parent::gml:scope) then h:before($n/parent::gml:scope) else ()"/>
  </xsl:function>
  <xsl:function name="h:last" as="node()?">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="c" select="$n/self::gml:scope/node()[not(h:invisible(.) or self::gml:br)][last()]"/>
    <xsl:sequence select="if (not($n/self::gml:scope)) then $n
                          else if (exists($c)) then h:last($c) else h:before($n)"/>
  </xsl:function>

  <!-- .sk skips do not add up (gml.tex \gml@vskip): of consecutive skips
       the largest one is kept, the last of equal ones.  Sizes compare as
       lines; skips in other units only when they are the same. -->
  <xsl:function name="h:sk-lines" as="xs:double">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="if ($n/self::gml:sk and (empty($n/@unit) or $n/@unit = 'line')
                              and $n/@n castable as xs:double) then xs:double($n/@n) else -1"/>
  </xsl:function>
  <xsl:function name="h:skip-dropped" as="xs:boolean">
    <xsl:param name="s" as="element()"/>
    <xsl:variable name="me" select="h:sk-lines($s)"/>
    <xsl:variable name="next" select="h:after($s)"/>
    <xsl:variable name="prev" select="h:before($s)"/>
    <xsl:sequence select="(exists($next/self::gml:sk)
                           and (h:len($next/@n || $next/@unit, 'line') = h:len($s/@n || $s/@unit, 'line')
                                or ($me ge 0 and h:sk-lines($next) ge $me)))
                          or (exists($prev/self::gml:sk) and $me ge 0 and h:sk-lines($prev) gt $me)"/>
  </xsl:function>

  <xsl:template match="gml:sp | gml:sk">
    <xsl:param name="ctx" as="xs:string" tunnel="yes" select="'flow'"/>
    <xsl:variable name="len" select="h:len(@n || @unit, 'line')"/>
    <xsl:if test="$len != '0' and not(self::gml:sk and h:skip-dropped(.))">
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
      <!-- .rc * c, .rc n on/off: the line is revised text, as a scope with
           rc= (gml:scope above); a blank character marks nothing -->
      <xsl:when test="$w = 'rc'">
        <xsl:choose>
          <xsl:when test="normalize-space(@char) = ''">
            <span class="gml-lines">
              <xsl:apply-templates>
                <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
              </xsl:apply-templates>
            </span>
          </xsl:when>
          <xsl:otherwise>
            <ins class="gml-lines gml-rc" data-rc="{@char}">
              <xsl:apply-templates>
                <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
              </xsl:apply-templates>
            </ins>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$w = ('us', 'up', 'uc') or not($w = ('ce', 'ri'))">
        <span class="gml-lines gml-{$w}">
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

  <!-- a symbol of a running heading (gml:symref, inside gml:rh/gml:rf,
       which are dropped): its value where the heading was defined -->
  <xsl:template match="gml:symref">
    <xsl:apply-templates/>
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
