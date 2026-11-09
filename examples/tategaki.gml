.* tategaki.gml -- a Japanese document set vertically: the tate tag set
.* (tate/: dcfstarter with Japanese literals, :ruby, and tagset.tex for
.* ApTeX).  cd examples && mk out/tategaki.pdf
:gdoc.
:frontm.
:titlep.
:title.縦書きの文書
:title.GMLとApTeXによる組版
:date.
:author.GML処理系
:etitlep.
:toc.
:body.
:h1 id=hajime.はじめに
:p.この文書は、GMLで書かれた日本語の原稿を縦書きで組んだ見本です。
原稿の行末は語の区切りにはならず、日本語の文字が改行をまたいでも
空白は入りません。
欧文のGML (Generalized Markup Language) や数字の1986のような語は、
縦組みの行の中で横に倒して組まれます。
:p.:ruby.振:rt.ふ:eruby.り:ruby.仮名:rt.がな:eruby.、
つまり:ruby.ruby:rt.ルビ:eruby.は
:hp2.&gml.ruby.:ehp2.タグの中に親文字と:hp2.&gml.rt.:ehp2.タグの読みを交互に書いて付けます。
:ruby.漢:rt.かん:ert.字:rt.じ:eruby.の右側に小さな仮名で:ruby.読:rt.よ:eruby.みが置かれ、
:ruby.日:rt.に:ert.本:rt.ほん:ert.語:rt.ご:eruby.のように読みは一
字ずつに付きます。
:ruby.明日:rt.あす:eruby.のように読みが親文字より短いときは、
読みを親文字の幅に割り付けます。
:ruby.承:rt.うけたまわ:eruby.るのように読みが親文字より長いときは、
読みが前後の文字に掛かり、
親文字の前後は空きません。
:ruby.東:rt.とう:ert.京:rt.きょう:eruby.では二つの読みが重ならずに並び、
熟語の前後に同じだけ掛かります。
:h1 id=shikumi.仕組み
:p.処理は三つの段階に分かれます:fn.横書きの文書と同じ段階です。HTMLは意味的な
プロファイルstarterから作ります。:efn.。
:ol.
:li.SCRIPTのプロファイルdcfstarterが、タグを制御語に置き換えます。
:li.XSLTが文書の構造を整え、TeXの入力を書きます。
:li.ApTeXが縦書きのページを組みます。
:eol.
:p.見出しや:q.注:eq.の言葉は、タグセットのプロファイルが日本語に置き換えています。
:note.ページ番号を問う参照は、数回の処理を経て決まります。
:h2 id=moji.文字と組版
:p.句読点、括弧、長音記号「ー」は縦書き用の字形になります。
禁則処理により、行頭に句点や閉じ括弧は来ません。
:p.参照の例：ルビについては:hdref refid=hajime.を見てください。
:egdoc.
