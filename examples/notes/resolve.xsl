<?xml version="1.0" encoding="UTF-8"?>
<!-- notes/resolve.xsl: resolve.xsl plus equation numbering for the math
     tags of the notes tag set (:fml, :fmlref).

     fml     gets num="n" (1, 2, ... in document order, counting only the
             numbered ones) and anchor (its id or gml-fml-n), like a
             figure.  A source num=no means unnumbered and is kept as
             num="no" (so the output resolves again unchanged).
     fmlref  resolved="yes", target="fml", num="n", content "(n)".
             Unknown id, or one that is not a numbered fml: an
             xsl:message and "Formula ID unknown" ($lit-formula). -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:r="urn:x-gml:resolve"
    exclude-result-prefixes="#all">
  <xsl:import href="../../xslt/resolve.xsl"/>

  <xsl:param name="lit-formula" as="xs:string" select="'Formula'"/>

  <xsl:function name="r:fml-num" as="xs:string">
    <xsl:param name="f" as="element()"/>
    <xsl:sequence select="if ($f/@num = 'no') then ''
        else string(count($f/preceding::fml[not(@num = 'no')]) + 1)"/>
  </xsl:function>

  <xsl:template match="fml">
    <xsl:copy>
      <xsl:apply-templates select="@* except (@num, @anchor)"/>
      <xsl:attribute name="num" select="if (@num = 'no') then 'no' else r:fml-num(.)"/>
      <xsl:attribute name="anchor" select="r:anchor(.)"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="fmlref">
    <xsl:variable name="t" select="key('id', string(@refid))[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@* except (@resolved, @target, @num)"/>
      <xsl:choose>
        <xsl:when test="$t/self::fml[not(@num = 'no')]">
          <xsl:attribute name="resolved" select="'yes'"/>
          <xsl:attribute name="target" select="'fml'"/>
          <xsl:attribute name="num" select="r:fml-num($t)"/>
          <xsl:value-of select="concat('(', r:fml-num($t), ')')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="r:unresolved(., if ($t/self::fml) then 'the formula is not numbered'
                                else if ($t) then concat('refers to a ', local-name($t), ', not a formula')
                                else 'no such id')"/>
          <xsl:attribute name="resolved" select="'no'"/>
          <xsl:value-of select="string-join(($lit-formula, @refid, $lit-unknown), ' ')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
