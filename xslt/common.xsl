<?xml version="1.0" encoding="UTF-8"?>
<!--
  common.xsl - functions and data shared by the stage stylesheets
  (xsl:include'd by scope.xsl, strip-hints.xsl, html.xsl and tex.xsl;
  templates none, so no precedence questions).

  What the engine knows of its own output comes from gml-shared.xml
  (namespace urn:x-gml:shared), next to this file: made by gmlshare
  (bin/gmlshare.ml, lib/shared.ml) from the engine's tables (lib/hints.ml,
  lib/units.ml ...) and kept current by dune build.  It is read once, by
  this file's own URI, so a tag set bundle that imports a stage from
  elsewhere finds it too.  Global variables, built once:
    $gml:shared              the shared element
    $gml:hint-names          every hint the engine writes (kind="hint");
                             a name may also be an element (rh, rf)
    $gml:state-hint-names    class="state" (scope.xsl: set until changed)
    $gml:conditional-hint-names  the state hints that are state only
                             with some attributes (conditional="yes")
    $gml:event-hint-names    class="event"
    $gml:properties          the formatting state properties, in
                             scope.xsl's attribute order; by tier:
    $gml:block-properties, $gml:inline-properties
    $gml:initial-state       map property -> initial value
    $gml:unit-names          the space units (lib/units.ml)
  Functions: gml:nodes(kind) (the node rows of a kind: root element
  scope hint raw), gml:unit(name), gml:unit-size(name, base) (one unit
  in another, from their inch sizes), gml:hint-mode(top).
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:sh="urn:x-gml:shared"
    exclude-result-prefixes="#all">

  <!-- ==== gml-shared.xml ================================================ -->
  <xsl:variable name="gml:shared" as="element(sh:shared)"
      select="doc(resolve-uri('gml-shared.xml', static-base-uri()))/sh:shared"/>

  <xsl:function name="gml:nodes" as="element(sh:node)*">
    <xsl:param name="kind" as="xs:string"/>
    <xsl:sequence select="$gml:shared/sh:nodes/sh:node[@kind = $kind]"/>
  </xsl:function>

  <xsl:variable name="gml:hint-names" as="xs:string*"
      select="gml:nodes('hint')/string(@name)"/>
  <xsl:variable name="gml:state-hint-names" as="xs:string*"
      select="gml:nodes('hint')[@class = 'state']/string(@name)"/>
  <xsl:variable name="gml:conditional-hint-names" as="xs:string*"
      select="gml:nodes('hint')[@conditional = 'yes']/string(@name)"/>
  <xsl:variable name="gml:event-hint-names" as="xs:string*"
      select="gml:nodes('hint')[@class = 'event']/string(@name)"/>

  <xsl:variable name="gml:properties" as="xs:string*"
      select="$gml:shared/sh:properties/sh:property/string(@name)"/>
  <xsl:variable name="gml:block-properties" as="xs:string*"
      select="$gml:shared/sh:properties/sh:property[@tier = 'block']/string(@name)"/>
  <xsl:variable name="gml:inline-properties" as="xs:string*"
      select="$gml:shared/sh:properties/sh:property[@tier = 'inline']/string(@name)"/>
  <xsl:variable name="gml:initial-state" as="map(xs:string, xs:string)"
      select="map:merge($gml:shared/sh:properties/sh:property
                        ! map {string(@name): string(@initial)})"/>

  <!-- the space units by their normalised names (ch line cm mm i mh mv
       dh dv pt dd: the unit= of a hint) -->
  <xsl:variable name="gml:unit-names" as="xs:string*"
      select="$gml:shared/sh:units/sh:unit/string(@name)"/>
  <xsl:function name="gml:unit" as="element(sh:unit)?">
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="$gml:shared/sh:units/sh:unit[@name = $name]"/>
  </xsl:function>

  <!-- the size of one $name in $base units, computed from their inch
       fractions (inch=, or nominal-inch= of a device unit); () when
       either is relative (no size without a font) or unknown.
       gml:unit-size('dd', 'pt') = 1.0656, gml:unit-size('dh', 'pt') = 0.3 -->
  <xsl:function name="gml:unit-size" as="xs:decimal?">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="base" as="xs:string"/>
    <xsl:variable name="f" select="for $u in (gml:unit($name), gml:unit($base))
        return ($u/@inch, $u[@device = 'yes']/@nominal-inch)[1]"/>
    <xsl:if test="count($f) = 2">
      <xsl:variable name="a" select="tokenize($f[1], '/') ! xs:integer(.)"/>
      <xsl:variable name="b" select="tokenize($f[2], '/') ! xs:integer(.)"/>
      <xsl:sequence select="($a[1] * ($b[2], 1)[1]) div (($a[2], 1)[1] * $b[1])"/>
    </xsl:if>
  </xsl:function>

  <!-- ==== the document ================================================== -->
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
