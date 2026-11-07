<?xml version="1.0" encoding="UTF-8"?>
<!--
  common.xsl - functions shared by the stage stylesheets (xsl:include'd by
  tex.xsl and html.xsl; templates none, so no precedence questions).
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    exclude-result-prefixes="#all">

  <!-- gml:hint-mode(top): a .df/.dh/.dr hint before the first source
       (non-gml:) element below top means a formatting profile
       (dcfstarter, a real DCF profile) wrote the text, numbers and labels:
       tex.xsl's auto mode, html.xsl's hint mode -->
  <xsl:function name="gml:hint-mode" as="xs:boolean">
    <xsl:param name="top" as="node()"/>
    <xsl:variable name="first-source" select="($top//*[not(self::gml:*)])[1]"/>
    <xsl:sequence select="exists($top//(gml:df | gml:dh | gml:dr)
        [empty($first-source) or . &lt;&lt; $first-source])"/>
  </xsl:function>

</xsl:stylesheet>
