(* TeX serializer for hint mode: the OCaml port of the part of
   xslt/tex.xsl that a formatting profile's document needs, writing the
   same macro calls for share/tex/gml.tex.

   It serializes the engine's finished tree directly (no resolve.xsl
   stage), so generated nodes (TOC entries, gml:num, page references,
   anchors) come only from what the tree holds.  The output is hint mode
   always: [\def\gmlmode{hints}], the profile's control words do the
   layout.  It is byte-identical to tex.xsl (tex-mode=hints) applied to
   the XML of the same tree (test/tex-parity.sh checks it).

   The rules are those of the tex.xsl header: escaping (t:esc, t:char,
   t:attr, t:name), \gmlstart/\gmlend for elements (text= on h0-h6,
   gml:h and title; desc=yes on a figcap or tcap followed by a figdesc
   or tdesc), \gmlhint for hints ("%" + line end after a breaking one),
   the parsed keys of gml:df/gml:dh/gml:dr, \gmlbeginlines ...
   \gmlendlines{} with more=yes, format-off and xml:space="preserve"
   text, tab lines, the .us/.up/.uc word wrapping and the upper-case
   font state (the accumulators), whitespace-only text next to blocks
   dropped.  Added here and in tex.xsl: a running heading or footing
   holding the page number (gml:pageno, or a .sx with pagesym=) is
   \gmlstart{NAME}{attrs}\gmlrundyn{body}\gmlend{NAME} (NAME gml:rh or
   gml:rf), the body typeset again at every page.

   The serializer is a recursive walk of the tree in document order:
   each node sees its siblings (for the whitespace, label and desc=
   rules), and the accumulators of tex.xsl are updated at every node,
   also in the content whose output is skipped (index tags, gml:pageref). *)

(* ==== escaping (t:esc, t:char, t:attr, t:name) ============================ *)

(* ==== escaping (t:esc, t:char, t:attr, t:name) ============================ *)

let is_ws_char = function ' ' | '\t' | '\n' | '\r' -> true | _ -> false

(* the code points of s; invalid UTF-8 is U+FFFD *)
let fold_utf8 f acc s =
  let n = String.length s in
  let rec go i acc =
    if i >= n then acc
    else
      let d = String.get_utf_8_uchar s i in
      let l = Uchar.utf_decode_length d in
      let u =
        if Uchar.utf_decode_is_valid d then Uchar.to_int (Uchar.utf_decode_uchar d)
        else 0xFFFD
      in
      go (i + l) (f acc (String.sub s i l) u)
  in
  go 0 acc

(* t:char for one code point; [pre]: blanks are "\ ".  Control characters
   other than tab, line end and carriage return are U+FFFD in the XML
   (Be_xml), so they print as \gmlchar{65533} *)
let add_char b ~pre raw u =
  match u with
  | 0x20 -> if pre then Buffer.add_string b "\\ " else Buffer.add_char b ' '
  | 0x24 | 0x26 | 0x23 | 0x25 ->
      Buffer.add_char b '\\';
      Buffer.add_string b raw
  | 0x5C | 0x7B | 0x7D | 0x5E | 0x5F | 0x7E | 0x3C | 0x3E | 0x7C | 0x22 ->
      Printf.bprintf b "\\gmlchar{%d}" u
  | 9 | 10 | 13 | 127 -> ()
  | u when u < 32 -> Buffer.add_string b "\\gmlchar{65533}"
  | u when u > 127 -> Printf.bprintf b "\\gmlchar{%d}" u
  | _ -> Buffer.add_string b raw

(* replace(s, "--", "-{}-"), left to right *)
let dashes s =
  if not (String.length s > 1 && String.contains s '-') then s
  else begin
    let b = Buffer.create (String.length s + 8) in
    let n = String.length s in
    let rec go i =
      if i < n then
        if i + 1 < n && s.[i] = '-' && s.[i + 1] = '-' then begin
          Buffer.add_string b "-{}-";
          go (i + 2)
        end
        else begin
          Buffer.add_char b s.[i];
          go (i + 1)
        end
    in
    go 0;
    Buffer.contents b
  end

let esc ?(pre = false) s =
  let b = Buffer.create (String.length s + 8) in
  fold_utf8 (fun () raw u -> add_char b ~pre raw u) () s;
  dashes (dashes (Buffer.contents b))

