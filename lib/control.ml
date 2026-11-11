(* Native control words.  Later phases add theirs with [Ctx.register]. *)

let words s = String.split_on_char ' ' s |> List.filter (( <> ) "")

let skip_blanks s i =
  let n = String.length s in
  let i = ref i in
  while !i < n && Expr.is_blank s.[!i] do
    incr i
  done;
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
      while !j < n && not (Expr.is_blank s.[!j]) do
        incr j
      done;
      !j
    end
  in
  if j = i then None else Some (String.sub s i (j - i), String.sub s j (n - j))

(* The parameters of an imbedded or appended file are the global symbols
   &0 and &1 ... &14 (LR p.68, p.208-209), tokenized like macro
   parameters.  Every .im/.ap resets &1 ... &14 and sets &0 to the number
   of non-null tokens; a [%] token leaves its symbol unset.  A token is
   up to eight characters.  The line holds at most 16 tokens: the
   control word, the file-id and 14 parameters, two fewer for a file name
   in parentheses and one fewer for each further word of it. *)
let max_file_params = 14
let max_token = 8

let set_file_params ctx cw name args =
  let toks = Macro.tokens args in
  let room =
    if name <> "" && name.[0] = '(' then
      max_file_params - 1 - List.length (words name)
    else max_file_params
  in
  let toks =
    if List.length toks > room then begin
      Ctx.warn ctx ".%s: more than 16 tokens on the line; the rest are ignored"
        cw;
      List.take (max 0 room) toks
    end
    else toks
  in
  let toks =
    List.map
      (fun t ->
        if String.length t > max_token then begin
          Ctx.warn ctx ".%s: token %s longer than %d characters; truncated" cw t
            max_token;
          String.sub t 0 max_token
        end
        else t)
      toks
  in
  ignore
    (Ctx.Sym.set ctx "0"
       (string_of_int (List.length (List.filter (( <> ) "") toks))));
  for i = 1 to max_file_params do
    ignore (Ctx.Sym.unset ctx (string_of_int i))
  done;
  List.iteri
    (fun i v ->
      if v <> "" then ignore (Ctx.Sym.set ctx (string_of_int (i + 1)) v))
    toks

let im ctx ops =
  match file_and_args ops with
  | None -> Ctx.error ctx ".im: file name required"
  | Some (name, args) -> (
      match Input.imbed ctx.Ctx.input name with
      | Ok _ -> set_file_params ctx "im" name args
      | Error e -> Ctx.error ctx ".im: %s" e)

