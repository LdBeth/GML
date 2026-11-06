(* Native control words.  Later phases add theirs with [Ctx.register]. *)

let words s = String.split_on_char ' ' s |> List.filter (( <> ) "")

let skip_blanks s i =
  let n = String.length s in
  let i = ref i in
  while !i < n && Expr.is_blank s.[!i] do incr i done;
  !i

(* With [.su off] a [.se] or [.if] line was not substituted: its operands
   are substituted one by one (SH35-0069 p.230, p.267). *)
let operand_subst ctx =
  if ctx.Ctx.line_substituted then Fun.id else Subst.string ctx

(* ---- files ---------------------------------------------------------------- *)

(* The file-id of [.im]/[.ap] and the parameters after it.  A file-id in
   parentheses is the real file name (p.50). *)
let file_and_args s =
  let n = String.length s in
  let i = skip_blanks s 0 in
  let j =
    if i < n && s.[i] = '(' then
      match String.index_from_opt s i ')' with Some e -> e + 1 | None -> n
    else begin
      let j = ref i in
      while !j < n && not (Expr.is_blank s.[!j]) do incr j done;
      !j
    end
  in
  if j = i then None
  else Some (String.sub s i (j - i), String.sub s j (n - j))

(* The parameters of an imbedded or appended file are the global symbols
   &0 (their number) and &1 ... &14 (p.252-253), tokenized like macro
   parameters.
   DCF-VERIFY: they are set only when parameters are given; the unused
   ones up to &14 are dropped; tokens are not cut to eight characters. *)
let max_file_params = 14

let set_file_params ctx cw args =
  match Macro.tokens args with
  | [] -> ()
  | toks ->
    let toks =
      if List.length toks > max_file_params then begin
        Ctx.warn ctx ".%s: more than %d parameters; the rest are ignored" cw max_file_params;
        List.filteri (fun i _ -> i < max_file_params) toks
      end
      else toks
    in
    let syms = ctx.Ctx.syms in
    ignore (Symbols.set syms "0" (string_of_int (List.length toks)));
    List.iteri (fun i v -> ignore (Symbols.set syms (string_of_int (i + 1)) v)) toks;
    for i = List.length toks + 1 to max_file_params do
      ignore (Symbols.unset syms (string_of_int i))
    done

let im ctx ops =
  match file_and_args ops with
  | None -> Ctx.error ctx ".im: file name required"
  | Some (name, args) -> (
    match Input.imbed ctx.Ctx.input name with
    | Ok _ -> set_file_params ctx "im" args
    | Error e -> Ctx.error ctx ".im: %s" e)

let ap ctx ops =
  match file_and_args ops with
  | None -> Ctx.error ctx ".ap: file name required"
  | Some (name, args) -> (
    match Input.append ctx.Ctx.input name with
    | Ok () -> set_file_params ctx "ap" args
    | Error e -> Ctx.error ctx ".ap: %s" e)

(* .cm: a comment.  It is an ordinary control word: the line is split at
   the separator first (p.44). *)
let cm _ _ = ()

(* .ef [close] (p.51): end the current file.  The next imbed of the file
   resumes after this .ef, or with CLOSE from the top.  In the -profile
   file the rest of the file is the epifile, processed after the main
   document. *)
let ef ctx ops =
  let close =
    match List.map String.lowercase_ascii (words ops) with
    | [] -> false
    | [ "close" ] -> true
    | _ -> Ctx.error ctx ".ef: CLOSE or nothing expected"; false
  in
  match Input.current_file ctx.Ctx.input with
  | Some ff when ff.Input.id = ctx.profile_id && ctx.epifile = None ->
    ctx.epifile <- Some (ff.path, ff.lines, ff.idx);
    ignore (Input.end_file ~close:true ctx.input)
  | _ -> ignore (Input.end_file ~close ctx.input)

(* .qu / .qq (p.52): processing stops.  Modern edge: no pages, so the two
   are the same. *)
let qu ctx _ = Ctx.stop ctx

