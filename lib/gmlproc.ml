(* GML processing (SH35-0069 Chapter 24): tag scanning in text lines,
   tag-to-APF mapping, the attribute stack and the residual text, and the
   control words [.gs] and [.aa].

   Scanning is off until [.gs tag on] (SH35-0069 p.287).  For each tag
   found in a text line (after symbol substitution of the whole line,
   residual text included, SH35-0050 p.10) the sequence of SH35-0069
   p.291 / SH35-0050 p.6 is followed:

   1. the attributes the previous tag left on the attribute stack are
      purged;
   2. attributes and value attributes are scanned as the rules allow
      ([Tagscan]); the scan goes on over the following lines of the same
      file or macro until the MCS, another tag, or text (p.289,
      SH35-0050 p.7); with neither att nor vat there is no scan;
   3. the residual text is identified: from the end of the markup up to
      the next tag or the end of the line, or the whole next line when
      the markup ended a line (SH35-0050 p.7);
   4. the APF is invoked (lookup, p.295: the explicit [.aa] mapping,
      then the class mapping [.gs prefix c] (APF c+name), then a macro
      or native control word named after the tag; for an end tag the
      [.aa] end APF, then c+"e"+name, then "e"+name — DCF-VERIFY: the
      direct APF name of an end tag).  Value attributes are its
      [&*1...], as written, with the count in [&*0] (p.293, SH35-0050
      p.9); named attributes stay on the attribute stack for
      [.gs exatt] / [.gs attval];
   5. the residual text, unless [.gs scan] took it, is processed as
      literal text (a Residual Lines frame, pushed below the APF), then
      the rest of the line, which starts with the next tag.

   Without an APF the tag is text, with an error message unless
   [.gs tag onno] (SH35-0050 p.8); [-undef-tags] can make it an element
   instead.  The lookup is done before the scan since the rules depend
   on [.aa]; the order is not observable otherwise.

   Our extension, the automatic element: before the APF runs, a start
   tag opens an element named after the tag, with its named attributes
   and value attributes (as name="name") as XML attributes, unless the
   rules say [noelem].  An end tag closes the element of that name and
   the elements opened inside it ([Doc.end_element ~force:true]) before
   its own APF runs; an end tag with no APF still closes its open
   element.  Implicit closes follow the [.xd] models ([Doc]).

   Line ends: a text line ends with "\n".  Text before a tag is emitted
   without one, so a tag in the middle of a word does not break it
   (p.294); the residual text then ends the line.  An empty residual
   ends the line only if text came before the tag on that line. *)

type apf =
  | Apf_macro of string * Macro.def
  | Apf_word of string * Ctx.word

(* ---- rules -------------------------------------------------------------- *)

let apply_rules (r : Ctx.rules) kws =
  List.fold_left
    (fun acc kw ->
       Result.bind acc (fun (r : Ctx.rules) ->
           match String.lowercase_ascii kw with
           | "att" -> Ok { r with att = true }
           | "noatt" -> Ok { r with att = false }
           | "vat" -> Ok { r with vat = true }
           | "novat" -> Ok { r with vat = false }
           | "stop" -> Ok { r with stop = true }
           | "step" -> Ok { r with stop = false }
           | "msg" -> Ok { r with msg = true }
           | "nomsg" -> Ok { r with msg = false }
           | "elem" -> Ok { r with elem = true }
           | "noelem" -> Ok { r with elem = false }
           | _ -> Error kw))
    (Ok r) kws

let rules_or_base base kws = Result.value (apply_rules base kws) ~default:base

(* ---- APF lookup ---------------------------------------------------------- *)

(* A macro or native control word named [name].  Macros are found
   whatever the setting of [.ms]: [.ms] governs macro substitution of
   control word lines (SH35-0069 p.271), while APFs are invoked by tag
   processing.  (The Starter Set profile turns .ms on anyway, SH35-0050
   p.21, so DCF documents cannot tell.)
   DCF-VERIFY: an APF macro under .ms off. *)
let find_named ctx name =
  match Macro.find ctx.Ctx.macros name with
  | Some m -> Some (Apf_macro (String.lowercase_ascii name, m))
  | None -> (
    let k = String.lowercase_ascii name in
    match Hashtbl.find_opt ctx.Ctx.words k with
    | Some w -> Some (Apf_word (k, w))
    | None -> None)

