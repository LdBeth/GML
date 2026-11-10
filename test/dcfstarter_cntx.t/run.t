Under -profile dcfstarter a tag out of context is mapped to ss@cntx
with the attribute rules of DSMPROF3 (starterset.gml): :li and :title
scan their attributes, so ":li id=x." and ":title stitle='s'." are
dropped whole, attributes and all, and only their text stays; :dt
scans none.  The same as under -profile starter.

  $ gml -profile dcfstarter -o d.xml in.gml 2>&1 | sed 's/ (in macro[^)]*)//'
  in.gml:2: +++DSMGML002W :LI FOUND OUTSIDE LIST. (page 1)
  in.gml:3: +++DSMGML002W :TITLE FOUND OUTSIDE TITLEP. (page 1)
  in.gml:4: +++DSMGML002W :DT FOUND OUTSIDE DL. (page 1)
  $ sed 's/<[^>]*>//g' d.xml | grep .
  an item outside a list
  a title outside the title page
  a term outside a definition list

  $ gml -profile starter -o s.xml in.gml 2>&1 | sed 's/ (in macro[^)]*)//'
  in.gml:2: +++DSMGML002W :LI FOUND OUTSIDE LIST. (page 1)
  in.gml:3: +++DSMGML002W :TITLE FOUND OUTSIDE TITLEP. (page 1)
  in.gml:4: +++DSMGML002W :DT FOUND OUTSIDE DL. (page 1)
  $ sed 's/<[^>]*>//g' s.xml | grep .
  an item outside a list
  a title outside the title page
  a term outside a definition list