let ap ctx ops =
  match file_and_args ops with
  | None -> Ctx.error ctx ".ap: file name required"
  | Some (name, args) -> (
      match Input.append ctx.Ctx.input name with
      | Ok () -> set_file_params ctx "ap" name args
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
    | _ ->
        Ctx.error ctx ".ef: CLOSE or nothing expected";
        false
  in
  match Input.current_file ctx.Ctx.input with
  | Some ff when ff.Input.id = ctx.profile_id && ctx.epifile = None ->
      ctx.epifile <- Some (ff.path, ff.lines, ff.idx);
      ignore (Input.end_file ~close:true ctx.input)
  | _ -> ignore (Input.end_file ~close ctx.input)

(* .qu / .qq (p.52): processing stops.  Modern edge: no pages, so the two
   are the same. *)
let qu ctx _ = Ctx.stop ctx

(* .ty text: the line on the terminal, a text variable as its
   text ([Doc.dvar_text]: DSMPROF3's &amp. &gml. &semi. are & : ;). *)
let ty ctx ops = prerr_endline (Doc.dvar_text ctx.Ctx.doc ops)

(* .mg /code/message/ (LR p.246): a message, written "+++code message"
   after the location.  The first non-blank character is the delimiter;
   the closing one is optional; a single field is the code.  The last
   character of the code is the severity: R and I informational, W
   warning (return code 4), E error (8), S severe (12) and T terminating
   (16); S and T stop processing.  A null code is informational.  No data
   at all: ignored; a null code and message: the prefix alone.
   The fields are split first, a delimiter in a text variable's string
   being text ([Line.split_on]); then each field's text variables are
   written as their text ([Doc.dvar_text]), so .mg /ASSERTE/&amp.util/
   writes "+++ASSERTE &util".
   We emulate the MESSAGE(ID) option (the code is shown) and CONTINUE (an
   E message does not stop processing, as with our other errors). *)
let mg ctx ops =
  let ops = String.trim ops in
  if ops <> "" then begin
    let d = ops.[0] in
    let fields =
      List.map
        (Doc.dvar_text ctx.Ctx.doc)
        (Line.split_on d (String.sub ops 1 (String.length ops - 1)))
    in
    let fields =
      match List.rev fields with
      | "" :: (_ :: _ as r) -> List.rev r
      | _ -> fields
    in
    let code, text =
      match fields with
      | [ c ] -> (c, "")
      | c :: rest -> (c, String.concat (String.make 1 d) rest)
      | [] -> ("", "")
    in
    let sev =
      if code = "" then 'I'
      else Char.uppercase_ascii code.[String.length code - 1]
    in
    let rc =
      match sev with 'W' -> 4 | 'E' -> 8 | 'S' -> 12 | 'T' -> 16 | _ -> 0
    in
    let d = ctx.Ctx.diag in
    if rc = 4 then d.Loc.warnings <- d.warnings + 1
    else if rc >= 8 then d.errors <- d.errors + 1;
    d.worst <- max d.worst rc;
    Printf.fprintf d.out "%s: +++%s%s\n%!" (Loc.to_string ctx.loc) code
      (if text <> "" then " " ^ text else "");
    if rc >= 12 then Ctx.stop ctx
  end

(* .dc option value (LR p.111-116).  A value is one character, written
   as itself or as two hexadecimal digits: an EBCDIC code ([Ebcdic]) that
   must be an ASCII character here (DSMPROF3: .dc cont 03).  An option
   given without a value restores its initial value (LR p.114 "Default";
   the Starter Set's DSM#XLST issues a bare ".dc cw").
   .dc gml c [e1 [e2]]: the tag delimiter c alone: end tags are not
   recognized (the end-tag delimiter is null); c e1: e1 is the end-tag
   delimiter; c e1 e2: e1 e2 is (LR p.113; initially ": : :", p.115).
   The delimiters may not be a blank, a period, an ampersand or a tag
   name character; of e1 e2 only e1 is checked (the Starter Set's
   ".dc gml : : e" sets ':e', SH35-0050 p.6).  The two characters of the
   end-tag delimiter may also be one operand that begins with c
   (DSMPROF3's ".dc gml : :e").
   .dc cw|gml|mcs X'00' or X'40': OFF (LR p.113 note 6).  .dc mcs off
   leaves the blank, always a markup/content separator (p.115 r4).
   .dc cont c|off (p.112); .dc rb c (&$RB); .dc ps c (p.114).
   .dc asep c...: up to four characters (Starter Set: ".dc asep , 40",
   a comma and a blank); it takes the rest of the operands (p.112).
   EXT: several options on one line ([.dc gml : : e mcs >]; the syntax
   has one per .dc).  IXB IXI PUNC STOP WORD are not supported. *)
let dc ctx ops =
  let ch = ctx.Ctx.chars in
  let init = Chars.create () in
  let one v =
    if String.length v = 1 then Some v.[0]
    else Option.bind (Ebcdic.of_hex v) Ebcdic.ascii
  in
  let off_code v =
    String.lowercase_ascii v = "off"
    || match Ebcdic.of_hex v with Some (0x00 | 0x40) -> true | _ -> false
  in
  let char_value opt v k =
    if String.lowercase_ascii v = "off" then k None
    else
      match one v with
      | Some c -> k (Some c)
      | None -> Ctx.error ctx ".dc %s: invalid value %s" opt v
  in
  let asep_char v =
    if String.length v = 1 then Some v
    else Option.map Ebcdic.utf8 (Ebcdic.of_hex v)
  in
  let asep vs =
    let cs = List.map asep_char vs in
    if vs = [] then ch.Chars.asep <- init.asep
    else if List.length vs > 4 then
      Ctx.error ctx ".dc asep: at most four characters"
    else if List.mem None cs then
      Ctx.error ctx ".dc asep: invalid character in %s" (String.concat " " vs)
    else ch.Chars.asep <- String.concat "" (List.filter_map Fun.id cs)
  in
  let restore opt =
    match String.lowercase_ascii opt with
    | "cw" -> ch.Chars.cw_sep <- init.cw_sep
    | "cont" -> ch.Chars.cont <- init.cont
    | "gml" ->
        ch.Chars.gml_delim <- init.gml_delim;
        ch.Chars.gml_end <- init.gml_end
    | "mcs" -> ch.Chars.mcs <- init.mcs
    | "rb" -> ch.Chars.rb <- init.rb
    | "ps" -> ch.Chars.ps <- init.ps
    | _ -> Ctx.warn ctx "unsupported .dc option %s" opt
  in
  (* the end-tag delimiter after tag delimiter [c]: the operands it takes
     and the rest *)
  let end_delim c = function
    | e :: rest when String.length e = 2 && e.[0] = c -> Ok (e, rest)
    | e1 :: rest -> (
        match one e1 with
        | None -> Ok ("", e1 :: rest)
        | Some a when not (Chars.valid_gml_delim a) ->
            Error (Printf.sprintf "invalid end-tag delimiter %s" e1)
        | Some a -> (
            match rest with
            | e2 :: rest' when one e2 <> None ->
                Ok (Printf.sprintf "%c%c" a (Option.get (one e2)), rest')
            | _ when a = c ->
                Error
                  (Printf.sprintf "end-tag delimiter %c is the tag delimiter" c)
            | _ -> Ok (String.make 1 a, rest)))
    | [] -> Ok ("", [])
  in
  let rec go = function
    | [] -> ()
    | opt :: rest when String.lowercase_ascii opt = "asep" -> asep rest
    | [ opt ] -> restore opt
    | opt :: v :: rest -> (
        match String.lowercase_ascii opt with
        | "cw" ->
            if off_code v then ch.Chars.cw_sep <- None
            else char_value opt v (fun c -> ch.Chars.cw_sep <- c);
            go rest
        | "cont" ->
            char_value opt v (fun c -> ch.Chars.cont <- c);
            go rest
        | "gml" when off_code v ->
            ch.Chars.gml_delim <- None;
            go rest
        | "gml" -> (
            match one v with
            | Some c when Chars.valid_gml_delim c -> (
                match end_delim c rest with
                | Ok (e, rest') ->
                    ch.Chars.gml_delim <- Some c;
                    ch.Chars.gml_end <- e;
                    go rest'
                | Error e -> Ctx.error ctx ".dc gml: %s" e)
            | _ -> Ctx.error ctx ".dc gml: invalid delimiter %s" v)
        | "mcs" when off_code v ->
            ch.Chars.mcs <- ' ';
            go rest
        | "mcs" -> (
            match one v with
            | Some c when Chars.valid_gml_char c ->
                ch.Chars.mcs <- c;
                go rest
            | _ -> Ctx.error ctx ".dc mcs: invalid delimiter %s" v)
        | "rb" -> (
            match asep_char v with
            | Some c ->
                ch.Chars.rb <- c;
                go rest
            | None -> Ctx.error ctx ".dc rb: invalid value %s" v)
        | "ps" ->
            char_value opt v (fun c ->
                Option.iter (fun c -> ch.Chars.ps <- c) c);
            go rest
        | _ ->
            Ctx.warn ctx "unsupported .dc option %s" opt;
            go rest)
  in
  match words ops with
  | [] -> Ctx.error ctx ".dc: operands required"
  | ws -> go ws

(* ---- symbols ------------------------------------------------------------ *)

(* Modern edge: the names of the pass model's coupling files (pa@ENC,
   pq@ENC: an encoded anchor or question id, lib/aux.ml) may be longer
   than ten characters while such a file is imbedded. *)
let check_name ctx cw name k =
  if
    Symbols.valid_name name
    || (ctx.Ctx.coupling && Symbols.valid_name ~long:true name)
  then k ()
  else if
    String.length name
    > Symbols.max_name_len + if Symbols.is_local name then 1 else 0
  then
    Ctx.error ctx "%s: symbol name %s longer than %d characters" cw name
      Symbols.max_name_len
  else Ctx.error ctx "%s: invalid symbol name %s" cw name

(* The page provenance of a global symbol (Ctx.page_syms): set to the
   answer of the one question asked on its line (.se fp = &$PN, .se fp =
   &), the symbol file carries the question and the next pass the answer
   TeX gave to it (Aux.resolve_pages).  The question is used up: a second
   .se on the same line (a ;-split line) does not claim it.  Set to
   anything else (two questions, &$PN+1, a constant), [.se name()] (an
   element by the counter, p.256) or OFF: no provenance.  An entry that
   another command made stale (.se x lib) is not written: its value is
   no longer the answer (Symbols.dump). *)
let page_provenance ctx name x v =
  let key = (Symbols.norm name, x) in
  match ctx.Ctx.line_queries with
  | [ ((_, ans, _) as q) ] when ans = v && not (Symbols.is_local name) ->
      Hashtbl.replace ctx.Ctx.page_syms key q;
      ctx.Ctx.line_queries <- []
  | _ -> Hashtbl.remove ctx.Ctx.page_syms key

(* .se name off: the whole symbol, every element of it *)
let page_unset ctx name x =
  let n = Symbols.norm name in
  if x <> 0 then Hashtbl.remove ctx.Ctx.page_syms (n, x)
  else
    Hashtbl.filter_map_inplace
      (fun (m, _) q -> if m = n then None else Some q)
      ctx.Ctx.page_syms

(* .se name() = v: the counter and the element it now names *)
let page_appended ctx name =
  let n = Symbols.norm name in
  Hashtbl.remove ctx.Ctx.page_syms (n, 0);
  Option.iter
    (fun c -> Hashtbl.remove ctx.Ctx.page_syms (n, c))
    (Option.bind (Ctx.Sym.get ctx n) int_of_string_opt)

(* .se name[(n)] = expression | 'string'  (quotes doubled inside)
   .se name[(n)] 'string                   (literal, LR p.337-338)
   .se name() = v    (the next element, p.256)
   .se name[(n)] off
   .se name = &      (the page number, p.254)
   .se name lib      (LR p.337) *)
let se ctx ops =
  let n = String.length ops in
  let sub_word = operand_subst ctx in
  let i = skip_blanks ops 0 in
  let j = ref i in
  if !j < n && ops.[!j] = '*' then incr j;
  while !j < n && Symbols.is_name_char ops.[!j] do
    incr j
  done;
  let j = !j in
  if j = i then Ctx.error ctx ".se: symbol name expected"
  else begin
    let name = String.sub ops i (j - i) in
    let sub, k =
      if j < n && ops.[j] = '(' then
        match String.index_from_opt ops j ')' with
        | None -> (Error "missing )", n)
        | Some e -> (
            let t =
              String.trim
                (sub_word (String.trim (String.sub ops (j + 1) (e - j - 1))))
            in
            if t = "" then (Ok `Next, e + 1)
            else
              match Expr.parse_int t with
              | Some x when x >= 0 -> (Ok (`At x), e + 1)
              | _ -> (Error (Printf.sprintf "invalid subscript %s" t), e + 1))
      else (Ok (`At 0), j)
    in
    let after = if k < n then ops.[k] else ' ' in
    match sub with
    | Error e -> Ctx.error ctx ".se %s: %s" name e
    | Ok _ when not (Expr.is_blank after || after = '=' || after = '\'') ->
        Ctx.error ctx ".se: invalid symbol name %s"
          (String.sub ops i (k + 1 - i))
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
                | `Next ->
                    let r = Ctx.Sym.append ctx name v in
                    if r = Ok () then page_appended ctx name;
                    r
                | `At x ->
                    let r = Ctx.Sym.set ~sub:x ctx name v in
                    if r = Ok () then page_provenance ctx name x v;
                    r)
            in
            let value rhs =
              if String.trim rhs = "&" then
                set (Option.value (Ctx.Sym.get ctx "$PN") ~default:"")
              else
                match
                  Expr.se_value ~sub:sub_word
                    ~warn:(fun m -> Ctx.warn ctx ".se %s: %s" name m)
                    rhs
                with
                | Ok v -> set v
                | Error e -> Ctx.error ctx ".se %s: %s" name e
            in
            if rest <> "" && rest.[0] = '=' then
              value (String.sub rest 1 (String.length rest - 1))
            else if String.lowercase_ascii (String.trim rest) = "off" then
              match sub with
              | `At x ->
                  page_unset ctx name x;
                  result (Ctx.Sym.unset ~sub:x ctx name)
              | `Next -> Ctx.error ctx ".se %s(): OFF needs a subscript" name
            else if rest = "" then begin
              (* not in the syntax (LR p.337); we set the null string *)
              Ctx.warn ctx ".se %s: = or a quoted value expected" name;
              set ""
            end
            else if rest.[0] = '\'' then set (Expr.qstring rest)
            else if String.lowercase_ascii (String.trim rest) = "lib" then
              (* the value is the first line of the library member
               (p.240, p.282) *)
              match sub with
              | `At 0 ->
                  if not (Library.load_symbol ctx name) then
                    Ctx.error ctx ".se %s lib: no member %s in the libraries"
                      name (Library.member_name name)
              | _ -> Ctx.error ctx ".se %s lib: a subscript is not allowed" name
            else begin
              (* not in the syntax (LR p.337); we take the value as
                 written *)
              Ctx.warn ctx ".se %s: = or a quoted value expected" name;
              set (sub_word rest)
            end)
  end

(* .su on|off|n (p.230): with n, the next n input lines are substituted,
   then substitution goes off. *)
let su ctx ops =
  match String.lowercase_ascii (String.trim ops) with
  | "" | "on" ->
      ctx.Ctx.subst_on <- true;
      ctx.su_lines <- 0
  | "off" ->
      ctx.subst_on <- false;
      ctx.su_lines <- 0
  | o -> (
      match int_of_string_opt o with
      | Some k when k >= 0 ->
          ctx.subst_on <- k > 0;
          ctx.su_lines <- k
      | _ -> Ctx.error ctx ".su: ON, OFF or a number expected, not %s" o)

(* .ur line: process [line] with substitution even under .su off. *)
let ur ctx ops =
  ctx.Ctx.process ctx
    (if ctx.Ctx.line_substituted then Ctx.Split true else Ctx.Force_subst)
    ops

(* ---- control flow ------------------------------------------------------ *)

(* The long forms .AND .ELSE .THEN .GOTO of .AN .EL .TH .GO (LR p.66,
   p.164, p.395, p.179). *)
let long_forms =
  [ ("and", "an"); ("else", "el"); ("then", "th"); ("goto", "go") ]

(** The control word of [c] and its operands; a long form is its two-character
    word. *)
let word_of (c : Line.control) =
  match c.Line.long with
  | Some l when List.assoc_opt l long_forms = Some c.name ->
      (c.name, Line.drop_blank c.long_args)
  | _ -> (c.name, Line.operands c)

let combines ch s =
  match Line.classify ch s with
  | Line.Control c -> c.name = "an" || c.name = "or"
  | _ -> false

(* The target of a condition: processed when [b], as an input line of its
   own ("the first nonblank character after .TH treated as the first
   position of the subject line", LR p.395, p.164, p.203).  An .an/.or
   target is processed whatever the result: SH35-0069 p.265's
   ".if x&city eq xCleveland .or x&city eq xWarrensburg" must reach the
   .or when the .if is false. *)
let conditional ctx b rest =
  if rest <> "" && (b || combines ctx.Ctx.chars rest) then
    ctx.Ctx.process ctx (Ctx.Split ctx.Ctx.line_substituted) rest

(* DCF-VERIFY (not in LR Rel 4): on a malformed condition we diagnose
   and take it as false. *)
let eval_condition ctx cw ops =
  match Expr.condition ~sub:(operand_subst ctx) ops with
  | Ok r -> Some r
  | Error e ->
      Ctx.error ctx ".%s: %s" cw e;
      None

(* A comparison whose result [f b] becomes the current one. *)
let test ctx cw f ops =
  match eval_condition ctx cw ops with
  | Some (b, rest) ->
      let r = f b in
      Ctx.set_cond ctx (Some r);
      conditional ctx r rest
  | None -> Ctx.set_cond ctx (Some false)

let if_ ctx ops = test ctx "if" Fun.id ops

(* .th/.el test the most recent comparison in the current file or macro;
   it is preserved across macro calls and imbeds (SH35-0069 p.265), and
   they do not consume it (a series of .th/.el lines all apply, LR p.164
   r4).  With no comparison yet, .th processes its target and .el does
   not (LR p.395 r5, p.164 r5). *)
let th ctx ops =
  conditional ctx (Option.value (Ctx.cond ctx) ~default:true) (String.trim ops)

let el ctx ops =
  match Ctx.cond ctx with
  | Some b -> conditional ctx (not b) (String.trim ops)
  | None -> ()

(* .an / .or (LR p.65, p.273) combine with the preceding comparison, and
   like .if process their own target.  DCF-VERIFY (not in LR Rel 4): with
   no comparison yet, an error. *)
let combine cw f ctx ops =
  match Ctx.cond ctx with
  | Some prev -> test ctx cw (f prev) ops
  | None -> Ctx.error ctx ".%s without a preceding .if" cw

let an = combine "an" ( && )
let or_ = combine "or" ( || )

(* .go [TO] label (LR p.179): TO is ignored (.GO TO, .GOTO).  An undefined
   label is an error (DCF then stops; we go on, as after our other
   errors).  DCF-VERIFY (not in LR Rel 4): label names compare
   case-insensitively. *)
let go ctx ops =
  let ws =
    match words ops with
    | t :: (_ :: _ as r) when String.lowercase_ascii t = "to" -> r
    | ws -> ws
  in
  match ws with
  | [] -> Ctx.error ctx ".go: label name required"
  | w :: rest -> (
      if rest <> [] then Ctx.warn ctx ".go: extra operands ignored";
      let w =
        if String.length w > 3 && String.sub w 0 3 = "..." then
          String.sub w 3 (String.length w - 3)
        else w
      in
      match Input.goto ctx.Ctx.input ~label_of:(Line.label_of ctx.chars) w with
      | Ok () ->
          ctx.go_count <- ctx.go_count + 1;
          if ctx.go_count > ctx.max_go then begin
            Ctx.error ctx ".go: more than %d jumps (loop?); processing stopped"
              ctx.max_go;
            Ctx.abort ctx
          end
      | Error e -> Ctx.error ctx ".go: %s" e)

(* ---- conditional sections (LR p.105-106, p.464) ------------------------ *)

(** Is the current line in an ignored conditional section? The bypass "is not a
    total one: macros and GML tags are resolved" (SH35-0069 p.268): native
    control words and text are dropped, macro calls and GML tags run (their
    APFs' document output is muted, [Ctx.sync_mute]). The Rel 4 Starter Set
    relies on it: :psc/:epsc (DSMPSC/DSMEPSC) enclose the element in conditional
    section 9, which DSM@PROC sets to ignore (SSR B.2.16); that works only if
    the :epsc APF runs inside the ignored section. The lines of the macros
    invoked from the section (frames that were not on the stack when it began,
    [Ctx.cs_frames]) are not in it. LR Rel 4 p.105 and p.464 describe the bypass
    of control words only. DCF-VERIFY: whether macro side effects happen. *)
let cs_ignoring ctx =
  List.exists (fun e -> e.Ctx.ignored) ctx.Ctx.cs_open
  && List.mem (Input.current_frame_id ctx.input) ctx.cs_frames

(* .cs n on|off|ignore|include; the blank before OFF is required
   (LR p.105).  Sections are included unless set to IGNORE (p.105 r4). *)
let cs ctx ops =
  match List.map String.lowercase_ascii (words ops) with
  | [ n; kw ] -> (
      match int_of_string_opt n with
      | Some k when k >= 1 && k <= 9 -> (
          match kw with
          (* in an ignored section only ON/OFF are processed, to pair the
             sections: in the TABLE example of SH35-0069 p.55-56 the
             .cs 2 include inside the ignored section 1 must have no
             effect until .cs 1 include *)
          | ("ignore" | "include") when cs_ignoring ctx -> ()
          | "ignore" -> Hashtbl.replace ctx.Ctx.cs_modes k true
          | "include" -> Hashtbl.replace ctx.cs_modes k false
          | "on" ->
              let ignored =
                Option.value (Hashtbl.find_opt ctx.cs_modes k) ~default:false
              in
              if
                ignored
                && not (List.exists (fun e -> e.Ctx.ignored) ctx.cs_open)
              then ctx.cs_frames <- Input.frame_ids ctx.input;
              ctx.cs_open <-
                { Ctx.section = k; ignored; cs_from = ctx.loc } :: ctx.cs_open;
              Ctx.sync_mute ctx
          | "off" ->
              if List.exists (fun e -> e.Ctx.section = k) ctx.cs_open then (
                let rec drop = function
                  | e :: r when e.Ctx.section = k -> r
                  | e :: r -> e :: drop r
                  | [] -> []
                in
                ctx.cs_open <- drop ctx.cs_open;
                Ctx.sync_mute ctx)
              else Ctx.warn ctx ".cs %d off: section %d is not on" k k
          | _ -> Ctx.error ctx ".cs %d: ON, OFF, IGNORE or INCLUDE expected" k)
      | _ -> Ctx.error ctx ".cs: section number 1 to 9 expected, not %s" n)
  | _ ->
      Ctx.error ctx
        ".cs: section number and ON, OFF, IGNORE or INCLUDE expected"

(* .ct [text] (p.48): the text continues the previous text line without a
   word space; alone, a continuation in effect is cancelled.  The text is
   an input line: a continuation character at its end continues it in
   turn (IBM's DSMFDESC: ".ct :&$RB.&$RB.&$CONT"). *)
let ct ctx ops =
  if ops = "" then Doc.cancel_continuation ctx.Ctx.doc
  else begin
    Doc.join_previous ctx.Ctx.doc;
    let n = String.length ops in
    let continued = ctx.Ctx.chars.Chars.cont = Some ops.[n - 1] in
    ctx.Ctx.process ctx
      (Ctx.Residual { Input.had_text = true; eol = not continued })
      (if continued then String.sub ops 0 (n - 1) else ops)
  end

(* ---- macros ------------------------------------------------------------- *)

(* .dm name /l1/l2/... | .dm name(n) /line/ | .dm name() /line/
   | .dm name(n) off | .dm name on | .dm name off | .dm name lib
   | .dm name[(n)] x | .dm name delete (EXT) (LR p.141-145).
   The line is substituted like any other when .su is on (p.142); the
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
      ctx.capture <- Some { Ctx.cname = name; cbody = []; cfrom = ctx.loc }
  | Macro.Assign (name, sub, x) -> (
      let sep =
        match ctx.Ctx.chars.Chars.cw_sep with
        | Some c -> String.make 1 c
        | None -> " "
      in
      match Macro.value st name sub ~sep with
      | None -> Ctx.error ctx ".dm %s %s: macro %s is not defined" name x name
      | Some v -> (
          match Ctx.Sym.set ctx x v with
          | Ok () -> ()
          | Error e -> Ctx.error ctx ".dm %s %s: %s" name x e))
  | Macro.Lib name ->
      (* searched whatever the setting of .ly; the definition replaces any
       existing one (p.282) *)
      if Library.load_macro ctx name = None then
        Ctx.error ctx ".dm %s lib: no member %s in the libraries" name
          (Library.member_name name)
  | Macro.End None -> Ctx.error ctx ".dm off without .dm name on"
  | Macro.End (Some name) | Macro.Delete name ->
      (* DCF-VERIFY (not in LR Rel 4): deleting an undefined macro is
         silently accepted *)
      ignore (Macro.delete st name)

(* The body captured by [.dm name on] is complete. *)
let end_capture ctx (cap : Ctx.capture) =
  ctx.Ctx.capture <- None;
  Macro.define ctx.macros cap.cname ~at:cap.cfrom (List.rev cap.cbody)

(* .ly on|off|mac|sym (LR p.243): which unresolved names the libraries
   are searched for.  ON: macros and symbols; MAC adds macros and SYM
   symbols to what was asked before; OFF: neither (the initial
   setting).  Without an operand: ON. *)
let ly ctx ops =
  match String.lowercase_ascii (String.trim ops) with
  | "" | "on" ->
      ctx.Ctx.ly_mac <- true;
      ctx.ly_sym <- true
  | "off" ->
      ctx.ly_mac <- false;
      ctx.ly_sym <- false
  | "mac" -> ctx.ly_mac <- true
  | "sym" -> ctx.ly_sym <- true
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
   SH35-0050 p.17).  Outside a macro the line is processed as if it had
   been written without the .me (LR p.245 r1). *)
let me ctx ops =
  match Input.end_macro ctx.Ctx.input with
  | Some _ ->
      if String.trim ops <> "" then
        Input.push_back ctx.input ~kind:(Input.Split ctx.line_substituted) ops
          ctx.loc
  | None ->
      if String.trim ops <> "" then
        ctx.Ctx.process ctx (Ctx.Split ctx.line_substituted) ops

(** Invoke macro [name] in a new Macro frame whose local scope is [scope] (it
    holds the arguments). *)
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

(** Invoke macro [name] with operands [ops] (already substituted): a new Macro
    frame, whose local scope holds the arguments. *)
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
  while !j < n && !j < len && Line.is_name_char ops.[!j] do
    incr j
  done;
  ( String.lowercase_ascii (String.sub ops 0 !j),
    Line.drop_blank (String.sub ops !j (n - !j)) )

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
  r "go" go;
  r "cs" cs;
  r "ct" ct;
  r "dm" dm;
  r "ms" ms;
  r "ly" ly;
  r "me" me;
  r "em" em;
  r "ec" ec
