.gs tag on
.* explicit mapping: tag APF and end-tag APF
.dm figure on
[figure APF]
.dm off
.dm figurex on
[end of figure]
.dm off
.aa fig figure figurex
:fig.Caption
::fig.after
.* class mapping with .gs prefix
.dm xnote /[class APF]
.gs prefix x
:note.Text
::note.
.gs prefix off
:note.Text again
.* direct mapping to a native control word; .aa with rules only
.aa ty (vat noelem)
:ty hello World.
.* rules on .aa override .gs rules: value attributes for ol
.dm ol /ol: n=&*0 1=&*1 2=&*2
.dm eol on
.dm off
.aa ol (vat)
:ol compact Break.
::ol.
.aa ol (vat noelem)
:ol compact.
::ol.
.* .aa with the tag name alone removes the association
.aa fig
:fig.no longer mapped
.* errors
.aa 1x foo
.aa p foo (bogus)
