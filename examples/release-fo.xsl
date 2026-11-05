<?xml version="1.0" encoding="UTF-8"?>
<!-- release-fo.xsl: fo.xsl plus a rule for the user-defined :warn tag. -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:gml="urn:x-gml:canonical"
    exclude-result-prefixes="gml">
  <xsl:import href="../xslt/fo.xsl"/>

  <xsl:template match="warn">
    <fo:block space-before="9pt" space-after="9pt" padding="4pt"
              border-start-style="solid" border-start-width="3pt"
              border-start-color="#cc6600" start-indent="6pt">
      <!-- the label ("Note:"/"Important:") is inserted by the APF -->
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
</xsl:stylesheet>
