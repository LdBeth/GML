<?xml version="1.0" encoding="UTF-8"?>
<!--
  check.xsl - structural checks on an XSL-FO 1.1 document.

    transform -s:doc.fo -xsl:xslt/test/fo/check.xsl
    xslt/test/fo/check [file.fo...]        (all the fo fixture outputs)

  Writes one line per error ("path: message") and a summary line
  ("ok: N elements" or "N errors"); with summary=no only the error lines
  (fo.xsl check=... uses that to report through xsl:message, so a fixture
  with an error gets an unexpected .err).

  Not a schema: these are the XSL 1.1 content-model rules that fo.xsl
  relies on, and the reference rules a formatter would reject.
    - fo:root = layout-master-set, declarations?, page-sequence+;
      layout-master-set holds simple-page-master / page-sequence-master;
      master names unique, every master-reference names a master
      (page-sequence: any; inside a page-sequence-master: a
      simple-page-master); simple-page-master = region-body,
      region-before?, region-after?, region-start?, region-end?
    - page-sequence = title?, folio-prefix?, folio-suffix?,
      static-content*, flow; flow-names unique in a page-sequence, each
      naming a region of the masters used or xsl-footnote-separator /
      xsl-before-float-separator; the flow names a region-body
    - block-only containers (flow static-content footnote-body float
      list-item-label list-item-body block-container table-cell) hold no
      text and only block-level or neutral children, and at least one
      block; no text directly in root, layout-master-set, page-sequence,
      list-block, list-item, footnote, table structure
    - list-block = marker*, list-item+; list-item = marker*,
      list-item-label, list-item-body
    - footnote = inline, footnote-body; no float, footnote or marker
      inside a footnote; no block in its inline (nor in a leader), unless
      inside an inline-container
    - float and footnote not inside float, footnote, static-content,
      marker (footnote) or an absolutely positioned block-container
    - fo:marker: only an initial child, of a block-level / inline /
      wrapper / list FO in a flow; marker-class-names unique among
      siblings; no id inside a marker; retrieve-marker only in
      static-content
    - empty FOs (page-number, page-number-citation[-last], leader
      excepted, change-bar-begin/end, regions, master references) empty
    - ids unique; every ref-id / internal-destination names an id
    - span only on a child of fo:flow
    - change-bar-end matches an earlier change-bar-begin of its class
      in the same page-sequence
    - enumerated values of a few properties, length syntax of the
      length-valued properties fo.xsl writes
    - no element outside the XSL-FO namespace (but $allow-ns), no
      attribute in a namespace other than xml and $allow-ns
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:c="urn:x-gml:fo-check"
    exclude-result-prefixes="#all">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="summary" as="xs:string" select="'yes'"/>
  <!-- namespaces whose attributes (and elements) are allowed: vendor extensions -->
  <xsl:param name="allow-ns" as="xs:string" select="''"/>

  <xsl:variable name="c:fo" select="'http://www.w3.org/1999/XSL/Format'"/>
  <!-- also from a processing instruction <?fo-check-allow-ns uri ...?> before the root
       (fo.xsl check= passes it so: fn:transform cannot take parameters here) -->
  <xsl:variable name="c:allowed" select="tokenize(normalize-space(string-join(($allow-ns, /processing-instruction('fo-check-allow-ns')), ' ')), ' ')"/>

  <xsl:variable name="c:block" select="('block', 'block-container', 'table-and-caption', 'table', 'list-block')"/>
  <xsl:variable name="c:inline" select="('bidi-override', 'character', 'external-graphic', 'instream-foreign-object',
      'inline', 'inline-container', 'leader', 'page-number', 'page-number-citation', 'page-number-citation-last',
      'scaling-value-citation', 'basic-link', 'multi-toggle', 'index-page-citation-list')"/>
  <xsl:variable name="c:neutral" select="('multi-switch', 'multi-properties', 'index-range-begin', 'index-range-end',
      'wrapper', 'retrieve-marker', 'retrieve-table-marker', 'change-bar-begin', 'change-bar-end')"/>
  <xsl:variable name="c:block-only" select="('flow', 'static-content', 'footnote-body', 'float', 'list-item-label',
      'list-item-body', 'block-container', 'table-cell')"/>
  <xsl:variable name="c:no-text" select="('root', 'layout-master-set', 'page-sequence', 'page-sequence-master',
      'simple-page-master', 'list-block', 'list-item', 'footnote', 'table', 'table-body', 'table-header',
      'table-footer', 'table-row', 'table-and-caption', 'repeatable-page-master-alternatives')"/>
  <xsl:variable name="c:empty" select="('page-number', 'page-number-citation', 'page-number-citation-last',
      'change-bar-begin', 'change-bar-end', 'region-body', 'region-before', 'region-after', 'region-start',
      'region-end', 'single-page-master-reference', 'repeatable-page-master-reference',
      'conditional-page-master-reference', 'retrieve-marker', 'retrieve-table-marker')"/>
  <xsl:variable name="c:marker-parents" select="('block', 'block-container', 'inline', 'inline-container', 'wrapper',
      'list-block', 'list-item', 'basic-link', 'table', 'table-and-caption', 'table-cell', 'table-row', 'table-body')"/>

  <xsl:variable name="c:enums" as="map(xs:string, xs:string*)" select="map {
      'float': ('before', 'start', 'end', 'left', 'right', 'inside', 'outside', 'none', 'inherit'),
      'text-align': ('start', 'center', 'end', 'justify', 'inside', 'outside', 'left', 'right', 'inherit'),
      'text-align-last': ('relative', 'start', 'center', 'end', 'justify', 'inside', 'outside', 'left', 'right', 'inherit'),
      'break-before': ('auto', 'column', 'page', 'even-page', 'odd-page', 'inherit'),
      'break-after': ('auto', 'column', 'page', 'even-page', 'odd-page', 'inherit'),
      'linefeed-treatment': ('ignore', 'preserve', 'treat-as-space', 'treat-as-zero-width-space', 'inherit'),
      'white-space-treatment': ('ignore', 'preserve', 'ignore-if-before-linefeed', 'ignore-if-after-linefeed',
                                'ignore-if-surrounding-linefeed', 'inherit'),
      'white-space-collapse': ('false', 'true', 'inherit'),
      'wrap-option': ('no-wrap', 'wrap', 'inherit'),
      'hyphenate': ('false', 'true', 'inherit'),
      'span': ('none', 'all', 'inherit'),
      'leader-pattern': ('space', 'rule', 'dots', 'use-content', 'inherit'),
      'font-style': ('normal', 'italic', 'oblique', 'backslant', 'inherit'),
      'font-weight': ('normal', 'bold', 'bolder', 'lighter', '100', '200', '300', '400', '500', '600', '700', '800', '900', 'inherit'),
      'text-transform': ('capitalize', 'uppercase', 'lowercase', 'none', 'inherit'),
      'text-decoration': ('none', 'underline', 'no-underline', 'overline', 'no-overline', 'line-through', 'no-line-through', 'blink', 'no-blink', 'inherit'),
      'force-page-count': ('auto', 'even', 'odd', 'end-on-even', 'end-on-odd', 'no-force', 'inherit'),
      'odd-or-even': ('odd', 'even', 'any', 'inherit'),
      'retrieve-position': ('first-starting-within-page', 'first-including-carryover', 'last-starting-within-page', 'last-ending-within-page'),
      'retrieve-boundary': ('page', 'page-sequence', 'document'),
      'change-bar-style': ('none', 'hidden', 'dotted', 'dashed', 'solid', 'double', 'groove', 'ridge', 'inset', 'outset', 'inherit'),
      'space-before.conditionality': ('discard', 'retain'),
      'space-after.conditionality': ('discard', 'retain'),
      'keep-with-next.within-page': ('auto', 'always'), 'keep-with-next.within-column': ('auto', 'always'),
      'keep-with-next.within-line': ('auto', 'always'),
      'keep-together.within-page': ('auto', 'always'), 'keep-together.within-column': ('auto', 'always') }"/>

  <xsl:variable name="c:lengths" select="('start-indent', 'end-indent', 'text-indent', 'last-line-end-indent',
      'space-before', 'space-after', 'provisional-distance-between-starts', 'provisional-label-separation',
      'font-size', 'line-height', 'leader-length', 'rule-thickness', 'column-gap', 'extent', 'page-width',
      'page-height', 'margin-top', 'margin-bottom', 'margin-left', 'margin-right', 'padding', 'padding-before',
      'padding-after', 'padding-start', 'padding-end', 'baseline-shift', 'word-spacing', 'change-bar-width',
      'change-bar-offset', 'block-progression-dimension')"/>
  <xsl:variable name="c:num" select="'-?[0-9]+(\.[0-9]+)?'"/>
  <xsl:variable name="c:len" select="concat($c:num, '(pt|em|in|mm|cm|pc|px|%)')"/>
  <xsl:variable name="c:length-re" select="concat('^(', $c:len, '|0)( [+-] ', $c:len, ')*$')"/>

  <xsl:key name="c:id" match="*[@id]" use="string(@id)"/>

  <xsl:function name="c:path" as="xs:string">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="string-join(for $a in $n/ancestor-or-self::* return
        concat(name($a), '[', count($a/preceding-sibling::*[node-name(.) eq node-name($a)]) + 1, ']'), '/')"/>
  </xsl:function>

  <xsl:function name="c:is-fo" as="xs:boolean">
    <xsl:param name="e" as="node()?"/>
    <xsl:sequence select="exists($e) and $e instance of element() and namespace-uri($e) = $c:fo"/>
  </xsl:function>

  <xsl:template match="/">
    <xsl:variable name="errors" as="xs:string*">
      <xsl:apply-templates select="*" mode="c:check"/>
      <xsl:call-template name="c:document"/>
    </xsl:variable>
    <xsl:for-each select="$errors">
      <xsl:value-of select="."/>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:if test="$summary = 'yes'">
      <xsl:value-of select="if (empty($errors)) then concat('ok: ', count(//*), ' elements')
                            else concat(count($errors), ' errors')"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- ==== document-wide rules ========================================= -->
  <xsl:template name="c:document">
    <xsl:variable name="root" select="/*"/>
    <xsl:if test="not($root/self::fo:root)">
      <xsl:sequence select="concat('/', name($root), ': the document element is not fo:root')"/>
    </xsl:if>
    <xsl:variable name="kids" select="$root/*"/>
    <xsl:if test="not($kids[1]/self::fo:layout-master-set)">
      <xsl:sequence select="'fo:root: the first child is not fo:layout-master-set'"/>
    </xsl:if>
    <xsl:if test="count($kids[self::fo:layout-master-set]) ne 1">
      <xsl:sequence select="'fo:root: not exactly one fo:layout-master-set'"/>
    </xsl:if>
    <xsl:if test="empty($kids[self::fo:page-sequence])">
      <xsl:sequence select="'fo:root: no fo:page-sequence'"/>
    </xsl:if>
    <xsl:for-each select="$kids[not(self::fo:layout-master-set or self::fo:declarations or self::fo:page-sequence
                                    or self::fo:bookmark-tree or self::fo:page-sequence-wrapper)]">
      <xsl:sequence select="concat(c:path(.), ': not allowed in fo:root')"/>
    </xsl:for-each>
    <!-- master names -->
    <xsl:variable name="masters" select="//fo:layout-master-set/(fo:simple-page-master | fo:page-sequence-master)"/>
    <xsl:for-each-group select="$masters" group-by="string(@master-name)">
      <xsl:if test="count(current-group()) gt 1">
        <xsl:sequence select="concat('fo:layout-master-set: master-name ', current-grouping-key(), ' defined ', count(current-group()), ' times')"/>
      </xsl:if>
    </xsl:for-each-group>
    <xsl:for-each select="//fo:layout-master-set/*[not(self::fo:simple-page-master or self::fo:page-sequence-master)]">
      <xsl:sequence select="concat(c:path(.), ': not allowed in fo:layout-master-set')"/>
    </xsl:for-each>
    <xsl:for-each select="//fo:page-sequence[not(@master-reference = $masters/@master-name)]">
      <xsl:sequence select="concat(c:path(.), ': master-reference ', @master-reference, ' names no master')"/>
    </xsl:for-each>
    <xsl:for-each select="//fo:page-sequence-master//*[@master-reference]
                            [not(@master-reference = //fo:simple-page-master/@master-name)]">
      <xsl:sequence select="concat(c:path(.), ': master-reference ', @master-reference, ' names no simple-page-master')"/>
    </xsl:for-each>
    <!-- ids and references -->
    <xsl:for-each-group select="//*[@id]" group-by="string(@id)">
      <xsl:if test="count(current-group()) gt 1">
        <xsl:sequence select="concat('id ', current-grouping-key(), ' used ', count(current-group()), ' times: ',
                                     string-join(current-group()/c:path(.), ', '))"/>
      </xsl:if>
    </xsl:for-each-group>
    <xsl:for-each select="//*[@ref-id][not(key('c:id', string(@ref-id)))]">
      <xsl:sequence select="concat(c:path(.), ': ref-id ', @ref-id, ' names no id')"/>
    </xsl:for-each>
    <xsl:for-each select="//fo:basic-link[@internal-destination][not(key('c:id', string(@internal-destination)))]">
      <xsl:sequence select="concat(c:path(.), ': internal-destination ', @internal-destination, ' names no id')"/>
    </xsl:for-each>
    <!-- change bars, per page-sequence -->
    <xsl:for-each select="//fo:change-bar-end">
      <xsl:variable name="class" select="string(@change-bar-class)"/>
      <xsl:variable name="ps" select="ancestor::fo:page-sequence"/>
      <xsl:variable name="last" select="(preceding::*[self::fo:change-bar-begin or self::fo:change-bar-end]
                                           [@change-bar-class = $class][ancestor::fo:page-sequence is $ps])[last()]"/>
      <xsl:if test="not($last/self::fo:change-bar-begin)">
        <xsl:sequence select="concat(c:path(.), ': change-bar-end ', $class, ' without a change-bar-begin')"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="//fo:change-bar-begin">
      <xsl:variable name="class" select="string(@change-bar-class)"/>
      <xsl:variable name="ps" select="ancestor::fo:page-sequence"/>
      <xsl:if test="empty(following::fo:change-bar-end[@change-bar-class = $class][ancestor::fo:page-sequence is $ps])">
        <xsl:sequence select="concat(c:path(.), ': change-bar-begin ', $class, ' never ended in its page-sequence')"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- ==== per element ================================================= -->
  <xsl:template match="*" mode="c:check">
    <xsl:variable name="e" select="."/>
    <xsl:variable name="n" select="local-name()"/>
    <xsl:variable name="p" select="c:path(.)"/>
    <xsl:choose>
      <xsl:when test="namespace-uri() = $c:allowed"/>
      <xsl:when test="namespace-uri() ne $c:fo">
        <xsl:sequence select="concat($p, ': element outside the XSL-FO namespace (', namespace-uri(), ')')"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- attributes -->
        <xsl:for-each select="@*[namespace-uri() ne ''][not(namespace-uri() = ('http://www.w3.org/XML/1998/namespace', $c:allowed))]">
          <xsl:sequence select="concat($p, ': attribute ', name(), ' in namespace ', namespace-uri())"/>
        </xsl:for-each>
        <xsl:for-each select="@*[namespace-uri() = ''][map:contains($c:enums, local-name())]" xmlns:map="http://www.w3.org/2005/xpath-functions/map">
          <xsl:if test="not(string(.) = $c:enums(local-name()))">
            <xsl:sequence select="concat($p, ': ', local-name(), '=&quot;', ., '&quot; is not a valid value')"/>
          </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="@*[namespace-uri() = ''][local-name() = $c:lengths]">
          <xsl:if test="not(matches(., $c:length-re) or . = ('inherit', 'normal', 'auto', 'baseline', 'super', 'sub',
                        'label-end()', 'body-start()') or matches(., '^[0-9.]+$') or matches(., '^[0-9.]+(pt|in|mm|cm) solid$'))">
            <xsl:sequence select="concat($p, ': ', local-name(), '=&quot;', ., '&quot; is not a length')"/>
          </xsl:if>
        </xsl:for-each>
        <!-- text -->
        <xsl:if test="$n = ($c:block-only, $c:no-text) and text()[normalize-space()]">
          <xsl:sequence select="concat($p, ': text in fo:', $n, ': &quot;', substring(normalize-space(string-join(text(), ' ')), 1, 40), '&quot;')"/>
        </xsl:if>
        <xsl:if test="$n = $c:empty and (* or text()[normalize-space()])">
          <xsl:sequence select="concat($p, ': fo:', $n, ' must be empty')"/>
        </xsl:if>
        <!-- block-only containers -->
        <xsl:if test="$n = $c:block-only">
          <xsl:for-each select="*[c:is-fo(.)][not(local-name() = ($c:block, $c:neutral, 'marker', 'float'))]">
            <xsl:sequence select="concat(c:path(.), ': fo:', local-name(), ' (inline-level) in fo:', $n)"/>
          </xsl:for-each>
          <xsl:if test="$n = ('flow', 'static-content', 'footnote-body', 'float', 'list-item-label', 'list-item-body')
                        and empty(*[c:is-fo(.)][local-name() = ($c:block, 'wrapper', 'float')])">
            <xsl:sequence select="concat($p, ': fo:', $n, ' has no block')"/>
          </xsl:if>
          <xsl:if test="$n = 'float' and *[local-name() = 'float']">
            <xsl:sequence select="concat($p, ': fo:float inside fo:float')"/>
          </xsl:if>
        </xsl:if>
        <xsl:if test="$n = ('flow', 'static-content') and not(parent::fo:page-sequence)">
          <xsl:sequence select="concat($p, ': fo:', $n, ' not a child of fo:page-sequence')"/>
        </xsl:if>
        <!-- particular content models -->
        <xsl:choose>
          <xsl:when test="$n = 'simple-page-master'">
            <xsl:variable name="order" select="('region-body', 'region-before', 'region-after', 'region-start', 'region-end')"/>
            <xsl:variable name="idx" select="for $k in * return index-of($order, local-name($k))[1]"/>
            <xsl:if test="not(*[1]/self::fo:region-body) or count($idx) ne count(*) or
                          (some $i in 2 to count($idx) satisfies $idx[$i] le $idx[$i - 1])">
              <xsl:sequence select="concat($p, ': content is not region-body, region-before?, region-after?, region-start?, region-end?')"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$n = 'page-sequence'">
            <xsl:variable name="order" select="('title', 'folio-prefix', 'folio-suffix', 'static-content', 'flow')"/>
            <xsl:variable name="idx" select="for $k in * return index-of($order, local-name($k))[1]"/>
            <xsl:if test="count($idx) ne count(*) or count(fo:flow) ne 1 or not(*[last()]/self::fo:flow)
                          or (some $i in 2 to count($idx) satisfies $idx[$i] lt $idx[$i - 1])
                          or count(fo:title) gt 1 or count(fo:folio-prefix) gt 1 or count(fo:folio-suffix) gt 1">
              <xsl:sequence select="concat($p, ': content is not title?, folio-prefix?, folio-suffix?, static-content*, flow')"/>
            </xsl:if>
            <xsl:for-each-group select="fo:static-content | fo:flow" group-by="string(@flow-name)">
              <xsl:if test="count(current-group()) gt 1">
                <xsl:sequence select="concat($p, ': flow-name ', current-grouping-key(), ' used twice')"/>
              </xsl:if>
            </xsl:for-each-group>
            <!-- the regions of the masters this sequence can use -->
            <xsl:variable name="ref" select="string(@master-reference)"/>
            <xsl:variable name="m" select="//fo:layout-master-set/*[@master-name = $ref]"/>
            <xsl:variable name="spm" select="($m/self::fo:simple-page-master,
                //fo:simple-page-master[@master-name = $m/self::fo:page-sequence-master//@master-reference])"/>
            <xsl:variable name="regions" select="$spm/*/string((@region-name, concat('xsl-', local-name()))[1])"/>
            <xsl:variable name="bodies" select="$spm/fo:region-body/string((@region-name, 'xsl-region-body')[1])"/>
            <xsl:for-each select="fo:static-content[not(@flow-name = ($regions, 'xsl-footnote-separator', 'xsl-before-float-separator'))]">
              <xsl:sequence select="concat(c:path(.), ': flow-name ', @flow-name, ' names no region of master ', $ref)"/>
            </xsl:for-each>
            <xsl:for-each select="fo:flow[not(@flow-name = $bodies)]">
              <xsl:sequence select="concat(c:path(.), ': the flow does not name a region-body (', @flow-name, ')')"/>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="$n = 'list-block'">
            <xsl:if test="empty(fo:list-item) or *[not(self::fo:list-item or self::fo:marker)]">
              <xsl:sequence select="concat($p, ': content is not marker*, list-item+ (', string-join(distinct-values(*/name()), ' '), ')')"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$n = 'list-item'">
            <xsl:variable name="k" select="*[not(self::fo:marker)]"/>
            <xsl:if test="count($k) ne 2 or not($k[1]/self::fo:list-item-label) or not($k[2]/self::fo:list-item-body)">
              <xsl:sequence select="concat($p, ': content is not marker*, list-item-label, list-item-body')"/>
            </xsl:if>
            <xsl:if test="not(parent::fo:list-block)">
              <xsl:sequence select="concat($p, ': fo:list-item outside fo:list-block')"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$n = 'footnote'">
            <xsl:if test="count(*) ne 2 or not(*[1]/self::fo:inline) or not(*[2]/self::fo:footnote-body)">
              <xsl:sequence select="concat($p, ': content is not inline, footnote-body')"/>
            </xsl:if>
            <xsl:if test=".//fo:float or .//fo:footnote or .//fo:marker">
              <xsl:sequence select="concat($p, ': fo:float, fo:footnote or fo:marker inside fo:footnote')"/>
            </xsl:if>
            <xsl:if test="fo:inline//*[local-name() = $c:block][not(ancestor::fo:inline-container)]">
              <xsl:sequence select="concat($p, ': a block inside the inline of fo:footnote')"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$n = 'leader'">
            <xsl:if test=".//*[c:is-fo(.)][local-name() = $c:block][not(ancestor::fo:inline-container)]">
              <xsl:sequence select="concat($p, ': a block inside fo:leader')"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$n = 'marker'">
            <xsl:if test="preceding-sibling::*[not(self::fo:marker)] or preceding-sibling::text()[normalize-space()]">
              <xsl:sequence select="concat($p, ': fo:marker is not an initial child')"/>
            </xsl:if>
            <xsl:if test="not(local-name(..) = $c:marker-parents) or not(ancestor::fo:flow)">
              <xsl:sequence select="concat($p, ': fo:marker not allowed in fo:', local-name(..))"/>
            </xsl:if>
            <xsl:if test="preceding-sibling::fo:marker[@marker-class-name = current()/@marker-class-name]">
              <xsl:sequence select="concat($p, ': marker-class-name ', @marker-class-name, ' twice in one parent')"/>
            </xsl:if>
            <xsl:if test=".//@id">
              <xsl:sequence select="concat($p, ': an id inside fo:marker')"/>
            </xsl:if>
          </xsl:when>
          <xsl:when test="$n = 'retrieve-marker'">
            <xsl:if test="not(ancestor::fo:static-content)">
              <xsl:sequence select="concat($p, ': fo:retrieve-marker outside fo:static-content')"/>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
        <xsl:if test="$n = ('float', 'footnote') and ancestor::*[self::fo:float or self::fo:footnote or self::fo:static-content
                      or (self::fo:marker and $n = 'footnote') or self::fo:block-container[@absolute-position = ('absolute', 'fixed')]]">
          <xsl:sequence select="concat($p, ': fo:', $n, ' inside fo:', local-name(ancestor::*[self::fo:float or self::fo:footnote
                                or self::fo:static-content or self::fo:marker or self::fo:block-container][1]))"/>
        </xsl:if>
        <xsl:if test="$n = ('footnote', 'float') and not(ancestor::fo:flow or ancestor::fo:marker)">
          <xsl:sequence select="concat($p, ': fo:', $n, ' outside fo:flow')"/>
        </xsl:if>
        <xsl:if test="$n = ('list-item-label', 'list-item-body') and not(parent::fo:list-item)">
          <xsl:sequence select="concat($p, ': fo:', $n, ' outside fo:list-item')"/>
        </xsl:if>
        <xsl:if test="$n = 'footnote-body' and not(parent::fo:footnote)">
          <xsl:sequence select="concat($p, ': fo:footnote-body outside fo:footnote')"/>
        </xsl:if>
        <xsl:if test="@span and not(parent::fo:flow)">
          <xsl:sequence select="concat($p, ': span on a block that is not a child of fo:flow')"/>
        </xsl:if>
        <!-- block-level FOs where only inline content is allowed -->
        <xsl:if test="$n = $c:block and (parent::fo:leader or parent::fo:title or parent::fo:page-number-citation)">
          <xsl:sequence select="concat($p, ': block-level fo:', $n, ' in fo:', local-name(..))"/>
        </xsl:if>
        <xsl:if test="$n = ($c:block, $c:inline, $c:neutral, 'footnote', 'float', 'list-item')
                      and not(ancestor::fo:flow or ancestor::fo:static-content or ancestor::fo:marker or ancestor::fo:title)">
          <xsl:sequence select="concat($p, ': fo:', $n, ' outside a flow')"/>
        </xsl:if>
        <xsl:apply-templates select="*" mode="c:check"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
