<?xml version="1.0" encoding="UTF-8"?>
<!--
  tex.xsl - resolved canonical GML XML -> plain TeX (share/tex/gml.tex).

  Input: the output of resolve.xsl (NOT scope.xsl): the DCF formatting
  hints stay point events, because TeX's \leftskip, fonts, \obeylines...
  are state too; gml.tex keeps the hint state and combines it with the
  element state (see the header of gml.tex).

  Output (method text, pure ASCII):
    [\def\gmlfonts{$tex-fonts}] [\def\gmltagset{$tex-tagset}]
    [\def\gmlmode{hints}] [\def\gmlpassno{K}\def\gmlpasses{N}: the root's
    pass= passes=, gml -pass/-passes, for gml.tex's \gmlpass]
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
      Tables (rdef table thd tft row c tnote tcap tdesc, and gml:cpart, a
      part of a cell) are source elements too; gml.tex lays them out from
      the attributes resolve.xsl puts on row and c.  tcap gets desc=yes
      when a tdesc follows.
      Index tags (i1 i2 i3 ih1 ih2 ih3 iref) get only the anchor (their
      text is in gml:index-entries).
    hint gml:NAME (empty)  \gmlhint{NAME}{k=v,...}      -> \gml@hint@NAME
                           (gml:pageno: the page number symbol in the text of
                           a running heading or footing, SH35-0069 p.128)
    gml:lines              \gmlbeginlines{WORD}{k=v,...[,more=yes]}...\gmlendlines
                           more=yes: the next gml:lines is its cont="yes"
                           continuation (the line does not end here).
                           (.in/.ir FOR/AFTER and .il/.un are plain hints:
                           gml.tex counts their output lines.)
    gml:query              \gmlquery{id}{pn|lc}  (a question of the pass model)
    gml:symref             \gmlsymref{name}{value} (a deferred symbol reference
                           in a running heading or footing, LR p.316)
    gml:symval             \gmlsymval{name}{value} (its new value here)
    gml:num                \gmlnum{label}
    gml:pageref            \gmlpageref{anchor}{always|auto}{label}
    generated lists        \gmltocbegin{title} \gmltocentry{level=..,..}{num}{text}{\gmlpageref..}
                           \gmlfiglistbegin{title} \gmlfiglistentry{num=..}{label}{text}{page}
                           \gmltlistbegin{title} \gmltlistentry{...}{label}{text}{page} \gmltlistend
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
  Format-off text: text that follows a gml:fo/gml:nf hint with fill="no"
  (until one with fill="yes") is written like xml:space="preserve" text:
  DCF keeps the input lines, their leading blanks and blank lines when
  formatting is off (SH35-0069 .FO), and a real profile (DSMXMP) does not
  mark its examples xml:space="preserve".
  Parsed operands: three definition hints get keys parsed from their spec
  (the spec itself is kept), so gml.tex need not parse DCF syntax:
    gml:df  os=yes us=yes up=yes (line functions; uc = us+up), font=NAME
            (FONT operand, left out when it is an unresolved &symbol),
            and from TYPE(...): face=quoted typeface, family=mono|sans|
            pi|serif (guessed from the typeface), size=N|+N|-N, bold=yes,
            italic=yes
    gml:dh  font= tfont= spbf= skbf= spaf= (vertical: a bare number is
            lines, p-notation "p14"/"1p6" is points), pa=yes|no,
            align=left|right|center|inside|outside, runin=yes (NBR) |no
            (BR), up=yes|no, us=yes|no, hy=yes|no, reset=yes (no options)
    gml:dr  rule=NAME, weight=h (WEIGHT or W operand)
  Upper case fonts: words of text whose current font (the first name of
  the last .bf/.pf font list that a gml:df defined; in a gml:h heading,
  its .dh font, default hdN) has UP or UC, or in a heading whose .dh says
  UP, are \gmlupword{} (\gmlucword{} inside .us scopes): plain TeX cannot
  upper-case text by a font switch.
  Mode (tex-mode): "hints" writes \def\gmlmode{hints} before \input:
  gml.tex then leaves the layout to the hints (a real DCF profile such as
  IBM's DSMPROF3 formats every tag with control words) and styles only
  gml:h, gml:fn, gml:rh, gml:rf and the fig float.  "auto" (default)
  chooses hints when a .df/.dh/.dr hint comes before the first source
  element (a formatting profile), else "elements".
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:t="urn:x-gml:tex"
    exclude-result-prefixes="#all">

  <xsl:include href="common.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:mode use-accumulators="#all"/>

  <!-- the macro package and extra preamble text -->
  <xsl:param name="tex-input" as="xs:string" select="'gml'"/>
  <xsl:param name="tex-preamble" as="xs:string" select="''"/>
  <!-- font scheme: share/tex/gmlfont-NAME.tex (ncs, cm, ...); empty = the
       gml.tex default.  Written as \def\gmlfonts{NAME} before \input. -->
  <xsl:param name="tex-fonts" as="xs:string" select="''"/>
  <!-- tag-set TeX file (gmlfmt -app: BUNDLE/tagset.tex); empty = none.
       Written as \def\gmltagset{PATH} before \input: gml.tex inputs it
       at its end, before gmllocal.tex. -->
  <xsl:param name="tex-tagset" as="xs:string" select="''"/>
  <!-- title page alignment as SYSVART: right (default) | left | center -->
  <xsl:param name="SYSVART" as="xs:string" select="''"/>
  <!-- elements | hints | auto (see the header) -->
  <xsl:param name="tex-mode" as="xs:string" select="'auto'"/>

  <xsl:variable name="root" select="(/gml:doc, /*)[1]"/>
  <xsl:variable name="mode" as="xs:string" select="
      if ($tex-mode = ('elements', 'hints')) then $tex-mode
      else if (gml:hint-mode($root))
      then 'hints' else 'elements'"/>

  <xsl:variable name="nl" select="'&#10;'"/>

  <xsl:variable name="blocks" as="xs:string*" select="
      ('gdoc', 'frontm', 'titlep', 'title', 'docnum', 'date', 'author', 'address',
       'aline', 'abstract', 'preface', 'toc', 'figlist', 'body', 'appendix', 'backm',
       'index', 'h0', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'pc', 'note',
       'ol', 'ul', 'sl', 'l', 'dl', 'gl', 'li', 'lp', 'dthd', 'ddhd', 'dt', 'dd',
       'gt', 'gd', 'lq', 'xmp', 'fig', 'figcap', 'figdesc', 'gml:h', 'gml:rh', 'gml:rf',
       'rdef', 'table', 'thd', 'tft', 'row', 'c', 'tnote', 'tcap', 'tdesc', 'tlist')"/>
  <xsl:variable name="index-tags" as="xs:string*"
      select="('i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>
  <!-- gml:* elements that are not hints -->
  <xsl:variable name="flows" as="xs:string*" select="('h', 'fn', 'rh', 'rf')"/>
  <xsl:variable name="generated" as="xs:string*" select="
      ('doc', 'lines', 'num', 'pageref', 'toc-entries', 'toc-entry', 'entry-text',
       'figlist-entries', 'figlist-entry', 'tlist-entries', 'tlist-entry',
       'index-entries', 'index-group',
       'index-entry', 'index-term', 'see', 'symref', 'symval')"/>

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

  <!-- a node that is put out in the line: a text variable (gml:dv, the
       profiles' &amp. &gml. &semi.), a font change, an element that is
       not a block (hp1, q ...) -->
  <xsl:function name="t:is-inline" as="xs:boolean">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="exists($n/(self::gml:dv | self::gml:bf | self::gml:pf | self::gml:symref))
        or (exists($n[self::*]) and not($n/self::gml:*) and not(t:is-block($n)))"/>
  </xsl:function>

  <!-- the plain text of a heading, for the running footing -->
  <xsl:function name="t:plain" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="normalize-space(string-join(($e//text() | $e//gml:dv/@text)[not(ancestor::gml:num)
        and not(ancestor::*[local-name() = $index-tags])]))"/>
  </xsl:function>

  <!-- ==== document ======================================================= -->
  <xsl:template match="/">
    <xsl:if test="$tex-fonts != ''">
      <xsl:value-of select="concat('\def\gmlfonts{', $tex-fonts, '}', $nl)"/>
    </xsl:if>
    <xsl:if test="$tex-tagset != ''">
      <xsl:value-of select="concat('\def\gmltagset{', $tex-tagset, '}', $nl)"/>
    </xsl:if>
    <xsl:if test="$mode = 'hints'">
      <xsl:value-of select="concat('\def\gmlmode{hints}', $nl)"/>
    </xsl:if>
    <!-- the pass model (gml -pass/-passes): gml.tex's \gmlpass reads them -->
    <xsl:if test="$root/@pass and $root/@passes">
      <xsl:value-of select="concat('\def\gmlpassno{', t:name($root/@pass), '}\def\gmlpasses{',
                                   t:name($root/@passes), '}', $nl)"/>
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
      <xsl:if test="(self::figcap and following-sibling::*[1][self::figdesc])
                    or (self::tcap and following-sibling::*[1][self::tdesc])">
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

  <!-- a question of the pass model (gml -aux, Ctx.query): gml.tex
       writes the answer to the aux file -->
  <xsl:template match="gml:query" priority="1">
    <xsl:value-of select="concat('\gmlquery{', t:name(string(@id)), '}{', t:name(string(@what)), '}')"/>
  </xsl:template>

  <!-- a .sx in a running heading or footing: the page number symbol
       (@pagesym) in its fields is the page number, \gmlpageno; any other
       character, a text "&" too, is text.  A deferred symbol reference
       in a field (U+E001 NAME U+E002 value U+E003, lib/doc.ml) is
       \gmlsymref{NAME}{value} (see gml:symref); its value is text, not
       split at the page number symbol -->
  <xsl:template match="gml:sx[@pagesym != '' or (@left | @fill | @right)[contains(., '&#xE001;')]]"
                priority="1">
    <xsl:variable name="ps" select="string(@pagesym)"/>
    <xsl:value-of select="concat('\gmlhint{sx}{', string-join(for $a in @* return
        if (name($a) = ('left', 'fill', 'right'))
        then name($a) || '=' || string-join(
            analyze-string(string($a), '&#xE001;([^&#xE002;]*)&#xE002;([^&#xE003;]*)&#xE003;')/*/
              (if (self::*:match)
               then '\gmlsymref{' || t:name(string(*:group[@nr = 1])) || '}{'
                    || t:attr(string(*:group[@nr = 2])) || '}'
               else t:sx-text(string(.), $ps)))
        else t:attrs($a, ()), ','), '}')"/>
    <xsl:if test="@break = 'yes'">%&#10;</xsl:if>
  </xsl:template>

  <!-- the text of a .sx field: the page number symbol $ps (none: '') is
       \gmlpageno -->
  <xsl:function name="t:sx-text" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="ps" as="xs:string"/>
    <xsl:sequence select="if ($ps = '') then t:attr($s)
        else string-join(for $p in tokenize($s, $ps, 'q') return t:attr($p), '\gmlpageno{}')"/>
  </xsl:function>

  <!-- Rel 4: a symbol in a running heading or footing is replaced when
       the heading is placed on a page (LR p.316).  gml:symref is a
       reference to symbol NAME, its content the value where the heading
       was defined: \gmlsymref{NAME}{value}, set by gml.tex with the value
       in effect where the page starts.  gml:symval is a new value of
       NAME at this point of the flow: \gmlsymval{NAME}{value} (a mark).
       NAME is written as an anchor name (t:name: [A-Za-z0-9.-]). -->
  <xsl:template match="gml:symref" priority="1">
    <xsl:value-of select="concat('\gmlsymref{', t:name(string(@name)), '}{')"/>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>
  <xsl:template match="gml:symval" priority="1">
    <xsl:value-of select="concat('\gmlsymval{', t:name(string(@name)), '}{', t:attr(string(@value)), '}')"/>
  </xsl:template>

  <xsl:template match="gml:df | gml:dh | gml:dr" priority="1">
    <xsl:variable name="keys" as="xs:string*" select="
        if (self::gml:df) then t:df-keys(string(@spec))
        else if (self::gml:dh) then t:dh-keys(string(@spec))
        else t:dr-keys(string(@spec))"/>
    <xsl:value-of select="concat('\gmlhint{', local-name(), '}{', t:attrs(@*, ()),
        string-join(for $k in $keys return ',' || substring-before($k, '=') || '='
                    || t:attr(substring-after($k, '='))), '}')"/>
  </xsl:template>

  <!-- gml:h & co. are elements (another flow), not hints; gml:cpart (a
       part of a table cell, :c n repeated) is a block element -->
  <xsl:template match="gml:h | gml:fn | gml:rh | gml:rf | gml:cpart" priority="1">
    <xsl:call-template name="element"/>
  </xsl:template>

  <!-- a running heading or footing holding the page number symbol (a .sx
       with pagesym=, or "&" alone in its operands or text: .dc PS
       default) or a deferred symbol reference (gml:symref, or one in a
       .sx field): the content is an argument of \gmlrundyn, typeset by
       gml.tex on every page -->
  <xsl:template match="(gml:rh | gml:rf)[.//gml:sx[@pagesym or @left = '&amp;'
                         or @fill = '&amp;' or @right = '&amp;'
                         or (@left | @fill | @right)[contains(., '&#xE001;')]]
                         or .//gml:pageno or .//gml:symref
                         or .//text()[matches(., '(^|\s)&amp;(\s|$)')]]" priority="2">
    <xsl:value-of select="concat('\gmlstart{', name(), '}{', t:attrs(@*, ()), '}%', $nl,
                                 '\gmlrundyn{')"/>
    <xsl:apply-templates/>
    <xsl:value-of select="concat('}\gmlend{', name(), '}%', $nl)"/>
  </xsl:template>

  <!-- .is TO after a label: the text (and .bf/.pf) between the last
       breaking hint and the gml:is is the start of an output line, so
       \gmlislabel before it lets gml.tex box and measure it -->
  <xsl:function name="t:is-label-start" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="is" select="$n/following-sibling::node()
        [not(self::text() or self::gml:bf or self::gml:pf)][1][self::gml:is]"/>
    <xsl:variable name="stop" select="$n/preceding-sibling::node()
        [not(self::text() or self::gml:bf or self::gml:pf)][1]"/>
    <xsl:sequence select="exists($is)
        and matches(lower-case(normalize-space($is/@spec)), '^to ')
        and empty($n/preceding-sibling::node()[1][self::text() or self::gml:bf or self::gml:pf])
        and ((exists($stop/self::gml:*[@break = 'yes'])
              and not(local-name($stop) = ($flows, $generated)))
             or (empty($stop) and t:is-block($n/..)))
        and normalize-space(string-join($is/preceding-sibling::text()
              [empty($stop) or . >> $stop])) != ''"/>
  </xsl:function>

  <xsl:template match="text() | gml:bf | gml:pf" priority="10">
    <xsl:if test="t:is-label-start(.)">\gmlislabel </xsl:if>
    <xsl:next-match/>
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

  <xsl:template match="gml:tlist-entries">
    <xsl:value-of select="concat('\gmltlistbegin{', t:esc(string(@title), false()), '}%', $nl)"/>
    <xsl:apply-templates select="gml:tlist-entry"/>
    <xsl:text>\gmltlistend%&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="gml:tlist-entry">
    <xsl:value-of select="concat('\gmltlistentry{', t:attrs(@*, ()), '}{')"/>
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

  <!-- ==== DCF definitions: parsed operands ============================================= -->
  <!-- the words of a spec, lower case; a quoted string is one word (quotes kept) -->
  <xsl:function name="t:words" as="xs:string*">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="analyze-string(lower-case($s), &quot;'[^']*'?|[^\s()']+|[()]&quot;)
                          /*:match/string()"/>
  </xsl:function>

  <xsl:function name="t:unresolved" as="xs:boolean">
    <xsl:param name="w" as="xs:string?"/>
    <xsl:sequence select="empty($w) or $w = '' or starts-with($w, '&amp;')"/>
  </xsl:function>

  <!-- .df: US UP UC STOP, OS RPT n | OS CHAR c, BOX c, FONT id, TYPE(desc),
       CODEPAGE cp (LR p.130-132).  A size in TYPE is points, signed =
       relative, 0 = unchanged (no size= then; p.131).  bold=yes for the
       weights from SEMIBOLD up; an omitted weight is MEDIUM and an
       omitted width NORMAL, not inherited (p.132), so no key means not
       bold.  DCF-VERIFY (not in LR Rel 4): the family is guessed from
       the typeface name.  OLDWEIGHT and OLDATTR (inherit) are not
       modelled. -->
  <xsl:function name="t:df-keys" as="xs:string*">
    <xsl:param name="spec" as="xs:string"/>
    <xsl:variable name="w" select="t:words($spec)"/>
    <xsl:variable name="open" select="index-of($w, '(')[1]"/>
    <xsl:variable name="tpos" select="index-of($w, 'type')[1]"/>
    <xsl:variable name="close" select="(index-of($w, ')')[. gt ($open, 0)[1]][1], count($w) + 1)[1]"/>
    <xsl:variable name="desc" as="xs:string*" select="
        if (exists($tpos)) then
          (if ($open = $tpos + 1) then subsequence($w, $open + 1, $close - $open - 1)
           else $w[$tpos + 1][. != '('])
        else ()"/>
    <xsl:variable name="inside" as="xs:integer*" select="
        if (exists($tpos)) then ($tpos to (if ($open = $tpos + 1) then $close else $tpos + 1)) else ()"/>
    <xsl:variable name="outer" as="xs:string*" select="
        for $i in 1 to count($w) return if ($i = $inside) then () else $w[$i]"/>
    <xsl:variable name="face" select="string-join(for $d in $desc[starts-with(., &quot;'&quot;)]
                                      return translate($d, &quot;'&quot;, ''), ' ')"/>
    <xsl:variable name="fonti" select="index-of($outer, 'font')[1]"/>
    <xsl:sequence select="
        (if ($outer = 'os') then 'os=yes' else ()),
        (if ($outer = ('us', 'uc')) then 'us=yes' else ()),
        (if ($outer = ('up', 'uc')) then 'up=yes' else ()),
        (if (exists($fonti) and not(t:unresolved($outer[$fonti + 1])))
         then 'font=' || $outer[$fonti + 1] else ()),
        (if ($face != '') then ('face=' || $face, 'family=' || t:family($face)) else ()),
        (for $d in $desc[matches(., '^[+-]?[0-9]*\.?[0-9]+$')][1]
         return if (matches($d, '^0*\.?0*$')) then () else 'size=' || $d),
        (if ($desc = ('bold', 'semibold', 'demibold', 'heavy', 'black', 'extrabold',
                      'ultrabold'))
         then 'bold=yes' else ()),
        (if ($desc = ('italic', 'oblique')) then 'italic=yes' else ())"/>
  </xsl:function>

  <xsl:function name="t:family" as="xs:string">
    <xsl:param name="face" as="xs:string"/>
    <xsl:sequence select="
        if (matches($face, '^pi( |$)|symbol|dingbat')) then 'pi'
        else if (matches($face, 'courier|prestige|elite|letter gothic|mono|typewriter|orator|(^| )pica( |$)'))
        then 'mono'
        else if (matches($face, 'sans|gothic|helvetica|univers|futura|avant')) then 'sans'
        else 'serif'"/>
  </xsl:function>

  <!-- a vertical .dh amount: a bare number is lines, p-notation points -->
  <xsl:function name="t:vdim" as="xs:string">
    <xsl:param name="v" as="xs:string?"/>
    <xsl:variable name="m" select="analyze-string(string($v), '^([0-9]*\.?[0-9]*)p([0-9]*\.?[0-9]*)$')/*:match"/>
    <xsl:sequence select="
        if (matches(string($v), '^[+-]?[0-9]*\.?[0-9]+$')) then $v || 'line'
        else if (exists($m) and string($v) != 'p') then
          string((if ($m/*:group[1] = '') then 0 else number($m/*:group[1])) * 12
                 + (if ($m/*:group[2] = '') then 0 else number($m/*:group[2]))) || 'pt'
        else string($v)"/>
  </xsl:function>

  <!-- .dh n options (LR p.136-138): BR NBR PA NPA TC NTC TO NTO TS NTS UP
       NUP US NUS DOT NODOT NUM NONUM SECT NOSECT AUTOHY NOHY CENTER LEFT
       INSIDE OUTSIDE RIGHT OJ NOJ (Rel 2 names of OUTSIDE and LEFT, r8)
       NOHANG; with one operand: FONT f (none when it is the last word),
       TFONT f, SKBF v, SPAF v, SPBF v, TCIN h, HANG n|AUTO.  Keys for
       gml.tex: font tfont spbf skbf spaf pa align runin up us hy; the
       others are parsed (their operand skipped) and not used.  Any other
       word is not an option (the engine warns) and is skipped. -->
  <xsl:function name="t:dh-keys" as="xs:string*">
    <xsl:param name="spec" as="xs:string"/>
    <xsl:variable name="w" select="t:words($spec)[not(. = ('(', ')'))]"/>
    <xsl:sequence select="if (empty($w)) then 'reset=yes' else t:dh-keys-from($w, 1)"/>
  </xsl:function>

  <xsl:function name="t:dh-keys-from" as="xs:string*">
    <xsl:param name="w" as="xs:string*"/>
    <xsl:param name="i" as="xs:integer"/>
    <xsl:if test="$i le count($w)">
      <xsl:variable name="t" select="$w[$i]"/>
      <xsl:variable name="val" select="$w[$i + 1]"/>
      <xsl:choose>
        <xsl:when test="$t = ('font', 'tfont')">
          <xsl:sequence select="(if (t:unresolved($val)) then () else $t || '=' || $val),
                                t:dh-keys-from($w, $i + 2)"/>
        </xsl:when>
        <xsl:when test="$t = ('spbf', 'skbf', 'spaf')">
          <xsl:sequence select="(if (empty($val)) then () else $t || '=' || t:vdim($val)),
                                t:dh-keys-from($w, $i + 2)"/>
        </xsl:when>
        <xsl:when test="$t = ('tcin', 'hang')">
          <xsl:sequence select="t:dh-keys-from($w, $i + 2)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="
              (if ($t = 'pa') then 'pa=yes' else if ($t = 'npa') then 'pa=no'
               else if ($t = ('left', 'right', 'center', 'inside', 'outside'))
               then 'align=' || $t
               else if ($t = 'oj') then 'align=outside' else if ($t = 'noj') then 'align=left'
               else if ($t = 'nbr') then 'runin=yes' else if ($t = 'br') then 'runin=no'
               else if ($t = 'up') then 'up=yes' else if ($t = 'nup') then 'up=no'
               else if ($t = 'us') then 'us=yes' else if ($t = 'nus') then 'us=no'
               else if ($t = 'autohy') then 'hy=yes' else if ($t = 'nohy') then 'hy=no'
               else ()),
              t:dh-keys-from($w, $i + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:function>

  <!-- .dr rulename [WEIGHT h] [FONT f] (SX26-3723 .DR) -->
  <xsl:function name="t:dr-keys" as="xs:string*">
    <xsl:param name="spec" as="xs:string"/>
    <xsl:variable name="w" select="t:words($spec)"/>
    <xsl:variable name="wi" select="(index-of($w, 'weight'), index-of($w, 'w'))[1]"/>
    <xsl:sequence select="(if (exists($w[1])) then 'rule=' || $w[1] else ()),
        (if (exists($wi) and exists($w[$wi + 1])) then 'weight=' || $w[$wi + 1] else ())"/>
  </xsl:function>

  <!-- ==== font state, for upper-case fonts ============================================= -->
  <!-- format mode: the fill= of the last .fo/.nf/.ju hint -->
  <xsl:accumulator name="t:fill" as="xs:string" initial-value="'yes'">
    <xsl:accumulator-rule match="gml:fo | gml:nf | gml:ju"
        select="if (@fill = ('yes', 'no')) then string(@fill) else $value"/>
  </xsl:accumulator>
  <!-- the .df names defined so far: name -> has UP/UC -->
  <xsl:accumulator name="t:dfs" as="map(xs:string, xs:boolean)" initial-value="map{}">
    <xsl:accumulator-rule match="gml:df"
        select="map:put($value, lower-case(normalize-space(@name)),
                        t:df-keys(string(@spec)) = 'up=yes')"/>
  </xsl:accumulator>
  <!-- the current .df-defined font: the first defined name of the last .bf
       or .pf list; a list with none of them leaves it unchanged ("=") -->
  <xsl:accumulator name="t:font" as="xs:string" initial-value="''">
    <xsl:accumulator-rule match="gml:bf | gml:pf" select="
        let $dfs := accumulator-before('t:dfs'),
            $f := (tokenize(lower-case(normalize-space(@font)), ' ')[map:contains($dfs, .)])[1]
        return if (exists($f)) then $f
               else if (self::gml:pf and normalize-space(@font) = '') then ''
               else $value"/>
  </xsl:accumulator>
  <!-- .dh per level: "font" and "up" -> value -->
  <xsl:accumulator name="t:dh" as="map(xs:string, xs:string)" initial-value="map{}">
    <xsl:accumulator-rule match="gml:dh" select="
        let $l := normalize-space(@level), $k := t:dh-keys(string(@spec)),
            $v := if ($k = 'reset=yes') then map:remove(map:remove($value, $l || 'font'), $l || 'up')
                  else $value,
            $font := (for $x in $k[starts-with(., 'font=')] return substring-after($x, '='))[1],
            $up := (for $x in $k[starts-with(., 'up=')] return substring-after($x, '='))[1],
            $v2 := if (exists($font)) then map:put($v, $l || 'font', $font) else $v
        return if (exists($up)) then map:put($v2, $l || 'up', $up) else $v2"/>
  </xsl:accumulator>

  <xsl:function name="t:upper" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="dfs" select="$n/accumulator-before('t:dfs')"/>
    <xsl:variable name="h" select="$n/ancestor::gml:h[1]"/>
    <xsl:choose>
      <xsl:when test="exists($h) and empty($h//(gml:bf | gml:pf)[. &lt;&lt; $n])">
        <xsl:variable name="dh" select="$h/accumulator-before('t:dh')"/>
        <xsl:variable name="l" select="normalize-space($h/@level)"/>
        <xsl:variable name="font" select="lower-case(($dh($l || 'font'), 'hd' || $l)[1])"/>
        <xsl:sequence select="$dh($l || 'up') = 'yes' or $dfs($font) = true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="f" select="$n/accumulator-before('t:font')"/>
        <xsl:sequence select="$f != '' and $dfs($f) = true()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ==== text ======================================================================= -->
  <xsl:template match="text()">
    <xsl:variable name="pre" select="string(ancestor::*[@xml:space][1]/@xml:space) = 'preserve'
        or accumulator-before('t:fill') = 'no'"/>
    <xsl:variable name="lword" select="string(ancestor::gml:lines[1]/@word)"/>
    <xsl:variable name="word" select="
        if (not(t:upper(.))) then $lword
        else if ($lword = ('us', 'uc')) then 'uc'
        else if ($lword = ('', 'up')) then 'up' else $lword"/>
    <xsl:choose>
      <!-- blanks between the parts of a table cell, even in preserved text -->
      <xsl:when test="normalize-space(.) = '' and parent::c and ../gml:cpart"/>
      <!-- a blank between a text variable and another one or an inline
           element ("&amp. &gml.", "&amp. :hp1.") is a word space; a hint
           (a footnote's callout before its gml:fn) is a block as before -->
      <xsl:when test="normalize-space(.) = ''
          and ((preceding-sibling::node()[1][self::gml:dv] and t:is-inline(following-sibling::node()[1]))
               or (following-sibling::node()[1][self::gml:dv] and t:is-inline(preceding-sibling::node()[1])))">
        <xsl:value-of select="t:text(., $pre, $word)"/>
      </xsl:when>
      <!-- a blank between two font changes (.pf .bf: the blank between two
           highlighted phrases, :ehp2. :hp1.) is a word space and stays -->
      <xsl:when test="not($pre) and normalize-space(.) = ''
          and not(preceding-sibling::node()[1][self::gml:bf or self::gml:pf]
                  and following-sibling::node()[1][self::gml:bf or self::gml:pf])
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
