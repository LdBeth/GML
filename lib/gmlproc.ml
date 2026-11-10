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
      SH35-0050 p.7); under NOATT there is no scan (LR p.186);
   3. the residual text is identified: from the end of the markup up to
      the next tag or the end of the line, or the whole next line when
      the markup ended a line (SH35-0050 p.7);
   4. the APF is invoked (lookup, p.295: the explicit [.aa] mapping,
      else the class mapping [.gs prefix c e] (LR p.187): APF c+name
      for a start tag, e+name for an end tag, a macro or a native
      control word).  Value attributes are its
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
  | Apf_null  (** [.aa tag NULL]: no processing (LR p.62) *)

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
          | "nostop" -> Ok { r with stop = false }
          | "msg" -> Ok { r with msg = true }
          | "nomsg" -> Ok { r with msg = false }
          | "elem" -> Ok { r with elem = true }
          | "noelem" -> Ok { r with elem = false }
          | _ -> Error kw))
    (Ok r) kws

let rules_or_base base kws = Result.value (apply_rules base kws) ~default:base

(* The default rules (ATT NOVAT STOP NOMSG) (NOATT), LR p.186, with our
   [elem]. *)
let default_tag_rules =
  { Ctx.att = true; vat = false; stop = true; msg = false; elem = true }

let default_end_rules = { default_tag_rules with Ctx.att = false }

(* The four rules of LR p.186 as keywords: they fix a rule set whatever
   rules they are applied over (our [elem] aside). *)
let dcf_keywords (r : Ctx.rules) =
  [
    (if r.att then "att" else "noatt");
    (if r.vat then "vat" else "novat");
    (if r.stop then "stop" else "nostop");
    (if r.msg then "msg" else "nomsg");
  ]

let is_elem_kw k =
  match String.lowercase_ascii k with "elem" | "noelem" -> true | _ -> false

(* ---- class mapping: .gs prefix ------------------------------------------- *)

(* The start-tag and end-tag prefixes of [.gs prefix] (LR p.187), None
   for OFF ([Ctx.gs_prefix]).  EXT: the initial setting, not in LR
   Rel 4, is the direct mapping: start tag x to APF x, end tag x to APF
   ex. *)
let prefixes ctx = ctx.Ctx.gs_prefix
let set_prefixes ctx v = ctx.Ctx.gs_prefix <- v

(* ---- APF lookup ---------------------------------------------------------- *)

(* A macro or native control word named [name].  Macros are found
   whatever the setting of [.ms]: [.ms] governs macro substitution of
   control word lines (SH35-0069 p.271), while APFs are invoked by tag
   processing.  (The Starter Set profile turns .ms on anyway, SH35-0050
   p.21, so DCF documents cannot tell.)
   DCF-VERIFY (not in LR Rel 4): an APF macro under .ms off. *)
let find_named ctx name =
  match Macro.find ctx.Ctx.macros name with
  | Some m -> Some (Apf_macro (String.lowercase_ascii name, m))
  | None -> (
      let k = String.lowercase_ascii name in
      match Hashtbl.find_opt ctx.Ctx.words k with
      | Some w -> Some (Apf_word (k, w))
      | None ->
          (* neither a macro nor native: the macro library, with .ly on|mac
         ([Library]); an [.aa] APF of the Starter Set comes from there *)
          Option.map (fun m -> Apf_macro (k, m)) (Library.find_macro ctx name))

(* The [.aa] association of one side of tag [name]: the explicit APF
   (None: class mapping; "." NULL) and its rule keywords ([]: the
   current [.gs rules]). *)
let assoc_side ctx ~is_end name =
  match Hashtbl.find_opt ctx.Ctx.assocs name with
  | Some a -> if is_end then (a.Ctx.endapf, a.endrules) else (a.apf, a.arules)
  | None -> (None, [])

(** APF and rules for tag [name] (lowercase). *)
let lookup ctx ~is_end name =
  let base = if is_end then ctx.Ctx.end_rules else ctx.Ctx.tag_rules in
  let explicit, kws = assoc_side ctx ~is_end name in
  let rules = rules_or_base base kws in
  let apf =
    match explicit with
    | Some "." -> Some Apf_null
    | Some a -> find_named ctx a
    (* DCF-VERIFY (not in LR Rel 4): an explicit APF that does not exist
       is not replaced by the class mapping *)
    | None ->
        let st, en = prefixes ctx in
        Option.bind
          (if is_end then en else st)
          (fun c -> find_named ctx (c ^ name))
  in
  (apf, rules)

