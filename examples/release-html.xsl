<?xml version="1.0" encoding="UTF-8"?>
<!-- release-html.xsl: html.xsl plus a rule for the user-defined :warn tag.
     Shows the override mechanism: import the shipped stylesheet and add or
     replace templates. -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:h="urn:x-gml:html"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="gml h xs">
  <xsl:import href="../xslt/html.xsl"/>

  <!-- tell html.xsl that :warn is handled here (no "unknown element" message) -->
  <xsl:variable name="h:extra-known" as="xs:string*" select="'warn'"/>

  <xsl:template match="warn">
    <aside class="gml-warn"
           style="border-left: 4px solid #c60; padding: .4em 1em; margin: 1em 0;">
      <!-- the label ("Note:"/"Important:") is inserted by the APF -->
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
      </xsl:apply-templates>
    </aside>
  </xsl:template>
</xsl:stylesheet>