let replace_char c by s =
  if not (String.contains s c) then s
  else String.concat by (String.split_on_char c s)

let attr v =
  let v = String.map (function '\t' | '\n' | '\r' -> ' ' | c -> c) v in
  esc v |> replace_char ',' "\\gmlchar{44}" |> replace_char '=' "\\gmlchar{61}"

let name s =
  let b = Buffer.create (String.length s) in
  fold_utf8
    (fun () raw u ->
      match raw with
      | ("." | "-") -> Buffer.add_string b raw
      | _ when String.length raw = 1
               && (match raw.[0] with
                  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' -> true
                  | _ -> false) ->
          Buffer.add_string b raw
      | _ -> Printf.bprintf b "+%d+" u)
    () s;
  Buffer.contents b

(* one attribute: anchor and refid are names *)
let attr_pair (k, v) =
  let local =
    match String.index_opt k ':' with
    | Some i -> String.sub k (i + 1) (String.length k - i - 1)
    | None -> k
  in
  k ^ "=" ^ if local = "anchor" || k = "refid" then name v else attr v

(* tokenize(s, sep, 'q') of XPath, but [""] for "" *)
let split_on sep s =
  let n = String.length s and m = String.length sep in
  let rec go i start acc =
    if i + m > n then List.rev (String.sub s start (n - start) :: acc)
    else if String.sub s i m = sep then go (i + m) (i + m) (String.sub s start (i - start) :: acc)
    else go (i + 1) start acc
  in
  go 0 0 []

let attrs ?(extra = []) l = String.concat "," (List.map attr_pair l @ extra)

let normalize_space s =
  String.split_on_char ' '
    (String.map (fun c -> if is_ws_char c then ' ' else c) s)
  |> List.filter (( <> ) "")
  |> String.concat " "

let is_ws s =
  let r = ref true in
  String.iter (fun c -> if not (is_ws_char c) then r := false) s;
  !r

(* ==== names ============================================================= *)

let blocks =
  [ "gdoc"; "frontm"; "titlep"; "title"; "docnum"; "date"; "author"; "address";
    "aline"; "abstract"; "preface"; "toc"; "figlist"; "body"; "appendix";
    "backm"; "index"; "h0"; "h1"; "h2"; "h3"; "h4"; "h5"; "h6"; "p"; "pc";
    "note"; "ol"; "ul"; "sl"; "l"; "dl"; "gl"; "li"; "lp"; "dthd"; "ddhd"; "dt";
    "dd"; "gt"; "gd"; "lq"; "xmp"; "fig"; "figcap"; "figdesc"; "gml:h";
    "gml:rh"; "gml:rf"; "rdef"; "table"; "thd"; "tft"; "row"; "c"; "tnote";
    "tcap"; "tdesc"; "tlist" ]

let index_tags = [ "i1"; "i2"; "i3"; "ih1"; "ih2"; "ih3"; "iref" ]
let flows = [ "h"; "fn"; "rh"; "rf" ]

let generated =
  [ "doc"; "lines"; "num"; "pageref"; "toc-entries"; "toc-entry"; "entry-text";
    "figlist-entries"; "figlist-entry"; "tlist-entries"; "tlist-entry";
    "index-entries"; "index-group"; "index-entry"; "index-term"; "see" ]

let gml_local n =
  if String.length n > 4 && String.sub n 0 4 = "gml:" then
    Some (String.sub n 4 (String.length n - 4))
  else None

(* t:is-block of an element of XML name n *)
let is_block n =
  List.mem n blocks
  ||
  match gml_local n with
  | Some l -> not (List.mem l flows || List.mem l generated)
  | None -> false

let is_heading n =
  match n with
  | "h0" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "gml:h" | "title" -> true
  | _ -> false

let xml_name = function
  | Tree.Element (n, _, _) -> Some n
  | Tree.Hint (n, _) -> Some ("gml:" ^ n)
  | Tree.Raw _ -> Some "gml:raw"
  | Tree.Text _ -> None

