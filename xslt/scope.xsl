<?xml version="1.0" encoding="UTF-8"?>
<!--
  scope.xsl - set-until-changed formatting hints -> nested scopes.

  Input: canonical or resolved XML (gml:doc).  Output: the same tree in
  which the STATE hints are replaced by <gml:scope> wrappers that carry the
  state in force over their content, for backends (HTML) whose model is
  inheritance down a tree rather than a global state.

  State hints (from the table in lib/hints.ml; every one carries the new
  absolute value, so the state at a point is just the last value seen):

    hint                         scope attribute   reset/initial value
    gml:in  (not temporary)      in   = left+unit      0
                                 (offset="0": also of = 0, a .in ends
                                 the offset, SH35-0069 p.80)
    gml:ir  (not temporary)      ir   = right+unit     0
    gml:of                       of   = offset+unit    0
    gml:ll                       ll   = length+unit    default
                                 ("default", or "default+1i" for a change
                                 relative to the device default)
    gml:fo gml:nf gml:ju         fill (yes|no)          yes
                                 align                  justify
                                 overdraw               extend
    gml:tp / gml:tb              tp / tb = tab stops   default
                                 (set replaces, add appends, del removes,
                                 no operand = default)
    gml:ls gml:wz gml:bc         ls wz bc = spec       default
    gml:bf gml:pf                font (pf: the font restored)  initial
    gml:hy (with mode)           hy  = on|off           off
    gml:ws gml:es gml:sb gml:ud  ws es sb ud = spec    default

  Dimensions are written n+unit ("5ch", "1.5i"); zero is "0"; a mixed sum
  is kept as written ("4ch+1i").  The first eleven attributes are BLOCK
  properties, the last six INLINE properties.

  Everything else is an event and stays where it is: br sp sk pa cp cc cb
  bx hr vr kp sx tc dh df hw rc fl is ic dr cl cd sc mc, the page layout
  words pn pl pw pm tm bm (page-level, not scoped), .in/.ir FOR an amount
  not in lines (temporary="yes"), .hy with options only, and the elements
  gml:lines (already a scope), gml:h, gml:fn, gml:rh, gml:rf, gml:raw.
  State hints inside such elements count like any other.

  Output vocabulary
    <gml:scope kind="block|inline" in=".." fill=".." ...>
        kind="block": only block properties; kind="inline": only inline
        properties.  A block scope contains inline scopes, never the
        reverse.  Only the properties that DIFFER from the enclosing
        context are written, with their new values (a property going back
        to its initial value is written with that value, e.g. in="0").
    <gml:br break="yes" cause="in"/>
        (cause: the breaking hint names of the run) stands where a state hint with break="yes" was, so the line break
        it causes inside running text is not lost.  It is written only when
        the hint has other (non-state-hint) siblings on both sides, one of
        them non-blank text, and only once for a run of adjacent state
        hints (in place of the last one, so it starts the scope of the
        final state), and not after another breaking hint (gml:sp,
        gml:br, ...).  A break
        between elements, or at the start or end of one, is implied by the
        structure and left out.
    A scope's kind names the property tier, not a content model: either
    kind may contain block elements (a font set before a :p. scopes the
    paragraph).

  Algorithm
    1. An accumulator `state` (a map property -> value, initially the
       values above) is updated by every state hint, in document order.
       accumulator-before(n) is the state in force when node n starts;
       for a state hint, accumulator-after(n) is the state it sets.
    2. Each element is copied and its children are processed with the
       context ctx = the state its output position already provides (the
       initial state at gml:doc; the state of the enclosing scope inside
       a scope).  The state hints that leave no gml:br are dropped from
       the child list.  For each remaining child c, S(c) is the state at
       c (accumulator-before, or -after for a state hint).
    3. The children are grouped with xsl:for-each-group group-adjacent on
       the block-property difference between S(c) and ctx; each group
       with a difference becomes a gml:scope kind="block".  Inside each
       group the same is done with the inline properties.  Within a
       group S is constant, so it becomes the ctx of the children,
       which are processed recursively (step 2).
    State is document-global in DCF, but a scope cannot cross an element
    boundary.  So (table, thd, tft and row excepted: they are never split
    by a scope, each child gets their context and the cells scope their
    own content):
     - a scope opened by a hint inside an element ends with that element;
       the state continues after it, and the next siblings at the parent
       level, whose S still differs from the parent's ctx, are re-opened
       in a new scope carrying the inherited state (and so on upwards);
     - an element that starts inside a scope inherits its state by
       nesting; its children are compared with that inherited state, so
       a later change inside it opens a scope relative to it, and no
       scope repeats what is already in force.
    The result: the state in force at any text node is the initial state
    overridden by the gml:scope ancestors, innermost first, and is the
    same as the DCF state at that point.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:s="urn:x-gml:scope"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <xsl:variable name="s:block" select="('in', 'ir', 'of', 'll', 'fill', 'align', 'overdraw',
                                        'tp', 'tb', 'ls', 'wz', 'bc')"/>
  <xsl:variable name="s:inline" select="('font', 'hy', 'ws', 'es', 'sb', 'ud')"/>

  <xsl:variable name="s:initial" as="map(xs:string, xs:string)" select="map {
      'in': '0', 'ir': '0', 'of': '0', 'll': 'default',
      'fill': 'yes', 'align': 'justify', 'overdraw': 'extend',
      'tp': 'default', 'tb': 'default', 'ls': 'default', 'wz': 'default', 'bc': 'default',
      'font': 'initial', 'hy': 'off',
      'ws': 'default', 'es': 'default', 'sb': 'default', 'ud': 'default' }"/>

  <xsl:function name="s:dim" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="unit" as="xs:string?"/>
    <xsl:sequence select="if ($unit = 'mixed') then $n
        else if (matches($n, '^[+-]?0*(\.0*)?$')) then '0'
        else concat($n, $unit)"/>
  </xsl:function>

  <xsl:function name="s:tabs" as="xs:string">
    <xsl:param name="h" as="element()"/>
    <xsl:param name="cur" as="xs:string"/>
    <xsl:variable name="stops" select="normalize-space($h/@stops)"/>
    <xsl:variable name="old" select="if ($cur = 'default') then () else tokenize($cur, ' ')"/>
    <xsl:variable name="new" as="xs:string*">
      <xsl:choose>
        <xsl:when test="$h/@action = 'reset' or $stops = ''"/>
        <xsl:when test="$h/@action = 'add'"><xsl:sequence select="$old, tokenize($stops, ' ')"/></xsl:when>
        <xsl:when test="$h/@action = 'del'"><xsl:sequence select="$old[not(. = tokenize($stops, ' '))]"/></xsl:when>
        <xsl:otherwise><xsl:sequence select="tokenize($stops, ' ')"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="if (empty($new)) then 'default' else string-join($new, ' ')"/>
  </xsl:function>

  <!-- is this a state hint? -->
  <xsl:function name="s:is-state" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="$n instance of element() and namespace-uri($n) = 'urn:x-gml:canonical'
        and (if (local-name($n) = ('in', 'ir')) then not($n/@temporary = 'yes')
             else if (local-name($n) = 'hy') then exists($n/@mode)
             else local-name($n) = ('of', 'll', 'fo', 'nf', 'ju', 'tp', 'tb', 'ls', 'wz', 'bc',
                                    'bf', 'pf', 'ws', 'es', 'sb', 'ud'))"/>
  </xsl:function>

  <!-- ==== step 1: the state accumulator ================================ -->
  <xsl:accumulator name="state" as="map(xs:string, xs:string)" initial-value="$s:initial">
    <xsl:accumulator-rule match="gml:in[not(@temporary = 'yes')]"
        select="map:put(if (@offset) then map:put($value, 'of', '0') else $value,
                        'in', s:dim(@left, @unit))"/>
    <xsl:accumulator-rule match="gml:ir[not(@temporary = 'yes')]"
        select="map:put($value, 'ir', s:dim(@right, @unit))"/>
    <xsl:accumulator-rule match="gml:of" select="map:put($value, 'of', s:dim(@offset, @unit))"/>
    <xsl:accumulator-rule match="gml:ll"
        select="map:put($value, 'll', if (@length = 'default') then concat('default', @delta)
                                      else s:dim(@length, @unit))"/>
    <xsl:accumulator-rule match="gml:fo | gml:nf | gml:ju"
        select="map:merge((map {'fill': string(@fill), 'align': string(@align),
                                 'overdraw': string(@overdraw)}, $value),
                          map {'duplicates': 'use-first'})"/>
    <xsl:accumulator-rule match="gml:tp | gml:tb"
        select="map:put($value, local-name(), s:tabs(., $value(local-name())))"/>
    <xsl:accumulator-rule match="gml:ls | gml:wz | gml:bc | gml:ws | gml:es | gml:sb | gml:ud"
        select="map:put($value, local-name(), (@spec[normalize-space() ne '']/string(), 'default')[1])"/>
    <xsl:accumulator-rule match="gml:bf" select="map:put($value, 'font', string(@font))"/>
    <xsl:accumulator-rule match="gml:pf" select="map:put($value, 'font', (@font/string(), 'initial')[1])"/>
    <xsl:accumulator-rule match="gml:hy[@mode]" select="map:put($value, 'hy', string(@mode))"/>
  </xsl:accumulator>

  <xsl:mode use-accumulators="state" on-no-match="shallow-copy"/>

  <xsl:function name="s:state-at" as="map(xs:string, xs:string)">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="if (s:is-state($n)) then $n/accumulator-after('state')
                          else $n/accumulator-before('state')"/>
  </xsl:function>

  <!-- the properties of $props where $st differs from $ctx, as a key -->
  <xsl:function name="s:diff" as="xs:string">
    <xsl:param name="st" as="map(xs:string, xs:string)"/>
    <xsl:param name="ctx" as="map(xs:string, xs:string)"/>
    <xsl:param name="props" as="xs:string*"/>
    <xsl:sequence select="string-join(for $k in $props return
        if ($st($k) ne $ctx($k)) then concat($k, '=', $st($k)) else (), '&#xE000;')"/>
  </xsl:function>

  <!-- the run of adjacent state hints that ends with $h -->
  <xsl:function name="s:run" as="element()+">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="prev" select="$h/preceding-sibling::node()[not(s:is-state(.))][1]"/>
    <xsl:sequence select="$h/preceding-sibling::node()[empty($prev) or . >> $prev], $h"/>
  </xsl:function>

  <!-- does this state hint leave a gml:br?  Only the last hint of a run of
       adjacent state hints can, when one of the run breaks. -->
  <xsl:function name="s:keeps-br" as="xs:boolean">
    <xsl:param name="h" as="element()"/>
    <xsl:variable name="prev" select="$h/preceding-sibling::node()[not(s:is-state(.))][1]"/>
    <xsl:variable name="next" select="$h/following-sibling::node()[1]"/>
    <xsl:variable name="run" select="s:run($h)"/>
    <xsl:sequence select="exists($prev) and exists($next) and not(s:is-state($next))
        and $run/@break = 'yes'
        and (($prev, $next)[. instance of text()][normalize-space() ne ''])
        and not($prev instance of element() and namespace-uri($prev) = 'urn:x-gml:canonical'
                and $prev/@break = 'yes')"/>
  </xsl:function>

  <!-- ==== step 2/3 ======================================================== -->
  <xsl:template match="/">
    <xsl:apply-templates>
      <xsl:with-param name="ctx" select="$s:initial" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*">
    <xsl:param name="ctx" as="map(xs:string, xs:string)" tunnel="yes"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="s:children">
        <xsl:with-param name="nodes" select="node()"/>
        <xsl:with-param name="ctx" select="$ctx"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <!-- Tables: no scope may come between a table, its header, footer and
       rows and their cells, so these containers pass their context on to
       each child (a state hint directly in them still counts, through the
       accumulator); a cell compares its content with that context, so the
       state in force inside a cell is still the DCF state. -->
  <xsl:template match="table | thd | tft | row">
    <xsl:param name="ctx" as="map(xs:string, xs:string)" tunnel="yes"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="node()[not(s:is-state(.))]">
        <xsl:with-param name="ctx" select="$ctx" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="s:children">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="ctx" as="map(xs:string, xs:string)"/>
    <xsl:variable name="items" select="$nodes[not(s:is-state(.)) or s:keeps-br(.)]"/>
    <xsl:for-each-group select="$items" group-adjacent="s:diff(s:state-at(.), $ctx, $s:block)">
      <xsl:variable name="st" select="s:state-at(.)"/>
      <xsl:variable name="bctx" select="map:merge(($ctx, map:merge(for $k in $s:block return map {$k: $st($k)})),
                                                  map {'duplicates': 'use-last'})"/>
      <xsl:variable name="inner" as="node()*">
        <xsl:for-each-group select="current-group()" group-adjacent="s:diff(s:state-at(.), $bctx, $s:inline)">
          <xsl:variable name="st" select="s:state-at(.)"/>
          <xsl:variable name="content" as="node()*">
            <xsl:for-each select="current-group()">
              <xsl:choose>
                <xsl:when test="s:is-state(.)">
                  <gml:br break="yes" cause="{s:run(.)[@break = 'yes']/local-name()}"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select=".">
                    <xsl:with-param name="ctx" select="$st" tunnel="yes"/>
                  </xsl:apply-templates>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="current-grouping-key() = ''"><xsl:sequence select="$content"/></xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="s:scope">
                <xsl:with-param name="kind" select="'inline'"/>
                <xsl:with-param name="st" select="$st"/>
                <xsl:with-param name="ctx" select="$bctx"/>
                <xsl:with-param name="props" select="$s:inline"/>
                <xsl:with-param name="content" select="$content"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="current-grouping-key() = ''"><xsl:sequence select="$inner"/></xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="s:scope">
            <xsl:with-param name="kind" select="'block'"/>
            <xsl:with-param name="st" select="$st"/>
            <xsl:with-param name="ctx" select="$ctx"/>
            <xsl:with-param name="props" select="$s:block"/>
            <xsl:with-param name="content" select="$inner"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="s:scope">
    <xsl:param name="kind" as="xs:string"/>
    <xsl:param name="st" as="map(xs:string, xs:string)"/>
    <xsl:param name="ctx" as="map(xs:string, xs:string)"/>
    <xsl:param name="props" as="xs:string*"/>
    <xsl:param name="content" as="node()*"/>
    <gml:scope kind="{$kind}">
      <xsl:for-each select="$props[$st(.) ne $ctx(.)]">
        <xsl:attribute name="{.}" select="$st(current())"/>
      </xsl:for-each>
      <xsl:sequence select="$content"/>
    </gml:scope>
  </xsl:template>

</xsl:stylesheet>
