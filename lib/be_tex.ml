(* TeX serializer for hint mode: the OCaml port of the part of
   xslt/tex.xsl that a formatting profile's document needs, writing the
   same macro calls for share/tex/gml.tex.

   It serializes the engine's tree directly (no resolve.xsl stage), so
   generated nodes (TOC entries, gml:num, page references, anchors) come
   only from what the tree holds.  The output is hint mode always:
   [\def\gmlmode{hints}], the profile's control words do the layout.

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
   \gmlrunning{NAME}{attrs}{body} (NAME rh or rf), typeset again at every page.

   Streaming ([stream]).  The serializer is a document-order event
   processor ([start], [stop], [text], [text_part]); what an event's
   output depends on that is not known yet (the next sibling of a
   whitespace text, whether a figdesc follows a figcap, the more= of a
   gml:lines, which depends on the next gml:lines in document order) is
   a hole in the output, filled when a later event or the end of the
   document decides it.  Output is taken in complete lines ([take]) up to
   the first open hole, and never inside a \gmlrunning argument.  The
   walker [flush] follows the live [Doc] stack: for each open element it
   has entered it keeps the record (physical identity), the number of
   its children already written and the bytes written of a trailing
   text that may still grow.  Elements that left the stack are finished
   from their closed record; [Doc.open_elt.contributed] says by how much
   the parent's cursor moves (0: a dropped empty scope piece, 1, or n+1
   for a provisional element left empty with its n children after it).
   A full batch run is one final flush and gives the same text as
   [document] on the finished tree. *)

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

(* the first index >= [from] of [sub] in [s] *)
let find_sub s sub from =
  let n = String.length s and m = String.length sub in
  let rec go i = if i + m > n then None else if String.sub s i m = sub then Some i else go (i + 1) in
  go from

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

(* ==== output: text with holes =========================================== *)

type hole = { mutable value : string option; mutable force : unit -> string }

type piece = Fixed of Buffer.t * int ref (* last line end allowed as a cut *)
           | Hole of hole

(* ==== the serializer (events) ============================================ *)