(** APF and rules for tag [name] (lowercase). *)
let lookup ctx ~is_end name =
  let base = if is_end then ctx.Ctx.end_rules else ctx.Ctx.tag_rules in
  let explicit, kws =
    match Hashtbl.find_opt ctx.Ctx.assocs name with
    | Some a -> if is_end then (a.Ctx.endapf, a.endrules) else (a.apf, a.arules)
    | None -> (None, [])
  in
  let rules = rules_or_base base kws in
  let apf =
    match explicit with
    | Some a -> find_named ctx a
    (* DCF-VERIFY: an explicit APF that does not exist is not replaced
       by the class or direct mapping *)
    | None -> (
      let dname = if is_end then "e" ^ name else name in
      let cls =
        Option.bind ctx.Ctx.prefix (fun c -> find_named ctx (String.make 1 c ^ dname))
      in
      match cls with Some _ -> cls | None -> find_named ctx dname)
  in
  (apf, rules)

(* ---- small helpers ------------------------------------------------------- *)

let is_blank_string s = String.for_all Tagscan.is_blank s

(* DCF-VERIFY: a line taken as markup continuation or residual text is
   substituted on its own, without the extended symbol rule. *)
let substitute ctx s = if ctx.Ctx.subst_on then Subst.string ctx s else s

let warn_on ctx = ctx.Ctx.tag_scan = Ctx.Tags_on

(* The tag as written, for messages. *)
let written s (f : Tagscan.found) = String.sub s f.at (f.after - f.at)

(* Can the next input line carry on the markup / be the residual text?
   It must be in the same frame, a text line (a control word ends the
   scan, p.289), not blank, and not start with a tag.  Decided on the raw
   line, so it is substituted only once it is taken. *)
let next_text_line ctx d =
  match Input.peek_in_frame ctx.Ctx.input with
  | None -> None
  | Some (raw, loc) -> (
    match Line.classify ctx.Ctx.chars raw with
    | Line.Control _ | Line.Comment _ | Line.Label _ -> None
    | Line.Text _ ->
      if is_blank_string raw then None
      (* DCF-VERIFY: a blank line ends the markup *)
      else if Tagscan.tag_at d raw (Tagscan.skip_blanks raw 0) <> None then None
      else begin
        ignore (Input.next_line ctx.Ctx.input);
        ctx.Ctx.loc <- loc;
        Some (substitute ctx raw)
      end)

(* ---- elements ------------------------------------------------------------ *)

let xml_attrs ctx tag named vats =
  let add acc (k, v) =
    if not (Tagscan.xml_name k) then begin
      Ctx.warn ctx "tag %s: attribute %s is not an XML name; left out of the element"
        tag k;
      acc
    end
    else List.remove_assoc k acc @ [ (k, v) ]
  in
  let named = List.map (fun (k, v) -> (String.lowercase_ascii k, v)) named in
  let vats =
    List.filter_map
      (fun w ->
         let k = String.lowercase_ascii w in
         if Tagscan.xml_name k then Some (k, w) else None)
      vats
  in
  List.fold_left add [] (named @ vats)

let open_auto ctx name named vats =
  if Tagscan.xml_name name then
    Doc.start_element ctx.Ctx.doc name (xml_attrs ctx name named vats)
  else Ctx.warn ctx "tag %s is not an XML name; no element" name

(* Would the start tag [name] open an element? *)
let opens_element ctx name =
  match lookup ctx ~is_end:false name with
  | Some _, r -> r.Ctx.elem
  | None, _ -> false

(* An end tag closes the element of its name — unless the start tag
   does not open elements ([noelem]): then an element of that name was
   made by the APFs ([.xs]) and is theirs to close.  An end tag without
   APF always closes. *)
let close_auto ctx src name ~has_apf =
  if has_apf && not (opens_element ctx name) then ()
  else
  match Doc.end_element ~force:true ctx.Ctx.doc name with
  | Doc.Closed forced ->
    List.iter
      (fun n -> Ctx.warn ctx "element %s implicitly closed by end tag %s" n src)
      forced
  | Doc.Mismatch _ -> ()
  | Doc.Not_open -> Ctx.warn ctx "end tag %s: element %s is not open" src name

