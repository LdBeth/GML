<?xml version="1.0" encoding="UTF-8"?>
<!--
  resolve.xsl - canonical GML XML -> resolved canonical XML.

  Input: the tree written by `gml` (root gml:doc, namespace
  urn:x-gml:canonical; Starter Set tags as plain elements; formatting hints
  as gml:* elements).  Output: the same tree, same conventions, with the
  whole-document features worked out, so that the backends (tex.xsl,
  scope.xsl -> html.xsl / fo.xsl) never need a second pass.  Everything is
  copied unchanged except what is listed here.  The semantics follow the
  GML Starter Set Implementation Guide (SH35-0050, cited as IG p.n).

  Generated attributes (no namespace) on source elements
    num       the number of a numbered element, without labels:
              h1 "1.0" (SCRIPT numbering) or "1" (prefixed), appendix h1 "A",
              h2-h4 "1.2", "A.1.3"; fig "3"; fn "2"; ol li "b" (formatted).
    anchor    a link target name: the element's id, or "gml-NAME-n"
              (n = 1-based count of NAME elements in document order).  Set on
              h0-h6, fig, fn, li[@id] and every index tag (i1 i2 i3 ih1 ih2
              ih3 iref).  gml:pageref/@refid and entry/@refid point at it.
    nest      on ol and ul: nesting depth among lists of the same type.
    callout   on fn: "yes" = the footnote number is called out where the
              fn stands; "no" = the fn has an id and is called out by
              :fnref instead (IG p.129, DSMFTNT).
    resolved, target    on hdref/figref/fnref/liref: "yes"/"no", and the
              name of the target element (h2, fig, fn, li).
    The ref elements (empty in the input) get the reference text as
    content; num is copied from the target.

  Generated elements (namespace gml)
    gml:num             first child of a numbered h0-h6 / figcap / ol li /
                        fn: the label as the Starter Set prints it
                        ("1.0", "Chapter 1.", "Appendix A.", "1.2",
                        "Figure 3.", "b.", "2").
    gml:pageref         an unknown page number, filled in by the backend:
                        @refid  anchor of the target
                        @when   "always" | "auto" (auto: print only when the
                                target is on another page; absent = always)
                        @label  words printed before the number ("on page");
                                absent = the number alone
                        @major="yes", @range="start|end", @text (print this
                                instead of the number): index references.
    gml:toc-entries     child of toc: @title, then gml:toc-entry*:
       gml:toc-entry    @level (0-6) @refid @section (body|appendix|backm)
                        [@num]; children: gml:num? gml:entry-text gml:pageref
    gml:figlist-entries child of figlist: @title, then gml:figlist-entry*:
       gml:figlist-entry @refid @num; children: gml:num ("Figure 3")
                        gml:entry-text gml:pageref
    gml:index-entries   child of index: @title, then gml:index-group*:
       gml:index-group  @letter (upper case initial without accents,
                        compared with $group-collation: E and É share
                        group "E"; "" for terms that do
                        not begin with a letter, which sort first and get
                        no heading, IG p.142 DSMIEH); gml:index-entry*
       gml:index-entry  @level (1-3); children in this order:
                        gml:index-term (printed text), gml:pageref* (in
                        document order), gml:see*, gml:index-entry* (next
                        level, sorted)
       gml:see          @kind "see" | "see-also" (see-also when the entry
                        also has page references), @label ("See",
                        "See also"); content: the referenced term(s),
                        levels joined by ", " for a seeid (IG p.145).

  Numbering rules (IG pp.57-62, 75-83, Figure 13)
    Headings: SYSVARH (the -set symbol) "no" (default) = no numbers; "yes"
    or a start number ("1.0", "3") = number h1-h4 in the body and h2-h4 in
    the appendix.  h0, h5, h6, and all headings in frontm and backm, are
    never numbered.  Body h1 with h1-prefix set ("Chapter"; DSMPROF3
    &@bodyhead1) are always numbered "Chapter n."; appendix h1 are always
    numbered "Appendix A.", "Appendix B." ...  Counters run per section
    element; a skipped level counts as 0.
    Figures: only a fig with a figcap is numbered (DSMFCAP), document-wide.
    Footnotes: :fn, document-wide, from 1.  gml:fn (.fn on) is not numbered.
    Ordered lists: the item number formatted with the identifier of the
    ordered nesting depth: ol-identifiers "1. a. 1) a) i. i)" cycling, as
    &@olistnest = 123456 (IG p.108).

  Cross-references (IG pp.151-156)
    hdref  quote + heading text + quote (+ gml:pageref when="auto" or, with
           page=yes, "always"); a prefixed h1 keeps its label in the text.
           Unresolved: "Heading ID unknown".
    figref "Figure n" (+ pageref).  Unresolved or no figcap: "Figure ID
           unknown".
    liref  the item identifier ("b.") (+ pageref).  Only ol items have one.
           Unresolved: "LI ID unknown".
    fnref  the footnote number.  Unresolved: "00".
    Every unresolved reference is reported with xsl:message.

  "Figure" and its number are joined by a no-break space (U+00A0, the
  Starter Set's required blank) in every label and reference.

  Table of contents: h0-h{toc-depth} (default 4) outside frontm, flat, in
    document order (backends nest by @level).  The control-word headings
    gml:h (.h0-.h6) are neither numbered nor listed.
  Figure list: every numbered figure.
  Index (IG pp.137-145): i1/i2/i3 give a page reference at their position;
    ih1/ih2/ih3 give an entry with no page reference (print= is the printed
    text, the tag text is the sort key); iref refid= adds a page reference
    to the entry of an index tag with that id.  i2 hangs under the latest
    i1/ih1 (or the i1/ih1 of its refid), i3 under the latest i2/ih2 after
    that (or the one of its refid); the level-1/2 terms of an i3 are those
    of that i2/ih2.  pg= (or pgref=, pageref=) start|begin|end|major or
    text.  see= / seeid= give a "See" reference instead of a page
    reference.  Terms are merged by their exact (whitespace-normalised)
    text and sorted with $collation.
  Index control words (SH35-0069 pp.213-218): gml:pi (.pi) is one entry,
    @t1-@t3 the terms, @k1-@k3 explicit sort keys, @start/@end="yes" a
    range, @order="yes" a major reference, @page a page text,
    @pageref="no" no page, @see a cross reference; it gets an anchor
    (gml-pi-n).  Without a key a term is merged by its text in upper case
    and printed as at its first occurrence (SH35-0069 p.218).  A document with gml:pi takes its index from them only
    (IBM's index APFs give .pi entries; their tags are left empty).
    gml:ix (.ix) places the index of the entries since the previous
    gml:ix: gml:index-entries follows it, @title from its title= (absent:
    $lit-index).  In a document with a gml:ix the index elements get no
    entries; otherwise each gets them all.

  The output is resolved again unchanged: generated nodes in the input are
  dropped and regenerated (resolve is idempotent).
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:r="urn:x-gml:resolve"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <!-- ==== parameters ================================================== -->
  <!-- heading numbering: SYSVARH as in DCF (no | yes | start number) -->
  <xsl:param name="SYSVARH" as="xs:string" select="'no'"/>
  <!-- prefix for body h1 (DSMPROF3 &@bodyhead1), e.g. "Chapter" -->
  <xsl:param name="h1-prefix" as="xs:string" select="''"/>
  <xsl:param name="appendix-prefix" as="xs:string" select="'Appendix'"/>
  <xsl:param name="toc-depth" as="xs:string" select="'4'"/>
  <!-- list parameters: words separated by blanks or commas (commas on a
       command line: ol-identifiers=I.,A.,1.,a.) -->
  <xsl:param name="ol-identifiers" as="xs:string" select="'1. a. 1) a) i. i)'"/>
  <xsl:param name="collation" as="xs:string"
      select="'http://www.w3.org/2013/collation/UCA?lang=en;strength=secondary'"/>
  <!-- the index letter groups: E and É together -->
  <xsl:param name="group-collation" as="xs:string"
      select="'http://www.w3.org/2013/collation/UCA?lang=en;strength=primary'"/>
  <!-- literals (DSM#SETS &LL@...) -->
  <xsl:param name="lit-figure" as="xs:string" select="'Figure'"/>
  <xsl:param name="lit-heading" as="xs:string" select="'Heading'"/>
  <xsl:param name="lit-li" as="xs:string" select="'LI'"/>
  <xsl:param name="lit-unknown" as="xs:string" select="'unknown'"/>
  <xsl:param name="lit-on-page" as="xs:string" select="'on page'"/>
  <xsl:param name="lit-see" as="xs:string" select="'See'"/>
  <xsl:param name="lit-see-also" as="xs:string" select="'See also'"/>
  <xsl:param name="lit-toc" as="xs:string" select="'Table of Contents'"/>
  <xsl:param name="lit-figlist" as="xs:string" select="'List of Illustrations'"/>
  <xsl:param name="lit-index" as="xs:string" select="'Index'"/>
  <!-- open, close; open, close inside an odd number of :q -->
  <xsl:param name="quotes" as="xs:string" select="'“ ” ‘ ’'"/>

  <xsl:variable name="nbsp" select="'&#xA0;'"/>
  <xsl:variable name="number-headings" as="xs:boolean"
      select="not(lower-case(normalize-space($SYSVARH)) = ('no', ''))"/>
  <xsl:variable name="h1-start" as="xs:integer"
      select="let $v := normalize-space($SYSVARH)
              return if (matches($v, '^[0-9]+(\.0)?$'))
                     then xs:integer(replace($v, '\.0$', '')) else 1"/>
  <xsl:variable name="toc-max" as="xs:integer"
      select="if ($toc-depth castable as xs:integer) then xs:integer($toc-depth) else 4"/>
  <xsl:variable name="ol-ids" select="tokenize(normalize-space(translate($ol-identifiers, ',', ' ')), ' ')"/>
  <xsl:variable name="q" select="tokenize(normalize-space(translate($quotes, ',', ' ')), ' ')"/>

  <xsl:key name="id" match="*[@id]" use="string(@id)"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <!-- previously generated nodes: dropped, regenerated below -->
  <xsl:template match="gml:num | gml:toc-entries | gml:figlist-entries | gml:index-entries"/>
  <xsl:template match="@*[namespace-uri() = '' and local-name() = ('num', 'anchor', 'nest', 'callout', 'resolved', 'target')]
                           [..[self::h0 or self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6
                               or self::fig or self::fn or self::li or self::ol or self::ul
                               or self::i1 or self::i2 or self::i3 or self::ih1 or self::ih2 or self::ih3
                               or self::iref or self::hdref or self::figref or self::fnref or self::liref
                               or self::gml:pi]]"/>

  <!-- ==== helpers ====================================================== -->
  <xsl:function name="r:section" as="xs:string">
    <xsl:param name="e" as="node()"/>
    <xsl:sequence select="($e/ancestor-or-self::*[self::frontm or self::body
                            or self::appendix or self::backm][1]/local-name(), 'body')[1]"/>
  </xsl:function>

  <xsl:function name="r:section-elt" as="element()?">
    <xsl:param name="e" as="node()"/>
    <xsl:sequence select="$e/ancestor::*[self::frontm or self::body
                            or self::appendix or self::backm][1]"/>
  </xsl:function>

  <xsl:function name="r:anchor" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="if ($e/@id) then string($e/@id)
        else concat('gml-', local-name($e), '-',
                    count($e/(preceding::* | ancestor::*)[node-name(.) eq node-name($e)]) + 1)"/>
  </xsl:function>

  <xsl:function name="r:is-heading" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="namespace-uri($e) = '' and matches(local-name($e), '^h[0-6]$')"/>
  </xsl:function>

  <xsl:function name="r:level" as="xs:integer">
    <xsl:param name="h" as="element()"/>
    <xsl:sequence select="if (r:is-heading($h)) then xs:integer(substring(local-name($h), 2)) else -1"/>
  </xsl:function>

  <!-- ==== headings ===================================================== -->
  <xsl:function name="r:h-prefixed" as="xs:boolean">
    <xsl:param name="h" as="element()"/>
    <xsl:sequence select="r:level($h) = 1 and
        ((r:section($h) = 'body' and $h1-prefix ne '') or r:section($h) = 'appendix')"/>
  </xsl:function>

  <xsl:function name="r:h-numbered" as="xs:boolean">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="l" select="r:level($h)"/>
    <xsl:variable name="s" select="r:section($h)"/>
    <xsl:sequence select="r:h-prefixed($h) or
        ($number-headings and $l = (1 to 4) and $s = ('body', 'appendix'))"/>
  </xsl:function>

  <!-- count of headings of $h's level since the last heading of a lower
       level 1..level-1 or the start of the section element -->
  <xsl:function name="r:h-count" as="xs:integer">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="l" select="r:level($h)"/>
    <xsl:variable name="sec" select="r:section-elt($h)"/>
    <xsl:variable name="stop" select="$h/preceding::*[r:is-heading(.)
                     and r:level(.) = (1 to $l - 1)][1]"/>
    <xsl:sequence select="count($h/preceding::*[local-name() = local-name($h)
                     and namespace-uri() = ''
                     and (empty($stop) or . >> $stop)
                     and (empty($sec) or . >> $sec)]) + 1"/>
  </xsl:function>

  <!-- number components h1..hn -->
  <xsl:function name="r:h-comps" as="xs:string*">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="l" select="r:level($h)"/>
    <xsl:variable name="sec" select="r:section-elt($h)"/>
    <xsl:variable name="n" select="r:h-count($h)"/>
    <xsl:choose>
      <xsl:when test="$l = 1">
        <xsl:sequence select="if (r:section($h) = 'appendix') then format-integer($n, 'A')
                              else string($n + $h1-start - 1)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="up" select="$h/preceding::*[r:is-heading(.)
                         and r:level(.) = (1 to $l - 1)][1]
                         [empty($sec) or . >> $sec]"/>
        <xsl:variable name="upc" select="if ($up) then r:h-comps($up) else ()"/>
        <xsl:sequence select="$upc, (for $i in (count($upc) + 1 to $l - 1) return '0'), string($n)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- num attribute value, '' if not numbered -->
  <xsl:function name="r:h-num" as="xs:string">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="c" select="r:h-comps($h)"/>
    <xsl:sequence select="if (not(r:h-numbered($h))) then ''
        else if (r:level($h) = 1 and not(r:h-prefixed($h))) then concat($c, '.0')
        else string-join($c, '.')"/>
  </xsl:function>

  <xsl:function name="r:h-label" as="xs:string">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="num" select="r:h-num($h)"/>
    <xsl:variable name="pfx" select="if (r:section($h) = 'appendix') then $appendix-prefix
                                     else $h1-prefix"/>
    <xsl:sequence select="if ($num = '') then ''
        else if (r:h-prefixed($h)) then concat(if ($pfx ne '') then concat($pfx, ' ') else '', $num, '.')
        else $num"/>
  </xsl:function>

  <xsl:template match="h0 | h1 | h2 | h3 | h4 | h5 | h6">
    <xsl:variable name="num" select="r:h-num(.)"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="$num ne ''">
        <xsl:attribute name="num" select="$num"/>
      </xsl:if>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
      <xsl:if test="$num ne ''">
        <gml:num><xsl:value-of select="r:h-label(.)"/></gml:num>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ==== reference text: inline copy of a heading / caption ============= -->
  <xsl:function name="r:text-of" as="node()*">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="raw" as="node()*">
      <xsl:apply-templates select="$e/node()" mode="reftext"/>
    </xsl:variable>
    <xsl:for-each select="$raw">
      <xsl:choose>
        <xsl:when test=". instance of text()">
          <xsl:variable name="t" select="replace(., '\s+', ' ')"/>
          <xsl:variable name="t" select="if (position() = 1) then replace($t, '^ ', '') else $t"/>
          <xsl:variable name="t" select="if (position() = last()) then replace($t, ' $', '') else $t"/>
          <xsl:if test="$t ne ''"><xsl:value-of select="$t"/></xsl:if>
        </xsl:when>
        <xsl:otherwise><xsl:sequence select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <xsl:mode name="reftext" on-no-match="shallow-copy"/>
  <xsl:template mode="reftext" match="fn | i1 | i2 | i3 | ih1 | ih2 | ih3 | iref | gml:num"/>
  <xsl:template mode="reftext" match="gml:*">
    <xsl:apply-templates mode="reftext"/>
  </xsl:template>
  <xsl:template mode="reftext" match="@id | @anchor"/>
  <xsl:template mode="reftext" match="text()">
    <xsl:value-of select="replace(., '\s+', ' ')"/>
  </xsl:template>

  <xsl:function name="r:pageref" as="element(gml:pageref)">
    <xsl:param name="ref" as="element()"/>
    <xsl:param name="target" as="element()"/>
    <gml:pageref refid="{r:anchor($target)}"
        when="{if ($ref/@page = 'yes') then 'always' else 'auto'}" label="{$lit-on-page}"/>
  </xsl:function>

  <xsl:function name="r:unresolved">
    <xsl:param name="ref" as="element()"/>
    <xsl:param name="why" as="xs:string"/>
    <xsl:message select="concat('resolve: ', local-name($ref), ' refid=&quot;',
                                $ref/@refid, '&quot;: ', $why)"/>
  </xsl:function>

  <!-- ==== cross-references ============================================== -->
  <xsl:template match="hdref">
    <xsl:variable name="t" select="key('id', string(@refid))[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$t and r:is-heading($t)">
          <xsl:variable name="num" select="r:h-num($t)"/>
          <xsl:variable name="deep" select="count(ancestor::q) mod 2 = 1"/>
          <xsl:attribute name="resolved" select="'yes'"/>
          <xsl:attribute name="target" select="local-name($t)"/>
          <xsl:if test="$num ne ''"><xsl:attribute name="num" select="$num"/></xsl:if>
          <xsl:value-of select="if ($deep) then $q[3] else $q[1]"/>
          <xsl:if test="r:h-prefixed($t)">
            <xsl:value-of select="concat(r:h-label($t), ' ')"/>
          </xsl:if>
          <xsl:sequence select="r:text-of($t)"/>
          <xsl:value-of select="if ($deep) then $q[4] else $q[2]"/>
          <xsl:sequence select="r:pageref(., $t)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="r:unresolved(., if ($t) then concat('refers to a ', local-name($t),
                                ', not a heading') else 'no such id')"/>
          <xsl:attribute name="resolved" select="'no'"/>
          <xsl:value-of select="string-join(($lit-heading, @refid, $lit-unknown), ' ')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="figref">
    <xsl:variable name="t" select="key('id', string(@refid))[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$t/self::fig[figcap]">
          <xsl:attribute name="resolved" select="'yes'"/>
          <xsl:attribute name="target" select="'fig'"/>
          <xsl:attribute name="num" select="r:fig-num($t)"/>
          <xsl:value-of select="concat($lit-figure, $nbsp, r:fig-num($t))"/>
          <xsl:sequence select="r:pageref(., $t)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="r:unresolved(., if ($t/self::fig) then 'the figure has no figcap'
                                else if ($t) then concat('refers to a ', local-name($t), ', not a figure')
                                else 'no such id')"/>
          <xsl:attribute name="resolved" select="'no'"/>
          <xsl:value-of select="string-join(($lit-figure, @refid, $lit-unknown), ' ')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="liref">
    <xsl:variable name="t" select="key('id', string(@refid))[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$t/self::li[parent::ol]">
          <xsl:attribute name="resolved" select="'yes'"/>
          <xsl:attribute name="target" select="'li'"/>
          <xsl:attribute name="num" select="r:li-num($t)[1]"/>
          <xsl:value-of select="r:li-num($t)[2]"/>
          <xsl:sequence select="r:pageref(., $t)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="r:unresolved(., if ($t/self::li) then 'not an ordered list item'
                                else if ($t) then concat('refers to a ', local-name($t), ', not a list item')
                                else 'no such id')"/>
          <xsl:attribute name="resolved" select="'no'"/>
          <xsl:value-of select="string-join(($lit-li, @refid, $lit-unknown), ' ')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fnref">
    <xsl:variable name="t" select="key('id', string(@refid))[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:choose>
        <xsl:when test="$t/self::fn">
          <xsl:attribute name="resolved" select="'yes'"/>
          <xsl:attribute name="target" select="'fn'"/>
          <xsl:attribute name="num" select="r:fn-num($t)"/>
          <xsl:value-of select="r:fn-num($t)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="r:unresolved(., if ($t) then concat('refers to a ', local-name($t),
                                ', not a footnote') else 'no such id')"/>
          <xsl:attribute name="resolved" select="'no'"/>
          <xsl:text>00</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- ==== figures ======================================================= -->
  <xsl:function name="r:fig-num" as="xs:string">
    <xsl:param name="f" as="element()"/>
    <xsl:sequence select="if ($f/figcap)
        then string(count($f/(preceding::fig | ancestor::fig)[figcap]) + 1) else ''"/>
  </xsl:function>

  <xsl:template match="fig">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="figcap"><xsl:attribute name="num" select="r:fig-num(.)"/></xsl:if>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fig/figcap[1]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <gml:num><xsl:value-of select="concat($lit-figure, $nbsp, r:fig-num(..), '.')"/></gml:num>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ==== footnotes ===================================================== -->
  <xsl:function name="r:fn-num" as="xs:string">
    <xsl:param name="f" as="element()"/>
    <xsl:sequence select="string(count($f/(preceding::fn | ancestor::fn)) + 1)"/>
  </xsl:function>

  <xsl:template match="fn">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="num" select="r:fn-num(.)"/>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
      <xsl:attribute name="callout" select="if (@id) then 'no' else 'yes'"/>
      <gml:num><xsl:value-of select="r:fn-num(.)"/></gml:num>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ==== lists ========================================================= -->
  <xsl:template match="ol | ul">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="nest" select="count(ancestor-or-self::*[node-name(.) eq node-name(current())])"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- (num, label) of an ol item -->
  <xsl:function name="r:li-num" as="xs:string*">
    <xsl:param name="li" as="element()"/>
    <xsl:variable name="d" select="count($li/ancestor::ol)"/>
    <xsl:variable name="tok" select="$ol-ids[($d - 1) mod count($ol-ids) + 1]"/>
    <xsl:variable name="pic" select="if (string-length($tok) gt 1)
                                     then substring($tok, 1, string-length($tok) - 1) else $tok"/>
    <xsl:variable name="sfx" select="if (string-length($tok) gt 1)
                                     then substring($tok, string-length($tok)) else ''"/>
    <xsl:variable name="n" select="format-integer(count($li/preceding-sibling::li) + 1, $pic)"/>
    <xsl:sequence select="$n, concat($n, $sfx)"/>
  </xsl:function>

  <xsl:template match="ol/li" priority="1">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="num" select="r:li-num(.)[1]"/>
      <xsl:if test="@id"><xsl:attribute name="anchor" select="r:anchor(.)"/></xsl:if>
      <gml:num><xsl:value-of select="r:li-num(.)[2]"/></gml:num>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="li[@id]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ==== table of contents, figure list ================================= -->
  <xsl:template match="toc">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <gml:toc-entries title="{$lit-toc}">
        <xsl:for-each select="//*[r:is-heading(.) and r:level(.) le $toc-max
                                  and empty(ancestor::frontm)]">
          <xsl:variable name="num" select="r:h-num(.)"/>
          <gml:toc-entry level="{r:level(.)}" refid="{r:anchor(.)}" section="{r:section(.)}">
            <xsl:if test="$num ne ''">
              <xsl:attribute name="num" select="$num"/>
              <gml:num><xsl:value-of select="r:h-label(.)"/></gml:num>
            </xsl:if>
            <gml:entry-text><xsl:sequence select="r:text-of(.)"/></gml:entry-text>
            <gml:pageref refid="{r:anchor(.)}"/>
          </gml:toc-entry>
        </xsl:for-each>
      </gml:toc-entries>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="figlist">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <gml:figlist-entries title="{$lit-figlist}">
        <xsl:for-each select="//fig[figcap]">
          <gml:figlist-entry refid="{r:anchor(.)}" num="{r:fig-num(.)}">
            <gml:num><xsl:value-of select="concat($lit-figure, $nbsp, r:fig-num(.))"/></gml:num>
            <gml:entry-text><xsl:sequence select="r:text-of(figcap[1])"/></gml:entry-text>
            <gml:pageref refid="{r:anchor(.)}"/>
          </gml:figlist-entry>
        </xsl:for-each>
      </gml:figlist-entries>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ==== index ========================================================= -->
  <xsl:template match="i1 | i2 | i3 | ih1 | ih2 | ih3 | iref">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="r:ix-level" as="xs:integer">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="xs:integer(replace(local-name($e), '^ih?', ''))"/>
  </xsl:function>

  <xsl:function name="r:is-ix" as="xs:boolean">
    <xsl:param name="e" as="element()?"/>
    <xsl:sequence select="exists($e) and namespace-uri($e) = ''
                          and matches(local-name($e), '^(i[123]|ih[123])$')"/>
  </xsl:function>

  <!-- the terms of an index tag: <t k="sort key" d="printed text" p="yes if print="/>
       for levels 1..n; empty if the tag is in error (a message is given) -->
  <xsl:function name="r:ix-terms" as="element(t)*">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="txt" select="normalize-space(string-join($e/text(), ''))"/>
    <xsl:variable name="own" as="element(t)?">
      <xsl:if test="$txt ne ''">
        <t k="{$txt}" d="{($e/@print, $txt)[1]}">
          <xsl:if test="$e/@print"><xsl:attribute name="p" select="'yes'"/></xsl:if>
        </t>
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$e/self::iref">
        <xsl:variable name="tg" select="key('id', string($e/@refid), root($e))[1]"/>
        <xsl:choose>
          <xsl:when test="r:is-ix($tg)"><xsl:sequence select="r:ix-terms($tg)"/></xsl:when>
          <xsl:otherwise>
            <xsl:message select="concat('resolve: iref refid=&quot;', $e/@refid,
                                        '&quot;: no index entry with this id')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="empty($own)">
        <xsl:message select="concat('resolve: ', local-name($e), ' without text: no index entry')"/>
      </xsl:when>
      <xsl:when test="r:ix-level($e) = 1"><xsl:sequence select="$own"/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="l" select="r:ix-level($e)"/>
        <xsl:variable name="up" as="element()?">
          <xsl:choose>
            <xsl:when test="$e/@refid">
              <xsl:variable name="tg" select="key('id', string($e/@refid), root($e))[1]"/>
              <xsl:sequence select="$tg[r:is-ix(.) and r:ix-level(.) = $l - 1]"/>
              <xsl:if test="not($tg[r:is-ix(.) and r:ix-level(.) = $l - 1])">
                <xsl:message select="concat('resolve: ', local-name($e), ' refid=&quot;', $e/@refid,
                                            '&quot;: no level ', $l - 1, ' index entry with this id')"/>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="c1" select="$e/preceding::*[self::i1 or self::ih1][1]"/>
              <xsl:variable name="c" select="if ($l = 2) then $c1
                  else $e/preceding::*[self::i2 or self::ih2][1][empty($c1) or . >> $c1]"/>
              <xsl:sequence select="$c"/>
              <xsl:if test="empty($c)">
                <xsl:message select="concat('resolve: ', local-name($e), ' &quot;', $txt,
                                            '&quot;: no current level ', $l - 1, ' index term')"/>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="upt" select="if ($up) then r:ix-terms($up) else ()"/>
        <xsl:if test="count($upt) = $l - 1">
          <xsl:sequence select="$upt, $own"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- the sources of index entries, in document order: the gml:pi of the
       .pi control word, if any, else the index tags -->
  <xsl:variable name="ix-sources" as="element()*"
      select="if (exists(//gml:pi)) then //gml:pi
              else //(i1 | i2 | i3 | ih1 | ih2 | ih3 | iref)"/>

  <!-- one record per index entry, in document order:
       <rec seq level k1.. d1.. p1.. anchor page="yes|no" major range text see/> -->
  <xsl:variable name="ix-records" as="element(rec)*">
    <xsl:for-each select="$ix-sources">
      <xsl:choose>
        <xsl:when test="self::gml:pi"><xsl:sequence select="r:pi-record(., position())"/></xsl:when>
        <xsl:otherwise><xsl:sequence select="r:tag-record(., position())"/></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:variable>

  <!-- the record of a .pi entry -->
  <xsl:function name="r:pi-record" as="element(rec)">
    <xsl:param name="e" as="element()"/>
    <xsl:param name="seq" as="xs:integer"/>
    <xsl:variable name="ts" select="($e/@t1, $e/@t2, $e/@t3)"/>
    <rec seq="{$seq}" level="{count($ts)}" anchor="{r:anchor($e)}"
         page="{if ($e/@see or $e/@pageref = 'no') then 'no' else 'yes'}">
      <xsl:for-each select="$ts">
        <xsl:variable name="i" select="position()"/>
        <xsl:variable name="k" select="$e/@*[local-name() = concat('k', $i)]"/>
        <xsl:attribute name="k{$i}" select="if ($k) then normalize-space($k)
                                            else upper-case(normalize-space(.))"/>
        <xsl:attribute name="d{$i}" select="normalize-space(.)"/>
        <xsl:attribute name="p{$i}" select="'yes'"/>
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="$e/@start = 'yes'"><xsl:attribute name="range" select="'start'"/></xsl:when>
        <xsl:when test="$e/@end = 'yes'"><xsl:attribute name="range" select="'end'"/></xsl:when>
        <xsl:when test="$e/@order = 'yes'"><xsl:attribute name="major" select="'yes'"/></xsl:when>
      </xsl:choose>
      <xsl:if test="$e/@page"><xsl:attribute name="text" select="$e/@page"/></xsl:if>
      <xsl:if test="$e/@see"><xsl:attribute name="see" select="$e/@see"/></xsl:if>
    </rec>
  </xsl:function>

  <!-- the record of an index tag; none if the tag is in error -->
  <xsl:function name="r:tag-record" as="element(rec)?">
    <xsl:param name="e" as="element()"/>
    <xsl:param name="seq" as="xs:integer"/>
    <xsl:for-each select="$e">
      <xsl:variable name="terms" select="r:ix-terms(.)"/>
      <xsl:if test="exists($terms)">
        <xsl:variable name="pg" select="normalize-space((@pg, @pgref, @pageref)[1])"/>
        <xsl:variable name="see" as="xs:string?">
          <xsl:choose>
            <xsl:when test="@see"><xsl:sequence select="string(@see)"/></xsl:when>
            <xsl:when test="@seeid">
              <xsl:variable name="tg" select="key('id', string(@seeid))[1]"/>
              <xsl:choose>
                <xsl:when test="r:is-ix($tg) and exists(r:ix-terms($tg))">
                  <xsl:sequence select="string-join(r:ix-terms($tg) ! string(@d), ', ')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:message select="concat('resolve: ', local-name(.), ' seeid=&quot;', @seeid,
                                              '&quot;: no index entry with this id')"/>
                  <xsl:sequence select="'?'"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        <rec seq="{$seq}" level="{count($terms)}" anchor="{r:anchor(.)}"
             page="{if (exists($see) or starts-with(local-name(), 'ih')) then 'no' else 'yes'}">
          <xsl:for-each select="$terms">
            <xsl:attribute name="k{position()}" select="@k"/>
            <xsl:attribute name="d{position()}" select="@d"/>
            <xsl:if test="@p"><xsl:attribute name="p{position()}" select="'yes'"/></xsl:if>
          </xsl:for-each>
          <xsl:choose>
            <xsl:when test="$pg = ''"/>
            <xsl:when test="lower-case($pg) = ('start', 'begin')"><xsl:attribute name="range" select="'start'"/></xsl:when>
            <xsl:when test="lower-case($pg) = 'end'"><xsl:attribute name="range" select="'end'"/></xsl:when>
            <xsl:when test="lower-case($pg) = 'major'"><xsl:attribute name="major" select="'yes'"/></xsl:when>
            <xsl:otherwise><xsl:attribute name="text" select="$pg"/></xsl:otherwise>
          </xsl:choose>
          <xsl:if test="exists($see)"><xsl:attribute name="see" select="$see"/></xsl:if>
        </rec>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="r:initial" as="xs:string">
    <xsl:param name="k" as="xs:string"/>
    <xsl:variable name="c" select="substring($k, 1, 1)"/>
    <xsl:sequence select="if (matches($c, '\p{L}'))
        then replace(normalize-unicode(upper-case($c), 'NFD'), '\p{M}', '') else ''"/>
  </xsl:function>

  <xsl:template match="index">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="empty(//gml:ix)">
        <xsl:call-template name="r:index">
          <xsl:with-param name="recs" select="$ix-records"/>
          <xsl:with-param name="title" select="$lit-index"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- .pi entries: the anchor of their page reference -->
  <xsl:template match="gml:pi">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
    </xsl:copy>
  </xsl:template>

  <!-- .ix: the index of the entries since the previous .ix -->
  <xsl:template match="gml:ix">
    <xsl:variable name="this" select="."/>
    <xsl:variable name="prev" select="preceding::gml:ix[1]"/>
    <xsl:variable name="lo" select="if ($prev) then count($ix-sources[. &lt;&lt; $prev]) else 0"/>
    <xsl:variable name="hi" select="count($ix-sources[. &lt;&lt; $this])"/>
    <xsl:next-match/>
    <xsl:call-template name="r:index">
      <xsl:with-param name="recs" select="$ix-records[xs:integer(@seq) gt $lo and xs:integer(@seq) le $hi]"/>
      <xsl:with-param name="title" select="string((@title, $lit-index)[1])"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="r:index">
    <xsl:param name="recs" as="element(rec)*"/>
    <xsl:param name="title" as="xs:string"/>
    <gml:index-entries title="{$title}">
      <xsl:for-each-group select="$recs" group-by="r:initial(@k1)" collation="{$group-collation}">
        <xsl:sort select="current-grouping-key()" collation="{$group-collation}"/>
        <gml:index-group letter="{current-grouping-key()}">
          <xsl:call-template name="r:entries">
            <xsl:with-param name="recs" select="current-group()"/>
            <xsl:with-param name="level" select="1"/>
          </xsl:call-template>
        </gml:index-group>
      </xsl:for-each-group>
    </gml:index-entries>
  </xsl:template>

  <xsl:template name="r:entries">
    <xsl:param name="recs" as="element(rec)*"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:for-each-group select="$recs" group-by="string(@*[local-name() = concat('k', $level)])">
      <xsl:sort select="current-grouping-key()" collation="{$collation}"/>
      <xsl:variable name="own" select="current-group()[xs:integer(@level) = $level]"/>
      <xsl:variable name="pages" select="$own[@page = 'yes']"/>
      <gml:index-entry level="{$level}">
        <gml:index-term>
          <xsl:value-of select="(current-group()[@*[local-name() = concat('p', $level)]]
                                   /@*[local-name() = concat('d', $level)],
                                 current-grouping-key())[1]"/>
        </gml:index-term>
        <xsl:for-each select="$pages">
          <gml:pageref refid="{@anchor}">
            <xsl:copy-of select="@major | @range | @text"/>
          </gml:pageref>
        </xsl:for-each>
        <xsl:for-each select="distinct-values($own/@see)">
          <gml:see kind="{if ($pages) then 'see-also' else 'see'}"
                   label="{if ($pages) then $lit-see-also else $lit-see}">
            <xsl:value-of select="."/>
          </gml:see>
        </xsl:for-each>
        <xsl:if test="$level lt 3">
          <xsl:call-template name="r:entries">
            <xsl:with-param name="recs" select="current-group()[xs:integer(@level) gt $level]"/>
            <xsl:with-param name="level" select="$level + 1"/>
          </xsl:call-template>
        </xsl:if>
      </gml:index-entry>
    </xsl:for-each-group>
  </xsl:template>

</xsl:stylesheet>
