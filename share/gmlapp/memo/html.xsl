<?xml version="1.0" encoding="UTF-8"?>
<!--
  memo/html.xsl - the memo tag set (profile.gml) -> the HTML body of a
  mail message.  gmlfmt -app memo -to html uses it in place of
  xslt/html.xsl (a browser preview of the message); mail.xsl imports it
  and writes the same HTML with the images as cid: references, after a
  line that describes the message.

  Input: scoped XML (resolve.xsl -> scope.xsl) of a memo: the empty
  elements logo to from cc bcc attach, the one-line memodate security
  subject ref, memotxt memtype=internal|external holding Starter Set
  elements, sign, and link href= inline in the text.  Every one of them
  is optional.

  Output: one HTML5 document made to be read in mail clients (Gmail,
  Apple Mail, Thunderbird, Outlook) and to survive being quoted in a
  reply:
    - every visual property is an inline style attribute; the class
      attributes stay (gml-NAME, as html.xsl writes them);
    - nothing external: no linked CSS (the css, css-inline, css-file
      parameters of html.xsl are not used), no web fonts, no script;
    - no CSS custom properties, position, grid, flex, pseudo-elements or
      lh units (what share/html/gml.css relies on): list labels, quotation
      marks, the rule above the footnotes are written as content;
    - in-page links (footnote callouts and back links, cross-references)
      are written as their text: mail clients drop the ids;
    - the one <style> element (in <head>) is progressive enhancement only:
      dark mode (prefers-color-scheme, class and element selectors with
      !important, made from the rule table below) and a small-screen
      query.  The message looks right without it.

  How: html.xsl's two passes with a third between them.  The main pass
  (html.xsl's templates plus the memo templates here) builds the page;
  mode m:style copies it, renames the elements mail clients do not
  know (section article header nav main aside figure figcaption ->
  div, q -> span with the marks) and gives each element its style:
    1. the rules of $m:rules for its element name and for each class it
       has, in that order (data: one m:rule per element or class);
    2. the style html.xsl wrote itself (scope state, cell alignment),
       its custom properties and lh units replaced by literal values;
    3. what depends on the context (m:context-css): list markers, the
       last block in a list item or cell, compact lists, dl termhi.
  A later declaration of a property replaces an earlier one.  Then
  html.xsl's output pass (mode h:out) writes the tree.

  Layout: body > div.gml-memo-page (the page background) > div.gml-memo
  (the card, $measure wide at most; for Outlook on Windows also an MSO
  conditional table of that width) holding
    div.gml-masthead   the logo (img.gml-logo, right), the security
                       classification (span.gml-security, a pill), the
                       subject (h1.gml-subject), the meta line (p.gml-memo-
                       meta: From, the sender's name, title, department,
                       phone, then the date of :memodate; no date
                       without it), for an external memo the sender's
                       address lines (p.gml-from-address), the reference
                       (p.gml-ref, labelled); not written when the memo
                       has none of these;
    div.gml-addresses  external memos only: the receiver blocks (name,
                       company, address lines of each :to);
    the text           the children of the document in their order:
                       div.gml-memotxt, text outside it, and the
                       signature (div.gml-sign: the name of :sign, else
                       :from name=, with title, department and phone
                       beneath) where :sign stands;
    div.gml-copies     the copy list: "cc:" and the names of the :cc
                       entries (never :bcc), a two-cell table;
    div.gml-footnotes  the footnotes, a short rule (hr) above them.
  Recipients are the mail headers' business (mail.xsl): an internal
  memo shows no address block; :attach is not shown.  Headings h1-h6 of
  the text are written one level down (h1 -> h2) and in smaller sizes,
  so that the subject stays the top heading.

  Lists: native markers when they say what html.xsl's labels say: an
  :ol whose labels are "1." "2." ..., "a." "b." ..., "A.", "i.", "I."
  (resolve.xsl's gml:num) gets list-style-type and the type/start
  attributes (value= on the items when they do not count up by one), a
  :ul whose bullet is one of • ● ◦ ○ ▪ ■ gets disc, circle or square;
  the footnote list is numbered the same way.  Other labels (other
  ul-identifiers, l-identifier, a numbering format with other
  punctuation) are written as html.xsl writes them, the label an inline
  block pulled into the list's padding by a negative margin.

  Parameters (besides html.xsl's lang, title, lit-note, lit-footnotes,
  table-width, l-identifier, pageref; its footnotes is not used: the
  footnotes are at the end)
    images        how the HTML refers to an image (the :logo): "file" (the
                  default: the file name as written, for a preview) or
                  "cid" (cid:NAME, the content id of an inline MIME part;
                  mail.xsl's default).  Content ids are
                  gml-KIND-N@gml.invalid: KIND the tag (logo), N its
                  number among the images of that kind (1).
    logo-height   the height of the logo in px (48).
    measure       the width of the card at most (640px).
    ul-identifiers  as in html.xsl; here "• ◦ ▪" (disc, circle, square:
                  native markers).
    lit-from      the label before the sender's name ("From"; "" = none).
    lit-to        the label above the receiver blocks ("To").
    lit-ref       the label of :ref ("Reference").
    lit-cc        the label of the copy list ("cc:").
    lit-phone     before the phone number ("Tel."; "" = none).
    lit-memo      the <title> of a memo without :subject ("Memo").
    lit-quotes    the quotation marks of :q: open and close of the outer
                  level, then of the inner one ("“ ” ‘ ’"; blank
                  separated).
  The theme (light; dark-NAME for the dark scheme):
    accent        links, the bar above the card, note labels (#2b5b84)
    text-color    the text (#1f2328)
    muted-color   secondary text: meta line, quotations, footnotes (#5c6670)
    rule-color    hairlines, table borders (#dde2e7)
    quote-color   the bar of a quotation, figure frames, separators (#c4ccd4)
    code-bg       examples, table headings (#f5f7f9)
    note-bg       the background of a :note (#eef4fa)
    page-bg       around the card (#eef1f4)
    card-bg       the card (#ffffff)
    alert-color   the security classification, unresolved references (#a4262c)
    font-text     the text (a serif stack: Charter, Sitka, Cambria, Georgia)
    font-sans     headings and the masthead (the system UI stack)
    font-mono     examples (ui-monospace, SF Mono, Menlo, Consolas)
  Sizes are px, for the stability of mail clients: the text 16px on
  26px lines.
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:gml="urn:x-gml:canonical"
    xmlns:h="urn:x-gml:html"
    xmlns:m="urn:x-gml:memo"
    exclude-result-prefixes="#all">

  <xsl:import href="../../../xslt/html.xsl"/>

  <!-- ==== parameters ================================================== -->
  <xsl:param name="images" as="xs:string" select="'file'"/>
  <xsl:param name="logo-height" as="xs:string" select="'48'"/>
  <xsl:param name="measure" as="xs:string" select="'640px'"/>
  <xsl:param name="ul-identifiers" as="xs:string" select="'• ◦ ▪'"/>
  <xsl:param name="lit-from" as="xs:string" select="'From'"/>
  <xsl:param name="lit-to" as="xs:string" select="'To'"/>
  <xsl:param name="lit-ref" as="xs:string" select="'Reference'"/>
  <xsl:param name="lit-cc" as="xs:string" select="'cc:'"/>
  <xsl:param name="lit-phone" as="xs:string" select="'Tel.'"/>
  <xsl:param name="lit-memo" as="xs:string" select="'Memo'"/>
  <xsl:param name="lit-quotes" as="xs:string" select="'“ ” ‘ ’'"/>

  <xsl:param name="accent" as="xs:string" select="'#2b5b84'"/>
  <xsl:param name="text-color" as="xs:string" select="'#1f2328'"/>
  <xsl:param name="muted-color" as="xs:string" select="'#5c6670'"/>
  <xsl:param name="rule-color" as="xs:string" select="'#dde2e7'"/>
  <xsl:param name="quote-color" as="xs:string" select="'#c4ccd4'"/>
  <xsl:param name="code-bg" as="xs:string" select="'#f5f7f9'"/>
  <xsl:param name="note-bg" as="xs:string" select="'#eef4fa'"/>
  <xsl:param name="page-bg" as="xs:string" select="'#eef1f4'"/>
  <xsl:param name="card-bg" as="xs:string" select="'#ffffff'"/>
  <xsl:param name="alert-color" as="xs:string" select="'#a4262c'"/>

  <xsl:param name="dark-accent" as="xs:string" select="'#8fbbe6'"/>
  <xsl:param name="dark-text-color" as="xs:string" select="'#e4e7eb'"/>
  <xsl:param name="dark-muted-color" as="xs:string" select="'#9ba5b0'"/>
  <xsl:param name="dark-rule-color" as="xs:string" select="'#30363d'"/>
  <xsl:param name="dark-quote-color" as="xs:string" select="'#46505b'"/>
  <xsl:param name="dark-code-bg" as="xs:string" select="'#1d2228'"/>
  <xsl:param name="dark-note-bg" as="xs:string" select="'#1a2532'"/>
  <xsl:param name="dark-page-bg" as="xs:string" select="'#0f1215'"/>
  <xsl:param name="dark-card-bg" as="xs:string" select="'#171b20'"/>
  <xsl:param name="dark-alert-color" as="xs:string" select="'#f0938c'"/>

  <xsl:param name="font-text" as="xs:string">Charter, 'Bitstream Charter', 'Sitka Text', Cambria, Georgia, serif</xsl:param>
  <xsl:param name="font-sans" as="xs:string">-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif</xsl:param>
  <xsl:param name="font-mono" as="xs:string">ui-monospace, 'SF Mono', Menlo, Consolas, 'Liberation Mono', monospace</xsl:param>

  <!-- the line height of the text, px (the lh unit of html.xsl's CSS) -->
  <xsl:variable name="m:line" as="xs:integer" select="26"/>
  <xsl:variable name="m:quotes" select="tokenize(normalize-space($lit-quotes), ' ')"/>
  <!-- the footnotes are always at the end (html.xsl's footnotes=chapter
       would write lists before the headings as well) -->
  <xsl:variable name="chapter-notes" as="xs:boolean" select="false()"/>

  <!-- ==== the vocabulary ============================================== -->
  <xsl:variable name="h:extra-known" as="xs:string*" select="'logo', 'to', 'from', 'cc', 'bcc',
      'attach', 'memodate', 'security', 'subject', 'ref', 'memotxt', 'sign', 'link'"/>
  <!-- html.xsl's elements written inline, and link (a copy: html.xsl has
       no hook for an importer's inline elements) -->
  <xsl:variable name="h:inline-tags" select="('q', 'cit', 'hp0', 'hp1', 'hp2', 'hp3', 'fn',
      'fnref', 'hdref', 'figref', 'liref', 'tref', 'i1', 'i2', 'i3', 'ih1', 'ih2', 'ih3', 'iref',
      'link')"/>

  <!-- the tags that collect, before the text: the last one counts, as
       the symbols IBM's profile sets -->
  <xsl:function name="m:last" as="element()?">
    <xsl:param name="doc" as="node()"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:sequence select="($doc//*[local-name() = $name and namespace-uri() = ''])[last()]"/>
  </xsl:function>

  <!-- the text of a one-line element: its text, a .dv its text= -->
  <xsl:function name="m:plain" as="xs:string">
    <xsl:param name="e" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join(
        $e/descendant::node()[self::text() or self::gml:dv]
          [not(ancestor::fn or ancestor::gml:fn or ancestor::gml:raw or ancestor::gml:rh or ancestor::gml:rf)]
          ! (if (self::gml:dv) then string(@text) else string(.)), ''))"/>
  </xsl:function>

  <!-- the images the HTML shows: m:image kind= n= file= cid= -->
  <xsl:function name="m:images" as="element(m:image)*">
    <xsl:param name="doc" as="node()"/>
    <xsl:for-each select="m:last($doc, 'logo')[normalize-space(@logoname) != '']">
      <m:image kind="logo" n="1" file="{@logoname}" cid="gml-logo-1@gml.invalid"/>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="m:src" as="xs:string">
    <xsl:param name="image" as="element(m:image)"/>
    <xsl:sequence select="if ($images = 'cid') then 'cid:' || $image/@cid else string($image/@file)"/>
  </xsl:function>

  <xsl:function name="m:memtype" as="xs:string">
    <xsl:param name="doc" as="node()"/>
    <xsl:sequence select="if (($doc//memotxt)[1]/@memtype = 'external') then 'external' else 'internal'"/>
  </xsl:function>

  <!-- ==== the passes ================================================== -->
  <xsl:template match="/">
    <xsl:for-each-group select="//*[h:unknown(.)]" group-by="name()">
      <xsl:message select="'html: unknown element ' || current-grouping-key()
                           || ': written as span.gml-unknown'"/>
    </xsl:for-each-group>
    <xsl:variable name="html">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:variable name="styled">
      <xsl:apply-templates select="$html" mode="m:style"/>
    </xsl:variable>
    <xsl:apply-templates select="$styled" mode="h:out"/>
  </xsl:template>

  <!-- ==== the page ===================================================== -->
  <xsl:template match="gml:doc">
    <xsl:variable name="subject" select="m:plain(m:last(., 'subject'))"/>
    <xsl:variable name="width" select="replace($measure, 'px$', '')"/>
    <html lang="{$lang}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="x-apple-disable-message-reformatting"/>
        <meta name="color-scheme" content="light dark"/>
        <meta name="supported-color-schemes" content="light dark"/>
        <meta name="generator" content="GML memo html.xsl"/>
        <title>
          <xsl:value-of select="if ($title != '') then $title else if ($subject != '') then $subject else $lit-memo"/>
        </title>
        <style><xsl:value-of select="m:head-css()"/></style>
        <xsl:text>&#10;</xsl:text>
      </head>
      <body class="gml gml-memo-body">
        <div class="gml-memo-page">
          <xsl:if test="$width castable as xs:integer">
            <xsl:comment>[if mso]&gt;&lt;table role="presentation" align="center" width="<xsl:value-of select="$width"/>" cellpadding="0" cellspacing="0" border="0"&gt;&lt;tr&gt;&lt;td&gt;&lt;![endif]</xsl:comment>
          </xsl:if>
          <div class="gml-memo gml-memtype-{m:memtype(.)}">
            <xsl:call-template name="m:masthead"/>
            <xsl:if test="m:memtype(.) = 'external'">
              <xsl:call-template name="m:addresses"/>
            </xsl:if>
            <xsl:apply-templates>
              <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:call-template name="m:copies"/>
            <xsl:sequence select="h:footnotes(//fn | //gml:fn[not(@kind = 'leader')])"/>
          </div>
          <xsl:if test="$width castable as xs:integer">
            <xsl:comment>[if mso]&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;&lt;![endif]</xsl:comment>
          </xsl:if>
        </div>
        <xsl:text>&#10;</xsl:text>
      </body>
      <xsl:text>&#10;</xsl:text>
    </html>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- the masthead: logo, classification, subject, meta line, reference -->
  <xsl:template name="m:masthead">
    <xsl:variable name="logo" select="m:images(.)[@kind = 'logo']"/>
    <xsl:variable name="security" select="m:last(., 'security')[m:plain(.) != '']"/>
    <xsl:variable name="subject" select="m:last(., 'subject')[m:plain(.) != '']"/>
    <xsl:variable name="from" select="m:last(., 'from')"/>
    <xsl:variable name="date" select="m:last(., 'memodate')[m:plain(.) != '']"/>
    <xsl:variable name="ref" select="m:last(., 'ref')[m:plain(.) != '']"/>
    <xsl:variable name="name" select="normalize-space($from/@name)"/>
    <xsl:variable name="meta" as="element()*">
      <xsl:if test="$name != ''">
        <span class="gml-from-name"><xsl:value-of select="$name"/></span>
      </xsl:if>
      <xsl:for-each select="$from/(@title, @dept)[normalize-space() != '']">
        <span class="gml-from-{local-name()}"><xsl:value-of select="normalize-space()"/></span>
      </xsl:for-each>
      <xsl:for-each select="$from/@phone[normalize-space() != '']">
        <span class="gml-from-phone">
          <xsl:value-of select="string-join(($lit-phone[. != ''], normalize-space()), ' ')"/>
        </span>
      </xsl:for-each>
      <xsl:for-each select="$date">
        <span class="gml-memodate">
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </span>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="from-address" select="$from/(@addr1, @addr2)[normalize-space() != '']"/>
    <xsl:if test="exists(($logo, $security, $subject, $meta, $ref))">
      <div class="gml-masthead">
        <xsl:for-each select="$logo">
          <img class="gml-logo" src="{m:src(.)}" alt="" height="{$logo-height}" align="right"/>
        </xsl:for-each>
        <xsl:for-each select="$security">
          <p class="gml-security-line">
            <span class="gml-security">
              <xsl:apply-templates>
                <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
              </xsl:apply-templates>
            </span>
          </p>
        </xsl:for-each>
        <xsl:for-each select="$subject">
          <h1 class="gml-subject">
            <xsl:apply-templates>
              <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
            </xsl:apply-templates>
          </h1>
        </xsl:for-each>
        <xsl:if test="exists($meta)">
          <p class="gml-memo-meta">
            <xsl:if test="$name != '' and $lit-from != ''">
              <span class="gml-memo-label"><xsl:value-of select="$lit-from"/></span>
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:for-each select="$meta">
              <xsl:if test="position() gt 1">
                <xsl:text> </xsl:text>
                <span class="gml-sep">·</span>
                <xsl:text> </xsl:text>
              </xsl:if>
              <xsl:sequence select="."/>
            </xsl:for-each>
          </p>
        </xsl:if>
        <xsl:if test="m:memtype(.) = 'external' and exists($from-address)">
          <p class="gml-from-address">
            <xsl:for-each select="$from-address">
              <xsl:if test="position() gt 1">
                <xsl:text> </xsl:text>
                <span class="gml-sep">·</span>
                <xsl:text> </xsl:text>
              </xsl:if>
              <xsl:value-of select="normalize-space()"/>
            </xsl:for-each>
          </p>
        </xsl:if>
        <xsl:for-each select="$ref">
          <p class="gml-ref">
            <xsl:if test="$lit-ref != ''">
              <span class="gml-ref-label"><xsl:value-of select="$lit-ref"/></span>
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:apply-templates>
              <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
            </xsl:apply-templates>
          </p>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- an external memo: the receiver blocks, letter style -->
  <xsl:template name="m:addresses">
    <xsl:variable name="to" select=".//to[(@name, @company, @addr1, @addr2)[normalize-space() != '']]"/>
    <xsl:if test="exists($to)">
      <div class="gml-addresses">
        <xsl:if test="$lit-to != ''">
          <p class="gml-to-label"><xsl:value-of select="$lit-to"/></p>
        </xsl:if>
        <xsl:for-each select="$to">
          <div class="gml-receiver">
            <xsl:for-each select="(@name, @company, @addr1, @addr2)[normalize-space() != '']">
              <div class="gml-receiver-{if (local-name() = 'name') then 'name' else 'line'}">
                <xsl:value-of select="normalize-space()"/>
              </div>
            </xsl:for-each>
          </div>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- the copy list: the names of the :cc entries (their address when
       they have no name) -->
  <xsl:template name="m:copies">
    <xsl:variable name="names" select=".//cc ! (normalize-space(@name)[. != ''], normalize-space(@email)[. != ''])[1]"/>
    <xsl:if test="exists($names)">
      <div class="gml-copies">
        <table class="gml-copies-table" role="presentation">
          <tr>
            <td class="gml-copies-label"><xsl:value-of select="$lit-cc"/></td>
            <td class="gml-copies-names">
              <xsl:for-each select="$names">
                <xsl:if test="position() gt 1"><br/></xsl:if>
                <xsl:value-of select="."/>
              </xsl:for-each>
            </td>
          </tr>
        </table>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- ==== the memo tags in the text ===================================== -->
  <!-- written by the masthead, the address blocks and the copy list, or
       not at all (bcc, attach: the message's business) -->
  <xsl:template match="logo | to | from | cc | bcc | attach | memodate | security | subject | ref"/>

  <xsl:template match="memotxt">
    <div class="gml-memotxt">
      <xsl:apply-templates>
        <xsl:with-param name="ctx" select="'flow'" tunnel="yes"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>

  <!-- the signature: the name, then the sender's title, department and
       phone beneath -->
  <xsl:template match="sign">
    <xsl:variable name="from" select="m:last(/, 'from')"/>
    <xsl:variable name="name" select="(m:plain(.)[. != ''], normalize-space($from/@name))[1]"/>
    <xsl:variable name="detail" select="$from/(@title, @dept)[normalize-space() != ''] ! normalize-space(),
        $from/@phone[normalize-space() != ''] ! string-join(($lit-phone[. != ''], normalize-space()), ' ')"/>
    <xsl:if test="$name != ''">
      <div class="gml-sign">
        <p class="gml-sign-name">
          <xsl:choose>
            <xsl:when test="m:plain(.) != ''">
              <xsl:apply-templates>
                <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$name"/></xsl:otherwise>
          </xsl:choose>
        </p>
        <xsl:if test="exists($detail)">
          <p class="gml-sign-detail">
            <xsl:for-each select="$detail">
              <xsl:if test="position() gt 1"><br/></xsl:if>
              <xsl:value-of select="."/>
            </xsl:for-each>
          </p>
        </xsl:if>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- :link href=: its text, or the address when it has none -->
  <xsl:template match="link">
    <xsl:element name="{if (normalize-space(@href) != '') then 'a' else 'span'}">
      <xsl:attribute name="class" select="'gml-link'"/>
      <xsl:if test="normalize-space(@href) != ''">
        <xsl:attribute name="href" select="normalize-space(@href)"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="normalize-space(.) = '' and empty(*)">
          <xsl:value-of select="normalize-space(@href)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates>
            <xsl:with-param name="ctx" select="'phrasing'" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <!-- ==== the style rules =============================================== -->
  <!-- match: element names and .classes; css: the declarations.  The
       declarations of the element come first, then those of its classes
       in their order; a later one replaces an earlier one. -->
  <xsl:variable name="m:text" select="'font-family: ' || $font-text || '; font-size: 16px; line-height: 26px'"/>
  <xsl:variable name="m:ui" select="'font-family: ' || $font-sans || '; font-size: 14px; line-height: 20px'"/>
  <xsl:variable name="m:small" select="'font-family: ' || $font-sans || '; font-size: 13px; line-height: 19px'"/>
  <xsl:variable name="m:caps" select="'font-family: ' || $font-sans
      || '; font-size: 11px; line-height: 16px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase'"/>
  <xsl:variable name="m:head" select="'font-family: ' || $font-sans || '; font-weight: 600; color: ' || $text-color"/>

  <xsl:variable name="m:rules" as="element(m:rule)*">
    <!-- the page and the card -->
    <m:rule match="body" css="margin: 0; padding: 0; background-color: {$page-bg}; -webkit-text-size-adjust: 100%"/>
    <m:rule match=".gml-memo-page" css="margin: 0; padding: 32px 12px; background-color: {$page-bg}"/>
    <m:rule match=".gml-memo" css="box-sizing: border-box; max-width: {$measure}; margin: 0 auto;
        padding: 36px 40px; background-color: {$card-bg}; border: 1px solid {$rule-color};
        border-top: 4px solid {$accent}; border-radius: 8px; color: {$text-color}; {$m:text};
        text-align: left; overflow-wrap: break-word; word-wrap: break-word"/>
    <!-- the masthead -->
    <m:rule match=".gml-masthead" css="margin: 0 0 28px; padding: 0 0 20px; border-bottom: 1px solid {$rule-color}"/>
    <m:rule match=".gml-logo" css="float: right; height: {$logo-height}px; width: auto; max-width: 160px;
        margin: 0 0 12px 20px; border: 0"/>
    <m:rule match=".gml-security-line" css="margin: 0 0 14px; {$m:caps}"/>
    <m:rule match=".gml-security" css="display: inline-block; padding: 3px 10px; border: 1px solid {$alert-color};
        border-radius: 999px; color: {$alert-color}"/>
    <m:rule match=".gml-subject" css="margin: 0; {$m:head}; font-size: 24px; line-height: 31px; letter-spacing: -0.01em"/>
    <m:rule match=".gml-memo-meta" css="margin: 10px 0 0; color: {$muted-color}; {$m:ui}"/>
    <m:rule match=".gml-from-name" css="color: {$text-color}; font-weight: 600; white-space: nowrap"/>
    <m:rule match=".gml-from-phone .gml-memodate" css="white-space: nowrap"/>
    <m:rule match=".gml-sep" css="color: {$quote-color}"/>
    <m:rule match=".gml-from-address" css="margin: 2px 0 0; color: {$muted-color}; {$m:ui}"/>
    <m:rule match=".gml-ref" css="margin: 12px 0 0; color: {$text-color}; {$m:ui}"/>
    <m:rule match=".gml-ref-label" css="{$m:caps}; color: {$muted-color}; padding-right: 4px"/>
    <!-- the receiver blocks of an external memo -->
    <m:rule match=".gml-addresses" css="margin: 0 0 24px"/>
    <m:rule match=".gml-to-label" css="margin: 0 0 8px; {$m:caps}; color: {$muted-color}"/>
    <m:rule match=".gml-receiver" css="display: inline-block; vertical-align: top; min-width: 200px;
        margin: 0 32px 12px 0; color: {$text-color}; {$m:ui}"/>
    <m:rule match=".gml-receiver-name" css="font-weight: 600"/>
    <!-- the text -->
    <m:rule match="p" css="margin: 0 0 16px; {$m:text}"/>
    <m:rule match="h1 h2 h3 h4 h5 h6" css="margin: 24px 0 8px; {$m:head}; font-size: 16px; line-height: 22px"/>
    <m:rule match=".gml-h0 .gml-h-0" css="margin: 32px 0 12px; font-size: 22px; line-height: 28px"/>
    <m:rule match=".gml-h1 .gml-h-1" css="margin: 28px 0 10px; font-size: 20px; line-height: 26px"/>
    <m:rule match=".gml-h2 .gml-h-2" css="margin: 24px 0 8px; font-size: 18px; line-height: 24px"/>
    <m:rule match=".gml-h3 .gml-h-3" css="margin: 20px 0 6px; font-size: 16px; line-height: 22px"/>
    <m:rule match=".gml-h4 .gml-h-4" css="margin: 16px 0 4px; font-size: 15px; line-height: 22px"/>
    <m:rule match=".gml-h5 .gml-h-5" css="margin: 16px 0 4px; font-size: 14px; line-height: 20px; font-style: italic"/>
    <m:rule match=".gml-h6 .gml-h-6" css="margin: 16px 0 4px; font-size: 14px; line-height: 20px; color: {$muted-color}"/>
    <m:rule match="a" css="color: {$accent}; text-decoration: underline"/>
    <m:rule match=".gml-link" css="word-break: break-word; overflow-wrap: anywhere"/>
    <m:rule match=".gml-hp0" css="font-style: normal; font-weight: normal"/>
    <m:rule match=".gml-note" css="margin: 0 0 16px; padding: 12px 16px; background-color: {$note-bg};
        border-left: 3px solid {$accent}; border-radius: 0 6px 6px 0"/>
    <m:rule match=".gml-note-label" css="color: {$accent}; font-family: {$font-sans}; font-size: 14px; font-weight: 700"/>
    <m:rule match="blockquote" css="margin: 0 0 16px; padding: 2px 0 2px 16px; border-left: 3px solid {$quote-color};
        color: {$muted-color}"/>
    <m:rule match="pre" css="margin: 0 0 16px; padding: 12px 14px; background-color: {$code-bg};
        border: 1px solid {$rule-color}; border-radius: 6px; color: {$text-color}; font-family: {$font-mono};
        font-size: 13px; line-height: 20px; white-space: pre-wrap; word-wrap: break-word;
        overflow-wrap: anywhere; text-align: left"/>
    <m:rule match="hr .gml-hr" css="height: 0; margin: 16px 0; border: 0; border-top: 1px solid {$rule-color}"/>
    <!-- lists -->
    <m:rule match="ul ol" css="margin: 0 0 16px; padding: 0 0 0 28px"/>
    <m:rule match="li" css="margin: 0 0 6px; {$m:text}"/>
    <m:rule match=".gml-label" css="display: inline-block; width: 22px; margin-left: -28px; text-align: right;
        white-space: nowrap"/>
    <m:rule match=".gml-lp" css="list-style-type: none; margin: 6px 0 6px -12px"/>
    <m:rule match="dl" css="margin: 0 0 16px; padding: 0"/>
    <m:rule match="dt" css="margin: 0; font-weight: 700; {$m:text}"/>
    <m:rule match="dd" css="margin: 0 0 10px 24px; padding: 0; {$m:text}"/>
    <m:rule match=".gml-dthd .gml-ddhd" css="{$m:caps}; color: {$muted-color}; margin-bottom: 6px"/>
    <!-- figures -->
    <m:rule match="figure .gml-fig" css="margin: 0 0 16px; padding: 12px 0"/>
    <m:rule match=".gml-frame-rule" css="border-top: 1px solid {$quote-color}; border-bottom: 1px solid {$quote-color}"/>
    <m:rule match=".gml-frame-box" css="padding: 12px 16px; border: 1px solid {$quote-color}"/>
    <m:rule match=".gml-frame-none" css="padding: 0"/>
    <m:rule match=".gml-frame-chars" css="overflow: hidden; white-space: nowrap; color: {$muted-color};
        font-family: {$font-mono}; font-size: 13px; line-height: 16px"/>
    <m:rule match=".gml-figbody" css="white-space: pre-wrap"/>
    <m:rule match="figcaption" css="margin: 10px 0 0; color: {$text-color}; {$m:ui}"/>
    <m:rule match=".gml-figcap .gml-tcap" css="font-weight: 600"/>
    <m:rule match=".gml-figdesc .gml-tdesc" css="display: block; margin-top: 2px; color: {$muted-color}"/>
    <!-- tables: a rule around every cell -->
    <m:rule match="table" css="width: 100%; margin: 0 0 16px; border-collapse: collapse; border-spacing: 0; {$m:ui}"/>
    <m:rule match="caption" css="caption-side: bottom; padding: 8px 0 0; text-align: left; {$m:ui}"/>
    <m:rule match="th" css="padding: 7px 10px; border: 1px solid {$rule-color}; background-color: {$code-bg};
        font-weight: 600; text-align: left; vertical-align: top; {$m:ui}"/>
    <m:rule match="td" css="padding: 7px 10px; border: 1px solid {$rule-color}; vertical-align: top; {$m:ui}"/>
    <m:rule match=".gml-tnote" css="color: {$muted-color}"/>
    <m:rule match=".gml-tnote-label" css="font-weight: 700"/>
    <m:rule match=".gml-cpart" css="margin-top: 6px; padding-top: 6px; border-top: 1px solid {$rule-color}"/>
    <m:rule match=".gml-shade-xlight" css="background-color: rgba(128, 128, 128, 0.07)"/>
    <m:rule match=".gml-shade-light" css="background-color: rgba(128, 128, 128, 0.13)"/>
    <m:rule match=".gml-shade-medium" css="background-color: rgba(128, 128, 128, 0.25)"/>
    <m:rule match=".gml-shade-dark" css="background-color: rgba(128, 128, 128, 0.4)"/>
    <m:rule match=".gml-shade-xdark" css="background-color: rgba(128, 128, 128, 0.55)"/>
    <!-- footnotes -->
    <m:rule match="sup" css="font-size: 11px; line-height: 0; vertical-align: super"/>
    <m:rule match=".gml-fn-callout .gml-fnref" css="padding-left: 1px; color: {$accent}; font-family: {$font-sans};
        font-weight: 600"/>
    <m:rule match=".gml-footnotes" css="margin: 32px 0 0; color: {$muted-color}; {$m:small}"/>
    <m:rule match=".gml-footnotes-rule" css="width: 96px; height: 0; margin: 0 0 12px; border: 0;
        border-top: 1px solid {$quote-color}; text-align: left"/>
    <m:rule match=".gml-footnotes-title" css="margin: 0 0 8px; {$m:small}; font-weight: 600"/>
    <m:rule match=".gml-footnote-list" css="margin: 0; padding: 0 0 0 22px"/>
    <m:rule match=".gml-footnote" css="margin: 0 0 6px; {$m:small}"/>
    <!-- the signature and the copy list -->
    <m:rule match=".gml-sign" css="margin: 28px 0 0"/>
    <m:rule match=".gml-sign-name" css="margin: 0; {$m:head}; font-size: 16px; line-height: 22px"/>
    <m:rule match=".gml-sign-detail" css="margin: 2px 0 0; color: {$muted-color}; {$m:ui}"/>
    <m:rule match=".gml-copies" css="margin: 24px 0 0; padding: 12px 0 0; border-top: 1px solid {$rule-color}"/>
    <m:rule match=".gml-copies-table" css="width: auto; margin: 0; {$m:small}"/>
    <m:rule match=".gml-copies-label" css="width: 36px; padding: 0 8px 0 0; border: 0; vertical-align: top;
        color: {$muted-color}; font-weight: 600; {$m:small}"/>
    <m:rule match=".gml-copies-names" css="padding: 0; border: 0; vertical-align: top; color: {$muted-color}; {$m:small}"/>
    <!-- .bf fonts of the Starter Set (gml.css) -->
    <m:rule match=".gml-font-hi0" css="font-style: normal; font-weight: normal"/>
    <m:rule match=".gml-font-hi1" css="font-style: italic"/>
    <m:rule match=".gml-font-hi2" css="font-weight: 700"/>
    <m:rule match=".gml-font-hi3 .gml-font-hd0 .gml-font-hd2 .gml-font-hd6" css="font-weight: 700; font-style: italic"/>
    <m:rule match=".gml-font-hd1 .gml-font-hd3 .gml-font-hd4 .gml-font-hd5" css="font-weight: 700"/>
    <m:rule match=".gml-font-xmpfont" css="font-family: {$font-mono}"/>
    <m:rule match=".gml-font-althi1" css="text-decoration: underline"/>
    <m:rule match=".gml-font-althi2" css="text-transform: uppercase"/>
    <m:rule match=".gml-font-althi3" css="text-decoration: underline; text-transform: uppercase"/>
    <!-- last: a reference that is not resolved, whatever it is -->
    <m:rule match=".gml-unresolved" css="color: {$alert-color}"/>
  </xsl:variable>

  <xsl:variable name="m:rule-map" as="map(xs:string, xs:string)" select="map:merge(
      for $r in $m:rules, $k in tokenize(normalize-space($r/@match), ' ')
      return map {$k: normalize-space($r/@css)},
      map {'duplicates': 'combine'}) ! map:merge(map:for-each(., function($k, $v) { map {$k: string-join($v, '; ')} }))"/>

  <!-- the theme colours: light -> dark (for the <style> element) -->
  <xsl:variable name="m:dark" as="map(xs:string, xs:string)" select="map:merge((
      map {$text-color: $dark-text-color}, map {$muted-color: $dark-muted-color},
      map {$accent: $dark-accent}, map {$rule-color: $dark-rule-color},
      map {$quote-color: $dark-quote-color}, map {$code-bg: $dark-code-bg},
      map {$note-bg: $dark-note-bg}, map {$page-bg: $dark-page-bg},
      map {$card-bg: $dark-card-bg}, map {$alert-color: $dark-alert-color}),
      map {'duplicates': 'use-first'})"/>

  <!-- ==== declarations ================================================== -->
  <xsl:function name="m:prop" as="xs:string">
    <xsl:param name="d" as="xs:string"/>
    <xsl:sequence select="lower-case(normalize-space(substring-before($d, ':')))"/>
  </xsl:function>
  <xsl:function name="m:value" as="xs:string">
    <xsl:param name="d" as="xs:string"/>
    <xsl:sequence select="normalize-space(substring-after($d, ':'))"/>
  </xsl:function>

  <!-- one declaration as mail clients take it: html.xsl's custom
       properties replaced by their value, lh units by px; () for what
       they do not support (custom properties, position) -->
  <xsl:function name="m:fix" as="xs:string?">
    <xsl:param name="d" as="xs:string"/>
    <xsl:variable name="p" select="m:prop($d)"/>
    <xsl:variable name="v" select="m:value($d)
        => replace('var\(--gml-measure\)', $measure)
        => replace('var\(--gml-leading\)', string(round($m:line div 16, 3)))
        => replace('var\(--gml-justify\)', 'left')"/>
    <xsl:variable name="v" as="xs:string">
      <xsl:value-of>
        <xsl:analyze-string select="$v" regex="([0-9]*\.?[0-9]+)lh">
          <xsl:matching-substring>
            <xsl:value-of select="round(number(regex-group(1)) * $m:line, 2) || 'px'"/>
          </xsl:matching-substring>
          <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:value-of>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$p = '' or starts-with($p, '--') or $p = 'position' or contains($v, 'var(')"/>
      <xsl:when test="$p = 'display' and $v = ('flex', 'grid')">display: block</xsl:when>
      <xsl:when test="$p = 'display' and $v = ('inline-flex', 'inline-grid')">display: inline-block</xsl:when>
      <xsl:otherwise><xsl:sequence select="$p || ': ' || $v"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- the declarations in force: of each property the last one -->
  <xsl:function name="m:merge" as="xs:string*">
    <xsl:param name="decls" as="xs:string*"/>
    <xsl:variable name="d" select="($decls ! tokenize(., ';') ! normalize-space())[. != ''] ! m:fix(.)"/>
    <xsl:sequence select="for $i in 1 to count($d)
        return $d[$i][not(m:prop(.) = subsequence($d, $i + 1) ! m:prop(.))]"/>
  </xsl:function>

  <!-- the style of an element of the page written as $name: the rules of
       its name (the one it had, unless it becomes a span: an in-page
       link is not styled as one) and classes, the style it has, then
       $extra -->
  <xsl:function name="m:css" as="xs:string*">
    <xsl:param name="e" as="element()"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="extra" as="xs:string*"/>
    <xsl:variable name="keys" select="if ($name = 'span') then 'span' else local-name($e),
                                      tokenize(normalize-space($e/@class), ' ') ! ('.' || .)"/>
    <xsl:sequence select="m:merge(($keys ! $m:rule-map(.), string($e/@style), $extra))"/>
  </xsl:function>

  <!-- ==== the <style> element: dark scheme and small screens ============ -->
  <!-- the dark scheme from the rule table: each colour declaration of a
       rule, its theme colour replaced, as a longhand (border-color ...:
       it must not add a border inline style takes away) -->
  <xsl:function name="m:head-css" as="xs:string">
    <xsl:variable name="dark" as="xs:string*">
      <xsl:for-each select="$m:rules">
        <xsl:variable name="decls" as="xs:string*">
          <xsl:for-each select="m:merge(@css)">
            <xsl:variable name="p" select="m:prop(.)"/>
            <xsl:variable name="c" select="tokenize(m:value(.), ' ')[map:contains($m:dark, .)][1]"/>
            <xsl:variable name="long" select="if ($p = ('color', 'background-color', 'background')) then
                (if ($p = 'color') then 'color' else 'background-color')
                else if (matches($p, '^border(-(top|right|bottom|left))?$')) then $p || '-color' else ()"/>
            <xsl:if test="exists($c) and exists($long)">
              <xsl:sequence select="$long || ': ' || $m:dark($c) || ' !important'"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:if test="exists($decls)">
          <xsl:sequence select="'  ' || string-join(tokenize(normalize-space(@match), ' '), ', ')
                                || ' { ' || string-join($decls, '; ') || '; }'"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="string-join((
        '',
        ':root { color-scheme: light dark; supported-color-schemes: light dark; }',
        '@media (prefers-color-scheme: dark) {',
        $dark,
        '}',
        '@media screen and (max-width: 600px) {',
        '  .gml-memo-page { padding: 0 !important; }',
        '  .gml-memo { padding: 24px 18px 22px !important; border-radius: 0 !important; border-left: 0 !important; border-right: 0 !important; }',
        '  .gml-subject { font-size: 21px !important; line-height: 27px !important; }',
        '  .gml-logo { height: 36px !important; margin-left: 12px !important; }',
        '  ul, ol { padding-left: 24px !important; }',
        '}',
        ''), '&#10;')"/>
  </xsl:function>

  <!-- ==== lists ========================================================= -->
  <!-- the label of a list item (html.xsl's span.gml-label, or the number
       of a footnote) -->
  <xsl:function name="m:label" as="element()?">
    <xsl:param name="li" as="element()"/>
    <xsl:sequence select="$li/span[tokenize(@class, ' ') = ('gml-label', 'gml-fn-num')][1]"/>
  </xsl:function>

  <xsl:variable name="m:bullets" as="map(xs:string, xs:string)"
      select="map {'•': 'disc', '●': 'disc', '◦': 'circle', '○': 'circle', '▪': 'square', '■': 'square'}"/>
  <xsl:variable name="m:ol-types" as="map(xs:string, xs:string)"
      select="map {'decimal': '1', 'lower-alpha': 'a', 'upper-alpha': 'A', 'lower-roman': 'i', 'upper-roman': 'I'}"/>

  <xsl:function name="m:roman" as="xs:integer?">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="u" select="upper-case($s)"/>
    <xsl:if test="matches($u, '^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$') and $u != ''">
      <xsl:variable name="v" select="for $c in string-to-codepoints($u)
          return (map {73: 1, 86: 5, 88: 10, 76: 50, 67: 100, 68: 500, 77: 1000})($c)"/>
      <xsl:sequence select="xs:integer(sum(for $i in 1 to count($v)
          return if ($i lt count($v) and $v[$i] lt $v[$i + 1]) then - $v[$i] else $v[$i]))"/>
    </xsl:if>
  </xsl:function>

  <!-- the value of label $s in a list of type $t, () if it is not one -->
  <xsl:function name="m:label-value" as="xs:integer?">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="t" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$t = 'decimal' and matches($s, '^[0-9]+$')"><xsl:sequence select="xs:integer($s)"/></xsl:when>
      <xsl:when test="$t = 'lower-alpha' and matches($s, '^[a-z]$')">
        <xsl:sequence select="string-to-codepoints($s) - 96"/>
      </xsl:when>
      <xsl:when test="$t = 'upper-alpha' and matches($s, '^[A-Z]$')">
        <xsl:sequence select="string-to-codepoints($s) - 64"/>
      </xsl:when>
      <xsl:when test="$t = 'lower-roman' and matches($s, '^[ivxlcdm]+$')"><xsl:sequence select="m:roman($s)"/></xsl:when>
      <xsl:when test="$t = 'upper-roman' and matches($s, '^[IVXLCDM]+$')"><xsl:sequence select="m:roman($s)"/></xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- How a list of the page shows its labels: map type (a CSS
       list-style-type; "" = the labels as written), values (of the
       labelled items of an ol), counts (do the items count up by one?).
       An ol label must end in "." (the native marker's punctuation), a
       footnote number need not. -->
  <xsl:function name="m:list" as="map(*)">
    <xsl:param name="list" as="element()"/>
    <xsl:variable name="items" select="$list/li"/>
    <xsl:variable name="labels" select="$items ! m:label(.)"/>
    <xsl:variable name="notes" select="tokenize($list/@class, ' ') = 'gml-footnote-list'"/>
    <xsl:variable name="text" select="$labels ! normalize-space(.)"/>
    <xsl:choose>
      <xsl:when test="empty($labels)">
        <xsl:sequence select="map {'type': 'none', 'values': (), 'counts': true()}"/>
      </xsl:when>
      <xsl:when test="$list/self::ul">
        <xsl:sequence select="map {'type': if (count(distinct-values($text)) = 1 and map:contains($m:bullets, $text[1]))
                                            then $m:bullets($text[1]) else '',
                                   'values': (), 'counts': true()}"/>
      </xsl:when>
      <xsl:when test="$list/self::ol and ($notes or (every $t in $text satisfies ends-with($t, '.')))">
        <xsl:variable name="core" select="$text ! replace(., '\.$', '')"/>
        <xsl:variable name="type" select="
            if (matches($core[1], '^[0-9]+$')) then 'decimal'
            else if ($core[1] = 'i' and (every $c in $core satisfies exists(m:label-value($c, 'lower-roman')))) then 'lower-roman'
            else if ($core[1] = 'I' and (every $c in $core satisfies exists(m:label-value($c, 'upper-roman')))) then 'upper-roman'
            else if (matches($core[1], '^[a-z]$')) then 'lower-alpha'
            else if (matches($core[1], '^[A-Z]$')) then 'upper-alpha' else ''"/>
        <xsl:variable name="values" select="$core ! m:label-value(., $type)"/>
        <xsl:choose>
          <xsl:when test="$type != '' and count($values) = count($core)">
            <xsl:sequence select="map {'type': $type, 'values': $values,
                'counts': count($labels) = count($items)
                          and (every $i in 1 to count($values) satisfies $values[$i] = $values[1] + $i - 1)}"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="map {'type': '', 'values': (), 'counts': true()}"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="map {'type': '', 'values': (), 'counts': true()}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="m:native" as="xs:boolean">
    <xsl:param name="list" as="element()?"/>
    <xsl:sequence select="exists($list) and m:list($list)?type != ''"/>
  </xsl:function>

  <!-- ==== what depends on the context =================================== -->
  <xsl:function name="m:context-css" as="xs:string*">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="name" select="local-name($e)"/>
    <xsl:variable name="parent" select="$e/parent::*"/>
    <xsl:variable name="pclass" select="tokenize($parent/@class, ' ')"/>
    <!-- a list: its markers -->
    <xsl:if test="$name = ('ul', 'ol')">
      <xsl:variable name="t" select="m:list($e)?type"/>
      <xsl:sequence select="'list-style-type: ' || (if ($t = '') then 'none' else $t)"/>
    </xsl:if>
    <!-- an item of a list with native markers: none when it has no label -->
    <xsl:if test="$name = 'li' and m:native($parent) and empty(m:label($e))">list-style-type: none</xsl:if>
    <!-- a list in a list item or definition -->
    <xsl:if test="$name = ('ul', 'ol', 'dl') and $parent[self::li or self::dd]">margin-top: 6px</xsl:if>
    <!-- compact lists -->
    <xsl:if test="$name = ('li', 'dd') and $pclass = 'gml-compact'">margin-bottom: 0</xsl:if>
    <!-- the last block of an item, a definition, a cell, a quotation, the
         text, the card (whose padding is the space after it) -->
    <xsl:if test="$name = ('p', 'pre', 'ul', 'ol', 'dl', 'blockquote', 'table', 'div')
                  and ($parent[self::li or self::dd or self::td or self::th or self::blockquote]
                       or $pclass = 'gml-memo'
                       or ($pclass = 'gml-memotxt' and empty($parent/following-sibling::*
                           [not(tokenize(@class, ' ') = ('gml-sign', 'gml-copies', 'gml-footnotes'))])))
                  and empty($e/following-sibling::*)
                  and normalize-space(string-join($e/following-sibling::text(), '')) = ''">margin-bottom: 0</xsl:if>
    <!-- dl termhi=: the font of the terms -->
    <!-- text after the signature (a postscript) -->
    <xsl:if test="$e/preceding-sibling::*[1][tokenize(@class, ' ') = 'gml-sign']">margin-top: 20px</xsl:if>
    <xsl:if test="$name = 'dt' and not(tokenize($e/@class, ' ') = 'gml-dthd')">
      <xsl:variable name="hi" select="($pclass[starts-with(., 'gml-termhi-')] ! substring-after(., 'gml-termhi-'))[1]"/>
      <xsl:choose>
        <xsl:when test="$hi = '0'">font-weight: normal; font-style: normal</xsl:when>
        <xsl:when test="$hi = '1'">font-weight: normal; font-style: italic</xsl:when>
        <xsl:when test="$hi = '2'">font-weight: 700; font-style: normal</xsl:when>
        <xsl:when test="$hi = '3'">font-weight: 700; font-style: italic</xsl:when>
      </xsl:choose>
    </xsl:if>
    <!-- the first part of a repeated cell has no rule above -->
    <xsl:if test="tokenize($e/@class, ' ') = 'gml-cpart'
                  and empty($e/preceding-sibling::*[tokenize(@class, ' ') = 'gml-cpart'])">margin-top: 0; padding-top: 0; border-top: 0</xsl:if>
  </xsl:function>

  <!-- attributes for old clients: an ol's type and start, an item's
       value when the items do not count up by one -->
  <xsl:function name="m:list-attrs" as="attribute()*">
    <xsl:param name="e" as="element()"/>
    <xsl:if test="$e/self::ol and m:native($e)">
      <xsl:variable name="l" select="m:list($e)"/>
      <xsl:attribute name="type" select="$m:ol-types($l?type)"/>
      <xsl:if test="$l?counts and $l?values[1] != 1">
        <xsl:attribute name="start" select="$l?values[1]"/>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$e/self::li and $e/parent::ol and m:native($e/parent::ol) and exists(m:label($e))">
      <xsl:variable name="l" select="m:list($e/parent::ol)"/>
      <xsl:if test="not($l?counts)">
        <xsl:attribute name="value"
            select="$l?values[count($e/preceding-sibling::li[exists(m:label(.))]) + 1]"/>
      </xsl:if>
    </xsl:if>
  </xsl:function>

  <!-- ==== mode m:style: the page as mail clients take it ================== -->
  <xsl:mode name="m:style" on-no-match="shallow-copy"/>

  <xsl:variable name="m:div-names" select="('section', 'article', 'header', 'nav', 'main', 'aside',
      'figure', 'figcaption')"/>

  <xsl:function name="m:name" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="n" select="local-name($e)"/>
    <xsl:sequence select="if ($n = $m:div-names) then 'div'
        else if (matches($n, '^h[1-6]$') and not(tokenize($e/@class, ' ') = 'gml-subject'))
        then 'h' || min((6, xs:integer(substring($n, 2)) + 1))
        else $n"/>
  </xsl:function>

  <!-- an element of the page: renamed, styled; ids dropped (mail
       clients drop them, and nothing links to them here) -->
  <xsl:template mode="m:style" match="*[namespace-uri() = '']" priority="-0.5" name="m:copy">
    <xsl:param name="name" as="xs:string" select="m:name(.)"/>
    <xsl:param name="extra" as="xs:string*" select="()"/>
    <xsl:param name="before" as="item()*" select="()"/>
    <xsl:param name="after" as="item()*" select="()"/>
    <xsl:element name="{$name}">
      <xsl:apply-templates select="@* except (@style, @id)" mode="m:style"/>
      <xsl:sequence select="m:list-attrs(.)"/>
      <xsl:variable name="css" select="m:css(., $name, (m:context-css(.), $extra))"/>
      <xsl:if test="exists($css)">
        <xsl:attribute name="style" select="string-join($css, '; ')"/>
      </xsl:if>
      <xsl:sequence select="$before"/>
      <xsl:apply-templates mode="m:style"/>
      <xsl:sequence select="$after"/>
    </xsl:element>
  </xsl:template>

  <!-- in-page links: their text (in a span when it has a class) -->
  <xsl:template mode="m:style" match="a[starts-with(@href, '#')]">
    <xsl:choose>
      <xsl:when test="normalize-space(@class) != ''">
        <xsl:call-template name="m:copy">
          <xsl:with-param name="name" select="'span'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:apply-templates mode="m:style"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template mode="m:style" match="a[starts-with(@href, '#')]/@href | a[starts-with(@href, '#')]/@role"/>

  <!-- q: the quotation marks of its level as text (browsers would add
       their own to a q) -->
  <xsl:template mode="m:style" match="q">
    <xsl:variable name="outer" select="count(ancestor-or-self::q) mod 2 = 1"/>
    <xsl:call-template name="m:copy">
      <xsl:with-param name="name" select="'span'"/>
      <xsl:with-param name="before" select="if ($outer) then $m:quotes[1] else $m:quotes[3]"/>
      <xsl:with-param name="after" select="if ($outer) then $m:quotes[2] else $m:quotes[4]"/>
    </xsl:call-template>
  </xsl:template>

  <!-- a label a native marker shows instead, and the blank after it -->
  <xsl:template mode="m:style" match="li/span[tokenize(@class, ' ') = ('gml-label', 'gml-fn-num')]
                                      [m:native(../..)][. is m:label(..)]"/>
  <xsl:template mode="m:style" match="li/text()[preceding-sibling::node()[1]
      [self::span[tokenize(@class, ' ') = ('gml-label', 'gml-fn-num')]][m:native(../..)]]">
    <xsl:value-of select="replace(., '^\s+', '')"/>
  </xsl:template>

  <!-- a :gl term ends in a colon (gml.css: dt::after) -->
  <xsl:template mode="m:style" match="dl[tokenize(@class, ' ') = 'gml-gl']/dt">
    <xsl:call-template name="m:copy">
      <xsl:with-param name="after" select="':'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- the footnotes: a short rule above them, as an element -->
  <xsl:template mode="m:style" match="section[tokenize(@class, ' ') = 'gml-footnotes']">
    <xsl:variable name="rule" as="element()"><hr class="gml-footnotes-rule"/></xsl:variable>
    <xsl:call-template name="m:copy">
      <xsl:with-param name="before" as="element()">
        <xsl:apply-templates select="$rule" mode="m:style"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- column widths: only percentages (calc() and ch are not for mail) -->
  <xsl:template mode="m:style" match="colgroup[col[not(matches(@style, '^\s*width:\s*[0-9.]+%\s*$'))]]"/>

  <!-- .in/.ir FOR and .il/.un floats (html.xsl's markers for its output
       pass): their heights without lh; a .il/.un float written here as
       an .in float, with its height (html.xsl writes 1lh) -->
  <xsl:template mode="m:style" match="h:float">
    <h:float class="{@class}" style="{string-join(m:merge(@style), '; ')}"/>
  </xsl:template>
  <xsl:template mode="m:style" match="h:il[h:il-use(.) = 'float']">
    <h:float class="{@class}" style="float: left; width: {@shift}; height: {$m:line}px"/>
  </xsl:template>

</xsl:stylesheet>
