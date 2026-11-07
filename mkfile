# mkfile - the GML pipeline (Plan 9 mk, recipes in rc).
#
#   mk doc.xml        canonical XML        gml -profile $PROFILE
#   mk doc.r.xml      resolved XML         xslt/resolve.xsl
#   mk doc.s.xml      scoped XML           xslt/scope.xsl      (from doc.r.xml)
#   mk doc.sem.xml    semantic XML         xslt/strip-hints.xsl (from doc.r.xml)
#   mk doc.html       HTML                 xslt/html.xsl       (from doc.s.xml)
#   mk doc.tex        plain TeX            xslt/tex.xsl        (from doc.r.xml)
#   mk doc.dvi        tex with share/tex on TEXINPUTS
#   mk test           test-ocaml, test-xslt and test-parity
#   mk test-ocaml     the engine's cram tests (dune test)
#   mk test-xslt      the XSLT fixture tests (xslt/test/run)
#   mk test-parity    gml -tex = tex.xsl on the XML (test/tex-parity.sh)
#
# Run mk in the project root (ROOT is the current directory).  Variables
# can be overridden on the command line: mk GML=gml SAXON=transform doc.html
#
# -set symbols: SETS is a list of name=value words, passed to gml as
# -set name=value and to every stylesheet as the parameter name=value
# (e.g. SYSVARH=yes numbers the headings in resolve.xsl).  Give it in the
# environment or quoted on the command line:
#   SETS='SYSVARH=yes SYSVARP=draft' mk doc.html
#   mk "SETS='SYSVARH=yes' 'SYSVARP=draft'" doc.html
# XSLTFLAGS adds parameters for the stylesheets only; a value with = must
# be quoted for mk:  mk "XSLTFLAGS='h1-prefix=Chapter'" doc.html
# List-valued parameters take commas: ol-identifiers=I.,A.,1.,a.
#
# TAGSET is a tag-set bundle directory, as for gmlfmt -tagset: its
# profile.gml is the profile (instead of PROFILE) and the last -I, its
# resolve.xsl scope.xsl strip-hints.xsl html.xsl tex.xsl replace the
# stock stages that it has, and its tagset.tex is given to tex.xsl
# (tex-tagset).  mk TAGSET=examples/notes doc.html
# OUTDIR (empty, or a directory ending in /) puts doc.xml, and so every
# later stage, in that directory: OUTDIR/doc.xml is made from doc.gml.
#
# Another mkfile can use these rules: set ROOT (and TAGSET, OUTDIR), then
# include this file (examples/mkfile does).

MKSHELL=/usr/local/plan9/bin/rc
ROOT=`{if(~ $#ROOT 0) pwd; if not echo $ROOT}
XSLT=$ROOT/xslt
SAXON=/usr/local/bin/transform
PROFILE=starter
# -share: the profiles of the source tree (dune exec does not refresh
# the copy of share/ in _build)
DUNE=opam exec --switch gml -- dune
GML=$DUNE exec --root $ROOT --display quiet -- gml -share $ROOT/share
TEX=tex

# the tag set: profile, imbed directory and stage stylesheets
GMLPROFILE=`{if(~ $"TAGSET '') echo $PROFILE; if not echo $TAGSET/profile.gml}
GMLFLAGS=`{if(! ~ $"TAGSET '') echo -I $TAGSET}
RESOLVEXSL=`{if(! ~ $"TAGSET '' && test -f $TAGSET/resolve.xsl) echo $TAGSET/resolve.xsl; if not echo $XSLT/resolve.xsl}
SCOPEXSL=`{if(! ~ $"TAGSET '' && test -f $TAGSET/scope.xsl) echo $TAGSET/scope.xsl; if not echo $XSLT/scope.xsl}
STRIPXSL=`{if(! ~ $"TAGSET '' && test -f $TAGSET/strip-hints.xsl) echo $TAGSET/strip-hints.xsl; if not echo $XSLT/strip-hints.xsl}
HTMLXSL=`{if(! ~ $"TAGSET '' && test -f $TAGSET/html.xsl) echo $TAGSET/html.xsl; if not echo $XSLT/html.xsl}
TEXXSL=`{if(! ~ $"TAGSET '' && test -f $TAGSET/tex.xsl) echo $TAGSET/tex.xsl; if not echo $XSLT/tex.xsl}
# (a path only: mk would read a value of the form x=y as an attribute)
TEXTAGSET=`{if(! ~ $"TAGSET '' && test -f $TAGSET/tagset.tex) echo $TAGSET/tagset.tex}

# (mk takes a metarule with an existing prerequisite as applicable, so
# the profile is not one here: a mkfile that includes this one can add
# "doc.xml: $TAGSET/profile.gml")
$OUTDIR%.xml: %.gml
	sets=`{echo $SETS}
	setargs=()
	for(s in $sets) setargs=($setargs -set $s)
	# gml returns 4 after warnings (DCF return codes): still a result
	st=()
	$GML -profile $GMLPROFILE $GMLFLAGS $setargs $stem.gml > $target.tmp || st=$status
	if(! ~ $st '' 4) { rm -f $target.tmp; exit $st }
	mv $target.tmp $target

# a tag set's stylesheet imports the stock one: both are prerequisites
%.r.xml: %.xml $XSLT/resolve.xsl $RESOLVEXSL
	$SAXON -s:$stem.xml -xsl:$RESOLVEXSL -o:$target `{echo $SETS} $XSLTFLAGS

%.s.xml: %.r.xml $XSLT/scope.xsl $SCOPEXSL
	$SAXON -s:$stem.r.xml -xsl:$SCOPEXSL -o:$target `{echo $SETS} $XSLTFLAGS

%.sem.xml: %.r.xml $XSLT/strip-hints.xsl $STRIPXSL
	$SAXON -s:$stem.r.xml -xsl:$STRIPXSL -o:$target `{echo $SETS} $XSLTFLAGS

%.html: %.s.xml $XSLT/html.xsl $HTMLXSL
	$SAXON -s:$stem.s.xml -xsl:$HTMLXSL -o:$target `{echo $SETS} $XSLTFLAGS

%.tex: %.r.xml $XSLT/tex.xsl $TEXXSL
	tagparam=()
	if(! ~ $"TEXTAGSET '') tagparam=tex-tagset^'='^$TEXTAGSET
	$SAXON -s:$stem.r.xml -xsl:$TEXXSL -o:$target `{echo $SETS} $tagparam $XSLTFLAGS

%.dvi: %.tex
	dir=`{/usr/local/plan9/bin/basename -d $stem}
	cd $dir && TEXINPUTS=$ROOT/share/tex: $TEX -interaction nonstopmode `{/usr/local/plan9/bin/basename $stem}.tex

test:V: test-ocaml test-xslt test-parity

test-ocaml:V:
	$DUNE test --root $ROOT

test-xslt:V:
	SAXON=$SAXON $XSLT/test/run

# (after test-ocaml: it uses the dune build of gml)
test-parity:V: test-ocaml
	SAXON=$SAXON $ROOT/test/tex-parity.sh