let ty _ ops = prerr_endline ops

(* .mg /id/text/ or .mg /text/ (SH35-0069 p.62): a message, written
   "+++ID text" after the location.  The last character of the id is the
   severity: I (and R) informational, W warning (return code 4), E error
   (8), S severe (12) and T terminating (16), which stop processing.
   The first non-blank character is the delimiter; the closing one is
   optional.  No data: ignored.
   DCF-VERIFY: we always show the id (as with MESSAGE(ID)); E does not
   stop processing (as with CONTINUE). *)
let mg ctx ops =
  let ops = String.trim ops in
  if ops <> "" then begin
    let d = ops.[0] in
    let fields =
      String.split_on_char d (String.sub ops 1 (String.length ops - 1))
    in
    let fields =
      match List.rev fields with "" :: r -> List.rev r | _ -> fields
    in
    let id, text =
      match fields with
      | [ t ] -> ("", t)
      | id :: rest -> (id, String.concat (String.make 1 d) rest)
      | [] -> ("", "")
    in
    if id <> "" || text <> "" then begin
      let sev = if id = "" then 'I' else Char.uppercase_ascii id.[String.length id - 1] in
      let rc = match sev with 'W' -> 4 | 'E' -> 8 | 'S' -> 12 | 'T' -> 16 | _ -> 0 in
      let d = ctx.Ctx.diag in
      if rc = 4 then d.Loc.warnings <- d.warnings + 1
      else if rc >= 8 then d.errors <- d.errors + 1;
      d.worst <- max d.worst rc;
      Printf.fprintf d.out "%s: +++%s%s%s\n%!" (Loc.to_string ctx.loc) id
        (if id <> "" && text <> "" then " " else "") text;
      if rc >= 12 then Ctx.stop ctx
    end
  end

(* .dc option value [option value ...]
   .dc gml c [e]: the GML tag delimiter and, optionally, the end-tag
   delimiter: one character, or two of which the first is the tag
   delimiter (SH35-0069 p.289).  None of them may be a tag name character
   or the ampersand.  .dc mcs c: the markup/content separator (p.290).
   .dc cont c|off: the continuation character (p.47).
   .dc asep c...: the array separator, up to four characters, each
   written as itself or as two hexadecimal digits (p.254); it takes the
   rest of the operands.  Modern edge: hexadecimal codes are ASCII (the
   manual's blank, "40", is EBCDIC; ours is "20").
   The two-character end-tag delimiter may also be written as two
   blank-separated operands, the tag delimiter and the second character:
   the Starter Set's ".dc gml : : e" sets ':' and ':e' (p.289; SH35-0050 p.6
   "the GML end-tag delimiter will be colon-e").
   DCF-VERIFY: without [e], the end-tag delimiter becomes the tag
   delimiter doubled (the default pair is ':' and '::').
   DCF-VERIFY: an option given last with no value restores its DCF
   default (the Starter Set's DSM#XLST and DSM#WRIT issue a bare ".dc cw"
   and ".dc asep" to undo an earlier setting; the .DC reference is in the
   Language Reference, which we lack). *)
