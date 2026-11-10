<?xml version="1.0" encoding="UTF-8"?>
<!--
  memo/mail.xsl - the memo tag set -> a mail message: its description and
  its HTML, for emacs/gml-mail.el (a Wanderlust draft).  A stage of the
  bundle's own: gmlfmt -app memo -to mail doc.gml (input: scoped XML).

  Output, one stream:
    line 1   a JSON object (one line):
               {"headers":{...},"inline":[...],"attachments":[...]}
    then     the HTML document exactly as html.xsl (the bundle's) makes
             it, but the images referred to by content id (parameter
             images=cid): the body of the text/html part.

  The JSON object
    headers      the fields the memo gives, in this order:
                   From     :from email= (the name= with it)
                   To       the :to entries with email=
                   Cc       the :cc entries with email=
                   Bcc      the :bcc entries with email=
                   Subject  the text of :subject, blanks normalized
                 To, Cc, Bcc: the entries joined with ", "; each entry is
                 the address alone, or "Name <address>"; a name holding
                 one of the RFC 5322 specials ( ) < > [ ] : ; @ \ , . "
                 is a quoted string (\ and " escaped).  Non-ASCII text
                 stays as it is (UTF-8): the mail client encodes the
                 header.  An entry without email= is shown only (in the
                 HTML), never a field; an empty field is not written.
                 Always present, possibly {}.
    inline       the images the HTML refers to: {"cid": content id, no
                 angle brackets, "file": the file as written in the
                 source}; today the :logo only (cid gml-logo-1@gml.invalid,
                 see html.xsl).  Always present, possibly [].
    attachments  {"file": name=} of each :attach, in order.  Always
                 present, possibly [].
  The JSON line holds no <, > or & (written as the escapes
  backslash-u003c, -u003e, -u0026) and no control or non-breaking
  characters (also escaped), so the html output method leaves it
  alone; the DOCTYPE follows it on the next line.

  Parameters: those of html.xsl; images defaults to "cid" here.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:m="urn:x-gml:memo"
    exclude-result-prefixes="#all">

  <xsl:import href="html.xsl"/>

  <xsl:param name="images" as="xs:string" select="'cid'"/>

  <!-- the backslash (written as a code point, so that no escape of the
       stylesheet's own is in the way) -->
  <xsl:variable name="m:bs" select="codepoints-to-string(92)"/>

  <xsl:template match="/">
    <xsl:value-of select="m:json(gml:doc)"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:next-match/>
  </xsl:template>

  <!-- ==== JSON =========================================================== -->
  <xsl:function name="m:hex4" as="xs:string">
    <xsl:param name="c" as="xs:integer"/>
    <xsl:sequence select="string-join(for $i in (3, 2, 1, 0)
        return substring('0123456789abcdef', ($c idiv xs:integer(math:pow(16, $i))) mod 16 + 1, 1), '')"
        xmlns:math="http://www.w3.org/2005/xpath-functions/math"/>
  </xsl:function>

  <!-- a JSON string; < > & control characters and the no-break space as
       \u escapes (the html output method would write them as entities) -->
  <xsl:function name="m:str" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="'&quot;' || string-join(
        for $c in string-to-codepoints($s) return
          if ($c = 34) then $m:bs || '&quot;'
          else if ($c = 92) then $m:bs || $m:bs
          else if ($c = 10) then $m:bs || 'n'
          else if ($c = 13) then $m:bs || 'r'
          else if ($c = 9) then $m:bs || 't'
          else if ($c lt 32 or $c = (38, 60, 62, 8232, 8233) or ($c ge 127 and $c le 160))
          then $m:bs || 'u' || m:hex4($c)
          else codepoints-to-string($c), '') || '&quot;'"/>
  </xsl:function>

  <!-- "Name <address>", the name a quoted string when it has specials -->
  <xsl:function name="m:mailbox" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="name" select="normalize-space($e/@name)"/>
    <xsl:variable name="addr" select="normalize-space($e/@email)"/>
    <xsl:variable name="specials" select="('(', ')', '&lt;', '&gt;', '[', ']', ':', ';', '@', $m:bs, ',', '.', '&quot;')"/>
    <xsl:choose>
      <xsl:when test="$name = ''"><xsl:sequence select="$addr"/></xsl:when>
      <xsl:when test="some $c in $specials satisfies contains($name, $c)">
        <xsl:sequence select="'&quot;' || string-join(for $c in string-to-codepoints($name) return
            (if ($c = (34, 92)) then $m:bs else '') || codepoints-to-string($c), '')
            || '&quot; &lt;' || $addr || '&gt;'"/>
      </xsl:when>
      <xsl:otherwise><xsl:sequence select="$name || ' &lt;' || $addr || '&gt;'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="m:json" as="xs:string">
    <xsl:param name="doc" as="element()"/>
    <xsl:variable name="addressed" select="$doc//*[normalize-space(@email) != '']"/>
    <xsl:variable name="from" select="m:last($doc, 'from')[normalize-space(@email) != '']"/>
    <xsl:variable name="subject" select="m:plain(m:last($doc, 'subject'))"/>
    <xsl:variable name="headers" as="xs:string*">
      <xsl:if test="exists($from)">
        <xsl:sequence select="m:str('From') || ':' || m:str(m:mailbox($from))"/>
      </xsl:if>
      <xsl:for-each select="('to', 'cc', 'bcc')">
        <xsl:variable name="tag" select="."/>
        <xsl:variable name="list" select="$addressed[local-name() = $tag and namespace-uri() = '']"/>
        <xsl:if test="exists($list)">
          <xsl:sequence select="m:str(upper-case(substring($tag, 1, 1)) || substring($tag, 2)) || ':'
                                || m:str(string-join($list ! m:mailbox(.), ', '))"/>
        </xsl:if>
      </xsl:for-each>
      <xsl:if test="$subject != ''">
        <xsl:sequence select="m:str('Subject') || ':' || m:str($subject)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="inline" select="m:images($doc) ! ('{' || m:str('cid') || ':' || m:str(@cid)
                                                          || ',' || m:str('file') || ':' || m:str(@file) || '}')"/>
    <xsl:variable name="attachments" select="$doc//attach[normalize-space(@name) != '']
                                             ! ('{' || m:str('file') || ':' || m:str(@name) || '}')"/>
    <xsl:sequence select="'{' || m:str('headers') || ':{' || string-join($headers, ',') || '},'
                          || m:str('inline') || ':[' || string-join($inline, ',') || '],'
                          || m:str('attachments') || ':[' || string-join($attachments, ',') || ']}'"/>
  </xsl:function>

</xsl:stylesheet>
