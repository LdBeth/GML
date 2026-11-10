<?xml version="1.0" encoding="UTF-8"?>
<!-- tate/tex.xsl: tex.xsl plus the layout of ruby.

     :ruby.日:rt.に:ert.本:rt.ほん:ert.語:rt.ご:ert.:eruby. interleaves the
     bases and their readings, as HTML's <ruby> does: each rt is the
     reading of the text before it (back to the previous rt).  This
     stylesheet pairs them and works out where each reading goes (after
     pxrubrica's rules; tagset.tex only places the boxes):

       - a reading is centred on its base (mono ruby); a reading shorter
         than a base of two or more characters (group ruby, 明日/あす) is
         spread over the base, its spaces 1:2:1 at the ends and between
         the characters;
       - the bases keep their natural width: a reading longer than its
         base overhangs the characters around it (承/うけたまわ takes no
         space beyond 承), into the room that the readings of the other
         bases of the same ruby leave (熟語ルビ, 東京/とうきょう);
       - the readings of one ruby never overlap: when they would, they
         are moved apart as little as they can be (in the least-squares
         sense: the pool-adjacent-violators algorithm), so a group of
         long readings stays centred on the group.

     The widths are TeX's, measured by the last pass: tagset.tex writes
     the natural widths of each base and reading to the aux file (by
     the pair's number k, from the profile's :rt), and the next pass's
     profile puts them on the rt (bw= rw=, in sp).  On the first pass
     (or when a pair of the ruby has none) they are estimated from the
     characters: a full-width character is 1zw of the base, a reading's
     character half of that, ASCII half a full width.  tagset.tex
     centres each reading on the base as it measures it and adds the
     shift worked out here, so an estimate only moves the readings.

     The ruby is the element <ruby first=N>..<> (N the code point of the
     first character of the bases); each pair in it is a hint with the
     base and the reading as brace arguments:
       <,rb k=K,shift=S>{base}{reading}        a reading at its natural width
       <,rb k=K,shift=S,spread>{base}{r<,rs>e} one spread over the base
     k= the pair's number (left out when the rt has none); the shift (in
     sp, or zw when estimated) moves the reading from the centre of its
     base toward the end of the line; the characters of a spread reading
     are separated by <,rs>.  The readings are not part of the plain
     text of a heading (the running footing). -->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:t="urn:x-gml:tex"
    xmlns:r="urn:x-gml:tate"
    exclude-result-prefixes="#all">
  <xsl:import href="../../xslt/tex.xsl"/>

  <xsl:template match="ruby">
    <!-- the pairs: a base and the rt after it (the base's last text, with no
         rt, is a pair of its own, without a reading, unless it is blank) -->
    <xsl:variable name="groups" as="map(*)*">
      <xsl:for-each-group select="node()" group-ending-with="rt">
        <xsl:variable name="rte" select="current-group()[self::rt]"/>
        <xsl:variable name="base" select="current-group()[not(self::rt)]"/>
        <xsl:if test="exists($rte) or normalize-space(string-join($base ! string(.))) != ''">
          <xsl:sequence select="map {'base': $base, 'rte': $rte}"/>
        </xsl:if>
      </xsl:for-each-group>
    </xsl:variable>
    <!-- measured (sp) when every pair has its widths from the last pass -->
    <xsl:variable name="sp" select="every $g in $groups satisfies
        ($g?rte/@bw castable as xs:double and $g?rte/@rw castable as xs:double)"/>
    <xsl:variable name="pairs" as="map(*)*">
      <xsl:for-each select="$groups">
        <xsl:variable name="rte" select="?rte"/>
        <xsl:variable name="rt" select="normalize-space(string-join($rte))"/>
        <xsl:variable name="btext" select="normalize-space(string-join(?base ! string(.)))"/>
        <xsl:variable name="bw" select="if ($sp) then number($rte/@bw) else r:zw($btext)"/>
        <xsl:variable name="rw" select="if ($sp) then number($rte/@rw) else 0.5 * r:zw($rt)"/>
        <xsl:variable name="spread" select="string-length($btext) gt 1 and $rw gt 0 and $rw lt $bw"/>
        <xsl:sequence select="map {'base': ?base, 'rt': $rt, 'k': string($rte/@k), 'bw': $bw,
                                   'w': if ($spread) then $bw else $rw, 'spread': $spread}"/>
      </xsl:for-each>
    </xsl:variable>
    <!-- the reading's wanted start: the centre of its base less half its width -->
    <xsl:variable name="want" select="for $i in 1 to count($pairs) return
        sum($pairs[position() lt $i] ! ?bw) + ($pairs[$i]?bw - $pairs[$i]?w) div 2"/>
    <xsl:variable name="at" select="r:place($want, $pairs ! ?w)"/>
    <!-- a line scope that the engine began inside the ruby (.il of a
         paragraph that begins with one) begins before it, empty: inside,
         in a box, its \parshape would be lost; the parts inside are
         unwrapped (the template below) -->
    <xsl:for-each select=".//gml:lines[not(@cont = 'yes')]">
      <xsl:value-of select="t:open('gml:lines', t:attrs(@*, t:extra(.)), false()) || t:close(false())"/>
    </xsl:for-each>
    <!-- the first character of the bases, for the space before the ruby -->
    <xsl:variable name="first" select="string-to-codepoints(
        replace(string-join($pairs[1]?base ! string(.)), '^\s+', ''))[1]"/>
    <xsl:value-of select="t:open('ruby', if (exists($first)) then 'first=' || $first else '', false())"/>
    <xsl:for-each select="$pairs">
      <xsl:variable name="i" select="position()"/>
      <xsl:variable name="b" as="xs:string*">
        <xsl:apply-templates select="?base"/>
      </xsl:variable>
      <xsl:value-of select="t:hint('rb', string-join((
            ('k=' || t:name(?k))[current()?k != ''],
            'shift=' || (if ($sp) then format-number(round($at[$i] - $want[$i]), '0') || 'sp'
                         else format-number($at[$i] - $want[$i], '0.###') || 'zw'),
            'spread'[current()?spread]), ','), false())
          || '{' || string-join($b) || '}{'
          || string-join(for $c in string-to-codepoints(?rt) return t:esc(codepoints-to-string($c), false()),
                         if (?spread) then t:hint('rs', '', false()) else '') || '}'"/>
    </xsl:for-each>
    <xsl:value-of select="t:close(false())"/>
  </xsl:template>

  <!-- a line scope inside a ruby: its text only (its beginning is before
       the ruby, see above) -->
  <xsl:template match="gml:lines[ancestor::ruby]" priority="2">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- the width of a text in zw: full width 1, ASCII and half-width kana .5 -->
  <xsl:function name="r:zw" as="xs:double">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="sum((0, for $c in string-to-codepoints($s) return
        if ($c le 32) then 0
        else if ($c lt 127 or ($c ge 65377 and $c le 65439)) then 0.5 else 1))"/>
  </xsl:function>

  <!-- the starts of boxes of widths $w nearest (least squares) to the wanted
       starts $p, the boxes in order and not overlapping: a stack of blocks
       of boxes set side by side (i the first box, n the number, w the
       width, s the sum of the wanted starts of the block, each less the
       width of the boxes before it in the block: the block starts at s/n);
       a new box that would overlap the last block joins it, and so on down -->
  <xsl:function name="r:place" as="xs:double*">
    <xsl:param name="p" as="xs:double*"/>
    <xsl:param name="w" as="xs:double*"/>
    <xsl:iterate select="1 to count($p)">
      <xsl:param name="stack" as="map(*)*" select="()"/>
      <xsl:on-completion>
        <xsl:sequence select="for $b in $stack, $k in 1 to $b?n
            return $b?s div $b?n + sum((0, subsequence($w, $b?i, $k - 1)))"/>
      </xsl:on-completion>
      <xsl:variable name="i" select="."/>
      <xsl:next-iteration>
        <xsl:with-param name="stack"
            select="r:push($stack, map {'i': $i, 'n': 1, 's': $p[$i], 'w': $w[$i]})"/>
      </xsl:next-iteration>
    </xsl:iterate>
  </xsl:function>

  <xsl:function name="r:push" as="map(*)*">
    <xsl:param name="stack" as="map(*)*"/>
    <xsl:param name="b" as="map(*)"/>
    <xsl:variable name="top" select="$stack[last()]"/>
    <xsl:sequence select="
        if (exists($top) and $top?s div $top?n + $top?w gt $b?s div $b?n + 0.001)
        then r:push($stack[position() lt last()],
                    map {'i': $top?i, 'n': $top?n + $b?n, 'w': $top?w + $b?w,
                         's': $top?s + $b?s - $b?n * $top?w})
        else ($stack, $b)"/>
  </xsl:function>

  <!-- Japanese text as it is: the engine reads UTF-8 (upTeX), and the
       blocks below are kanji to it (\kcatcode 16 to 18), set in the
       Japanese font that the Latin font switches choose (tagset.tex):
       CJK radicals to the unified ideographs (with the symbols and
       punctuation, kana and the CJK compatibility block), the
       compatibility ideographs, the vertical forms, the full-width
       and half-width forms and the ideographs beyond the BMP.  Any
       other character is tex.xsl's &n; (gml.tex's renderings of the
       typographic punctuation shared with Latin text, — “ …). -->
  <xsl:function name="t:char" as="xs:string">
    <xsl:param name="c" as="xs:string"/>
    <xsl:variable name="n" select="string-to-codepoints($c)[1]"/>
    <xsl:sequence select="
        if (($n ge 11904 and $n le 40959) or ($n ge 63744 and $n le 64255)
            or ($n ge 65072 and $n le 65103) or ($n ge 65280 and $n le 65519)
            or $n ge 131072) then $c
        else if ($c = ' ') then '\ '
        else if ($n lt 32 or $n = 127) then ''
        else t:ref($n)"/>
  </xsl:function>

  <!-- the plain text of a heading, without the readings -->
  <xsl:function name="t:plain" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="normalize-space(string-join(($e//text() | $e//gml:dv/@text)[not(ancestor::gml:num)
        and not(ancestor::*[local-name() = $index-tags]) and not(ancestor::rt)]))"/>
  </xsl:function>
</xsl:stylesheet>