let dc ctx ops =
  let ch = ctx.Ctx.chars in
  let char_value opt v k =
    if String.lowercase_ascii v = "off" then k None
    else if String.length v = 1 then k (Some v.[0])
    else if String.length v = 2 then
      (* two hexadecimal digits (DSMPROF3: .dc cont 03) *)
      match int_of_string_opt ("0x" ^ v) with
      | Some c -> k (Some (Char.chr c))
      | None -> Ctx.error ctx ".dc %s: invalid value %s" opt v
    else Ctx.error ctx ".dc %s: invalid value %s" opt v
  in
  let gml_char opt v k =
    if String.length v = 1 && Chars.valid_gml_char v.[0] then k v.[0]
    else Ctx.error ctx ".dc %s: invalid delimiter %s" opt v
  in
  let asep vs =
    let one v =
      if String.length v = 1 then Some v
      else if String.length v = 2 then
        Option.map (fun c -> String.make 1 (Char.chr c)) (int_of_string_opt ("0x" ^ v))
      else None
    in
    let cs = List.map one vs in
    if vs = [] then ch.Chars.asep <- (Chars.create ()).asep
    else if List.length vs > 4 then Ctx.error ctx ".dc asep: at most four characters"
    else if List.mem None cs then Ctx.error ctx ".dc asep: invalid character in %s"
        (String.concat " " vs)
    else ch.Chars.asep <- String.concat "" (List.filter_map Fun.id cs)
  in
  let rec go = function
    | [] -> ()
    | opt :: rest when String.lowercase_ascii opt = "asep" -> asep rest
    | [ opt ] ->
      let d = Chars.create () in
      (match String.lowercase_ascii opt with
       | "cw" -> ch.Chars.cw_sep <- d.cw_sep
       | "cont" -> ch.Chars.cont <- d.cont
       | "gml" -> ch.Chars.gml_delim <- d.gml_delim; ch.Chars.gml_end <- d.gml_end
       | "mcs" -> ch.Chars.mcs <- d.mcs
       | _ -> Ctx.warn ctx "unsupported .dc option %s" opt)
    | opt :: v :: rest ->
      (match String.lowercase_ascii opt with
       | "cw" -> char_value opt v (fun c -> ch.Chars.cw_sep <- c); go rest
       | "cont" -> char_value opt v (fun c -> ch.Chars.cont <- c); go rest
       | "gml" when String.lowercase_ascii v = "off" ->
         ch.Chars.gml_delim <- None; go rest
       | "gml" ->
         gml_char opt v (fun c ->
             let end_ok e =
               (String.length e = 1 && Chars.valid_gml_char e.[0] && e.[0] <> c)
               || (String.length e = 2 && e.[0] = c)
             in
             ch.Chars.gml_delim <- Some c;
             match rest with
             | e1 :: e2 :: rest'
               when e1 = String.make 1 c && String.length e2 = 1 ->
               ch.Chars.gml_end <- e1 ^ e2; go rest'
             | e :: _ when e = String.make 1 c ->
               Ctx.error ctx ".dc gml: end-tag delimiter %s is the tag delimiter" e
             | e :: rest' when end_ok e -> ch.Chars.gml_end <- e; go rest'
             | _ -> ch.Chars.gml_end <- String.make 2 c; go rest)
       | "mcs" -> gml_char opt v (fun c -> ch.Chars.mcs <- c); go rest
       | _ -> Ctx.warn ctx "unsupported .dc option %s" opt; go rest)
  in
  match words ops with
  | [] -> Ctx.error ctx ".dc: operands required"
  | ws -> go ws

(* ---- symbols ------------------------------------------------------------ *)

let check_name ctx cw name k =
  if Symbols.valid_name name then k ()
  else if String.length name > Symbols.max_name_len + (if Symbols.is_local name then 1 else 0)
  then Ctx.error ctx "%s: symbol name %s longer than %d characters" cw name
      Symbols.max_name_len
  else Ctx.error ctx "%s: invalid symbol name %s" cw name

(* .se name[(n)] = expression | 'string
   .se name[(n)] 'string
   .se name() = v    (the next element, p.256)
   .se name[(n)] off
   .se name = &      (the page number, p.254) *)
