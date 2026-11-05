<?xml version="1.0" encoding="UTF-8"?>
<!--
  fo-vendor-ah.xsl - fo.xsl plus Antenna House Formatter extensions.

  An example of the layering: fo.xsl writes plain XSL-FO 1.1 and applies
  empty hook modes at the points where a vendor may add attributes; this
  stylesheet imports it and fills two of them.  Anything else can be
  overridden the usual way (a template rule here beats the imported one;
  xsl:next-match / xsl:apply-imports reach the original).

    transform -s:doc.s.xml -xsl:xslt/fo-vendor-ah.xsl -o:doc.fo [appendix-prefix=A-]

  Extensions used (AH Formatter "axf:" properties):
    axf:suppress-duplicate-page-number="true"  on each index entry: an
        entry with several references on one page prints the page once
        (FO 1.1 page-number-citation cannot merge them).
    axf:page-number-prefix  on the appendix page-sequence, when
        $appendix-prefix is given ("A-"): page numbers there, and the
        citations of them in the TOC and index, print as "A-3".

  Hook modes of fo.xsl (each adds attributes to the FO element being
  written; the context node is the GML element):
    f:root-attrs (the document node, on fo:root), f:page-sequence-attrs
    (the section element; $kind = titlep frontm body appendix backm),
    f:float-attrs (fig, on fo:float), f:toc-attrs (gml:toc-entry /
    gml:figlist-entry), f:index-attrs (gml:index-entry); and the mode
    f:fig-in-place (fig, $block: the figure block) for a figure that is
    not floated (place=inline or bottom).
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:axf="http://www.antennahouse.com/names/XSL/Extensions"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:f="urn:x-gml:fo"
    exclude-result-prefixes="xs gml f">

  <xsl:import href="fo.xsl"/>

  <xsl:param name="appendix-prefix" as="xs:string" select="''"/>

  <xsl:template match="gml:index-entry" mode="f:index-attrs">
    <xsl:attribute name="axf:suppress-duplicate-page-number" select="'true'"/>
  </xsl:template>

  <xsl:template match="*" mode="f:page-sequence-attrs">
    <xsl:param name="kind" as="xs:string"/>
    <xsl:if test="$kind = 'appendix' and $appendix-prefix ne ''">
      <xsl:attribute name="axf:page-number-prefix" select="$appendix-prefix"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