(* ---- small helpers ------------------------------------------------------- *)

let is_blank_string s = String.for_all Tagscan.is_blank s

(* DCF-VERIFY (not in LR Rel 4): a line taken as markup continuation or
   residual text is substituted on its own, without the extended symbol
   rule. *)
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
          if is_blank_string raw then
            None
            (* DCF-VERIFY (not in LR Rel 4): a blank line ends the markup *)
          else if Tagscan.tag_at d raw (Tagscan.skip_blanks raw 0) <> None then
            None
          else begin
            ignore (Input.next_line ctx.Ctx.input);
            ctx.Ctx.loc <- loc;
            Some (substitute ctx raw)
          end)

(* ---- elements ------------------------------------------------------------ *)

let xml_attrs ctx tag named vats =
  let keep (k, _) =
    Tagscan.xml_name k
    || begin
      Ctx.warn ctx
        "tag %s: attribute %s is not an XML name; left out of the element" tag k;
      false
    end
  in
  let named = List.map (fun (k, v) -> (String.lowercase_ascii k, v)) named in
  let vats =
    List.filter_map
      (fun w ->
        let k = String.lowercase_ascii w in
        if Tagscan.xml_name k then Some (k, w) else None)
      vats
  in
  Tagscan.last_wins (List.filter keep (named @ vats))

(* A tag with no end tag ([.aa] gives no end APF, there is no direct
   one, so DCF would reject [:eX]) and no [.xd] model has nothing that
   could close its element: IBM's profile has no models, and its :figref,
   :p, :li, :dt ... would hold the rest of the document.  Such an element
   is provisional ([Doc.start_element]): if an end tag closes it after
   all (our extension, as before), it holds what came between; if it is
   closed otherwise (by an enclosing end tag, at the end of the input),
   it is left empty, a marker, and the APF's output and the text follow
   it.  EXT: the automatic element. *)
let no_end ctx name =
  match Hashtbl.find_opt ctx.Ctx.assocs name with
  | Some { Ctx.endapf = None; _ } ->
      not
        (Doc.has_model ctx.Ctx.doc name
        || Doc.closable ctx.Ctx.doc name
        || fst (lookup ctx ~is_end:true name) <> None)
  | _ -> false

let open_auto ctx name named vats =
  if Tagscan.xml_name name then
    Doc.start_element ~provisional:(no_end ctx name) ctx.Ctx.doc name
      (xml_attrs ctx name named vats)
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
          (fun n ->
            Ctx.warn ctx "element %s implicitly closed by end tag %s" n src)
          forced
    | Doc.Mismatch _ -> ()
    | Doc.Not_open -> Ctx.warn ctx "end tag %s: element %s is not open" src name