let se ctx ops =
  let n = String.length ops in
  let sub_word = operand_subst ctx in
  let i = skip_blanks ops 0 in
  let j = ref i in
  if !j < n && ops.[!j] = '*' then incr j;
  while !j < n && Symbols.is_name_char ops.[!j] do incr j done;
  let j = !j in
  if j = i then Ctx.error ctx ".se: symbol name expected"
  else begin
    let name = String.sub ops i (j - i) in
    let sub, k =
      if j < n && ops.[j] = '(' then
        match String.index_from_opt ops j ')' with
        | None -> (Error "missing )", n)
        | Some e ->
          let t = String.trim (sub_word (String.trim (String.sub ops (j + 1) (e - j - 1)))) in
          if t = "" then (Ok `Next, e + 1)
          else
            (match Expr.parse_int t with
             | Some x when x >= 0 -> (Ok (`At x), e + 1)
             | _ -> (Error (Printf.sprintf "invalid subscript %s" t), e + 1))
      else (Ok (`At 0), j)
    in
    let after = if k < n then ops.[k] else ' ' in
    match sub with
    | Error e -> Ctx.error ctx ".se %s: %s" name e
    | Ok _ when not (Expr.is_blank after || after = '=' || after = '\'') ->
      Ctx.error ctx ".se: invalid symbol name %s" (String.sub ops i (k + 1 - i))
    | Ok sub ->
      check_name ctx ".se" name (fun () ->
          let k = skip_blanks ops k in
          let rest = String.sub ops k (n - k) in
          let result = function
            | Ok () -> ()
            | Error e -> Ctx.error ctx ".se: %s" e
          in
          let set v =
            result
              (match sub with
               | `Next -> Symbols.append ctx.Ctx.syms name v
               | `At x -> Symbols.set ~sub:x ctx.Ctx.syms name v)
          in
          let value rhs =
            if String.trim rhs = "&" then
              set (Option.value (Symbols.get ctx.syms "$PN") ~default:"")
            else
              match Expr.se_value ~sub:sub_word rhs with
              | Ok v -> set v
              | Error e -> Ctx.error ctx ".se %s: %s" name e
          in
          if rest <> "" && rest.[0] = '=' then value (String.sub rest 1 (String.length rest - 1))
          else if String.lowercase_ascii (String.trim rest) = "off" then
            match sub with
            | `At x -> result (Symbols.unset ~sub:x ctx.syms name)
            | `Next -> Ctx.error ctx ".se %s(): OFF needs a subscript" name
          else if rest = "" then
            (* DCF-VERIFY: [.se name] alone sets the null string *)
            set ""
          else if Expr.is_quote rest.[0] then value rest
          else if String.lowercase_ascii (String.trim rest) = "lib" then
            (* the value is the first line of the library member
               (p.240, p.282) *)
            match sub with
            | `At 0 ->
              if not (Library.load_symbol ctx name) then
                Ctx.error ctx ".se %s lib: no member %s in the libraries" name
                  (Library.member_name name)
            | _ -> Ctx.error ctx ".se %s lib: a subscript is not allowed" name
          else
            (* DCF-VERIFY: an undelimited value without '=' is taken as
               written *)
            set (sub_word rest))
  end

(* .su on|off|n (p.230): with n, the next n input lines are substituted,
   then substitution goes off. *)
let su ctx ops =
  match String.lowercase_ascii (String.trim ops) with
  | "" | "on" -> ctx.Ctx.subst_on <- true; ctx.su_lines <- 0
  | "off" -> ctx.subst_on <- false; ctx.su_lines <- 0
  | o -> (
    match int_of_string_opt o with
    | Some k when k >= 0 -> ctx.subst_on <- k > 0; ctx.su_lines <- k
    | _ -> Ctx.error ctx ".su: ON, OFF or a number expected, not %s" o)

(* .ur line: process [line] with substitution even under .su off. *)
let ur ctx ops =
  ctx.Ctx.process ctx (if ctx.Ctx.line_substituted then Ctx.Split true else Ctx.Force_subst) ops

(* ---- control flow ------------------------------------------------------ *)

let is_cond_word = function
  | "if" | "th" | "el" | "an" | "or" -> true
  | _ -> false

let do_operand c =
  match words (Line.operands c) with
  | w :: _ -> String.lowercase_ascii w
  | [] -> ""

(** Does line [s] open a [.do] group if it is executed: [.do begin], or a
    conditional word ([.if .th .el .an .or]) whose object ends with
    [.do begin].  Used for not-executed objects and while skipping. *)
let opens_group ch s =
  match Line.classify ch s with
  | Line.Control c when c.name = "do" -> do_operand c = "begin"
  | Line.Control c when is_cond_word c.name -> (
    match List.rev (words s) with
    | b :: d :: _ :: _ when String.lowercase_ascii b = "begin" -> (
      match Line.classify ch d with
      | Line.Control dc -> dc.name = "do" && dc.args = ""
      | _ -> false)
    | _ -> false)
  | _ -> false

let closes_group ch s =
  match Line.classify ch s with
  | Line.Control c -> c.name = "do" && do_operand c = "end"
  | _ -> false

let start_skip ctx =
  ctx.Ctx.skip <- 1;
  ctx.skip_from <- ctx.loc;
  ctx.skip_owner <- Input.current_frame_id ctx.input

(* The object of a condition: processed when [b] as an input line of its
   own (p.264: "the first nonblank character after comparand2 is treated
   as the first character of the input line"), else skipped (a
   [.do begin] object skips its whole group). *)
let combines ch s =
  match Line.classify ch s with
  | Line.Control c -> c.name = "an" || c.name = "or"
  | _ -> false

(* An .an/.or object is processed whatever the result: p.265's
   ".if x&city eq xCleveland .or x&city eq xWarrensburg" must reach the
   .or when the .if is false. *)
let conditional ctx b rest =
  if rest <> "" then
    if b || combines ctx.Ctx.chars rest then
      ctx.Ctx.process ctx (Ctx.Split ctx.Ctx.line_substituted) rest
    else if opens_group ctx.chars rest then start_skip ctx

(* DCF-VERIFY: on a malformed condition we diagnose and take it as
   false. *)
let eval_condition ctx cw ops =
  match Expr.condition ~sub:(operand_subst ctx) ops with
  | Ok r -> Some r
  | Error e -> Ctx.error ctx ".%s: %s" cw e; None

let if_ ctx ops =
  match eval_condition ctx "if" ops with
  | Some (b, rest) -> Ctx.set_cond ctx (Some b); conditional ctx b rest
  | None -> Ctx.set_cond ctx (Some false)

let need_cond ctx cw k =
  match Ctx.cond ctx with
  | Some b -> k b
  | None -> Ctx.error ctx ".%s without a preceding .if" cw

(* .th/.el test the most recent comparison in the current file or macro;
   it is preserved across macro calls and imbeds (p.265), and they do not
   consume it (a series of .th/.el lines all apply, p.265). *)
let th ctx ops = need_cond ctx "th" (fun b -> conditional ctx b (String.trim ops))

let el ctx ops = need_cond ctx "el" (fun b -> conditional ctx (not b) (String.trim ops))

(* .an / .or (p.265) combine with the preceding comparison, and like .if
   process their own object. *)
let combine cw f ctx ops =
  need_cond ctx cw (fun prev ->
      match eval_condition ctx cw ops with
      | Some (b, rest) ->
        let r = f prev b in
        Ctx.set_cond ctx (Some r);
        conditional ctx r rest
      | None -> Ctx.set_cond ctx (Some false))

let an = combine "an" ( && )
let or_ = combine "or" ( || )

(* .do begin / .do end.  A group saves the comparison of its frame, so a
   .el after .do end refers to the .if that opened the group.
   DCF-VERIFY: .do is not in SH35-0069; .do with no operand is an error
   (not an implicit BEGIN); the saving of the comparison by the group. *)
let do_ ctx ops =
  match List.map String.lowercase_ascii (words ops) with
  | [ "begin" ] ->
    ctx.Ctx.do_stack <-
      { Ctx.saved_cond = Ctx.cond ctx; owner = Input.current_frame_id ctx.input;
        opened = ctx.loc }
      :: ctx.do_stack
  | [ "end" ] -> (
    match ctx.do_stack with
    | e :: rest -> ctx.do_stack <- rest; Ctx.set_cond ctx e.saved_cond
    | [] -> Ctx.error ctx ".do end without .do begin")
  | _ -> Ctx.error ctx ".do: BEGIN or END expected"

(* .go label.  Open .do groups of the frame jumped in are abandoned (a
   loop body inside a .do group would otherwise leave one open group per
   iteration).  DCF-VERIFY: label names compare case-insensitively. *)
let go ctx ops =
  match words ops with
  | [] -> Ctx.error ctx ".go: label name required"
  | w :: rest ->
    if rest <> [] then Ctx.warn ctx ".go: extra operands ignored";
    let w =
      if String.length w > 3 && String.sub w 0 3 = "..." then
        String.sub w 3 (String.length w - 3)
      else w
    in
    match Input.goto ctx.Ctx.input ~label_of:(Line.label_of ctx.chars) w with
    | Ok id ->
      ctx.do_stack <- List.filter (fun e -> e.Ctx.owner <> id) ctx.do_stack;
      ctx.go_count <- ctx.go_count + 1;
      if ctx.go_count > ctx.max_go then begin
        Ctx.error ctx ".go: more than %d jumps (loop?); processing stopped"
          ctx.max_go;
        Ctx.abort ctx
      end
    | Error e -> Ctx.error ctx ".go: %s" e

(* ---- conditional sections (p.267-269) ----------------------------------- *)

(** Is the current line in an ignored conditional section?  Lines of the
    macros invoked from the section (frames that were not on the stack
    when it began) are not:
    "macros and GML tags are resolved" (p.269).
    DCF-VERIFY: the extent of "resolved": we run macro calls and GML tags
    (with their APFs) of an ignored section, and drop everything else. *)
let cs_ignoring ctx =
  List.exists (fun e -> e.Ctx.ignored) ctx.Ctx.cs_open
  && List.mem (Input.current_frame_id ctx.input) ctx.cs_frames

(* .cs n on|off|ignore|include; the blank before OFF is required (p.40). *)
let cs ctx ops =
  match List.map String.lowercase_ascii (words ops) with
  | [ n; kw ] -> (
    match int_of_string_opt n with
    | Some k when k >= 1 && k <= 9 -> (
      match kw with
      (* in an ignored section only ON/OFF are processed, to pair the
         sections: in the TABLE example of p.55-56 the .cs 2 include
         inside the ignored section 1 must have no effect until
         .cs 1 include *)
      | "ignore" | "include" when cs_ignoring ctx -> ()
      | "ignore" -> Hashtbl.replace ctx.Ctx.cs_modes k true
      | "include" -> Hashtbl.replace ctx.cs_modes k false
      | "on" ->
        let ignored = Option.value (Hashtbl.find_opt ctx.cs_modes k) ~default:false in
        if ignored && not (List.exists (fun e -> e.Ctx.ignored) ctx.cs_open) then
          ctx.cs_frames <- Input.frame_ids ctx.input;
        ctx.cs_open <- { Ctx.section = k; ignored; cs_from = ctx.loc } :: ctx.cs_open;
        Ctx.sync_mute ctx
      | "off" ->
        if List.exists (fun e -> e.Ctx.section = k) ctx.cs_open then
          let rec drop = function
            | e :: r when e.Ctx.section = k -> r
            | e :: r -> e :: drop r
            | [] -> []
          in
          (ctx.cs_open <- drop ctx.cs_open; Ctx.sync_mute ctx)
        else Ctx.warn ctx ".cs %d off: section %d is not on" k k
      | _ -> Ctx.error ctx ".cs %d: ON, OFF, IGNORE or INCLUDE expected" k)
    | _ -> Ctx.error ctx ".cs: section number 1 to 9 expected, not %s" n)
  | _ -> Ctx.error ctx ".cs: section number and ON, OFF, IGNORE or INCLUDE expected"

(* .ct [text] (p.48): the text continues the previous text line without a
   word space; alone, a continuation in effect is cancelled. *)
let ct ctx ops =
  if ops = "" then Doc.cancel_continuation ctx.Ctx.doc
  else begin
    Doc.join_previous ctx.Ctx.doc;
    ctx.Ctx.process ctx (Ctx.Residual { Input.had_text = true; eol = true }) ops
  end

(* ---- macros ------------------------------------------------------------- *)

(* .dm name /l1/l2/... | .dm name(n) /line | .dm name() /line
   | .dm name(n) off | .dm name on | .dm name off | .dm name delete.
   The line is substituted like any other when .su is on (p.274); the
   body of [.dm name on] is captured raw by [Interp.process]. *)
let dm ctx ops =
  let st = ctx.Ctx.macros and at = ctx.loc in
  match Macro.parse_dm ops with
  | Macro.Bad msg -> Ctx.error ctx "%s" msg
  | Macro.Lines (name, body) -> Macro.define st name ~at body
  | Macro.Set_line (name, sub, line) -> Macro.set_line st name ~at sub line
  | Macro.Delete_line (name, k) ->
    if not (Macro.delete_line st name k) then
      Ctx.warn ctx ".dm %s(%d) off: macro %s is not defined" name k name
  | Macro.Begin name ->
    ctx.capture <-
      Some { Ctx.cname = name; cbody = []; cfrom = ctx.loc; discard = false }
  | Macro.Lib name ->
    (* searched whatever the setting of .ly; the definition replaces any
       existing one (p.282) *)
    if Library.load_macro ctx name = None then
      Ctx.error ctx ".dm %s lib: no member %s in the libraries" name
        (Library.member_name name)
  | Macro.End None -> Ctx.error ctx ".dm off without .dm name on"
  | Macro.End (Some name) | Macro.Delete name ->
    (* DCF-VERIFY: deleting an undefined macro is silently accepted *)
    ignore (Macro.delete st name)

(* The body captured by [.dm name on] is complete. *)
let end_capture ctx (cap : Ctx.capture) =
  ctx.Ctx.capture <- None;
  if not cap.discard then
    Macro.define ctx.macros cap.cname ~at:cap.cfrom (List.rev cap.cbody)

(* .ly on|off|mac|sym (p.240, p.282-283): which unresolved names the
   libraries are searched for.  ON: macros and symbols; MAC: macros
   only; SYM: symbols only; OFF: neither (the initial setting).
   DCF-VERIFY: .ly without an operand is ON. *)
let ly ctx ops =
  let set m s = ctx.Ctx.ly_mac <- m; ctx.ly_sym <- s in
  match String.lowercase_ascii (String.trim ops) with
  | "" | "on" -> set true true
  | "off" -> set false false
  | "mac" -> set true false
  | "sym" -> set false true
  | o -> Ctx.error ctx ".ly: ON, OFF, MAC or SYM expected, not %s" o

(* .ms on|off; off initially (p.271). *)
let ms ctx ops =
  match String.lowercase_ascii (String.trim ops) with
  | "" | "on" -> ctx.Ctx.ms_on <- true
  | "off" -> ctx.ms_on <- false
  | o -> Ctx.error ctx ".ms: ON or OFF expected, not %s" o

(* .me [line] (p.277): leave the current macro; the rest of the line, if
   any, is processed after it as if it had been part of the caller (it
   was substituted with the .me line, while the macro was current:
   SH35-0050 p.17).
   DCF-VERIFY: .me outside a macro is a warning. *)
let me ctx ops =
  match Input.end_macro ctx.Ctx.input with
  | Some _ ->
    if String.trim ops <> "" then
      Input.push_back ctx.input ~kind:(Input.Split ctx.line_substituted) ops ctx.loc
  | None -> Ctx.warn ctx ".me outside a macro ignored"

(** Invoke macro [name] in a new Macro frame whose local scope is
    [scope] (it holds the arguments). *)
let invoke_in ctx name (_ : Macro.def) scope =
  if Input.macro_depth ctx.Ctx.input >= ctx.max_macro_depth then begin
    Ctx.error ctx "macro %s: calls nested deeper than %d; processing stopped"
      name ctx.max_macro_depth;
    Ctx.abort ctx
  end
  else
    let key = Macro.key name in
    Input.push_macro ctx.input ~name
      ~lines:(fun () ->
          match Hashtbl.find_opt ctx.Ctx.macros key with
          | Some d -> Array.of_list d.Macro.lines
          | None -> [||])
      ~called_from:ctx.loc ~scope

(** Invoke macro [name] with operands [ops] (already substituted): a new
    Macro frame, whose local scope holds the arguments. *)
let invoke ctx name m ops =
  let scope = Symbols.new_scope () in
  Macro.bind_args scope ops;
  invoke_in ctx name m scope

(* The name after an optional control word indicator, and the operands
   after it ([.em .xx args], [.ec .xx args]). *)
let target ctx ops ~len =
  let ops = String.trim ops in
  let ops =
    if ops <> "" && ops.[0] = ctx.Ctx.chars.Chars.cw_ind then
      String.sub ops 1 (String.length ops - 1)
    else ops
  in
  let n = String.length ops in
  let j = ref 0 in
  while !j < n && !j < len && Line.is_name_char ops.[!j] do incr j done;
  (String.lowercase_ascii (String.sub ops 0 !j), Line.drop_blank (String.sub ops !j (n - !j)))

(* .em .name args (p.278): execute a macro, whatever the setting of .ms
   (and from a text line, after a separator, p.41). *)
let em ctx ops =
  match target ctx ops ~len:Line.max_macro_name with
  | "", _ -> Ctx.error ctx ".em: macro name required"
  | name, args -> (
    match Macro.find ctx.Ctx.macros name with
    | Some m -> invoke ctx name m args
    | None -> (
      match Library.find_macro ctx name with
      | Some m -> invoke ctx name m args
      | None -> Ctx.error ctx ".em: macro %s not defined" name))

(* .ec .xx args (p.277-279): execute the native control word even when a
   macro of that name is defined. *)
let ec ctx ops =
  match target ctx ops ~len:2 with
  | "", _ -> Ctx.error ctx ".ec: control word required"
  | name, args -> (
    match Hashtbl.find_opt ctx.Ctx.words name with
    | Some w -> w.Ctx.run ctx args
    | None -> Ctx.warn ctx "unsupported control word .%s" name)

(* A Macro frame left the stack (end of body, .me, .ef, .ap, abort):
   .do groups opened in it and still open are discarded, and a skip that
   began in it ends with it. *)
let frame_popped ctx = function
  | Input.Macro m ->
    let mine, others =
      List.partition (fun e -> e.Ctx.owner = m.Input.mid) ctx.Ctx.do_stack
    in
    List.iter
      (fun e ->
         Loc.report ctx.diag Loc.Warning e.Ctx.opened
           ".do begin without .do end in macro %s; group discarded" m.Input.name)
      (List.rev mine);
    ctx.do_stack <- others;
    if ctx.skip > 0 && ctx.skip_owner = m.mid then begin
      Ctx.error_at ctx ctx.skip_from
        ".do begin without .do end (skipped to end of macro %s)" m.name;
      ctx.skip <- 0
    end
  | Input.File _ | Input.Lines _ -> ()

let install ctx =
  let r name f = Ctx.register ctx name f in
  r "im" im;
  r "ap" ap;
  r "cm" cm;
  r "ef" ef;
  r "qu" qu;
  r "qq" qu;
  r "dc" dc;
  r "ty" ty;
  r "mg" mg;
  r "se" se;
  r "su" su;
  r "ur" ur;
  r "if" if_;
  r "th" th;
  r "el" el;
  r "an" an;
  r "or" or_;
  r "do" do_;
  r "go" go;
  r "cs" cs;
  r "ct" ct;
  r "dm" dm;
  r "ms" ms;
  r "ly" ly;
  r "me" me;
  r "em" em;
  r "ec" ec;
  ctx.input.Input.on_pop <- frame_popped ctx
