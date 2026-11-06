<?xml version="1.0" encoding="UTF-8"?>
<!--
  tex.xsl - resolved canonical GML XML -> plain TeX (share/tex/gml.tex).

  Input: the output of resolve.xsl (NOT scope.xsl): the DCF formatting
  hints stay point events, because TeX's \leftskip, fonts, \obeylines...
  are state too; gml.tex keeps the hint state and combines it with the
  element state (see the header of gml.tex).

  Output (method text, pure ASCII):
    [\def\gmlfonts{$tex-fonts}]
    \input gml ($tex-input), then $tex-preamble
    \gmlbegindocument ... \gmlenddocument \bye
  Dispatch scheme - one rule for source elements, one for generated ones:
    source element NAME (h1, p, ol, fig, gml:h, gml:fn, gml:rh, gml:rf,
      user tags ...)       \gmlstart{NAME}{k=v,...} content \gmlend{NAME}
      gml.tex calls \gml@NAME@start / \gml@NAME@end (overridable per
      element; an undefined element is plain text).  All attributes are
      passed; added: text= (plain text of h0-h6, gml:h, title: for the
      running footing), desc=yes on a figcap followed by a figdesc.
      An element with @anchor gets \gmlanchor{anchor} as first content.
      Index tags (i1 i2 i3 ih1 ih2 ih3 iref) get only the anchor (their
      text is in gml:index-entries).
    hint gml:NAME (empty)  \gmlhint{NAME}{k=v,...}      -> \gml@hint@NAME
    gml:lines              \gmlbeginlines{WORD}{k=v,...[,more=yes]}...\gmlendlines
                           more=yes: the next gml:lines is its cont="yes"
                           continuation (the line does not end here).
    gml:num                \gmlnum{label}
    gml:pageref            \gmlpageref{anchor}{always|auto}{label}
    generated lists        \gmltocbegin{title} \gmltocentry{level=..,..}{num}{text}{\gmlpageref..}
                           \gmlfiglistbegin{title} \gmlfiglistentry{num=..}{label}{text}{page}
                           \gmlindexbegin{title} \gmlindexgroup{letter}
                           \gmlindexentry{level}{term}{refs} ... \gmlindexend
  Attribute values and text are escaped by t:esc: TeX specials $ & # %
  become \$ \& \# \%; \ { } ^ _ ~ < > | " and every character outside
  printable ASCII become \gmlchar{decimal code point}; "-" "-" -> "-{}-"
  (no en-dash ligature).  In attribute values "," and "=" are \gmlchar
  too (the key=value list).  Anchor names are reduced to [A-Za-z0-9.-]
  (other characters as +n+) so they are safe in \csname and \write.
  Text: in xml:space="preserve" text each blank is "\ " and lines are
  kept (gml.tex obeys lines in format-off mode); elsewhere runs of
  blank lines collapse to one line end (a TeX empty line would be \par)
  and whitespace-only text next to block elements is dropped.  A line
  containing tab characters is \gmltabline{seg\gmltab seg...}.  Words
  inside .us/.up/.uc scopes are \gmlusword{} \gmlupword{} \gmlucword{}.
  Lay-out only: "%" + line end after block elements and breaking hints.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:t="urn:x-gml:tex"
    exclude-result-prefixes="#all">

  <xsl:output method="text" encoding="UTF-8"/>

  <!-- the macro package and extra preamble text -->
  <xsl:param name="tex-input" as="xs:string" select="'gml'"/>
  <xsl:param name="tex-preamble" as="xs:string" select="''"/>
  <!-- font scheme: share/tex/gmlfont-NAME.tex (ncs, cm, ...); empty = the
       gml.tex default.  Written as \def\gmlfonts{NAME} before \input. -->
  <xsl:param name="tex-fonts" as="xs:string" select="''"/>
  <!-- title page alignment as SYSVART: right (default) | left | center -->
  <xsl:param name="SYSVART" as="xs:string" select="''"/>

  <xsl:variable name="nl" select="'&#10;'"/>

  <xsl:variable name="blocks" as="xs:string*" select="
      ('gdoc', 'frontm', 'titlep', 'title', 'docnum', 'date', 'author', 'address',
       'aline', 'abstract', 'preface', 'toc', 'figlist', 'body', 'appendix', 'backm',
       'index', 'h0', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'pc', 'note',
       'ol', 'ul', 'sl', 'l', 'dl', 'gl', 'li', 'lp', 'dthd', 'ddhd', 'dt', 'dd',
       'gt', 'gd', 'lq', 'xmp', 'fig', 'figcap', 'figdesc', 'gml:h', 'gml:rh', 'gml:rf')"/>
  <xsl:variable name="index-tags" as="xs:string*"
      select="('i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>
  <!-- gml:* elements that are not hints -->
  <xsl:variable name="flows" as="xs:string*" select="('h', 'fn', 'rh', 'rf')"/>
  <xsl:variable name="generated" as="xs:string*" select="
      ('doc', 'lines', 'num', 'pageref', 'toc-entries', 'toc-entry', 'entry-text',
       'figlist-entries', 'figlist-entry', 'index-entries', 'index-group',
       'index-entry', 'index-term', 'see')"/>

  <!-- ==== escaping ===================================================== -->
  <xsl:variable name="special"
      select="'[\\{}$&amp;#\^_%~&lt;&gt;|&quot;]|[^&#x20;-&#x7E;]'"/>

  <xsl:function name="t:esc" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pre" as="xs:boolean"/>
    <xsl:variable name="e" select="string-join(
        analyze-string($s, $special || (if ($pre) then '| ' else ''))/*/
          (if (self::*:match) then t:char(string(.)) else string(.)))"/>
    <xsl:sequence select="replace(replace($e, '--', '-{}-'), '--', '-{}-')"/>
  </xsl:function>

  <xsl:function name="t:char" as="xs:string">
    <xsl:param name="c" as="xs:string"/>
    <xsl:variable name="n" select="string-to-codepoints($c)[1]"/>
    <xsl:sequence select="
        if ($c = ' ') then '\ '
        else if ($c = ('$', '&amp;', '#', '%')) then '\' || $c
        else if ($n lt 32 or $n = 127) then ''
        else '\gmlchar{' || $n || '}'"/>
  </xsl:function>

  <xsl:function name="t:attr" as="xs:string">
    <xsl:param name="v" as="xs:string"/>
    <xsl:sequence select="replace(replace(t:esc(translate($v, '&#9;&#10;&#13;', '   '), false()),
                                          ',', '\\gmlchar{44}'), '=', '\\gmlchar{61}')"/>
  </xsl:function>

  <xsl:function name="t:name" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="string-join(for $c in string-to-codepoints($s)
        return (if (matches(codepoints-to-string($c), '^[A-Za-z0-9.\-]$'))
                then codepoints-to-string($c) else concat('+', $c, '+')))"/>
  </xsl:function>

  <xsl:function name="t:attrs" as="xs:string">
    <xsl:param name="atts" as="attribute()*"/>
    <xsl:param name="extra" as="xs:string*"/>
    <xsl:sequence select="string-join((for $a in $atts return
        concat(name($a), '=', if (local-name($a) = 'anchor' or name($a) = 'refid')
                              then t:name($a) else t:attr($a)), $extra), ',')"/>
  </xsl:function>

  <xsl:function name="t:is-block" as="xs:boolean">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="exists($n[self::*]) and (name($n) = $blocks
        or ($n/self::gml:* and not(local-name($n) = ($flows, $generated))))"/>
  </xsl:function>

  <!-- the plain text of a heading, for the running footing -->
  <xsl:function name="t:plain" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="normalize-space(string-join($e//text()[not(ancestor::gml:num)
        and not(ancestor::*[local-name() = $index-tags])]))"/>
  </xsl:function>

  <!-- ==== document ======================================================= -->
  <xsl:template match="/">
    <xsl:if test="$tex-fonts != ''">
      <xsl:value-of select="concat('\def\gmlfonts{', $tex-fonts, '}', $nl)"/>
    </xsl:if>
    <xsl:text>\input </xsl:text>
    <xsl:value-of select="$tex-input"/>
    <xsl:value-of select="$nl"/>
    <xsl:if test="$tex-preamble != ''">
      <xsl:value-of select="$tex-preamble, $nl" separator=""/>
    </xsl:if>
    <xsl:if test="lower-case($SYSVART) = ('right', 'left', 'center')">
      <xsl:value-of select="concat('\def\gmltitlealign{', lower-case($SYSVART), '}', $nl)"/>
    </xsl:if>
    <xsl:text>\gmlbegindocument%&#10;</xsl:text>
    <xsl:apply-templates select="(gml:doc, *)[1]/node()"/>
    <xsl:text>%&#10;\gmlenddocument&#10;\bye&#10;</xsl:text>
  </xsl:template>

  <!-- ==== source elements ================================================ -->
  <xsl:template match="*">
    <xsl:call-template name="element"/>
  </xsl:template>

  <xsl:template name="element">
    <xsl:variable name="name" select="name()"/>
    <xsl:variable name="extra" as="xs:string*">
      <xsl:if test="self::h0 or self::h1 or self::h2 or self::h3 or self::h4 or self::h5
                    or self::h6 or self::gml:h or self::title">
        <xsl:sequence select="'text=' || t:attr(t:plain(.))"/>
      </xsl:if>
      <xsl:if test="self::figcap and following-sibling::*[1][self::figdesc]">
        <xsl:sequence select="'desc=yes'"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="block" select="t:is-block(.)"/>
    <xsl:value-of select="concat('\gmlstart{', $name, '}{', t:attrs(@*, $extra), '}')"/>
    <xsl:if test="$block">%&#10;</xsl:if>
    <xsl:if test="@anchor">
      <xsl:value-of select="concat('\gmlanchor{', t:name(@anchor), '}')"/>
    </xsl:if>
    <xsl:if test="not($name = $index-tags)">
      <xsl:apply-templates/>
    </xsl:if>
    <xsl:value-of select="concat('\gmlend{', $name, '}')"/>
    <xsl:if test="$block">%&#10;</xsl:if>
  </xsl:template>

  <!-- ==== hints ============================================================= -->
  <xsl:template match="gml:*">
    <xsl:value-of select="concat('\gmlhint{', local-name(), '}{', t:attrs(@*, ()), '}')"/>
    <xsl:if test="@break = 'yes'">%&#10;</xsl:if>
    <xsl:apply-templates/>
  </xsl:template>

  <!-- gml:h & co. are elements (another flow), not hints -->
  <xsl:template match="gml:h | gml:fn | gml:rh | gml:rf" priority="1">
    <xsl:call-template name="element"/>
  </xsl:template>

  <!-- ==== generated nodes ======================================================= -->
  <xsl:template match="gml:num">
    <xsl:text>\gmlnum{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="gml:pageref">
    <xsl:value-of select="concat('\gmlpageref{', t:name(@refid), '}{',
        (@when, 'always')[1], '}{', t:attr(string(@label)), '}')"/>
  </xsl:template>

  <xsl:template match="gml:lines">
    <xsl:variable name="next" select="following::gml:lines[1]"/>
    <xsl:variable name="more" select="if ($next/@cont = 'yes' and $next/@word = @word)
                                      then 'more=yes' else ()"/>
    <xsl:value-of select="concat('\gmlbeginlines{', @word, '}{', t:attrs(@* except @word, $more), '}')"/>
    <xsl:apply-templates/>
    <xsl:text>\gmlendlines{}</xsl:text>
  </xsl:template>

  <xsl:template match="gml:toc-entries">
    <xsl:value-of select="concat('\gmltocbegin{', t:esc(string(@title), false()), '}%', $nl)"/>
    <xsl:apply-templates select="gml:toc-entry"/>
    <xsl:text>\gmltocend%&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="gml:toc-entry">
    <xsl:value-of select="concat('\gmltocentry{', t:attrs(@*, ()), '}{')"/>
    <xsl:apply-templates select="gml:num/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="gml:entry-text/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="gml:pageref"/>
    <xsl:text>}%&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="gml:figlist-entries">
    <xsl:value-of select="concat('\gmlfiglistbegin{', t:esc(string(@title), false()), '}%', $nl)"/>
    <xsl:apply-templates select="gml:figlist-entry"/>
    <xsl:text>\gmlfiglistend%&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="gml:figlist-entry">
    <xsl:value-of select="concat('\gmlfiglistentry{', t:attrs(@*, ()), '}{')"/>
    <xsl:apply-templates select="gml:num/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="gml:entry-text/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="gml:pageref"/>
    <xsl:text>}%&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="gml:index-entries">
    <xsl:value-of select="concat('\gmlindexbegin{', t:esc(string(@title), false()), '}%', $nl)"/>
    <xsl:apply-templates select="gml:index-group"/>
    <xsl:text>\gmlindexend%&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="gml:index-group">
    <xsl:value-of select="concat('\gmlindexgroup{', t:esc(string(@letter), false()), '}%', $nl)"/>
    <xsl:apply-templates select="gml:index-entry"/>
  </xsl:template>

  <xsl:template match="gml:index-entry">
    <xsl:value-of select="concat('\gmlindexentry{', (@level, '1')[1], '}{')"/>
    <xsl:apply-templates select="gml:index-term/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:if test="gml:pageref">\gmlindexfirst </xsl:if>
    <xsl:for-each select="gml:pageref">
      <xsl:if test="position() gt 1">
        <xsl:value-of select="if (preceding-sibling::gml:pageref[1]/@range = 'start')
                              then '\gmlindexrangesep ' else '\gmlindexsep '"/>
      </xsl:if>
      <xsl:value-of select="concat('\gmlindexref{', t:name(@refid), '}{',
          t:attrs(@major | @range | @text, ()), '}')"/>
    </xsl:for-each>
    <xsl:for-each select="gml:see">
      <xsl:value-of select="concat('\gmlsee{', @kind, '}{', t:esc(string(@label), false()), '}{')"/>
      <xsl:apply-templates/>
      <xsl:text>}</xsl:text>
    </xsl:for-each>
    <xsl:text>}%&#10;</xsl:text>
    <xsl:apply-templates select="gml:index-entry"/>
  </xsl:template>

  <!-- ==== text ======================================================================= -->
  <xsl:template match="text()">
    <xsl:variable name="pre" select="string(ancestor::*[@xml:space][1]/@xml:space) = 'preserve'"/>
    <xsl:variable name="word" select="string(ancestor::gml:lines[1]/@word)"/>
    <xsl:choose>
      <xsl:when test="not($pre) and normalize-space(.) = ''
          and (t:is-block(preceding-sibling::node()[1]) or t:is-block(following-sibling::node()[1])
               or (t:is-block(..) and (empty(preceding-sibling::node()) or empty(following-sibling::node()))))"/>
      <xsl:otherwise>
        <xsl:value-of select="t:text(., $pre, $word)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:function name="t:text" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pre" as="xs:boolean"/>
    <xsl:param name="word" as="xs:string"/>
    <xsl:variable name="s1" select="if ($pre) then $s else replace($s, '\n(\s*\n)+', $nl)"/>
    <xsl:sequence select="string-join(
        for $line in tokenize($s1, '\n') return
          if (contains($line, '&#9;'))
          then concat('\gmltabline{', string-join(for $seg in tokenize($line, '&#9;')
                                                  return t:seg($seg, $pre, $word), '\gmltab '), '}')
          else t:seg($line, $pre, $word),
        $nl)"/>
  </xsl:function>

  <xsl:function name="t:seg" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pre" as="xs:boolean"/>
    <xsl:param name="word" as="xs:string"/>
    <xsl:variable name="wrap" select="if ($word = 'us') then '\gmlusword{'
        else if ($word = 'up') then '\gmlupword{' else if ($word = 'uc') then '\gmlucword{' else ''"/>
    <xsl:sequence select="if ($wrap = '') then t:esc($s, $pre)
        else string-join(analyze-string($s, '\S+')/*/
            (if (self::*:match) then concat($wrap, t:esc(string(.), $pre), '}')
             else t:esc(string(.), $pre)))"/>
  </xsl:function>

</xsl:stylesheet>
