<?xml version="1.0" encoding="UTF-8"?>
<!--
  strip-hints.xsl - remove the formatting layer, leaving the semantic tree.

  Input: canonical, resolved or scoped XML.  Output: the same tree with
    - every formatting hint removed: each node of kind="hint" in
      gml-shared.xml (the hints the engine writes: the table of
      lib/hints.ml and the nodes declared with the text, made by
      gmlshare; common.xsl reads it), but for the four below that are
      document content.  gml:br is a hint of the table, so the gml:br
      that scope.xsl writes for a state hint goes too;
    - the scopes unwrapped, their content kept: gml:lines (line-counted
      words) and gml:scope (scope.xsl); gml:symref (a symbol of a running
      heading) is its value;
    - the running heading/footing definitions gml:rh and gml:rf removed
      with their content (page furniture, not document text).
  Kept: gml:doc, gml:h (.h0-.h6 headings), gml:fn (.fn footnotes),
  gml:raw (backend passthrough), the resolve.xsl vocabulary (gml:num,
  gml:pageref, gml:toc-entries, ...), every non-gml element and all
  attributes, and four hints that are content, not format (the
  $content-hints below): gml:pi (a .pi index entry: its anchor= is the
  target of the gml:pageref of the index resolve.xsl writes), gml:dv (a
  .dv text variable: its text= is document text), gml:tcentry (an entry
  of a .tc table of contents, text= its title: the counterpart of the
  gml:toc-entries kept above) and gml:tcmark (in a heading: the target
  of the anchor= of its gml:tcentry).  xml:space="preserve" on xmp keeps
  its lines without the no-fill hint.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    exclude-result-prefixes="#all">

  <xsl:include href="common.xsl"/>

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <!-- hints that carry document content: kept (see the header) -->
  <xsl:variable name="content-hints" as="xs:string*" select="('pi', 'dv', 'tcentry', 'tcmark')"/>
  <xsl:variable name="hints" as="xs:string*"
      select="$gml:hint-names[not(. = $content-hints)]"/>

  <xsl:template match="gml:*[local-name() = $hints] | gml:rh | gml:rf"/>

  <xsl:template match="gml:lines | gml:scope | gml:symref">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