(* ---- APF invocation ------------------------------------------------------ *)

let vat_scope vats =
  let scope = Symbols.new_scope () in
  Symbols.set_in scope "*" (String.concat " " vats);
  List.iteri (fun i v -> Symbols.set_in scope ("*" ^ string_of_int (i + 1)) v) vats;
  Symbols.set_in scope "*0" (string_of_int (List.length vats));
  scope

(* DCF-VERIFY: a native control word as APF receives the value
   attributes as its operands. *)
let invoke_apf ctx apf args =
  match apf with
  | Apf_macro (name, m) -> Control.invoke_in ctx name m (vat_scope args)
  | Apf_word (_, w) -> w.Ctx.run ctx (String.concat " " args)

(* Schedule [apf] with [args] to run before the next input line (for
   .gs exatt, where several calls are queued; pushed in reverse). *)
let schedule_apf ctx apf args =
  match apf with
  | Apf_macro _ -> invoke_apf ctx apf args
  | Apf_word (name, _) ->
    let ch = ctx.Ctx.chars in
    let line = Printf.sprintf "%c'%s %s" ch.Chars.cw_ind name (String.concat " " args) in
    Input.push_lines ~kind:(Input.Split true) ctx.input [ (line, ctx.loc) ]

(* ---- text lines ------------------------------------------------------------ *)

type decision =
  | As_text
  | Tag of Tagscan.found * apf option * Ctx.rules

let undefined ctx s (f : Tagscan.found) rules =
  let src = written s f in
  match ctx.Ctx.undef_tags with
  | Ctx.Undef_text ->
    (* an error message and the tag is text (SH35-0050 p.8; SH35-0069
       p.295 says a warning); none under .gs tag onno (p.295) *)
    if warn_on ctx then Ctx.error ctx "no APF for tag %s; treated as text" src;
    As_text
  | Ctx.Undef_error -> Ctx.error ctx "no APF for tag %s" src; As_text
  (* also under .gs tag onno *)
  | Ctx.Undef_element ->
    if warn_on ctx then Ctx.warn ctx "no APF for tag %s; emitted as an element" src;
    Tag (f, None, rules)

(* With a two-character end-tag delimiter such as ":e", every name after
   it is an end tag (SH35-0050 p.6): there is no fallback to a start tag
   "e...". *)
let decide ctx s (f : Tagscan.found) =
  match lookup ctx ~is_end:f.is_end f.name with
  | (Some _ as apf), rules -> Tag (f, apf, rules)
  | None, rules ->
    if f.is_end && Doc.is_open ctx.Ctx.doc f.name then Tag (f, None, rules)
    else undefined ctx s f rules

(* The end of a piece of text: [eol] if it ends its input line, then
   with "\n" — always for a [plain] input line, otherwise if it is not
   empty or text came before the tag on that line. *)
let final ctx ~plain (p : Input.piece) seg =
  if not p.eol then Doc.text_inline ctx.Ctx.doc seg
  else if plain || seg <> "" || p.had_text then Doc.text ctx.Ctx.doc seg
  else Doc.end_line ctx.Ctx.doc

(** Process text (already substituted): an input line ([plain]), or a
    piece of one after a tag (see [Input.piece]). *)
let rec text ctx ~plain (p : Input.piece) s =
  let d =
    if ctx.Ctx.tag_scan = Ctx.Tags_off then None else Tagscan.delims_of ctx.Ctx.chars
  in
  match d with
  | None -> final ctx ~plain p s
  | Some d -> scan ctx d ~plain p s 0 0

and scan ctx d ~plain p s start pos =
  match Tagscan.find_tag d s pos with
  | None -> final ctx ~plain p (String.sub s start (String.length s - start))
  | Some f -> (
    match decide ctx s f with
    | As_text -> scan ctx d ~plain p s start f.after
    | Tag (f, apf, rules) ->
      let before = String.sub s start (f.at - start) in
      Doc.text_inline ctx.Ctx.doc before;
      tag ctx d f apf rules s ~eol:p.eol
        ~had_text:(p.had_text || not (is_blank_string before)))

(* The markup of tag [f] (from [f.after] on line [s]): its attributes,
   what follows the markup on the line where it ends, and whether the
   markup ended that line. *)
