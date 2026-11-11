# The line boxes of the shipped pages, from \tracingoutput: the first
# four letters, the shift (the left edge: the \parshape indention) and
# the width (the line length).  Lines with no letters are left out.
# A line is an \hbox of the page body (two dots); with -v all=1 also
# an \hbox in any \vbox deeper down (a figure's lines, a running
# footing's), its shift relative to that box.
function flush() { if (box && n > 0) printf "%-4s %9s %10s\n", w, sh, wd; box = 0 }
function depth(s) { match(s, /^\.*/); return RLENGTH }
# only the shipped pages: a box shown in a warning (an overfull page in
# \output) is not read
/^Completed box being shipped out/ { flush(); ship = 1; next }
/^$/ { flush(); ship = 0; next }
!ship { next }
{ d = depth($0) }
box && d > bd { if (d == bd + 1 && /\\[a-z@]+ .$/) { if (n < 4) w = w substr($0, length($0)); n++ }
  if (/\\[hv]box\(/) kind[d] = substr($0, d + 2, 1); next }
{ flush() }
/\\vbox\(/ { kind[d] = "v" }
/\\hbox\(/ { kind[d] = "h"
  if (d == 2 || (all && d > 2 && kind[d - 1] == "v")) { box = 1; bd = d; sh = "0"; w = ""; n = 0
    if (match($0, /shifted -?[0-9.]+/)) sh = substr($0, RSTART + 8, RLENGTH - 8)
    match($0, /\)x[0-9.]+/); wd = substr($0, RSTART + 2, RLENGTH - 2) } }
END { flush() }
