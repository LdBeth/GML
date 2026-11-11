<?xml version="1.0" encoding="UTF-8"?>
<!--
  tex.xsl - resolved canonical GML XML -> plain TeX (share/tex/gml.tex).

  Input: the output of resolve.xsl (NOT scope.xsl): the DCF formatting
  hints stay point events, because TeX's \leftskip, fonts, \obeylines...
  are state too; gml.tex keeps the hint state and combines it with the
  element state (see the header of gml.tex).

  Output (method text, pure ASCII):
    [\def\gmlfonts{$tex-fonts}] [\def\gmltagset{$tex-tagset}]
    [\def\gmlpassno{K}\def\gmlpasses{N}: the root's pass= passes=, for
    gml.tex's \gmlpass]
    \input gml ($tex-input), $tex-preamble
    \gml         the body starts: < and & are active from here
    body<
    >            closes the root: ends the document
  Body: a tag is <...>, its first character selects the kind:
    <NAME ATTRS> .. <>   source element NAME (h1, p, c, user tags ...),
                         and gml:NAME as <:NAME ..>: h fn rh rf cpart
                         lines toc-entries figlist-entries tlist-entries
                         index-entries.  <> ends the innermost element.
    <.NAME ATTRS>        hint gml:NAME (an empty element) that breaks
    <,NAME ATTRS>        one that does not (break= is never written)
    <?WHAT ID>           gml:query (a question of the pass model)
    <=LABEL>             gml:num
    <@NAME>              an anchor that is not an element's own (tag sets)
    <!TEXT>              upper-case text, one per text segment
    <_WORD> <*WORD>      a word in a .us / .uc scope
    &N;                  the character with code point N
  ATTRS is k=v,k=v: all attributes, a value "yes" as the bare key, a
  value holding markup in braces.  An element with anchor= sets its
  anchor itself.  Computed attributes (t:extra): more on a gml:lines
  whose next gml:lines is its cont="yes" continuation, and the keys
  parsed from the spec of gml:df gml:dh gml:dr (below).  Index tags (i1 i2 i3
  ih1 ih2 ih3 iref) are written empty (their text is in
  gml:index-entries).
  A hint may take brace arguments after the tag:
    <,symref name=N>{value}   a deferred symbol reference (LR p.316),
                              also in .sx fields; <,symval name=N,value=V>
                              is its new value (a mark)
    <:rh ..><,rundyn>{..}<>   a running heading or footing typeset on
                              every page (page number symbol, symref)
    <,pageno>                 the page number symbol in a .sx field
    <,pageref refid=A,when=auto,label=L>  (when= left out if always)
    <,toc-entry ATTRS>{text}{page}   (figlist-entry, tlist-entry)
    <,index-group letter=L> <,index-entry level=N>{term}{refs}, refs:
      <,ixfirst> <,ixref refid=A,..> <,ixsep> <,ixrangesep>
      <,see kind=K,label=L>{text}
    <,tabline>{seg&9;seg}     a line holding tab characters
    <,islabel>                before the label that a .is TO measures
  Escaping (t:esc text, t:attr attribute values, t:name names): every
  TeX special ($ & # % \ { } ^ _ ~ < > | ") and every character outside
  printable ASCII is &N;, in attribute values "," and "=" too; two
  hyphens are "-{}-".  Names (anchor, refid, symbol names) keep
  [A-Za-z0-9.-], other characters are +n+.
  Line ends, for lay-out only, and no "%" anywhere in the body: a tag
  may have a newline right after its "<" (a blank inside a tag); the
  start and end tag of a block element, every breaking hint and each
  entry of a generated list (toc-entry ... index-entry) have one, so
  they start a line.
  Text: in xml:space="preserve" text each blank is "\ " and lines are
  kept; elsewhere runs of blank lines collapse to one line end and
  whitespace-only text next to block elements is dropped.  Format-off
  text (after a gml:fo/gml:nf with fill="no", until fill="yes") is
  written like preserved text: DCF keeps the input lines, their leading
  blanks and blank lines (SH35-0069 .FO; DSMXMP marks no xml:space).
  Parsed operands, so gml.tex need not parse DCF syntax:
    gml:df  os us up (line functions; uc = us+up), font=NAME (FONT
            operand, left out when an unresolved &symbol), from
            TYPE(...): face=quoted typeface, family=mono|sans|pi|serif
            (guessed from the typeface), size=N|+N|-N, bold, italic
    gml:dh  font= tfont= spbf= skbf= spaf= (a bare number is lines,
            p-notation "p14"/"1p6" points), pa=yes|no, align=left|right|
            center|inside|outside, runin=yes (NBR)|no (BR), up= us= hy=
            yes|no, reset (no options)
    gml:dr  rule=NAME, weight=h (WEIGHT or W operand)
  Upper case fonts: text whose current font (the first name of the last
  .bf/.pf font list that a gml:df defined; in a gml:h heading, its .dh
  font, default hdN) has UP or UC, or in a heading whose .dh says UP, is
  <!..> (<*..> inside .us scopes): plain TeX cannot upper-case text by a
  font switch.
  The document is formatted by a formatting profile (dcfstarter, or a
  tag set built on it): its control words, the hints, do the layout.
  gml.tex styles what the profile leaves to TeX (gml:h, gml:fn, gml:rh,
  gml:rf, the fig float, the tables, the generated lists); any other
  element is a group unless gml.tex or the tag set's tagset.tex defines
  it.  (The semantic profile starter is for HTML only: tags without a
  .df/.dh/.dr hint before the first of them are reported.)
  Tag sets (xsl:import): write syntax only through the functions of the
  writer section (t:open t:close t:hint t:tag t:anchor t:attrs t:kv
  t:arg t:esc t:attr t:name t:char t:ref); t:value t:omit t:extra
  decide the attributes.  Raw TeX may use backslash commands but never
  a raw "<" or "&".
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

  <xsl:variable name="root" select="(/gml:doc, /*)[1]"/>

  <xsl:variable name="nl" select="'&#10;'"/>

  <xsl:variable name="blocks" as="xs:string*" select="
      ('gdoc', 'frontm', 'titlep', 'title', 'docnum', 'date', 'author', 'address',
       'aline', 'abstract', 'preface', 'toc', 'figlist', 'body', 'appendix', 'backm',
       'index', 'h0', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'pc', 'note',
       'ol', 'ul', 'sl', 'dl', 'gl', 'li', 'lp', 'dthd', 'ddhd', 'dt', 'dd',
       'gt', 'gd', 'lq', 'xmp', 'fig', 'figcap', 'figdesc', 'gml:h', 'gml:rh', 'gml:rf',
       'rdef', 'table', 'thd', 'tft', 'row', 'c', 'tnote', 'tcap', 'tdesc', 'tlist')"/>
  <xsl:variable name="index-tags" as="xs:string*"
      select="('i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref')"/>
  <!-- gml:* elements that are another flow, not hints -->
  <xsl:variable name="flows" as="xs:string*" select="('h', 'fn', 'rh', 'rf')"/>
  <!-- gml:* written <:NAME ..>..<> (all others are hints) -->
  <xsl:variable name="elements" as="xs:string*" select="
      ($flows, 'cpart', 'lines', 'toc-entries', 'figlist-entries', 'tlist-entries',
       'index-entries')"/>
  <!-- generated gml:* that are neither hints nor blocks -->
  <xsl:variable name="generated" as="xs:string*" select="
      ('doc', 'lines', 'num', 'pageref', 'toc-entry', 'entry-text', 'figlist-entry',
       'tlist-entry', 'index-group', 'index-entry', 'index-term', 'see', 'symref', 'symval')"/>
  <!-- hints whose content is their brace argument -->
  <xsl:variable name="arg-hints" as="xs:string*" select="('symref', 'see')"/>

  <!-- ==== writers: all of the syntax ===================================== -->
  <!-- <SIGIL NAME ATTRS>; NAME and ATTRS are escaped by the caller; $nl:
       the tag starts a new line (a newline right after the "<") -->
  <xsl:function name="t:tag" as="xs:string">
    <xsl:param name="sigil" as="xs:string"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="attrs" as="xs:string"/>
    <xsl:param name="nl" as="xs:boolean"/>
    <xsl:sequence select="'&lt;' || (if ($nl) then '&#10;' else '') || $sigil || $name
                          || (if ($attrs = '') then '' else ' ' || $attrs) || '&gt;'"/>
  </xsl:function>

  <!-- an element start and end; "gml:NAME" is written ":NAME"; $block:
       on a new line -->
  <xsl:function name="t:open" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="attrs" as="xs:string"/>
    <xsl:param name="block" as="xs:boolean"/>
    <xsl:sequence select="t:tag('', replace($name, '^gml:', ':'), $attrs, $block)"/>
  </xsl:function>

  <xsl:function name="t:close" as="xs:string">
    <xsl:param name="block" as="xs:boolean"/>
    <xsl:sequence select="t:tag('', '', '', $block)"/>
  </xsl:function>

  <!-- a hint; a breaking one is on a new line -->
  <xsl:function name="t:hint" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="attrs" as="xs:string"/>
    <xsl:param name="break" as="xs:boolean"/>
    <xsl:sequence select="t:tag(if ($break) then '.' else ',', $name, $attrs, $break)"/>
  </xsl:function>

  <xsl:function name="t:anchor" as="xs:string">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="t:tag('@', t:name($name), '', false())"/>
  </xsl:function>

  <!-- the character reference &N; -->
  <xsl:function name="t:ref" as="xs:string">
    <xsl:param name="n" as="xs:integer"/>
    <xsl:sequence select="'&amp;' || $n || ';'"/>
  </xsl:function>

  <!-- one key: "yes" is the bare key, a value holding markup is braced -->
  <xsl:function name="t:kv" as="xs:string">
    <xsl:param name="k" as="xs:string"/>
    <xsl:param name="v" as="xs:string"/>
    <xsl:sequence select="if ($v = 'yes') then $k
        else $k || '=' || t:arg($v)"/>
  </xsl:function>

  <!-- a value holding markup in braces -->
  <xsl:function name="t:arg" as="xs:string">
    <xsl:param name="v" as="xs:string"/>
    <xsl:sequence select="if (contains($v, '&lt;')) then '{' || $v || '}' else $v"/>
  </xsl:function>

  <!-- the attribute list: $atts (escaped by t:value, less t:omit) and
       $extra, "key=value" strings with the value escaped -->
  <xsl:function name="t:attrs" as="xs:string">
    <xsl:param name="atts" as="attribute()*"/>
    <xsl:param name="extra" as="xs:string*"/>
    <xsl:sequence select="string-join((
        for $a in $atts[not(t:omit(.))] return t:kv(name($a), t:value($a)),
        for $x in $extra return if (contains($x, '='))
          then t:kv(substring-before($x, '='), substring-after($x, '=')) else $x), ',')"/>
  </xsl:function>

  <!-- an attribute's value: names, the fields of a .sx, or a value -->
  <xsl:function name="t:value" as="xs:string">
    <xsl:param name="a" as="attribute()"/>
    <xsl:sequence select="
        if (local-name($a) = 'anchor' or name($a) = 'refid'
            or (name($a) = 'name' and $a/(parent::gml:symref | parent::gml:symval)))
        then t:name($a)
        else if ($a/parent::gml:sx and name($a) = ('left', 'fill', 'right'))
        then t:sx-field(string($a), string($a/../@pagesym))
        else t:attr($a)"/>
  </xsl:function>

  <!-- attributes left out: break= of a hint (its sigil), a pageref's
       when=always and empty label=, an empty title= of a generated list,
       and in a table what gml.tex assumes or does not read: of a gml:cell of
       a row definition, and of a c in a row that states its own cwidths (a
       row that names its rdef takes the cells' options from it, so its c
       are written as they are), the defaults, col= when it is the place
       among its siblings and n= when it is col=; cols=; subrows=1; rdef= of
       a row with its own cwidths; split=no and rotate=0 of the table,
       split=no of a row in such a table -->
  <xsl:variable name="cell-defaults" as="map(xs:string, xs:string)" select="map{
      'colspan': '1', 'subrow': '1', 'rowspan': '1', 'hp': '0', 'align': 'left',
      'valign': 'top', 'concat': 'yes', 'rotate': '0', 'mindepth': '*', 'shade': '0'}"/>
  <xsl:function name="t:omit" as="xs:boolean">
    <xsl:param name="a" as="attribute()"/>
    <xsl:sequence select="(name($a) = 'break' and $a/parent::gml:*[not(local-name() = $elements)])
        or ($a/parent::gml:pageref and (name($a) = 'when' and $a = 'always'
                                        or name($a) = 'label' and $a = ''))
        or (name($a) = 'title' and $a = '' and $a/parent::gml:*[ends-with(local-name(), '-entries')])
        or ($a/(parent::c[parent::row/@cwidths] | parent::gml:cell) and (string($a) = $cell-defaults(name($a))
            or name($a) = 'col' and string($a) = string(count($a/../preceding-sibling::*[name() = name($a/..)]) + 1)
            or name($a) = 'n' and string($a) = string($a/../@col)))
        or ($a/(parent::row | parent::rdef[gml:cell]) and (name($a) = 'cols' or name($a) = 'subrows' and $a = '1'))
        or ($a/parent::row and (name($a) = 'rdef' and exists($a/../@cwidths)
            or name($a) = 'split' and $a = 'no' and $a/ancestor::table[1]/@split = 'no'))
        or ($a/parent::table and (name($a) = 'split' and $a = 'no' or name($a) = 'rotate' and $a = '0'))"/>
  </xsl:function>

  <!-- ==== escaping ===================================================== -->
  <xsl:variable name="special"
      select="'[\\{}$&amp;#\^_%~&lt;&gt;|&quot;]|[^&#x20;-&#x7E;]'"/>

  <!-- text; $pre: a blank is "\ " too -->
  <xsl:function name="t:esc" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pre" as="xs:boolean"/>
    <xsl:variable name="e" select="string-join(
        analyze-string($s, $special || (if ($pre) then '| ' else ''))/*/
          (if (self::*:match) then t:char(string(.)) else string(.)))"/>
    <xsl:sequence select="replace(replace($e, '--', '-{}-'), '--', '-{}-')"/>
  </xsl:function>

  <!-- one character to escape (tag sets may pass some through) -->
  <xsl:function name="t:char" as="xs:string">
    <xsl:param name="c" as="xs:string"/>
    <xsl:variable name="n" select="string-to-codepoints($c)[1]"/>
    <xsl:sequence select="
        if ($c = ' ') then '\ '
        else if ($n lt 32 or $n = 127) then ''
        else t:ref($n)"/>
  </xsl:function>

  <xsl:function name="t:attr" as="xs:string">
    <xsl:param name="v" as="xs:string"/>
    <xsl:sequence select="replace(replace(t:esc(translate($v, '&#9;&#10;&#13;', '   '), false()),
                                          ',', '&amp;44;'), '=', '&amp;61;')"/>
  </xsl:function>

  <xsl:function name="t:name" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="string-join(for $c in string-to-codepoints($s)
        return (if (matches(codepoints-to-string($c), '^[A-Za-z0-9.\-]$'))
                then codepoints-to-string($c) else concat('+', $c, '+')))"/>
  </xsl:function>

  <!-- ==== classification ================================================= -->
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

  <!-- the computed attributes of an element or hint, "key=value" -->
  <xsl:function name="t:extra" as="xs:string*">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="next" select="$e/following::gml:lines[1]"/>
    <xsl:sequence select="
        if ($e/self::gml:lines) then
          (if ($next/@cont = 'yes' and $next/@word = $e/@word) then 'more=yes' else ())
        else if ($e/(self::gml:df | self::gml:dh | self::gml:dr)) then
          for $k in (if ($e/self::gml:df) then t:df-keys(string($e/@spec))
                     else if ($e/self::gml:dh) then t:dh-keys(string($e/@spec))
                     else t:dr-keys(string($e/@spec)))
          return substring-before($k, '=') || '=' || t:attr(substring-after($k, '='))
        else ()"/>
  </xsl:function>

  <!-- a running heading or footing holding the page number symbol (a .sx
       with pagesym=, or "&" alone in its operands or text: .dc PS
       default) or a deferred symbol reference (gml:symref, or one in a
       .sx field): typeset by gml.tex on every page -->
  <xsl:function name="t:is-rundyn" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="exists($e/(self::gml:rh | self::gml:rf)[
        .//gml:sx[@pagesym or @left = '&amp;' or @fill = '&amp;' or @right = '&amp;'
                  or (@left | @fill | @right)[contains(., '&#xE001;')]]
        or .//gml:pageno or .//gml:symref
        or .//text()[matches(., '(^|\s)&amp;(\s|$)')]])"/>
  </xsl:function>

  <!-- ==== document ======================================================= -->
  <xsl:template match="/">
    <!-- tags but no .df/.dh/.dr before the first: not a formatting
         profile (the semantic profile starter is for HTML only) -->
    <xsl:variable name="first-source" select="($root//*[not(self::gml:*)])[1]"/>
    <xsl:if test="exists($first-source)
        and empty($root//(gml:df | gml:dh | gml:dr)[. &lt;&lt; $first-source])">
      <xsl:message select="'tex: ' || local-name($first-source) || ': no .df/.dh/.dr'
          || ' before the first tag: TeX needs a formatting profile (-profile dcfstarter)'"/>
    </xsl:if>
    <!-- the settings (pass=/passes=: the pass model, gml.tex's \gmlpass) -->
    <xsl:value-of separator="&#10;" select="
        ('\def\gmlfonts{' || $tex-fonts || '}')[$tex-fonts != ''],
        ('\def\gmltagset{' || $tex-tagset || '}')[$tex-tagset != ''],
        ('\def\gmlpassno{' || t:name(string($root/@pass)) || '}\def\gmlpasses{'
         || t:name(string($root/@passes)) || '}')[$root/@pass and $root/@passes],
        '\input ' || $tex-input, $tex-preamble[. != ''],
        '\gml', ''"/>
    <xsl:apply-templates select="(gml:doc, *)[1]/node()"/>
    <xsl:value-of select="t:close(true()) || $nl"/>
  </xsl:template>

  <!-- ==== elements ========================================================= -->
  <xsl:template match="*">
    <xsl:call-template name="element"/>
  </xsl:template>

  <xsl:template name="element">
    <xsl:variable name="block" select="t:is-block(.)"/>
    <xsl:value-of select="t:open(name(), t:attrs(@*, t:extra(.)), $block)"/>
    <xsl:choose>
      <xsl:when test="name() = $index-tags"/>
      <xsl:when test="t:is-rundyn(.)">
        <xsl:value-of select="t:hint('rundyn', '', false()) || '{'"/>
        <xsl:apply-templates/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="t:close($block)"/>
  </xsl:template>

  <!-- ==== hints ============================================================= -->
  <xsl:template match="gml:*[not(local-name() = $elements)]">
    <xsl:value-of select="t:hint(local-name(), t:attrs(@*, t:extra(.)), @break = 'yes')"/>
    <xsl:if test="local-name() = $arg-hints">{</xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="local-name() = $arg-hints">}</xsl:if>
  </xsl:template>

  <!-- a question of the pass model (gml -aux, Ctx.query): gml.tex
       writes the answer to the aux file -->
  <xsl:template match="gml:query" priority="1">
    <xsl:value-of select="t:tag('?', t:name(@what), t:name(@id), false())"/>
  </xsl:template>

  <xsl:template match="gml:num" priority="1">
    <xsl:variable name="label">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:value-of select="t:tag('=', t:arg(string($label)), '', false())"/>
  </xsl:template>

  <!-- a .sx field in a running heading or footing: the page number
       symbol $ps (none: '') is <,pageno>, any other character, a text
       "&" too, is text.  A deferred symbol reference (U+E001 NAME U+E002
       value U+E003, lib/doc.ml) is <,symref name=NAME>{value}; its value
       is text, not split at the page number symbol -->
  <xsl:function name="t:sx-field" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="ps" as="xs:string"/>
    <xsl:sequence select="string-join(
        analyze-string($s, '&#xE001;([^&#xE002;]*)&#xE002;([^&#xE003;]*)&#xE003;')/*/
          (if (self::*:match)
           then t:hint('symref', 'name=' || t:name(*:group[@nr = 1]), false())
                || '{' || t:attr(*:group[@nr = 2]) || '}'
           else if ($ps = '') then t:attr(.)
           else string-join(tokenize(., $ps, 'q') ! t:attr(.), t:hint('pageno', '', false()))))"/>
  </xsl:function>

  <!-- .is TO after a label: the text (and .bf/.pf) between the last
       breaking hint and the gml:is is the start of an output line, so
       <,islabel> before it lets gml.tex box and measure it -->
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
    <xsl:if test="t:is-label-start(.)">
      <xsl:value-of select="t:hint('islabel', '', false())"/>
    </xsl:if>
    <xsl:next-match/>
  </xsl:template>

  <!-- ==== generated lists ======================================================= -->
  <xsl:template match="gml:toc-entry | gml:figlist-entry | gml:tlist-entry" priority="1">
    <xsl:value-of select="t:tag(',', local-name(), t:attrs(@*, ()), true()) || '{'"/>
    <xsl:apply-templates select="gml:entry-text/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="gml:pageref"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="gml:index-group" priority="1">
    <xsl:value-of select="t:tag(',', 'index-group', t:attrs(@*, ()), true())"/>
    <xsl:apply-templates select="gml:index-entry"/>
  </xsl:template>

  <xsl:template match="gml:index-entry" priority="1">
    <xsl:value-of select="t:tag(',', 'index-entry', t:kv('level', t:attr((@level, '1')[1])), true()) || '{'"/>
    <xsl:apply-templates select="gml:index-term/node()"/>
    <xsl:text>}{</xsl:text>
    <xsl:for-each select="gml:pageref">
      <xsl:value-of select="t:hint(if (position() = 1) then 'ixfirst'
          else if (preceding-sibling::gml:pageref[1]/@range = 'start') then 'ixrangesep'
          else 'ixsep', '', false()),
          t:hint('ixref', t:attrs((@refid, @major, @range, @text), ()), false())" separator=""/>
    </xsl:for-each>
    <xsl:apply-templates select="gml:see"/>
    <xsl:text>}</xsl:text>
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

  <!-- text: lines, a line with tabs is <,tabline>{seg&9;seg..} -->
  <xsl:function name="t:text" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pre" as="xs:boolean"/>
    <xsl:param name="word" as="xs:string"/>
    <xsl:variable name="s1" select="if ($pre) then $s else replace($s, '\n(\s*\n)+', $nl)"/>
    <xsl:sequence select="string-join(
        for $line in tokenize($s1, '\n') return
          if (contains($line, '&#9;'))
          then t:hint('tabline', '', false()) || '{' || string-join(
                 for $seg in tokenize($line, '&#9;') return t:seg($seg, $pre, $word), t:ref(9)) || '}'
          else t:seg($line, $pre, $word),
        $nl)"/>
  </xsl:function>

  <!-- a segment of text; $word: up = one <!..> around its words, us uc =
       <_..> <*..> around each word -->
  <xsl:function name="t:seg" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pre" as="xs:boolean"/>
    <xsl:param name="word" as="xs:string"/>
    <xsl:variable name="sigil" select="map{'up': '!', 'us': '_', 'uc': '*'}($word)"/>
    <xsl:variable name="re" select="if ($word = 'up') then '\S(.*\S)?' else '\S+'"/>
    <xsl:sequence select="if (empty($sigil)) then t:esc($s, $pre)
        else string-join(analyze-string($s, $re)/*/
            (if (self::*:match) then t:tag($sigil, t:esc(., $pre), '', false()) else t:esc(., $pre)))"/>
  </xsl:function>

</xsl:stylesheet>