type sib =
  | Next of {
      text : bool;
      block : bool;
      xname : string;
      xattrs : Tree.attrs;
      content : string;  (** a text's *)
    }
  | End

let next_text content = Next { text = true; block = false; xname = ""; xattrs = []; content }

(* text, gml:bf or gml:pf: the run before a .is TO that is a label *)
let tbp = function
  | Next { text = true; _ } | Next { xname = "gml:bf" | "gml:pf"; _ } -> true
  | _ -> false

type frame = {
  fname : string;  (** XML name; "gml:doc" for the root *)
  kind : [ `Elt | `Hint | `Lines | `Running | `Num | `Skip | `Root ];
  fblock : bool;
  fspace : string option;  (** its own xml:space *)
  fword : string option;  (** gml:lines: the word *)
  head : (string * string) option;  (** gml:h: the .dh font and up at its start *)
  mutable font_seen : bool;  (** gml:h: a .bf/.pf inside it so far *)
  mutable has_prev : bool;
  mutable prev_block : bool;
  mutable prev_tbp : bool;  (** the last child is text, gml:bf or gml:pf *)
  mutable prev_brk : bool;
      (** the last child is a breaking gml:* (not a flow nor generated) *)
  mutable waiters : (sib -> bool) list;  (** waiting for the next sibling *)
  mutable cpart : bool;  (** c: a gml:cpart child seen *)
  mutable lines_begin : (hole * string) option;
      (** gml:lines: the hole for more=yes, and the separator before it *)
  fattrs : Tree.attrs;
}

type st = {
  mutable pieces : piece list;  (** newest first; the head is Fixed *)
  mutable atomic : int;  (** inside a \gmlrunning argument: no cut *)
  mutable frames : frame list;  (** innermost first; the root last *)
  (* the accumulators of tex.xsl *)
  mutable fill : string;
  dfs : (string, bool) Hashtbl.t;
  mutable font : string;
  dh : (string, string) Hashtbl.t;
  mutable lines_waiting : (string * string * hole * hole) list;
      (** ended gml:lines (word, separator, begin hole, end hole) waiting for
          the next gml:lines in document order (their more=) *)
  mutable warn : string -> unit;
}

let new_frame ?(kind = `Elt) ?space ?word ?head ?(attrs = []) name =
  {
    fname = name; kind; fblock = is_block name; fspace = space; fword = word;
    head; font_seen = false; has_prev = false; prev_block = false;
    prev_tbp = false; prev_brk = false; waiters = [];
    cpart = false; lines_begin = None; fattrs = attrs;
  }

let create () =
  {
    pieces = [ Fixed (Buffer.create 4096, ref (-1)) ];
    atomic = 0;
    frames = [ new_frame ~kind:`Root "gml:doc" ];
    fill = "yes";
    dfs = Hashtbl.create 16;
    font = "";
    dh = Hashtbl.create 16;
    lines_waiting = [];
    warn = ignore;
  }

let out st s =
  if s <> "" then
    match st.pieces with
    | Fixed (b, cut) :: _ ->
        Buffer.add_string b s;
        if st.atomic = 0 then (
          match String.rindex_opt s '\n' with
          | Some i -> cut := Buffer.length b - String.length s + i + 1
          | None -> ())
    | _ -> assert false

let hole st ~force =
  let h = { value = None; force } in
  st.pieces <- Fixed (Buffer.create 256, ref (-1)) :: Hole h :: st.pieces;
  h

let fill_hole h v = if h.value = None then h.value <- Some v

let top st = List.hd st.frames
let silent st = match (top st).kind with `Skip -> true | _ -> false

(* a child event in the current frame: the waiting siblings learn it *)
let child st sib =
  let f = top st in
  f.waiters <- List.filter (fun w -> not (w sib)) f.waiters;
  match sib with
  | Next { block; xname; xattrs; _ } ->
      f.has_prev <- true;
      f.prev_block <- block;
      f.prev_tbp <- tbp sib;
      f.prev_brk <-
        (match gml_local xname with
        | Some l -> List.assoc_opt "break" xattrs = Some "yes"
                    && not (List.mem l flows || List.mem l generated)
        | None -> false)
  | End -> ()

(* t:is-label-start: before a node that is text, gml:bf or gml:pf, at the
   start of an output line (after a breaking hint, or first in a block),
   whose run of text and fonts ends at a .is TO with some text in the run:
   \gmlislabel.  Call before [child] for the node. *)
let label_start st sib =
  let f = top st in
  if tbp sib && (not f.prev_tbp)
     && ((f.has_prev && f.prev_brk) || ((not f.has_prev) && f.fblock))
  then begin
    let nonblank = ref false in
    let see = function Next { content; _ } -> if not (is_ws content) then nonblank := true | End -> () in
    see sib;
    Some
      (fun () ->
        let h = hole st ~force:(fun () -> "") in
        let w s =
          if tbp s then (see s; false)
          else begin
            (match s with
            | Next { xname = "gml:is"; xattrs; _ } ->
                let spec =
                  String.lowercase_ascii
                    (normalize_space (Option.value (List.assoc_opt "spec" xattrs) ~default:""))
                in
                fill_hole h
                  (if String.length spec >= 3 && String.sub spec 0 3 = "to " && !nonblank
                   then "\\gmlislabel " else "")
            | _ -> fill_hole h "");
            true
          end
        in
        f.waiters <- f.waiters @ [ w ])
  end
  else None

(* the more= of ended gml:lines: [w] and [cont] of the next one *)
let resolve_lines st next =
  List.iter
    (fun (word, sep, b, e) ->
      let more =
        match next with
        | Some (w, cont) -> cont && w = word
        | None -> false
      in
      match b.value with
      | None ->
          b.value <- Some (if more then sep ^ "more=yes" else "");
          fill_hole e ""
      | Some _ -> (
          (* the begin went out without it (a query forced it): patch *)
          match e.value with
          | None -> e.value <- Some (if more then "\\gmllinesmore " else "")
          | Some _ ->
              if more then
                st.warn
                  "layout: a line scope went to TeX before its continuation was \
                   known (more=yes lost)"))
    st.lines_waiting;
  st.lines_waiting <- []

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
      List.iter
        (fun f -> match f.head with Some _ -> f.font_seen <- true | None -> ())
        st.frames;
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

(* ---- text ---- *)

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

(* is the current text in upper case (t:upper) *)
let upper st =
  let dfs f = Hashtbl.find_opt st.dfs f = Some true in
  match List.find_opt (fun f -> f.fname = "gml:h") st.frames with
  | Some ({ head = Some (font, up); _ } as h) when not h.font_seen ->
      up = "yes" || dfs (String.lowercase_ascii font)
  | _ -> st.font <> "" && dfs st.font

let text_context st =
  let space = List.find_map (fun f -> f.fspace) st.frames in
  let pre = space = Some "preserve" || st.fill = "no" in
  let lword = Option.value (List.find_map (fun f -> f.fword) st.frames) ~default:"" in
  let word =
    if not (upper st) then lword
    else if lword = "us" || lword = "uc" then "uc"
    else if lword = "" || lword = "up" then "up"
    else lword
  in
  (pre, word)

(** A whole text node. *)
let text st s =
  if not (silent st) then begin
    let f = top st in
    let pre, word = text_context st in
    let o = t_text s ~pre ~word in
    let label = label_start st (next_text s) in
    if not (is_ws s) then begin
      child st (next_text s);
      Option.iter (fun k -> k ()) label;
      out st o
    end
    else begin
      let has_prev = f.has_prev and prev_block = f.prev_block in
      child st (next_text s);
      Option.iter (fun k -> k ()) label;
      let in_c = f.fname = "c" in
      let decide ~has_next ~next_block =
        if in_c && f.cpart then ""
        else if
          (not pre)
          && ((has_prev && prev_block) || next_block
             || (f.fblock && ((not has_prev) || not has_next)))
        then ""
        else o
      in
      let h = hole st ~force:(fun () -> decide ~has_next:true ~next_block:false) in
      let next = ref None in
      let w sib =
        (match (!next, sib) with
        | None, Next { block; _ } -> next := Some (true, block)
        | None, End -> next := Some (false, false)
        | Some _, _ -> ());
        let resolve () =
          let has_next, next_block = Option.get !next in
          fill_hole h (decide ~has_next ~next_block);
          true
        in
        match sib with
        | Next { xname = "gml:cpart"; _ } when in_c -> fill_hole h ""; true
        | End -> resolve ()
        | Next _ -> if in_c then false else resolve ()
      in
      f.waiters <- f.waiters @ [ w ]
    end
  end

(** A piece of a text node that is not whitespace only, cut after a line end
    followed by a non-blank (so [t_text] of the pieces is [t_text] of the
    whole); the next piece continues the same node. *)
let text_part st s =
  if not (silent st) && s <> "" then begin
    let pre, word = text_context st in
    let label = label_start st (next_text s) in
    child st (next_text s);
    Option.iter (fun k -> k ()) label;
    out st (t_text s ~pre ~word)
  end

(** The start of a node of XML name [xname] (an element, a hint gml:NAME,
    gml:raw).  [plain]: the text= of a heading; [running]: a gml:rh/gml:rf that
    holds the page number. *)
let start st ?plain ?(running = false) xname a =
  let local = gml_local xname in
  Option.iter (fun l -> accumulate st l a) local;
  if xname = "gml:lines" then
    resolve_lines st
      (Some (Option.value (List.assoc_opt "word" a) ~default:"",
             List.assoc_opt "cont" a = Some "yes"));
  if silent st then st.frames <- new_frame ~kind:`Skip xname :: st.frames
  else begin
    let f = top st in
    if xname = "gml:cpart" then f.cpart <- true;
    let sib = Next { text = false; block = is_block xname; xname; xattrs = a; content = "" } in
    let label = label_start st sib in
    child st sib;
    Option.iter (fun k -> k ()) label;
    let block = is_block xname in
    let nl () = if block then out st "%\n" in
    let anchor () =
      match List.assoc_opt "anchor" a with
      | Some v -> out st ("\\gmlanchor{" ^ name v ^ "}")
      | None -> ()
    in
    let space = List.assoc_opt "xml:space" a in
    let element ?(kind = `Elt) () =
      let extra =
        match plain with
        | Some p when is_heading xname -> [ "text=" ^ attr (normalize_space p) ]
        | _ -> []
      in
      let head =
        if xname = "gml:h" then
          let l = normalize_space (Option.value (List.assoc_opt "level" a) ~default:"") in
          Some
            ( Option.value (Hashtbl.find_opt st.dh (l ^ "font")) ~default:("hd" ^ l),
              Option.value (Hashtbl.find_opt st.dh (l ^ "up")) ~default:"" )
        else None
      in
      let skip = List.mem xname index_tags in
      let fr = new_frame ~kind:(if skip then `Skip else kind) ?space ?head ~attrs:a xname in
      (match (kind, xname) with
      | `Running, _ ->
          (* gml.tex keeps the content as tokens and typesets it at every
             page: one argument, never cut between chunks *)
          out st ("\\gmlstart{" ^ xname ^ "}{" ^ attrs a ^ "}%\n");
          st.atomic <- st.atomic + 1;
          out st "\\gmlrundyn{"
      | _, ("figcap" | "tcap") ->
          out st ("\\gmlstart{" ^ xname ^ "}{" ^ attrs ~extra a);
          let desc = if xname = "figcap" then "figdesc" else "tdesc" in
          let sep = if a = [] && extra = [] then "" else "," in
          let h = hole st ~force:(fun () -> "") in
          let w = function
            | Next { text = true; _ } -> false
            | Next { xname = n; _ } ->
                fill_hole h (if n = desc then sep ^ "desc=yes" else "");
                true
            | End -> fill_hole h ""; true
          in
          f.waiters <- f.waiters @ [ w ];
          out st "}";
          nl ()
      | _ ->
          out st ("\\gmlstart{" ^ xname ^ "}{" ^ attrs ~extra a ^ "}");
          nl ());
      anchor ();
      st.frames <- fr :: st.frames
    in
    match local with
    | Some "lines" ->
        let word = Option.value (List.assoc_opt "word" a) ~default:"" in
        let rest = List.filter (fun (k, _) -> k <> "word") a in
        out st ("\\gmlbeginlines{" ^ word ^ "}{" ^ attrs rest);
        let b = hole st ~force:(fun () -> "") in
        out st "}";
        let fr = new_frame ~kind:`Lines ?space ~word ~attrs:a xname in
        fr.lines_begin <- Some (b, if rest = [] then "" else ",");
        st.frames <- fr :: st.frames
    | Some (("df" | "dh" | "dr") as l) ->
        let spec = Option.value (List.assoc_opt "spec" a) ~default:"" in
        let keys =
          match l with "df" -> df_keys spec | "dh" -> dh_keys spec | _ -> dr_keys spec
        in
        out st
          ("\\gmlhint{" ^ l ^ "}{" ^ attrs a
          ^ String.concat "" (List.map (fun (k, v) -> "," ^ k ^ "=" ^ attr v) keys)
          ^ "}");
        st.frames <- new_frame ~kind:`Hint ?space xname :: st.frames
    | Some ("h" | "fn" | "cpart") -> element ()
    | Some ("rh" | "rf") -> element ~kind:(if running then `Running else `Elt) ()
    | Some "num" ->
        out st "\\gmlnum{";
        st.frames <- new_frame ~kind:`Num ?space xname :: st.frames
    | Some "pageref" ->
        out st
          ("\\gmlpageref{" ^ name (Option.value (List.assoc_opt "refid" a) ~default:"")
          ^ "}{" ^ Option.value (List.assoc_opt "when" a) ~default:"always" ^ "}{"
          ^ attr (Option.value (List.assoc_opt "label" a) ~default:"") ^ "}");
        st.frames <- new_frame ~kind:`Skip xname :: st.frames
    | Some "sx" when List.mem_assoc "pagesym" a ->
        (* the page number symbol in the fields is the page number,
           \gmlpageno (SH35-0069 p.128); any other character, a text "&"
           too, is text *)
        let ps = List.assoc "pagesym" a in
        let field (k, v) =
          if (k = "left" || k = "fill" || k = "right") && ps <> "" then
            k ^ "=" ^ String.concat "\\gmlpageno{}" (List.map attr (split_on ps v))
          else attr_pair (k, v)
        in
        out st ("\\gmlhint{sx}{" ^ String.concat "," (List.map field a) ^ "}");
        if List.assoc_opt "break" a = Some "yes" then out st "%\n";
        st.frames <- new_frame ~kind:`Hint ?space xname :: st.frames
    | Some l ->
        out st ("\\gmlhint{" ^ l ^ "}{" ^ attrs a ^ "}");
        if List.assoc_opt "break" a = Some "yes" then out st "%\n";
        st.frames <- new_frame ~kind:`Hint ?space xname :: st.frames
    | None -> element ()
  end

(** The end of the current node. *)
let stop st =
  let f = top st in
  child st End;
  st.frames <- List.tl st.frames;
  match f.kind with
  | `Skip ->
      (* an index tag: its start and end are written, not its content *)
      if List.mem f.fname index_tags && not (silent st) then begin
        out st ("\\gmlend{" ^ f.fname ^ "}");
        if f.fblock then out st "%\n"
      end
  | `Root | `Hint -> ()
  | `Num -> out st "}"
  | `Running ->
      out st "}";
      st.atomic <- st.atomic - 1;
      out st ("\\gmlend{" ^ f.fname ^ "}%\n")
  | `Elt ->
      out st ("\\gmlend{" ^ f.fname ^ "}");
      if f.fblock then out st "%\n"
  | `Lines ->
      let e = hole st ~force:(fun () -> "") in
      out st "\\gmlendlines{}";
      let b, sep = Option.get f.lines_begin in
      st.lines_waiting <-
        st.lines_waiting @ [ (Option.value f.fword ~default:"", sep, b, e) ]

(** Serialize a complete node. *)
let rec node st n =
  match n with
  | Tree.Text s -> text st s
  | Tree.Hint (nm, a) ->
      start st ("gml:" ^ nm) a;
      stop st
  | Tree.Raw (b, c) ->
      start st "gml:raw" [ ("backend", b) ];
      if c <> "" then text st c;
      stop st
  | Tree.Element (nm, a, ch) ->
      let plain =
        if is_heading nm then (
          let b = Buffer.create 64 in
          plain_nodes b ch;
          Some (Buffer.contents b))
        else None
      in
      let running = (nm = "gml:rh" || nm = "gml:rf") && List.exists has_pageno ch in
      start st ?plain ~running nm a;
      List.iter (node st) ch;
      stop st

(** The output so far that may go to TeX: whole lines up to the first open
    hole ([force]: holes followed by text are decided by their default), never
    inside a \gmlrunning argument; [all]: everything (the end). *)
let take ?(force = false) ?(all = false) st =
  if all then begin
    resolve_lines st None;
    List.iter (function Hole h -> fill_hole h (h.force ()) | Fixed _ -> ()) st.pieces
  end;
  let pieces = List.rev st.pieces in
  (* the takeable prefix *)
  let rec has_text = function
    | [] -> false
    | Fixed (b, _) :: r -> Buffer.length b > 0 || has_text r
    | Hole { value = Some v; _ } :: r -> v <> "" || has_text r
    | Hole _ :: r -> has_text r
  in
  let rec prefix acc = function
    | [] -> (List.rev acc, [])
    | (Fixed _ as p) :: r -> prefix (p :: acc) r
    | (Hole h as p) :: r ->
        if h.value = None && force && has_text r then fill_hole h (h.force ());
        if h.value <> None then prefix (p :: acc) r else (List.rev acc, p :: r)
  in
  let pre, rest = prefix [] pieces in
  (* the last cut in the prefix *)
  let last_cut =
    if all then None
    else
      List.fold_left
        (fun (i, found) p ->
          match p with
          | Fixed (_, c) when !c >= 0 -> (i + 1, Some (i, !c))
          | _ -> (i + 1, found))
        (0, None) pre
      |> snd
  in
  let b = Buffer.create 4096 in
  let add = function
    | Fixed (x, _) -> Buffer.add_buffer b x
    | Hole { value = Some v; _ } -> Buffer.add_string b v
    | Hole _ -> assert false
  in
  if all then begin
    List.iter add pre;
    assert (rest = []);
    st.pieces <- [ Fixed (Buffer.create 256, ref (-1)) ]
  end
  else begin
    match last_cut with
    | None -> ()
    | Some (k, c) ->
        let kept = ref [] in
        List.iteri
          (fun i p ->
            if i < k then add p
            else if i = k then (
              match p with
              | Fixed (x, _) ->
                  Buffer.add_string b (Buffer.sub x 0 c);
                  let nb = Buffer.create 256 in
                  Buffer.add_string nb (Buffer.sub x c (Buffer.length x - c));
                  kept := [ Fixed (nb, ref (-1)) ]
              | _ -> assert false)
            else kept := p :: !kept)
          pre;
        let remaining = List.rev !kept @ rest in
        (* keep a Fixed piece at the head (newest) *)
        let rev = List.rev remaining in
        st.pieces <-
          (match rev with
          | Fixed _ :: _ -> rev
          | _ -> Fixed (Buffer.create 256, ref (-1)) :: rev)
  end;
  Buffer.contents b

(* ==== documents =========================================================== *)

type config = {
  fonts : string;  (** \def\gmlfonts; "" none *)
  tagset : string;  (** \def\gmltagset; "" none *)
  input : string;  (** the macro package, "gml" *)
  preamble : string;  (** after \input *)
  title_align : string;  (** SYSVART: right, left, center or "" *)
  extra_input : string list;  (** files \input after the package *)
}

let default_config =
  { fonts = ""; tagset = ""; input = "gml"; preamble = ""; title_align = ""; extra_input = [] }

let preamble c =
  let b = Buffer.create 256 in
  if c.fonts <> "" then Printf.bprintf b "\\def\\gmlfonts{%s}\n" c.fonts;
  if c.tagset <> "" then Printf.bprintf b "\\def\\gmltagset{%s}\n" c.tagset;
  Buffer.add_string b "\\def\\gmlmode{hints}\n";
  Printf.bprintf b "\\input %s\n" c.input;
  List.iter (Printf.bprintf b "\\input %s\n") c.extra_input;
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
  let st = create () in
  (match root with
  | Tree.Element (_, _, ch) -> List.iter (node st) ch
  | n -> node st n);
  stop st (* the root *);
  take ~all:true st

let document ?(config = default_config) root =
  preamble config ^ body root ^ postamble

(* ==== streaming ============================================================ *)

type level = {
  elt : Doc.open_elt;
  mutable done_ : int;  (** children written (counted from the oldest) *)
  mutable tdone : int;  (** bytes written of the child [done_], a growing text *)
  hoisted : bool;  (** provisional: written as an empty marker, its content after it *)
}

type stream = {
  doc : Doc.t;
  ser : st;
  mutable levels : level list;  (** entered, innermost first; the root last *)
  mutable warned : bool;
}

let stream ?(warn = ignore) doc =
  let ser = create () in
  ser.warn <- warn;
  let root = List.nth doc.Doc.stack (List.length doc.Doc.stack - 1) in
  let s =
    { doc; ser; levels = [ { elt = root; done_ = 0; tdone = 0; hoisted = false } ];
      warned = false }
  in
  (* [.ct] may change a child that has not been written: a growing text
     (child [done_], partly written) never has its trailing line end
     written ([emit_partial]); an element not entered has nothing written *)
  doc.Doc.sent <-
    (fun e i ->
      match List.find_opt (fun l -> l.elt == e) s.levels with
      | Some l -> i < l.done_
      | None -> false);
  s

(* the children of [l] not yet written, oldest first *)
let new_children l =
  let rec take k lst acc =
    if k <= 0 then acc else match lst with x :: r -> take (k - 1) r (x :: acc) | [] -> acc
  in
  take (l.elt.Doc.count - l.done_) l.elt.Doc.children []

let emit_complete s l n =
  (match n with
  | Tree.Text t when l.tdone > 0 ->
      text_part s.ser (String.sub t l.tdone (String.length t - l.tdone))
  | n -> node s.ser n);
  l.done_ <- l.done_ + 1;
  l.tdone <- 0

(* a growing text: up to its last line end that is followed by a non-blank *)
let emit_partial s l t =
  let n = String.length t in
  let rec find i = if i <= l.tdone then None
    else if t.[i - 1] = '\n' && i < n && not (is_ws_char t.[i]) then Some i
    else find (i - 1) in
  match find (n - 1) with
  | Some c ->
      text_part s.ser (String.sub t l.tdone (c - l.tdone));
      l.tdone <- c
  | None -> ()

let all_newlines s = String.for_all (( = ) '\n') s

(* will the open element path.(j) add a node to its parent? *)
let rec certain path j =
  let e = path.(j) in
  match e.Doc.kind with
  | Doc.Plain -> true
  | Doc.Scope _ -> (
      match e.Doc.children with
      | [] -> j + 1 < Array.length path && certain path (j + 1)
      | [ Tree.Text t ] -> not (all_newlines t)
      | _ -> true)

(* the text of an open heading so far (a query forced it out) *)
let rec live_plain path j =
  let e = path.(j) in
  let b = Buffer.create 64 in
  plain_nodes b (List.rev e.Doc.children);
  if j + 1 < Array.length path && not (List.mem path.(j + 1).Doc.name index_tags) then
    Buffer.add_string b (live_plain path (j + 1));
  Buffer.contents b

(** Write what is known of the document so far; returns the text that may go
    to TeX (complete lines).  [force] (a query): open elements are entered
    (a provisional one as an empty marker, a heading with the text it has so
    far) and holes followed by text are decided; without it only complete
    children of the entered elements are written.  [final]: after
    [Doc.finish], everything. *)
let flush ?(force = false) ?(final = false) s =
  let path = Array.of_list (List.rev s.doc.Doc.stack) in
  let lv = Array.of_list (List.rev s.levels) in
  let np = Array.length path and nl = Array.length lv in
  let k =
    let rec go i = if i < np && i < nl && lv.(i).elt == path.(i) then go (i + 1) else i in
    go 0
  in
  (* elements that left the stack, innermost first *)
  for j = nl - 1 downto k do
    let l = lv.(j) in
    let parent = lv.(j - 1) in
    let kids = new_children l in
    if l.hoisted && l.elt.Doc.contributed > 1 then begin
      (* its children are now the parent's, after the marker: a last text
         may still grow there, so it is handed over *)
      let n = List.length kids in
      List.iteri
        (fun i c ->
          match c with
          | Tree.Text _ when i = n - 1 -> ()
          | c -> emit_complete s l c)
        kids;
      let last_text =
        match l.elt.Doc.children with Tree.Text _ :: _ -> true | _ -> false
      in
      if last_text then begin
        parent.done_ <- parent.done_ + l.done_ + 1;
        parent.tdone <- l.tdone
      end
      else parent.done_ <- parent.done_ + l.elt.Doc.contributed
    end
    else begin
      List.iter (emit_complete s l) kids;
      if not l.hoisted then stop s.ser
      else if not s.warned then begin
        s.warned <- true;
        s.ser.warn
          (Printf.sprintf
             "layout: element %s was closed by its own end tag after it went \
              to TeX as an empty marker"
             l.elt.Doc.name)
      end;
      parent.done_ <- parent.done_ + max 0 l.elt.Doc.contributed
    end
  done;
  let levels = ref (List.filteri (fun i _ -> i < k) (Array.to_list lv)) in
  let rec descend i =
    let l = List.nth !levels (List.length !levels - 1) in
    let is_top = i = np - 1 in
    let kids = new_children l in
    let n = List.length kids in
    let child_certain = (not is_top) && certain path (i + 1) in
    List.iteri
      (fun idx c ->
        if idx < n - 1 || final then emit_complete s l c
        else
          match c with
          | Tree.Text t when is_top || not child_certain -> emit_partial s l t
          | _ -> emit_complete s l c)
      kids;
    if (not is_top) && force && l.done_ = l.elt.Doc.count && l.tdone = 0 then begin
      let e = path.(i + 1) in
      let enter =
        (not (e.Doc.name = "gml:rh" || e.Doc.name = "gml:rf"))
        && match e.Doc.kind with Doc.Scope _ -> certain path (i + 1) | Doc.Plain -> true
      in
      if enter then begin
        let hoisted = e.Doc.kind = Doc.Plain && e.Doc.provisional in
        if hoisted then node s.ser (Tree.Element (e.Doc.name, e.Doc.attrs, []))
        else begin
          let plain = if is_heading e.Doc.name then Some (live_plain path (i + 1)) else None in
          start s.ser ?plain e.Doc.name e.Doc.attrs
        end;
        levels := !levels @ [ { elt = e; done_ = 0; tdone = 0; hoisted } ];
        descend (i + 1)
      end
    end
  in
  descend (k - 1);
  s.levels <- List.rev !levels;
  if final then begin
    stop s.ser (* the root *);
    take ~all:true s.ser
  end
  else take ~force s.ser
