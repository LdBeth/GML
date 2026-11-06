<?xml version="1.0" encoding="UTF-8"?>
<!-- notes/fo.xsl: fo.xsl plus rules for the :warn and math tags of the
     notes tag set.  Plain XSL-FO 1.1 has no math renderer, so the math
     (TeX notation) is shown as its source in the monospace font: m
     inline, fml as a centred block (inside the paragraph, which it
     splits) with "(n)" at the right, a three-column fixed table. -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:f="urn:x-gml:fo"
    exclude-result-prefixes="gml f">
  <xsl:import href="../../xslt/fo.xsl"/>

  <xsl:template match="warn">
    <fo:block space-before="9pt" space-after="9pt" padding="4pt"
              border-start-style="solid" border-start-width="3pt"
              border-start-color="#cc6600" start-indent="6pt">
      <!-- the label ("Note:"/"Important:") is inserted by the APF -->
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <!-- ==== math ============================================================ -->
  <xsl:template match="m">
    <fo:inline font-family="{$mono-family}" font-size="90%">
      <xsl:value-of select="normalize-space(.)"/>
    </fo:inline>
  </xsl:template>

  <xsl:template match="fml">
    <fo:block space-before="6pt" space-after="6pt" text-indent="0pt">
      <xsl:if test="@anchor"><xsl:attribute name="id" select="@anchor"/></xsl:if>
      <fo:table table-layout="fixed" width="100%">
        <fo:table-column column-width="proportional-column-width(1)"/>
        <fo:table-column column-width="proportional-column-width(8)"/>
        <fo:table-column column-width="proportional-column-width(1)"/>
        <fo:table-body start-indent="0pt" end-indent="0pt">
          <fo:table-row>
            <fo:table-cell><fo:block/></fo:table-cell>
            <fo:table-cell display-align="center">
              <fo:block text-align="center" font-family="{$mono-family}" font-size="90%"
                        hyphenate="false">
                <xsl:value-of select="normalize-space(.)"/>
              </fo:block>
            </fo:table-cell>
            <fo:table-cell display-align="center">
              <fo:block text-align="end">
                <xsl:if test="not(@num = 'no')">
                  <xsl:value-of select="concat('(', @num, ')')"/>
                </xsl:if>
              </fo:block>
            </fo:table-cell>
          </fo:table-row>
        </fo:table-body>
      </fo:table>
    </fo:block>
  </xsl:template>

  <xsl:template match="fmlref">
    <xsl:choose>
      <xsl:when test="@resolved = 'yes' and exists(key('f:anchor', string(@refid))[self::fml])">
        <fo:basic-link internal-destination="{@refid}"><xsl:value-of select="."/></fo:basic-link>
      </xsl:when>
      <xsl:otherwise>
        <fo:inline><xsl:value-of select="."/></fo:inline>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
