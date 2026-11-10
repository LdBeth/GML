<?xml version="1.0" encoding="UTF-8"?>
<!-- notes/tex.xsl: tex.xsl plus the math tags of the notes tag set.
     The text of m and fml is TeX math and is written UNESCAPED, except
     for the two characters that are markup in the body: "<" is written
     \noteslt (the relation <) and "&" \notesamp (an alignment tab, as
     in \eqalign), both defined in tagset.tex, and "%" \% (no comment
     may hide the end tag that follows); characters outside
     printable ASCII still become &n;, and line ends become blanks.  fml
     writes its anchor (<@NAME>) before its start tag, so the \write is
     not inside the display; the blanks after an fml are dropped (the
     text after a display starts a new line).  The styles ($...$,
     $$...\eqno(n)$$) are in tagset.tex. -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:t="urn:x-gml:tex"
    exclude-result-prefixes="#all">
  <xsl:import href="../../xslt/tex.xsl"/>

  <xsl:template match="fml">
    <xsl:value-of select="(if (@anchor) then t:anchor(@anchor) else '')
                          || t:open('fml', t:attrs(@* except @anchor, ()), false())"/>
    <xsl:apply-templates/>
    <xsl:value-of select="t:close(false())"/>
  </xsl:template>

  <xsl:template match="text()[ancestor::m or ancestor::fml]" priority="2">
    <xsl:sequence select="string-join(
        analyze-string(translate(., '&#9;&#10;&#13;', '   '), '[^&#x20;-&#x7E;]|[&lt;&amp;%]')/*/
          (if (self::*:match)
           then (if (. = '&lt;') then '\noteslt ' else if (. = '&amp;') then '\notesamp '
                 else if (. = '%') then '\%' else t:char(string(.)))
           else string(.)))"/>
  </xsl:template>

  <xsl:template match="text()[preceding-sibling::node()[1][self::fml]]" priority="1">
    <xsl:variable name="s" select="replace(., '^\s+', '')"/>
    <xsl:if test="$s != ''">
      <xsl:value-of select="t:text($s, false(), string(ancestor::gml:lines[1]/@word))"/>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