(* An end tag with an APF closes its element after the APF when a flow
   (.fn, .rh, .rf: gml:fn ...) is open inside it: the APF ends the flow
   (IBM's DSMEFTNT: ".fn off"), so the element is closed by a [.xe] run
   after it.  Otherwise the end tag closes it before its APF runs. *)
let flow_inside ctx name =
  let rec go = function
    | n :: _ when n = name -> false
    | ("gml:fn" | "gml:rh" | "gml:rf") :: _ -> true
    | _ :: rest -> go rest
    | [] -> false
  in
  Doc.is_open ctx.Ctx.doc name && go (Doc.open_elements ctx.Ctx.doc)

(* ---- APF invocation ------------------------------------------------------ *)

let vat_scope vats =
  let scope = Symbols.new_scope () in
  Macro.bind_args_list scope (String.concat " " vats) vats;
  scope

(* A native control word as APF receives the value attributes as its
   operands (LR p.62: an APF is a macro or control word; p.186). *)
let invoke_apf ctx apf args =
  match apf with
  | Apf_macro (name, m) -> Control.invoke_in ctx name m (vat_scope args)
  | Apf_word (_, w) -> w.Ctx.run ctx (String.concat " " args)
  | Apf_null -> ()

(* Schedule [apf] with [args] to run before the next input line (for
   .gs exatt, where several calls are queued; pushed in reverse). *)
let schedule_apf ctx apf args =
  match apf with
  | Apf_macro _ | Apf_null -> invoke_apf ctx apf args
  | Apf_word (name, _) ->
      let ch = ctx.Ctx.chars in
      let line =
        Printf.sprintf "%c'%s %s" ch.Chars.cw_ind name (String.concat " " args)
      in
      Input.push_lines ~kind:(Input.Split true) ctx.input [ (line, ctx.loc) ]

(* ---- text lines ------------------------------------------------------------ *)

(* The messages of an attribute scan: invalid attributes under MSG, and
   unquoted values that are not a word of name characters (taken all
   the same: EXT). *)
let scan_messages ctx what (rules : Ctx.rules) (r : Tagscan.result) =
  if rules.msg then
    List.iter
      (fun a ->
        Ctx.warn ctx "%s: invalid attribute %s%s" what a
          (if rules.stop then " (treated as text)" else " (ignored)"))
      r.invalid;
  List.iter
    (fun a -> Ctx.warn ctx "%s: value of %s should be quoted (LR p.186)" what a)
    r.lax

type decision = As_text | Tag of Tagscan.found * apf option * Ctx.rules

let undefined ctx s (f : Tagscan.found) rules =
  let src = written s f in
  match ctx.Ctx.undef_tags with
  | Ctx.Undef_text ->
      (* an error message and the tag is text (SH35-0050 p.8; SH35-0069
       p.295 says a warning); none under .gs tag onno (p.295) *)
      if warn_on ctx then Ctx.error ctx "no APF for tag %s; treated as text" src;
      As_text
  | Ctx.Undef_error ->
      Ctx.error ctx "no APF for tag %s" src;
      As_text
  (* also under .gs tag onno *)
  | Ctx.Undef_element ->
      if warn_on ctx then
        Ctx.warn ctx "no APF for tag %s; emitted as an element" src;
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

(** Process text (already substituted): an input line ([plain]), or a piece of
    one after a tag (see [Input.piece]). *)
let rec text ctx ~plain (p : Input.piece) s =
  let d =
    if ctx.Ctx.tag_scan = Ctx.Tags_off then None
    else Tagscan.delims_of ctx.Ctx.chars
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
  if not rules.att then begin
    (* NOATT: no scan, the other rules are immaterial; all after the
       name (and its MCS) is residual text (LR p.186, SH35-0050 p.6) *)
    let k = f.after in
    let k = if k < String.length s && s.[k] = d.Tagscan.mcs then k + 1 else k in
    ([], rest s k, k = String.length s)
  end
  else begin
    let rec go s i acc =
      let r =
        Tagscan.attributes d ~att:rules.att ~vat:rules.vat ~stop:rules.stop s i
      in
      scan_messages ctx ("tag " ^ src) rules r;
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
      (Option.value (next_text_line ctx d) ~default:"", false)
    else (after, had_text)
  in
  let residual, remainder =
    match Tagscan.find_tag d after 0 with
    | Some n ->
        ( String.sub after 0 n.at,
          Some (String.sub after n.at (String.length after - n.at)) )
    | None -> (after, None)
  in
  let named, vats =
    List.partition_map
      (function
        | Tagscan.Named (k, v) -> Either.Left (k, v)
        | Tagscan.Vat w -> Either.Right w)
      attrs
  in
  ctx.gml_attrs <- named;
  (* our automatic element *)
  (* an end tag whose rules say noelem leaves the element to its APF
     ([.xe]), so that the APF's output can still go inside it *)
  let deferred =
    f.is_end && rules.elem && apf <> None && flow_inside ctx f.name
  in
  if f.is_end then (
    if rules.elem && not deferred then
      close_auto ctx src f.name ~has_apf:(apf <> None))
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
    Some
      (Input.push_residual ctx.input residual ctx.loc
         { Input.had_text; eol = eol && remainder = None });
  if deferred then
    Input.push_lines ~kind:(Input.Split true) ctx.input
      [ (Printf.sprintf "%c'xe %s" ctx.chars.Chars.cw_ind f.name, ctx.loc) ];
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
      | Some e ->
          go (e + 1) (G (words (String.sub s (i + 1) (e - i - 1))) :: acc)
    else begin
      let j = ref i in
      while !j < n && (not (Tagscan.is_blank s.[!j])) && s.[!j] <> '(' do
        incr j
      done;
      go !j (W (String.sub s i (!j - i)) :: acc)
    end
  in
  go 0 []

let check_rules ctx cw g k =
  match apply_rules ctx.Ctx.tag_rules g with
  | Ok _ -> k ()
  | Error kw -> Ctx.error ctx ".%s: unknown rule %s" cw kw

let valid_tag_name t =
  match Tagscan.tag_name t 0 with
  | Some j -> j = String.length t
  | None -> false

(* The APF operand of one side of [.aa] (LR p.62). *)
type apf_op = Omitted | Off | Null | Keep | Name of string

let take_apf = function
  | W a :: r ->
      ( (match String.lowercase_ascii a with
        | "off" -> Off
        | "null" | "." -> Null
        | "=" -> Keep
        | _ -> Name a),
        r )
  | r -> (Omitted, r)

let take_rules = function G g :: r -> (Some g, r) | r -> (None, r)

(* One side of an association from the old one [(apf, kws)], the APF
   operand and the rules list [g] (None: not given).  The rules are
   frozen as keywords: an association keeps them when [.gs rules]
   changes (LR p.63 r2).  A list is applied over the current rules [cur],
   () is the current rules (r4); without a list a new APF keeps the old
   rules (r3), or takes the current ones the first time (r4).  OFF
   deletes the association: the class mapping applies (p.62).
   EXT: [elem] is frozen only when written, and a new APF without rules
   drops it (the profiles' [.aa li ss@cntx (noelem)], [.aa li dsmlitem]).
   EXT: rules with no APF apply to the class mapping ([.aa ol (vat)]).
   DCF-VERIFY (not in LR Rel 4): an omitted side is deleted. *)
let aa_side cur (old_apf, old_kws) op g =
  let freeze g =
    dcf_keywords (rules_or_base cur g) @ List.filter is_elem_kw g
  in
  let rules () =
    match g with
    | Some g -> freeze g
    | None when old_kws = [] -> freeze []
    | None -> List.filter (fun k -> not (is_elem_kw k)) old_kws
  in
  match op with
  | Off -> (None, [])
  | Omitted -> (None, Option.fold ~none:[] ~some:freeze g)
  | Keep -> (old_apf, Option.fold ~none:old_kws ~some:freeze g)
  | Null -> (Some ".", rules ())
  | Name a -> (Some a, rules ())

(* .aa tag [apf (rules)] [endapf (rules)], each APF a name, OFF, NULL,
   '.' or '=' (LR p.62-63).
   DCF-VERIFY (not in LR Rel 4): .aa tag alone removes the association. *)
let aa ctx ops =
  match items ops with
  | Error e -> Ctx.error ctx ".aa: %s" e
  | Ok ([] | G _ :: _) -> Ctx.error ctx ".aa: tag name required"
  | Ok (W t :: rest) ->
      if not (valid_tag_name t) then Ctx.error ctx ".aa: invalid tag name %s" t
      else begin
        let key = String.lowercase_ascii t in
        let op, r = take_apf rest in
        let g, r = take_rules r in
        let eop, r = take_apf r in
        let eg, r = take_rules r in
        let opt = Option.value ~default:[] in
        if r <> [] then Ctx.error ctx ".aa %s: too many operands" t
        else if rest = [] then Hashtbl.remove ctx.Ctx.assocs key
        else
          check_rules ctx "aa" (opt g) (fun () ->
              check_rules ctx "aa" (opt eg) (fun () ->
                  let side is_end = assoc_side ctx ~is_end key in
                  let apf, arules = aa_side ctx.tag_rules (side false) op g in
                  let endapf, endrules =
                    aa_side ctx.end_rules (side true) eop eg
                  in
                  if apf = None && arules = [] && endapf = None && endrules = []
                  then Hashtbl.remove ctx.assocs key
                  else
                    Hashtbl.replace ctx.assocs key
                      { Ctx.apf; arules; endapf; endrules }))
      end

(* .gs rules [(tag rules) | =] [(end-tag rules) | =] (LR p.185-186): =
   leaves a set unchanged, () restores its default.  DCF-VERIFY (not in
   LR Rel 4): the keywords change the current rules one by one, unnamed
   rules keep their setting. *)
let gs_rules ctx ops =
  match items ops with
  | Error e -> Ctx.error ctx ".gs rules: %s" e
  | Ok its -> (
      if
        List.length its > 2
        || List.exists (function W w -> w <> "=" | G _ -> false) its
      then Ctx.error ctx ".gs rules: (tag rules) [(end-tag rules)] expected"
      else
        let bad =
          List.find_map
            (function
              | G g -> (
                  match apply_rules ctx.Ctx.tag_rules g with
                  | Error kw -> Some kw
                  | Ok _ -> None)
              | W _ -> None)
            its
        in
        match bad with
        | Some kw -> Ctx.error ctx ".gs rules: unknown rule %s" kw
        | None ->
            let set cur def = function
              | W _ -> cur
              | G [] -> def
              | G g -> rules_or_base cur g
            in
            List.iteri
              (fun i it ->
                if i = 0 then
                  ctx.Ctx.tag_rules <- set ctx.tag_rules default_tag_rules it
                else ctx.end_rules <- set ctx.end_rules default_end_rules it)
              its)

(* "name [as x] name [as x] ..." *)
let rec name_as = function
  | [] -> []
  | n :: a :: x :: rest when String.lowercase_ascii a = "as" ->
      (n, Some x) :: name_as rest
  | n :: rest -> (n, None) :: name_as rest

(* The stacked attributes named by "[NOT] name [AS x] ..." (LR p.184):
   (name, AS, value), in the order of the list (each occurrence in the
   order written; [absent]: a name not on the stack once, with the null
   string), else in the order of the stack.  No names: all of them. *)
let selected ?(absent = false) ctx args =
  let stack = ctx.Ctx.gml_attrs in
  let all p =
    List.filter_map
      (fun (k, v) -> if p k then Some (k, None, v) else None)
      stack
  in
  match args with
  | [] -> all (fun _ -> true)
  | n :: rest when String.lowercase_ascii n = "not" ->
      let l = List.map String.uppercase_ascii rest in
      all (fun k -> not (List.mem k l))
  | l ->
      let l =
        List.map (fun (k, a) -> (String.uppercase_ascii k, a)) (name_as l)
      in
      let l =
        List.filteri (fun i (k, _) -> not (List.mem_assoc k (List.take i l))) l
      in
      List.concat_map
        (fun (k, a) ->
          match List.filter (fun (k', _) -> k' = k) stack with
          | [] when absent -> [ (k, a, "") ]
          | occ -> List.map (fun (_, v) -> (k, a, v)) occ)
        l

(* Processed attributes are deleted from the stack (LR p.184). *)
let drop ctx keys =
  ctx.Ctx.gml_attrs <-
    List.filter (fun (k, _) -> not (List.mem k keys)) ctx.Ctx.gml_attrs

let keys l = List.map (fun (k, _, _) -> k) l

(* .gs exatt [[NOT] name [as apf] ...]: process stacked attributes by
   their APFs (LR p.184, p.188).  An attribute given more than once is
   processed once per occurrence, in the order written, each with its
   own value (LR p.188: DIET twice).  The value is passed as the
   macro's parameters (LR p.188), tokenized as the operands of a macro
   call ([Macro.bind_args]): &* is the value, &*1 &*2 ... its tokens; a
   control word gets it as its operands. *)
let exatt ctx args =
  let calls =
    List.filter_map
      (fun (k, a, v) ->
        let lk = String.lowercase_ascii k in
        let name = Option.value a ~default:lk in
        match find_named ctx name with
        | Some apf -> Some (k, apf, v)
        | None ->
            (* a message (SH35-0050 p.9) *)
            Ctx.warn ctx ".gs exatt: no APF %s for attribute %s" name lk;
            None)
      (selected ctx args)
  in
  drop ctx (keys calls);
  List.iter
    (fun (_, apf, v) ->
      match apf with
      | Apf_macro (name, m) ->
          let scope = Symbols.new_scope () in
          Macro.bind_args scope v;
          Control.invoke_in ctx name m scope
      | Apf_word _ | Apf_null -> schedule_apf ctx apf [ v ])
    (List.rev calls)

(* .gs attval [[NOT] name [as sym] ...] (LR p.184, p.188): the symbol
   &NAME, the attribute name in upper case, gets the value; a symbol
   given with AS is used exactly as written (the normative text of
   p.188; its example's "&*xyz" for [as xyz] contradicts it).
   DCF-VERIFY (not in LR Rel 4): a name not on the stack sets the null
   string. *)
let attval ctx args =
  let l = selected ~absent:true ctx args in
  List.iter
    (fun (k, a, v) ->
      let sym = Option.value a ~default:k in
      match Symbols.set ctx.Ctx.syms sym v with
      | Ok () -> ()
      | Error e -> Ctx.error ctx ".gs attval: %s" e)
    l;
  drop ctx (keys l)

(* .gs purge / purgemsg [[NOT] name ...] (LR p.185): delete stacked
   attributes; PURGEMSG names them. *)
let purge ctx ~msg args =
  let l = selected ctx args in
  if msg && l <> [] then
    Ctx.warn ctx ".gs purgemsg: attributes purged: %s"
      (String.concat " "
         (List.map (fun (k, _, v) -> Printf.sprintf "%s='%s'" k v) l));
  drop ctx (keys l)

(* .gs snap [tag ...] (LR p.186): the current rules, and the [.aa]
   association and rules of each tag given. *)
let snap ctx tags =
  let show (r : Ctx.rules) =
    String.concat " " (dcf_keywords r @ if r.elem then [] else [ "noelem" ])
  in
  Ctx.info ctx ".gs snap: rules (%s) (%s)" (show ctx.Ctx.tag_rules)
    (show ctx.end_rules);
  List.iter
    (fun t ->
      let k = String.lowercase_ascii t in
      let one is_end =
        let apf =
          match assoc_side ctx ~is_end k with
          | Some ".", _ -> "NULL"
          | Some a, _ -> a
          | None, _ -> "(class mapping)"
        in
        Printf.sprintf "%s (%s)" apf (show (snd (lookup ctx ~is_end k)))
      in
      Ctx.info ctx ".gs snap: %s: %s, end tag: %s" k (one false) (one true))
    tags

(* The residual text of the current tag, if not yet processed. *)
let residual ctx =
  match ctx.Ctx.residual with
  | Some l when l.Input.pos = 0 -> Some l
  | _ -> None

let set_sym ctx cw sym v =
  match Symbols.set ctx.Ctx.syms sym v with
  | Ok () -> ()
  | Error e -> Ctx.error ctx ".gs %s: %s" cw e

(* The operand string after the first word. *)
let after_word s =
  let i = Tagscan.skip_blanks s 0 in
  let n = String.length s in
  let j = ref i in
  while !j < n && not (Tagscan.is_blank s.[!j]) do
    incr j
  done;
  let k = if !j < n then !j + 1 else !j in
  String.sub s k (n - k)

(* Scan [s] for attributes under the start-tag rules: they go on the
   attribute stack, the residual text is returned (LR p.184).
   DCF-VERIFY (not in LR Rel 4): value attributes are dropped. *)
let scan_string ctx s =
  let r = ctx.Ctx.tag_rules in
  if not r.att then s
  else begin
    let d =
      match Tagscan.delims_of ctx.chars with
      | Some d -> d
      | None ->
          { Tagscan.tag = '\000'; etag = "\000"; mcs = ctx.chars.Chars.mcs }
    in
    let res = Tagscan.attributes d ~att:r.att ~vat:r.vat ~stop:r.stop s 0 in
    scan_messages ctx ".gs scan" r res;
    ctx.gml_attrs <-
      ctx.gml_attrs
      @ List.filter_map
          (function
            | Tagscan.Named (k, v) -> Some (k, v) | Tagscan.Vat _ -> None)
          res.attrs;
    match res.stop with
    | Tagscan.Eol -> ""
    | Mcs k | Next_tag k | Invalid k -> String.sub s k (String.length s - k)
  end

(* .gs scan sym [string] / .gs copy sym [string] (LR p.184): with a
   string, scan it; else the residual text, which SCAN removes.
   DCF-VERIFY (not in LR Rel 4): with no residual text the symbol gets
   the null string. *)
let scan_copy ctx cw ~remove ops =
  match words ops with
  | [] -> Ctx.error ctx ".gs %s: symbol name expected" cw
  | [ sym ] -> (
      match residual ctx with
      | Some l ->
          let t, loc, k = l.Input.src.(0) in
          set_sym ctx cw sym t;
          if remove then l.src.(0) <- ("", loc, k)
      | None -> set_sym ctx cw sym "")
  | sym :: _ -> set_sym ctx cw sym (scan_string ctx (after_word ops))

(* .gs insert text: before the residual text, with continuation (no
   blank is added); with no residual text, as text now (LR p.187). *)
let insert ctx text =
  match residual ctx with
  | Some l ->
      let t, loc, k = l.Input.src.(0) in
      l.src.(0) <- (text ^ t, loc, k)
  | None ->
      if text <> "" then
        Input.push_back ctx.Ctx.input
          ~kind:(Input.Residual { Input.had_text = false; eol = true })
          text ctx.loc

(* .gs args v1 v2 ... (LR p.187, SH35-0050 p.17, p.28-29): the operands
   become the local argument symbols of the current macro (or of the
   file, when no macro is the source): [&*1], [&*2] ... the values,
   [&*0] their number, [&*] the operand string; the previous [&*n] are
   destroyed ("using the .GS ARGS control word destroys the &* array",
   SH35-0050 p.17).  [.gs args] alone sets [&*0] to 0, and [&*] and the
   [&*n] there were to null (LR p.187).  The values are separated by
   blanks; a value in single quotation marks may contain blanks, ['']
   alone is the null string and a doubled quote inside stands for one
   (DSMPROF3 sets its quotation marks with a quoted double quote and a
   quoted doubled single quote).  The operands were substituted with the
   line, so [.gs args &* x y] appends to the current list (DSM#SETS).
   DCF-VERIFY (not in LR Rel 4): the tokenization (blanks only, unlike
   macro operands, p.276, so [-1] and [a-b] stay one value). *)
let args_tokens s =
  let n = String.length s in
  let rec go i acc =
    let i = Tagscan.skip_blanks s i in
    if i >= n then List.rev acc
    else if s.[i] = '\'' then
      let v, j = Macro.quoted s i in
      go j (v :: acc)
    else begin
      let j = ref i in
      while !j < n && not (Tagscan.is_blank s.[!j]) do
        incr j
      done;
      go !j (String.sub s i (!j - i) :: acc)
    end
  in
  go 0 []

let is_arg_key k =
  String.length k >= 2
  && k.[0] = '*'
  && String.for_all
       (function '0' .. '9' -> true | _ -> false)
       (String.sub k 1 (String.length k - 1))

let gs_args ctx ops =
  let scope = ctx.Ctx.syms.Symbols.local () in
  let old =
    Hashtbl.fold
      (fun k _ acc -> if is_arg_key k then k :: acc else acc)
      scope []
  in
  let ops = String.trim ops in
  match args_tokens ops with
  | [] ->
      List.iter (fun k -> Symbols.set_in scope k "") ("*" :: old);
      Symbols.set_in scope "*0" "0"
  | toks ->
      List.iter (Hashtbl.remove scope) old;
      Macro.bind_args_list scope ops toks

(* .gs vars n1 n2 ... (LR p.187, SH35-0050 p.17): symbol n1 gets the
   value of [&*1], n2 of [&*2] ... (the [.gs args] values): [.gs args 1 2]
   then [.gs vars a b] is [.se a '1] [.se b '2].  The names are as
   written (case-sensitive) and may be local ([*t4]); array symbols are
   not allowed (LR p.187).
   DCF-VERIFY (not in LR Rel 4): a name beyond the last value gets the
   null string. *)
let gs_vars ctx names =
  List.iteri
    (fun i name ->
      let v =
        Option.value ~default:""
          (Symbols.get ctx.Ctx.syms ("*" ^ string_of_int (i + 1)))
      in
      if String.contains name '(' then
        Ctx.error ctx ".gs vars: array symbol %s not allowed" name
      else
        Control.check_name ctx ".gs vars" name (fun () ->
            match Symbols.set ctx.Ctx.syms name v with
            | Ok () -> ()
            | Error e -> Ctx.error ctx ".gs vars: %s" e))
    names

(* .gs qatt sym name ... (LR p.185, SH20-9161-3 p.266): the attributes
   in the list that are not in the attribute stack become the elements
   of [sym].  DSMFTNT's ".gs qatt *q id" then tests &E'&*q: so when
   every attribute is present [sym] is left undefined.  DCF-VERIFY (not
   in LR Rel 4): that, and the names are stored as written. *)
let qatt ctx = function
  | [] -> Ctx.error ctx ".gs qatt: symbol name expected"
  | sym :: names ->
      Control.check_name ctx ".gs qatt" sym (fun () ->
          let syms = ctx.Ctx.syms in
          ignore (Symbols.unset syms sym);
          List.iter
            (fun n ->
              if not (List.mem_assoc (String.uppercase_ascii n) ctx.gml_attrs)
              then
                match Symbols.append syms sym n with
                | Ok () -> ()
                | Error e -> Ctx.error ctx ".gs qatt: %s" e)
            names)

(* .gs hctr [n | n1.n2...] (LR p.185, p.188, [Headctr]): a single
   number steps that level, a dotted value sets the counter, nothing or
   0 reinitialises it.  The symbol &@xref (LR p.185) gets the counter up
   to that level ("1.3.2"), null when reinitialised; &xref the same, as
   SH20-9161-3 names it.  Their elements (1) ... are the positions
   (IBM's DSMHEAD1 prefixes an appendix heading with &xref(1)).
   DCF-VERIFY (not in LR Rel 4): the elements; &@xref after 0. *)
let hctr ctx args =
  let c = ctx.Ctx.hctr and syms = ctx.Ctx.syms in
  let xref n =
    let ps = Headctr.parts c n in
    List.iter
      (fun s ->
        ignore (Symbols.unset syms s);
        List.iteri (fun i p -> ignore (Symbols.set ~sub:(i + 1) syms s p)) ps;
        ignore (Symbols.set syms s (String.concat "." ps)))
      [ "xref"; "@xref" ]
  in
  match args with
  | [] ->
      Headctr.reset c;
      xref 0
  | [ v ] -> (
      let ps = List.map Headctr.position (String.split_on_char '.' v) in
      match int_of_string_opt v with
      | Some 0 ->
          Headctr.reset c;
          xref 0
      | Some n when n >= 1 && n <= Headctr.levels ->
          Headctr.step c n;
          xref n
      | _ when List.length ps <= Headctr.levels && not (List.mem None ps) ->
          Headctr.set c (List.filter_map Fun.id ps);
          xref (List.length ps)
      | _ -> Ctx.error ctx ".gs hctr: invalid value %s" v)
  | _ -> Ctx.error ctx ".gs hctr: one value expected"

(* .gs prefix [p [e]] (LR p.187): the class mapping prefixes of start
   and end tags, each OFF, = (unchanged) or one or two characters
   (quoted or not).  DCF-VERIFY (not in LR Rel 4): an omitted end
   prefix is unchanged; no operand restores the initial setting. *)
let gs_prefix ctx args =
  let one old a =
    match String.lowercase_ascii a with
    | "off" -> Ok None
    | "=" -> Ok old
    | _ ->
        let n = String.length a in
        let a =
          if n >= 3 && a.[0] = '\'' && a.[n - 1] = '\'' then
            String.sub a 1 (n - 2)
          else a
        in
        if a <> "" && String.length a <= 2 && not (String.contains a '\'') then
          Ok (Some a)
        else Error a
  in
  let st, en = prefixes ctx in
  let res =
    match args with
    | [] -> Ok (Some "", Some "e")
    | [ p ] -> Result.map (fun p -> (p, en)) (one st p)
    | [ p; e ] ->
        Result.bind (one st p) (fun p ->
            Result.map (fun e -> (p, e)) (one en e))
    | _ -> Error (String.concat " " args)
  in
  match res with
  | Ok v -> set_prefixes ctx v
  | Error a ->
      Ctx.error ctx ".gs prefix: OFF, = or one or two characters expected: %s" a

let gs ctx ops =
  match words ops with
  | [] -> Ctx.error ctx ".gs: service required"
  | w :: args -> (
      match
        (String.lowercase_ascii w, List.map String.lowercase_ascii args)
      with
      | "tag", [ "on" ] -> ctx.Ctx.tag_scan <- Ctx.Tags_on
      | "tag", [ "onno" ] -> ctx.tag_scan <- Ctx.Tags_onno
      | "tag", [ "off" ] -> ctx.tag_scan <- Ctx.Tags_off
      | "tag", _ -> Ctx.error ctx ".gs tag: ON, ONNO or OFF expected"
      | "rules", _ -> gs_rules ctx (after_word ops)
      | "prefix", _ -> gs_prefix ctx args
      | "exatt", _ -> exatt ctx args
      | "attval", _ -> attval ctx args
      | "purge", _ -> purge ctx ~msg:false args
      | "purgemsg", _ -> purge ctx ~msg:true args
      | "snap", _ -> snap ctx args
      | "scan", _ -> scan_copy ctx "scan" ~remove:true (after_word ops)
      | "copy", _ -> scan_copy ctx "copy" ~remove:false (after_word ops)
      | "insert", _ -> insert ctx (after_word ops)
      | "args", _ -> gs_args ctx (after_word ops)
      | "vars", _ -> gs_vars ctx args
      | "qatt", _ -> qatt ctx args
      | "hctr", _ -> hctr ctx args
      | s, _ -> Ctx.warn ctx "unsupported .gs service %s" s)

let install ctx =
  Ctx.register ctx "gs" gs;
  Ctx.register ctx "aa" aa