and markup ctx d (f : Tagscan.found) (rules : Ctx.rules) s =
  let src = written s f in
  let rest s k = String.sub s k (String.length s - k) in
  if not (rules.att || rules.vat) then begin
    (* no attributes: no scan, all after the name (and its MCS) is
       residual text (SH35-0050 p.6) *)
    let k = f.after in
    let k = if k < String.length s && s.[k] = d.Tagscan.mcs then k + 1 else k in
    ([], rest s k, k = String.length s)
  end
  else begin
    let rec go s i acc =
      let r = Tagscan.attributes d ~att:rules.att ~vat:rules.vat ~stop:rules.stop s i in
      if rules.msg then
        List.iter
          (fun a ->
             Ctx.warn ctx "tag %s: invalid attribute %s%s" src a
               (if rules.stop then " (treated as text)" else " (ignored)"))
          r.invalid;
      let acc = acc @ r.attrs in
      match r.stop with
      | Tagscan.Eol -> (
        (* the scan goes on over the following lines (p.289) *)
        match next_text_line ctx d with
        | Some s2 -> go s2 0 acc
        | None -> (acc, "", true))
      | Tagscan.Mcs k -> (acc, rest s k, k = String.length s)
      | Tagscan.Next_tag k | Tagscan.Invalid k -> (acc, rest s k, false)
    in
    go s f.after []
  end