(* t:plain: the text of an element, without the index tags' text *)
let rec plain_nodes b l = List.iter (plain_node b) l

and plain_node b = function
  | Tree.Text s -> Buffer.add_string b s
  | Tree.Raw (_, c) -> Buffer.add_string b c
  | Tree.Hint ("dv", a) ->
      (* a text variable is known text (SH35-0069 p.261: usable in a
         heading and its TOC entry) *)
      Buffer.add_string b (Option.value (List.assoc_opt "text" a) ~default:"")
  | Tree.Hint _ -> ()
  | Tree.Element (n, _, ch) ->
      if not (List.mem n index_tags || n = "gml:num") then plain_nodes b ch

(* (^|\s)&(\s|$) *)
let lone_amp s =
  let n = String.length s in
  let rec go i =
    match String.index_from_opt s i '&' with
    | None -> false
    | Some j ->
        ((j = 0 || is_ws_char s.[j - 1]) && (j = n - 1 || is_ws_char s.[j + 1]))
        || go (j + 1)
  in
  n > 0 && go 0

(* does a running heading/footing hold the page number (tex.xsl: a .sx with
   pagesym= or a lone "&" field, a lone "&" in its text, or gml:pageno)? *)
let rec has_pageno = function
  | Tree.Hint ("pageno", _) -> true
  | Tree.Hint ("sx", a) ->
      List.mem_assoc "pagesym" a
      || List.exists (fun k -> List.assoc_opt k a = Some "&") [ "left"; "fill"; "right" ]
  | Tree.Element (_, _, ch) -> List.exists has_pageno ch
  | Tree.Text t | Tree.Raw (_, t) -> lone_amp t
  | Tree.Hint _ -> false

(* ==== DCF definitions: parsed operands ==================================== *)

(* t:words: lower case; a quoted string is one word (quotes kept) *)
let words s =
  let s = String.lowercase_ascii s in
  let n = String.length s in
  let rec go i acc =
    if i >= n then List.rev acc
    else
      match s.[i] with
      | '\'' ->
          let j = match String.index_from_opt s (i + 1) '\'' with
            | Some j -> j + 1 | None -> n in
          go j (String.sub s i (j - i) :: acc)
      | '(' | ')' -> go (i + 1) (String.make 1 s.[i] :: acc)
      | c when is_ws_char c -> go (i + 1) acc
      | _ ->
          let j = ref i in
          while !j < n && not (is_ws_char s.[!j] || List.mem s.[!j] [ '('; ')'; '\'' ])
          do incr j done;
          go !j (String.sub s i (!j - i) :: acc)
  in
  go 0 []

let unresolved = function
  | None | Some "" -> true
  | Some w -> w.[0] = '&'

let contains s sub =
  let n = String.length s and m = String.length sub in
  let rec go i = i + m <= n && (String.sub s i m = sub || go (i + 1)) in
  go 0

(* ^[+-]?[0-9]*\.?[0-9]+$ *)
let is_number s =
  let n = String.length s in
  let i = if n > 0 && (s.[0] = '+' || s.[0] = '-') then 1 else 0 in
  let rec digits j = if j < n && s.[j] >= '0' && s.[j] <= '9' then digits (j + 1) else j in
  let j = digits i in
  if j = n then j > i
  else if s.[j] = '.' then
    let k = digits (j + 1) in
    k = n && k > j + 1
  else false

let family face =
  let words = String.split_on_char ' ' face in
  if (match words with "pi" :: _ -> true | _ -> false)
     || contains face "symbol" || contains face "dingbat" then "pi"
  else if List.exists (contains face)
            [ "courier"; "prestige"; "elite"; "letter gothic"; "mono"; "typewriter";
              "orator" ]
          || List.mem "pica" words then "mono"
  else if List.exists (contains face)
            [ "sans"; "gothic"; "helvetica"; "univers"; "futura"; "avant" ] then "sans"
  else "serif"

let nth l i = List.nth_opt l (i - 1) (* 1-based, as in XPath *)

let index_of l x =
  let rec go i = function [] -> None | y :: r -> if y = x then Some i else go (i + 1) r in
  go 1 l

(* .df (t:df-keys) *)
let df_keys spec =
  let w = words spec in
  let cnt = List.length w in
  let open_ = index_of w "(" in
  let tpos = index_of w "type" in
  let close =
    let after = Option.value open_ ~default:0 in
    let rec go i = function
      | [] -> cnt + 1
      | ")" :: _ when i > after -> i
      | _ :: r -> go (i + 1) r
    in
    go 1 w
  in
  let paren = match (open_, tpos) with Some o, Some t -> o = t + 1 | _ -> false in
  let desc =
    match tpos with
    | None -> []
    | Some t ->
        if paren then
          let o = Option.get open_ in
          List.filteri (fun i _ -> i + 1 > o && i + 1 < close) w
        else (match nth w (t + 1) with Some d when d <> "(" -> [ d ] | _ -> [])
  in
  let inside i =
    match tpos with
    | None -> false
    | Some t -> i >= t && i <= if paren then close else t + 1
  in
  let outer = List.filteri (fun i _ -> not (inside (i + 1))) w in
  let face =
    String.concat " "
      (List.filter_map
         (fun d ->
           if d <> "" && d.[0] = '\'' then
             Some (String.concat "" (String.split_on_char '\'' d))
           else None)
         desc)
  in
  let fonti = index_of outer "font" in
  List.concat
    [
      (if List.mem "os" outer then [ ("os", "yes") ] else []);
      (if List.mem "us" outer || List.mem "uc" outer then [ ("us", "yes") ] else []);
      (if List.mem "up" outer || List.mem "uc" outer then [ ("up", "yes") ] else []);
      (match fonti with
      | Some i when not (unresolved (nth outer (i + 1))) ->
          [ ("font", Option.get (nth outer (i + 1))) ]
      | _ -> []);
      (if face <> "" then [ ("face", face); ("family", family face) ] else []);
      (match List.find_opt is_number desc with Some d -> [ ("size", d) ] | None -> []);
      (if List.exists (fun d -> List.mem d desc)
            [ "bold"; "semibold"; "demibold"; "heavy"; "black"; "extrabold" ]
       then [ ("bold", "yes") ] else []);
      (if List.mem "italic" desc || List.mem "oblique" desc then [ ("italic", "yes") ]
       else []);
    ]

(* XPath string() of a double *)
let xpath_number f =
  if Float.is_integer f && Float.abs f < 1e15 then Printf.sprintf "%.0f" f
  else
    let rec go p =
      let s = Printf.sprintf "%.*g" p f in
      if p >= 17 || float_of_string s = f then s else go (p + 1)
    in
    go 1

(* t:vdim: a bare number is lines, p-notation points *)
let vdim v =
  if is_number v then v ^ "line"
  else
    match String.index_opt v 'p' with
    | Some i when v <> "p" ->
        let a = String.sub v 0 i and b = String.sub v (i + 1) (String.length v - i - 1) in
        let ok s =
          String.for_all (fun c -> (c >= '0' && c <= '9') || c = '.') s
          && List.length (String.split_on_char '.' s) <= 2
        in
        if ok a && ok b then
          let num s = if s = "" then 0. else Option.value (float_of_string_opt s) ~default:Float.nan in
          xpath_number ((num a *. 12.) +. num b) ^ "pt"
        else v
    | _ -> v

(* .dh n options (t:dh-keys) *)
let dh_keys spec =
  let w = List.filter (fun x -> x <> "(" && x <> ")") (words spec) in
  if w = [] then [ ("reset", "yes") ]
  else
    let rec go = function
      | [] -> []
      | (("font" | "tfont") as t) :: rest ->
          let v = match rest with v :: _ -> Some v | [] -> None in
          (if unresolved v then [] else [ (t, Option.get v) ])
          @ go (match rest with _ :: r -> r | [] -> [])
      | (("spbf" | "skbf" | "spaf") as t) :: rest ->
          (match rest with v :: _ -> [ (t, vdim v) ] | [] -> [])
          @ go (match rest with _ :: r -> r | [] -> [])
      | ("tind" | "tskip" | "tsk") :: rest -> go (match rest with _ :: r -> r | [] -> [])
      | t :: rest ->
          (match t with
          | "pa" -> [ ("pa", "yes") ]
          | "npa" -> [ ("pa", "no") ]
          | "left" | "right" | "center" | "inside" | "outside" -> [ ("align", t) ]
          | "centre" -> [ ("align", "center") ]
          | "nbr" -> [ ("runin", "yes") ]
          | "br" -> [ ("runin", "no") ]
          | "up" -> [ ("up", "yes") ]
          | "nup" -> [ ("up", "no") ]
          | "us" -> [ ("us", "yes") ]
          | "nus" -> [ ("us", "no") ]
          | "hy" -> [ ("hy", "yes") ]
          | "nohy" -> [ ("hy", "no") ]
          | _ -> [])
          @ go rest
    in
    go w

(* .dr rulename [WEIGHT h] (t:dr-keys) *)
let dr_keys spec =
  let w = words spec in
  let wi = match index_of w "weight" with Some i -> Some i | None -> index_of w "w" in
  (match w with r :: _ -> [ ("rule", r) ] | [] -> [])
  @ match wi with
    | Some i -> (match nth w (i + 1) with Some v -> [ ("weight", v) ] | None -> [])
    | None -> []

(* ==== text (t:text, t:seg) =============================================== *)

(* replace(s, '\n(\s*\n)+', '\n') *)
let collapse s =
  if not (String.contains s '\n') then s
  else begin
    let n = String.length s in
    let b = Buffer.create n in
    let rec go i =
      if i < n then
        if s.[i] = '\n' then begin
          (* the last line end of the blank run after i *)
          let rec run j last = if j < n && is_ws_char s.[j] then
              run (j + 1) (if s.[j] = '\n' then j else last) else last in
          let last = run (i + 1) i in
          Buffer.add_char b '\n';
          go (last + 1)
        end
        else begin
          Buffer.add_char b s.[i];
          go (i + 1)
        end
    in
    go 0;
    Buffer.contents b
  end

let seg ~pre ~word s =
  let wrap =
    match word with
    | "us" -> "\\gmlusword{"
    | "up" -> "\\gmlupword{"
    | "uc" -> "\\gmlucword{"
    | _ -> ""
  in
  if wrap = "" then esc ~pre s
  else begin
    let b = Buffer.create (String.length s * 2) in
    let n = String.length s in
    let rec go i =
      if i < n then begin
        let w = not (is_ws_char s.[i]) in
        let j = ref i in
        while !j < n && not (is_ws_char s.[!j]) = w do incr j done;
        let piece = esc ~pre (String.sub s i (!j - i)) in
        if w then (Buffer.add_string b wrap; Buffer.add_string b piece; Buffer.add_char b '}')
        else Buffer.add_string b piece;
        go !j
      end
    in
    go 0;
    Buffer.contents b
  end

let t_text s ~pre ~word =
  let s1 = if pre then s else collapse s in
  String.concat "\n"
    (List.map
       (fun line ->
         if String.contains line '\t' then
           "\\gmltabline{"
           ^ String.concat "\\gmltab "
               (List.map (seg ~pre ~word) (String.split_on_char '\t' line))
           ^ "}"
         else seg ~pre ~word line)
       (String.split_on_char '\n' s1))

(* ==== nodes ================================================================ *)

let attrs_of = function
  | Tree.Element (_, a, _) | Tree.Hint (_, a) -> a
  | Tree.Raw (b, _) -> [ ("backend", b) ]
  | Tree.Text _ -> []

(* the child nodes, as in the XML: a gml:raw holds its content as text *)
let children_of = function
  | Tree.Element (_, _, ch) -> ch
  | Tree.Raw (_, c) when c <> "" -> [ Tree.Text c ]
  | _ -> []

let is_name x n = xml_name n = Some x
let is_lines = is_name "gml:lines"

(* t:is-block of a node *)
let node_block n = match xml_name n with Some x -> is_block x | None -> false

(* text, gml:bf or gml:pf: the run before a .is TO that is a label *)
let is_tbp n =
  match n with Tree.Text _ -> true | _ -> is_name "gml:bf" n || is_name "gml:pf" n

(* a breaking gml:* node that is not a flow nor generated *)
let breaking n =
  match Option.bind (xml_name n) gml_local with
  | Some l ->
      List.assoc_opt "break" (attrs_of n) = Some "yes"
      && not (List.mem l flows || List.mem l generated)
  | None -> false

let nonblank = function Tree.Text s -> not (is_ws s) | _ -> false

(* t:is-label-start: a node that is text, gml:bf or gml:pf, at the start
   of an output line (after a breaking hint, or first in a block), whose
   run of text and fonts ends at a .is TO with some text in the run *)
let label_start ~pblock ~prev ~rest n =
  is_tbp n
  && (match prev with Some p -> (not (is_tbp p)) && breaking p | None -> pblock)
  &&
  let rec run text = function
    | m :: r when is_tbp m -> run (text || nonblank m) r
    | m :: _ when is_name "gml:is" m ->
        let spec =
          String.lowercase_ascii
            (normalize_space (Option.value (List.assoc_opt "spec" (attrs_of m)) ~default:""))
        in
        text && String.length spec >= 3 && String.sub spec 0 3 = "to "
    | _ -> false
  in
  run (nonblank n) rest

(* the gml:lines nodes in [l] and below, in document order *)
let rec lines_in acc l =
  List.fold_left
    (fun acc n ->
      let acc =
        if is_lines n then
          let a = attrs_of n in
          (Option.value (List.assoc_opt "word" a) ~default:"", List.assoc_opt "cont" a = Some "yes")
          :: acc
        else acc
      in
      lines_in acc (children_of n))
    acc l

(* ==== the serializer ======================================================= *)

type heading = { hfont : string; hup : string; mutable seen : bool }
(** an open gml:h: its .dh font and up at its start; [seen]: a .bf/.pf
    inside it so far *)

type st = {
  b : Buffer.t;
  (* the accumulators of tex.xsl *)
  mutable fill : string;
  dfs : (string, bool) Hashtbl.t;
  mutable font : string;
  dh : (string, string) Hashtbl.t;
  mutable heads : heading list;  (** the open gml:h, innermost first *)
  lines : (string * bool) array;
      (** every gml:lines in document order: its word, cont=yes *)
  mutable nlines : int;  (** the gml:lines met so far *)
}

(* what a node inherits *)
type env = {
  space : string option;  (** the nearest xml:space *)
  lword : string;  (** the word of the nearest gml:lines *)
}

let out st s = Buffer.add_string st.b s

(* ---- accumulators (tex.xsl t:fill t:dfs t:font t:dh) ---- *)

let accumulate st local a =
  let get k = List.assoc_opt k a in
  match local with
  | "fo" | "nf" | "ju" -> (
      match get "fill" with Some ("yes" | "no" as v) -> st.fill <- v | _ -> ())
  | "df" ->
      Hashtbl.replace st.dfs
        (String.lowercase_ascii (normalize_space (Option.value (get "name") ~default:"")))
        (List.mem ("up", "yes") (df_keys (Option.value (get "spec") ~default:"")))
  | "bf" | "pf" -> (
      let font = normalize_space (Option.value (get "font") ~default:"") in
      let toks =
        List.filter (( <> ) "") (String.split_on_char ' ' (String.lowercase_ascii font))
      in
      List.iter (fun h -> h.seen <- true) st.heads;
      match List.find_opt (Hashtbl.mem st.dfs) toks with
      | Some f -> st.font <- f
      | None -> if local = "pf" && font = "" then st.font <- "")
  | "dh" ->
      let l = normalize_space (Option.value (get "level") ~default:"") in
      let k = dh_keys (Option.value (get "spec") ~default:"") in
      if List.mem ("reset", "yes") k then begin
        Hashtbl.remove st.dh (l ^ "font");
        Hashtbl.remove st.dh (l ^ "up")
      end;
      Option.iter (Hashtbl.replace st.dh (l ^ "font")) (List.assoc_opt "font" k);
      Option.iter (Hashtbl.replace st.dh (l ^ "up")) (List.assoc_opt "up" k)
  | _ -> ()

(* a node and its content, accumulators only (no output) *)
let rec visit st n =
  match xml_name n with
  | Some x ->
      Option.iter (fun l -> accumulate st l (attrs_of n)) (gml_local x);
      if is_lines n then st.nlines <- st.nlines + 1;
      List.iter (visit st) (children_of n)
  | None -> ()

(* is the current text in upper case (t:upper) *)
let upper st =
  let dfs f = Hashtbl.find_opt st.dfs f = Some true in
  match st.heads with
  | h :: _ when not h.seen -> h.hup = "yes" || dfs (String.lowercase_ascii h.hfont)
  | _ -> st.font <> "" && dfs st.font

(* ---- the walk ---- *)

(* the children [sibs] of a node of XML name [pname] *)
let rec children st env ~pname sibs =
  let pblock = is_block pname in
  let rec go prev = function
    | [] -> ()
    | n :: rest ->
        if label_start ~pblock ~prev ~rest n then out st "\\gmlislabel ";
        (match n with
        | Tree.Text s -> text st env ~pname ~pblock ~prev ~rest ~sibs s
        | _ -> node st env ~rest n);
        go (Some n) rest
  in
  go None sibs

and text st env ~pname ~pblock ~prev ~rest ~sibs s =
  let pre = env.space = Some "preserve" || st.fill = "no" in
  let drop =
    is_ws s
    && ((pname = "c" && List.exists (is_name "gml:cpart") sibs)
       || (not pre)
          && ((match prev with Some p -> node_block p | None -> false)
             || (match rest with n :: _ -> node_block n | [] -> false)
             || (pblock && (Option.is_none prev || rest = []))))
  in
  if not drop then begin
    let lword = env.lword in
    let word =
      if not (upper st) then lword
      else if lword = "us" || lword = "uc" then "uc"
      else if lword = "" || lword = "up" then "up"
      else lword
    in
    out st (t_text s ~pre ~word)
  end

(* an element, hint or gml:raw; [rest]: its following siblings *)
and node st env ~rest n =
  let x = Option.get (xml_name n) and a = attrs_of n and ch = children_of n in
  let local = gml_local x in
  Option.iter (fun l -> accumulate st l a) local;
  let env =
    match List.assoc_opt "xml:space" a with Some v -> { env with space = Some v } | None -> env
  in
  let kids ?(env = env) () = children st env ~pname:x ch in
  let skip () = List.iter (visit st) ch in
  let hint l keys =
    out st ("\\gmlhint{" ^ l ^ "}{" ^ keys ^ "}");
    if List.assoc_opt "break" a = Some "yes" then out st "%\n"
  in
  let element () =
    let block = is_block x in
    let extra =
      (if is_heading x then begin
         let b = Buffer.create 64 in
         plain_nodes b ch;
         [ "text=" ^ attr (normalize_space (Buffer.contents b)) ]
       end
       else [])
      @
      let desc = match x with "figcap" -> "figdesc" | "tcap" -> "tdesc" | _ -> "" in
      match List.find_opt (fun n -> xml_name n <> None) rest with
      | Some n when desc <> "" && is_name desc n -> [ "desc=yes" ]
      | _ -> []
    in
    out st ("\\gmlstart{" ^ x ^ "}{" ^ attrs ~extra a ^ "}");
    if block then out st "%\n";
    Option.iter (fun v -> out st ("\\gmlanchor{" ^ name v ^ "}")) (List.assoc_opt "anchor" a);
    if List.mem x index_tags then skip ()
    else if x = "gml:h" then begin
      let l = normalize_space (Option.value (List.assoc_opt "level" a) ~default:"") in
      let h =
        {
          hfont = Option.value (Hashtbl.find_opt st.dh (l ^ "font")) ~default:("hd" ^ l);
          hup = Option.value (Hashtbl.find_opt st.dh (l ^ "up")) ~default:"";
          seen = false;
        }
      in
      st.heads <- h :: st.heads;
      kids ();
      st.heads <- List.tl st.heads
    end
    else kids ();
    out st ("\\gmlend{" ^ x ^ "}");
    if block then out st "%\n"
  in
  match local with
  | Some "lines" ->
      (* more=yes: the next gml:lines in document order (after this one's
         content) is its continuation *)
      let i = st.nlines in
      st.nlines <- i + 1;
      let word = Option.value (List.assoc_opt "word" a) ~default:"" in
      let j = i + 1 + List.length (lines_in [] ch) in
      let more =
        j < Array.length st.lines
        && (let w, cont = st.lines.(j) in cont && w = word)
      in
      out st
        ("\\gmlbeginlines{" ^ word ^ "}{"
        ^ attrs ~extra:(if more then [ "more=yes" ] else []) (List.remove_assoc "word" a)
        ^ "}");
      kids ~env:{ env with lword = word } ();
      out st "\\gmlendlines{}"
  | Some (("df" | "dh" | "dr") as l) ->
      let spec = Option.value (List.assoc_opt "spec" a) ~default:"" in
      let keys =
        match l with "df" -> df_keys spec | "dh" -> dh_keys spec | _ -> dr_keys spec
      in
      out st
        ("\\gmlhint{" ^ l ^ "}{" ^ attrs a
        ^ String.concat "" (List.map (fun (k, v) -> "," ^ k ^ "=" ^ attr v) keys)
        ^ "}");
      skip ()
  | Some ("rh" | "rf") when List.exists has_pageno ch ->
      (* gml.tex keeps the content as tokens and typesets it at every page *)
      out st ("\\gmlstart{" ^ x ^ "}{" ^ attrs a ^ "}%\n\\gmlrundyn{");
      kids ();
      out st ("}\\gmlend{" ^ x ^ "}%\n")
  | Some ("h" | "fn" | "rh" | "rf" | "cpart") | None -> element ()
  | Some "num" ->
      out st "\\gmlnum{";
      kids ();
      out st "}"
  | Some "pageref" ->
      out st
        ("\\gmlpageref{" ^ name (Option.value (List.assoc_opt "refid" a) ~default:"")
        ^ "}{" ^ Option.value (List.assoc_opt "when" a) ~default:"always" ^ "}{"
        ^ attr (Option.value (List.assoc_opt "label" a) ~default:"") ^ "}");
      skip ()
  | Some "sx" when (match List.assoc_opt "pagesym" a with Some p -> p <> "" | None -> false) ->
      (* the page number symbol in the fields is the page number,
         \gmlpageno (SH35-0069 p.128); any other character, a text "&"
         too, is text *)
      let ps = List.assoc "pagesym" a in
      let field (k, v) =
        if k = "left" || k = "fill" || k = "right" then
          k ^ "=" ^ String.concat "\\gmlpageno{}" (List.map attr (split_on ps v))
        else attr_pair (k, v)
      in
      hint "sx" (String.concat "," (List.map field a));
      skip ()
  | Some l ->
      hint l (attrs a);
      kids ()

(* ==== documents =========================================================== *)

type config = {
  fonts : string;  (** \def\gmlfonts; "" none *)
  tagset : string;  (** \def\gmltagset; "" none *)
  input : string;  (** the macro package, "gml" *)
  preamble : string;  (** after \input *)
  title_align : string;  (** SYSVART: right, left, center or "" *)
}

let default_config = { fonts = ""; tagset = ""; input = "gml"; preamble = ""; title_align = "" }

let preamble c =
  let b = Buffer.create 256 in
  if c.fonts <> "" then Printf.bprintf b "\\def\\gmlfonts{%s}\n" c.fonts;
  if c.tagset <> "" then Printf.bprintf b "\\def\\gmltagset{%s}\n" c.tagset;
  Buffer.add_string b "\\def\\gmlmode{hints}\n";
  Printf.bprintf b "\\input %s\n" c.input;
  if c.preamble <> "" then Printf.bprintf b "%s\n" c.preamble;
  (match String.lowercase_ascii c.title_align with
  | ("right" | "left" | "center") as a -> Printf.bprintf b "\\def\\gmltitlealign{%s}\n" a
  | _ -> ());
  Buffer.add_string b "\\gmlbegindocument%\n";
  Buffer.contents b

let postamble = "%\n\\gmlenddocument\n\\bye\n"

(** The body (between \gmlbegindocument and \gmlenddocument) of a finished
    tree. *)
let body root =
  let st =
    {
      b = Buffer.create 65536;
      fill = "yes";
      dfs = Hashtbl.create 16;
      font = "";
      dh = Hashtbl.create 16;
      heads = [];
      lines = Array.of_list (List.rev (lines_in [] [ root ]));
      nlines = 0;
    }
  in
  (match root with
  | Tree.Element (x, _, ch) -> children st { space = None; lword = "" } ~pname:x ch
  | n -> children st { space = None; lword = "" } ~pname:Doc.root_name [ n ]);
  Buffer.contents st.b

let document ?(config = default_config) root =
  preamble config ^ body root ^ postamble
