<?xml version="1.0" encoding="UTF-8"?>
<!-- notes/html.xsl: html.xsl plus rules for the :warn and math tags of the
     notes tag set.  gmlfmt -tagset uses it in place of xslt/html.xsl.
     Shows the override mechanism: import the shipped stylesheet and add or
     replace templates.

     Math: m is <span class="gml-m">\(...\)</span>; fml (inside a <p>) is a
     display-block span holding \[...\] and the number "(n)" at the right;
     fmlref links to its equation.  When the document has math, <head>
     loads KaTeX and its auto-render extension (version $katex-version,
     from cdnjs), which typesets the \( \) and \[ \] delimiters; without
     JavaScript the TeX source stays readable. -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:h="urn:x-gml:html"
    xmlns:n="urn:x-gml:notes"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="gml h n xs">
  <xsl:import href="../../xslt/html.xsl"/>

  <!-- KaTeX location; katex-base="" = no KaTeX (the TeX source is shown) -->
  <xsl:param name="katex-version" as="xs:string" select="'0.16.9'"/>
  <xsl:param name="katex-base" as="xs:string"
      select="'https://cdnjs.cloudflare.com/ajax/libs/KaTeX/' || $katex-version"/>

  <!-- tell html.xsl that these tags are handled here (no "unknown element" message) -->
  <xsl:variable name="h:extra-known" as="xs:string*" select="'warn', 'm', 'fml', 'fmlref'"/>

  <xsl:template match="warn">
    <aside class="gml-warn"
           style="border-left: 4px solid #c60; padding: .4em 1em; margin: 1em 0;">
      <!-- the label ("Note:"/"Important:") is inserted by the APF -->
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </aside>
  </xsl:template>

  <!-- ==== math ============================================================ -->
  <!-- the document as html.xsl builds it, then KaTeX added to <head> -->
  <xsl:template match="gml:doc">
    <xsl:choose>
      <xsl:when test="$katex-base != '' and (.//m or .//fml)">
        <xsl:variable name="page"><xsl:next-match/></xsl:variable>
        <xsl:apply-templates select="$page" mode="n:head"/>
      </xsl:when>
      <xsl:otherwise><xsl:next-match/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:mode name="n:head" on-no-match="shallow-copy"/>
  <xsl:template mode="n:head" match="head">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="n:head"/>
      <link rel="stylesheet" href="{$katex-base}/katex.min.css"/>
      <xsl:text>&#10;</xsl:text>
      <script defer="defer" src="{$katex-base}/katex.min.js"></script>
      <xsl:text>&#10;</xsl:text>
      <script defer="defer" src="{$katex-base}/contrib/auto-render.min.js"
              onload="renderMathInElement(document.body, {{delimiters: [{{left: '\\[', right: '\\]', display: true}}, {{left: '\\(', right: '\\)', display: false}}]}});"></script>
      <xsl:text>&#10;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="m">
    <span class="gml-m">
      <xsl:text>\(</xsl:text>
      <xsl:value-of select="normalize-space(.)"/>
      <xsl:text>\)</xsl:text>
    </span>
  </xsl:template>

  <xsl:template match="fml">
    <span class="gml-fml" style="display: flex; align-items: center; margin: .6em 0;">
      <xsl:call-template name="h:id"/>
      <span class="gml-fml-body" style="flex: 1; text-align: center;">
        <xsl:text>\[</xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text>\]</xsl:text>
      </span>
      <xsl:if test="not(@num = 'no')">
        <span class="gml-fml-num" style="margin-left: 1em;">
          <xsl:value-of select="concat('(', @num, ')')"/>
        </span>
      </xsl:if>
    </span>
  </xsl:template>

  <xsl:template match="fmlref">
    <xsl:choose>
      <xsl:when test="@resolved = 'yes'">
        <a class="gml-fmlref" href="#{(key('h:id', string(@refid))/@anchor, @refid)[1]}">
          <xsl:value-of select="."/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <span class="gml-fmlref gml-unresolved"><xsl:value-of select="."/></span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