and tag ctx d (f : Tagscan.found) apf (rules : Ctx.rules) s ~had_text ~eol =
  let src = written s f in
  (* 1. purge the attribute stack *)
  ctx.Ctx.gml_attrs <- [];
  (* 2. attributes *)
  let attrs, after, at_eol = markup ctx d f rules s in
  (* 3. residual text: up to the next tag or the end of the line; the
     whole next line if the markup ended a line (SH35-0050 p.7) *)
  let after, had_text =
    if after = "" && at_eol && not had_text then
      match next_text_line ctx d with
      | Some l -> (l, false)
      | None -> ("", false)
    else (after, had_text)
  in
  let residual, remainder =
    match Tagscan.find_tag d after 0 with
    | Some n ->
      (String.sub after 0 n.at, Some (String.sub after n.at (String.length after - n.at)))
    | None -> (after, None)
  in
  let named = List.filter_map (function Tagscan.Named (k, v) -> Some (k, v) | _ -> None) attrs in
  let vats = List.filter_map (function Tagscan.Vat w -> Some w | _ -> None) attrs in
  ctx.gml_attrs <- named;
  (* our automatic element *)
  (* an end tag whose rules say noelem leaves the element to its APF
     ([.xe]), so that the APF's output can still go inside it *)
  if f.is_end then (if rules.elem then close_auto ctx src f.name ~has_apf:(apf <> None))
  else if rules.elem then open_auto ctx f.name named vats;
  ctx.last_tag <-
    String.sub s (f.after - String.length f.name) (String.length f.name);
  ctx.last_tagd <-
    (if f.is_end then ctx.chars.Chars.gml_end
     else Ctx.char_value ctx.chars.Chars.gml_delim);
  (* the rest of the line after the residual text, then the residual
     text, are processed after the APF *)
  Option.iter
    (fun r ->
       ignore
         (Input.push_residual ctx.input r ctx.loc
            { Input.had_text = had_text || not (is_blank_string residual); eol }))
    remainder;
  ctx.residual <-
    Some (Input.push_residual ctx.input residual ctx.loc
            { Input.had_text; eol = eol && remainder = None });
  (* 4. the APF *)
  Option.iter (fun a -> invoke_apf ctx a vats) apf

(* ---- control words --------------------------------------------------------- *)

let words = Control.words

(* Words and parenthesised groups: "a (b c) d" -> [W a; G [b; c]; W d]. *)
type item = W of string | G of string list

let items s =
  let n = String.length s in
  let rec go i acc =
    let i = Tagscan.skip_blanks s i in
    if i >= n then Ok (List.rev acc)
    else if s.[i] = '(' then
      match String.index_from_opt s i ')' with
      | None -> Error "missing )"
      | Some e -> go (e + 1) (G (words (String.sub s (i + 1) (e - i - 1))) :: acc)
    else begin
      let j = ref i in
      while !j < n && not (Tagscan.is_blank s.[!j]) && s.[!j] <> '(' do incr j done;
      go !j (W (String.sub s i (!j - i)) :: acc)
    end
  in
  go 0 []

let check_rules ctx cw g k =
  match apply_rules ctx.Ctx.tag_rules g with
  | Ok _ -> k ()
  | Error kw -> Ctx.error ctx ".%s: unknown rule %s" cw kw

let valid_tag_name t =
  match Tagscan.tag_name t 0 with Some j -> j = String.length t | None -> false

(* .aa tag [apf] [(rules)] [endapf] [(rules)]   (p.291, p.295)
   .aa tag alone removes the association (DCF-VERIFY). *)
let aa ctx ops =
  match items ops with
  | Error e -> Ctx.error ctx ".aa: %s" e
  | Ok [] -> Ctx.error ctx ".aa: tag name required"
  | Ok (G _ :: _) -> Ctx.error ctx ".aa: tag name required"
  | Ok (W t :: rest) ->
    if not (valid_tag_name t) then Ctx.error ctx ".aa: invalid tag name %s" t
    else begin
      let key = String.lowercase_ascii t in
      let take_w = function W a :: r -> (Some a, r) | r -> (None, r) in
      let take_g = function G g :: r -> (g, r) | r -> ([], r) in
      let apf, r = take_w rest in
      let arules, r = take_g r in
      let endapf, r = take_w r in
      let endrules, r = take_g r in
      if r <> [] then Ctx.error ctx ".aa %s: too many operands" t
      else if rest = [] then Hashtbl.remove ctx.Ctx.assocs key
      else
        check_rules ctx "aa" arules (fun () ->
            check_rules ctx "aa" endrules (fun () ->
                Hashtbl.replace ctx.Ctx.assocs key
                  { Ctx.apf; arules; endapf; endrules }))
    end

(* .gs rules (tag rules) (end-tag rules) (p.291).  The keywords change
   the current rules one by one (DCF-VERIFY: unnamed rules keep their
   setting). *)
let gs_rules ctx ops =
  match items ops with
  | Error e -> Ctx.error ctx ".gs rules: %s" e
  | Ok its ->
    let groups = List.filter_map (function G g -> Some g | W _ -> None) its in
    if List.exists (function W _ -> true | G _ -> false) its || groups = []
       || List.length groups > 2
    then Ctx.error ctx ".gs rules: (tag rules) [(end-tag rules)] expected"
    else begin
      let set get put g =
        match apply_rules (get ()) g with
        | Ok r -> put r
        | Error kw -> Ctx.error ctx ".gs rules: unknown rule %s" kw
      in
      (match groups with
       | g :: _ -> set (fun () -> ctx.Ctx.tag_rules) (fun r -> ctx.Ctx.tag_rules <- r) g
       | [] -> ());
      match groups with
      | [ _; g ] -> set (fun () -> ctx.Ctx.end_rules) (fun r -> ctx.Ctx.end_rules <- r) g
      | _ -> ()
    end

(* "name [as x] name [as x] ..." *)
let rec name_as = function
  | [] -> []
  | n :: a :: x :: rest when String.lowercase_ascii a = "as" -> (n, Some x) :: name_as rest
  | n :: rest -> (n, None) :: name_as rest

(* .gs exatt [name [as apf]] ...: process stacked attributes by their
   APFs, the value as &*1 (p.292-293).  Processed attributes leave the
   stack (DCF-VERIFY). *)
let exatt ctx args =
  let stack = ctx.Ctx.gml_attrs in
  let selected =
    match name_as args with
    | [] -> List.map (fun (k, _) -> (k, None)) stack
    | l -> List.map (fun (k, a) -> (String.uppercase_ascii k, a)) l
  in
  let calls =
    List.filter_map
      (fun (k, a) ->
         match List.assoc_opt k stack with
         | None -> None   (* not specified: skipped (p.293) *)
         | Some v -> (
           let lk = String.lowercase_ascii k in
           let name = Option.value a ~default:lk in
           match find_named ctx name with
           | Some apf -> Some (k, apf, v)
           | None ->
             (* a message (SH35-0050 p.9) *)
             Ctx.warn ctx ".gs exatt: no APF %s for attribute %s" name lk;
             None))
      selected
  in
  ctx.gml_attrs <-
    List.filter (fun (k, _) -> not (List.exists (fun (k', _, _) -> k' = k) calls)) stack;
  List.iter (fun (_, apf, v) -> schedule_apf ctx apf [ v ]) (List.rev calls)

(* .gs attval name [as sym] ...: the symbol &NAME, the attribute name in
   upper case, gets the value; a symbol given with AS is used exactly as
   written, not folded (p.293; symbol names are case-sensitive, p.239).
   DCF-VERIFY: an attribute that was not specified sets the null
   string. *)
let attval ctx args =
  List.iter
    (fun (k, a) ->
       let v = Option.value (List.assoc_opt (String.uppercase_ascii k) ctx.Ctx.gml_attrs)
           ~default:"" in
       let sym = Option.value a ~default:(String.uppercase_ascii k) in
       match Symbols.set ctx.Ctx.syms sym v with
       | Ok () -> ()
       | Error e -> Ctx.error ctx ".gs attval: %s" e)
    (name_as args)

(* The residual text of the current tag, if not yet processed. *)
let residual ctx =
  match ctx.Ctx.residual with
  | Some l when l.Input.pos = 0 -> Some l
  | _ -> None

let set_sym ctx cw sym v =
  match Symbols.set ctx.Ctx.syms sym v with
  | Ok () -> ()
  | Error e -> Ctx.error ctx ".gs %s: %s" cw e

(* .gs scan sym / .gs copy sym (p.294).  DCF-VERIFY: with no residual
   text the symbol gets the null string. *)
let scan_copy ctx cw ~remove args =
  match args with
  | [ sym ] -> (
    match residual ctx with
    | Some l ->
      let t, loc, k = l.Input.src.(0) in
      set_sym ctx cw sym t;
      if remove then l.src.(0) <- ("", loc, k)
    | None -> set_sym ctx cw sym "")
  | _ -> Ctx.error ctx ".gs %s: one symbol name expected" cw

(* .gs insert text: before the residual text, with continuation (no
   blank is added) (p.295).  DCF-VERIFY. *)
let insert ctx text =
  match residual ctx with
  | Some l ->
    let t, loc, k = l.Input.src.(0) in
    l.src.(0) <- (text ^ t, loc, k)
  | None -> Ctx.warn ctx ".gs insert: no residual text to insert before"

(* The operand string after the first word. *)
let after_word s =
  let i = Tagscan.skip_blanks s 0 in
  let n = String.length s in
  let j = ref i in
  while !j < n && not (Tagscan.is_blank s.[!j]) do incr j done;
  let k = if !j < n then !j + 1 else !j in
  String.sub s k (n - k)

let gs ctx ops =
  match words ops with
  | [] -> Ctx.error ctx ".gs: service required"
  | w :: args -> (
    match (String.lowercase_ascii w, List.map String.lowercase_ascii args) with
    | "tag", [ "on" ] -> ctx.Ctx.tag_scan <- Ctx.Tags_on
    | "tag", [ "onno" ] -> ctx.tag_scan <- Ctx.Tags_onno
    | "tag", [ "off" ] -> ctx.tag_scan <- Ctx.Tags_off
    | "tag", _ -> Ctx.error ctx ".gs tag: ON, ONNO or OFF expected"
    | "rules", _ -> gs_rules ctx (after_word ops)
    | "prefix", ([] | [ "off" ]) -> ctx.prefix <- None
    (* DCF-VERIFY: .gs prefix without operand / OFF ends class mapping *)
    | "prefix", [ c ] when String.length c = 1 -> ctx.prefix <- Some c.[0]
    | "prefix", _ -> Ctx.error ctx ".gs prefix: one character expected"
    | "exatt", _ -> exatt ctx args
    | "attval", _ ->
      if args = [] then Ctx.error ctx ".gs attval: attribute name expected"
      else attval ctx args
    | "scan", _ -> scan_copy ctx "scan" ~remove:true args
    | "copy", _ -> scan_copy ctx "copy" ~remove:false args
    | "insert", _ -> insert ctx (after_word ops)
    | s, _ -> Ctx.warn ctx "unsupported .gs service %s" s)

let install ctx =
  Ctx.register ctx "gs" gs;
  Ctx.register ctx "aa" aa
