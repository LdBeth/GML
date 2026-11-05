<?xml version="1.0" encoding="UTF-8"?>
<!--
  strip-hints.xsl - remove the formatting layer, leaving the semantic tree.

  Input: canonical, resolved or scoped XML.  Output: the same tree with
    - every formatting hint element removed: the gml:NAME hints of the
      table in lib/hints.ml (br sp sk in ir of ll fo nf ju pa cp cc cb bx
      hr vr kp dh tc sx tp tb bf pf df hy hw rc bc fl ls sb ws es wz is ic
      ud dr pn pl pw pm tm bm cl cd sc mc) and the gml:br breaks written
      by scope.xsl;
    - the scopes unwrapped, their content kept: gml:lines (line-counted
      words) and gml:scope (scope.xsl);
    - the running heading/footing definitions gml:rh and gml:rf removed
      with their content (page furniture, not document text).
  Kept: gml:doc, gml:h (.h0-.h6 headings), gml:fn (.fn footnotes),
  gml:raw (backend passthrough), the resolve.xsl vocabulary (gml:num,
  gml:pageref, gml:toc-entries, ...), every non-gml element and all
  attributes.  xml:space="preserve" on xmp keeps its lines without the
  no-fill hint.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gml="urn:x-gml:canonical"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <xsl:variable name="hints" select="('br', 'sp', 'sk', 'in', 'ir', 'of', 'll', 'fo', 'nf', 'ju',
      'pa', 'cp', 'cc', 'cb', 'bx', 'hr', 'vr', 'kp', 'dh', 'tc', 'sx', 'tp', 'tb', 'bf', 'pf',
      'df', 'hy', 'hw', 'rc', 'bc', 'fl', 'ls', 'sb', 'ws', 'es', 'wz', 'is', 'ic', 'ud', 'dr',
      'pn', 'pl', 'pw', 'pm', 'tm', 'bm', 'cl', 'cd', 'sc', 'mc')"/>

  <xsl:template match="gml:*[local-name() = $hints] | gml:rh | gml:rf"/>

  <xsl:template match="gml:lines | gml:scope">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
