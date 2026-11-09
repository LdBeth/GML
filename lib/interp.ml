(* The main loop: the per-line processing of SCRIPT/VS.

   Per-line order.  A physical input line (a line of a file or macro,
   [Ctx.Raw]) goes through these steps; the numbers are referred to
   below.

   1. Macro definition capture.  While a [.dm name on] definition is in
      progress, the raw line is appended to the body: no substitution, no
      tag scanning, nothing executed (SH35-0069 p.272).  The definition
      ends at a [.dm off] line, which must start in column 1 without the
      modifier (p.272).  An inline [.dm x on] line also ends it (p.280:
      "an inline form of .DM within an inline form will cause the initial
      macro definition to end"), and then starts its own definition.
      Single-line and subscripted [.dm] lines are just body lines.  A
      [.dm name on] seen while skipping (step 2) starts a capture that
      discards its body, so that the [.do] lines in it do not count.
   2. Skipping.  Inside a skipped [.do] group (a false [.if]/[.th]/[.el]
      whose object was [.do begin]) the raw line is only split at the
      separator and examined for [.do begin] / [.do end] (also as the
      object of a conditional word) to track nesting.  Nothing is
      substituted or executed.  Lines of an ignored conditional section
      ([.cs], p.267-269) are not skipped here: their macros and GML tags
      are still resolved (step 6).
   3. Comments and labels, on the raw line: a [.*] line is ignored as a
      whole, separators included, and never substituted (p.44); a label
      line [...name] is not substituted either.
      DCF-VERIFY: text after a label on the same line is ignored.
   4. Symbol substitution of the whole line, if [.su] is on (p.229-230,
      chapter 21), right to left, with the extended symbol rule: a value
      that begins with the separator splits the line there, the rest
      becoming new input lines (p.257-258).  Substitution comes before
      the line is classified, so a control word can come out of a symbol
      and a separator out of a value is a separator (p.258).  With
      [.su off], [.se] and [.if] lines still have their operands
      substituted, by those words themselves ([Ctx.line_substituted]).
   5. Classification of the substituted line, and the separator rule
      (p.40-41, [Line.split]): a control word line is split at every
      separator unless it has the [.'] modifier, which acts on this one
      line only (p.258); a text line is split only at a separator
      followed by the indicator and a control word name, the part before
      it being text with continuation (no word space).  The rest is the
      next input line.
   6. Dispatch.  A control word line: with [.ms on] and no modifier, the
      longest name ([Line.control.long]) is tried as a macro first,
      then (with [.ly on|mac], when it is not a control word name) as a
      member of the macro library, which defines it ([Library], p.282);
      otherwise the first two characters are the control word (p.40,
      p.271).  A text line: the continuation character
      ([.dc cont], p.47) is removed from its end; a null line, a blank
      line, a leading blank and a leading tab are the implicit control
      words [.nl], [.bl], [.lb] and [.lt] (p.281): a macro of that name
      (with [.ms on]) is invoked with the line as [&*]; for [.lb]/[.lt]
      the line is processed as text after the macro (the macro replaces
      the break, p.281: [.dm lb /.*] makes the blank an ordinary one).
      Natively [.lb]/[.lt] give a break hint (none in no-fill mode)
      and then the line; in fill mode [.bl] is [.sp 1] and [.nl] only
      cancels a continuation, in no-fill mode both are text lines
      ([Hints.implicit]).  Text then goes to [Gmlproc.text], which
      scans it for GML tags once [.gs tag on].
   Literal mode ([.li], p.89).  While [.li on] or [.li n] is in effect,
      steps 3-6 are replaced: only a [.li off] line is a control word;
      every other line is substituted (if [.su] is on) and is text, with
      no separator split, no tag scan and no implicit words.
      In an ignored conditional section only [.cs] lines, macro calls
      and the GML tags of text lines are processed; the text is dropped.

   The rest of a split line ([Ctx.Split]) and the object of [.if],
   [.th], [.el] start at step 3 but skip step 4: they are never
   substituted again.  They are not physical lines, so step 1 (the end of
   a definition) and the implicit words of step 6 do not apply to them.
   [.ur] lines ([Ctx.Force_subst]) are substituted whatever [.su] says.

   The text after a GML tag (residual text and the rest of the line)
   comes back as [Ctx.Residual] lines: substituted with the whole line
   before the tag's APF ran, never a control word, only scanned for tags
   (SH35-0069 p.294).  While skipping they are dropped; while capturing a
   [.dm] body they are captured. *)

let is_cw ctx = Ctx.is_cw_name ctx

(* ---- step 1: capture ----------------------------------------------------- *)

let dm_operands ctx s =
  match Line.classify ctx.Ctx.chars s with
  | Line.Control c when c.name = "dm" -> Some (Line.operands c)
  | _ -> None

(* [.dm off], in column 1 and without the modifier (p.272). *)
let ends_definition ctx s =
  match Line.classify ctx.Ctx.chars s with
  | Line.Control c ->
      c.name = "dm" && (not c.quoted)
      && String.lowercase_ascii (String.trim (Line.operands c)) = "off"
  | _ -> false

let starts_definition ctx s =
  match Option.map Macro.parse_dm (dm_operands ctx s) with
  | Some (Macro.Begin _) -> true
  | _ -> false

(* ---- step 2: skipping ------------------------------------------------------ *)

let skip_line ctx s =
  let ch = ctx.Ctx.chars in
  match Option.map Macro.parse_dm (dm_operands ctx s) with
  | Some (Macro.Begin name) ->
      ctx.capture <-
        Some { Ctx.cname = name; cbody = []; cfrom = ctx.loc; discard = true }
  | _ ->
      let s, rest = Line.split ch ~is_cw:(is_cw ctx) s in
      Option.iter
        (fun r -> Input.push_back ctx.input ~kind:(Input.Split false) r ctx.loc)
        rest;
      if Control.opens_group ch s then ctx.skip <- ctx.skip + 1
      else if Control.closes_group ch s then ctx.skip <- ctx.skip - 1

(* ---- step 6: dispatch -------------------------------------------------------- *)

(* An unresolved macro from the library ([.ly on|mac], p.282): with
   [.ms on] and without the modifier, like any macro call, when the long
   name is not itself a control word name (so [.sp] never searches the
   library).  The library is searched before the two-character native
   word: [.dsmgdoc] is the macro DSMGDOC, not [.ds mgdoc].
   DCF-VERIFY: this order. *)
let library_macro ctx (c : Line.control) =
  if ctx.Ctx.ms_on && ctx.ly_mac && not c.Line.quoted then
    match c.Line.long with
    | Some name when not (Ctx.is_cw_name ctx name) ->
        Option.map
          (fun m -> (name, m, Line.drop_blank c.Line.long_args))
          (Library.find_macro ctx name)
    | _ -> None
  else None

let control ctx (c : Line.control) =
  let ignoring = Control.cs_ignoring ctx in
  match
    match Ctx.macro_of ctx c with
    | Some _ as r -> r
    | None -> library_macro ctx c
  with
  | Some (name, m, ops) -> Control.invoke ctx name m ops
  | None when ignoring && c.name <> "cs" -> ()
  | None -> (
      match Hashtbl.find_opt ctx.Ctx.words c.name with
      | Some w -> w.run ctx (Line.operands c)
      | None -> Ctx.warn ctx "unsupported control word .%s" c.name)

let plain_text ctx ~eol t =
  Gmlproc.text ctx ~plain:true { Input.had_text = false; eol } t

(* The implicit control word of a physical text line (p.281). *)
let implicit t =
  if t = "" then Some "nl"
  else if String.for_all (fun c -> c = ' ') t then Some "bl"
  else if t.[0] = ' ' then Some "lb"
  else if t.[0] = '\t' then Some "lt"
  else None

let text ctx ~physical ~continued t =
  let continued, t =
    match ctx.Ctx.chars.Chars.cont with
    | Some c when t <> "" && t.[String.length t - 1] = c ->
        (true, String.sub t 0 (String.length t - 1))
    | _ -> (continued, t)
  in
  let eol = not continued in
  if Control.cs_ignoring ctx then
    (* only the GML tags of the line; the document builder is muted
       ([Ctx.sync_mute]), so only their APFs' side effects remain *)
    begin if ctx.tag_scan <> Ctx.Tags_off then plain_text ctx ~eol t
    end
  else
    match if physical then implicit t else None with
    | None -> plain_text ctx ~eol t
    | Some w -> (
        match if ctx.ms_on then Macro.find ctx.macros w else None with
        | Some m ->
            if w = "lb" || w = "lt" then
              ignore
                (Input.push_residual ctx.input t ctx.loc
                   { Input.had_text = true; eol });
            Control.invoke ctx w m t
        | None -> (
            (* natively (p.90-91): .lb/.lt are a break, then the line;
           .bl is a .sp; .nl only cancels a continuation.  In no-fill
           mode ([.fo off], [.nf on]: every input line is an output
           line) the break is implied, and a blank or null line is kept
           as an empty text line (modern edge for .nl: files written
           by modern editors have null lines where CMS had blank ones;
           DCF-VERIFY). *)
            let nofill = not ctx.fmt.Ctx.fill in
            match w with
            | "lb" | "lt" ->
                if not nofill then Hints.implicit ctx w "";
                plain_text ctx ~eol t
            | _ ->
                if nofill then plain_text ctx ~eol t else Hints.implicit ctx w t
            ))

(* [.li] (SH35-0069 p.42): literal lines are text even when they begin
   with the control word indicator, a blank or a tab: no control word,
   no implicit word ([.lb .lt .bl .nl], p.281), no separator split.  They
   are substituted and scanned for GML tags like other text lines
   (DCF-VERIFY).  In literal mode only [.li off] is a control word. *)
let literal_line ctx s =
  let s = if ctx.Ctx.subst_on then Subst.string ctx s else s in
  text ctx ~physical:false ~continued:false s

let li ctx ops =
  match String.lowercase_ascii (String.trim ops) with
  | "" -> ctx.Ctx.literal <- 1
  | "on" -> ctx.literal <- -1
  | "off" -> ctx.literal <- 0
  | o -> (
      match int_of_string_opt o with
      | Some n when n >= 0 -> ctx.literal <- n
      | _ -> text ctx ~physical:false ~continued:false ops)

let literal_off ctx s =
  match Line.classify ctx.Ctx.chars s with
  | Line.Control c ->
      c.name = "li"
      && String.lowercase_ascii (String.trim (Line.operands c)) = "off"
  | _ -> false

(* Steps 3, 5 and 6 of a line that is substituted already (or not to be
   substituted). *)
let dispatch ctx ~physical ~substituted s =
  let ch = ctx.Ctx.chars in
  match Line.classify ch s with
  | Line.Comment _ | Line.Label _ -> ()
  | Line.Control _ | Line.Text _ -> (
      let head, rest = Line.split ch ~is_cw:(is_cw ctx) s in
      Option.iter
        (fun r ->
          Input.push_back ctx.input ~kind:(Input.Split substituted) r ctx.loc)
        rest;
      ctx.line_substituted <- substituted;
      match Line.classify ch head with
      | Line.Comment _ | Line.Label _ -> ()
      | Line.Control c -> control ctx c
      | Line.Text t -> text ctx ~physical ~continued:(rest <> None) t)

(* Step 4, then the rest. *)
let substitute_and_dispatch ctx mode s =
  match Line.classify ctx.Ctx.chars s with
  | Line.Comment _ | Line.Label _ -> () (* step 3: never substituted *)
  | Line.Control _ | Line.Text _ -> (
      (* a new input line: no questions yet (Ctx.line_queries; with .su
         off a .se asks while it substitutes its own operands) *)
      ctx.Ctx.line_queries <- [];
      let force = mode = Ctx.Force_subst in
      let on = force || ctx.subst_on in
      if mode = Ctx.Raw && ctx.su_lines > 0 then begin
        ctx.su_lines <- ctx.su_lines - 1;
        if ctx.su_lines = 0 then ctx.subst_on <- false
      end;
      if not on then
        dispatch ctx ~physical:(mode = Ctx.Raw) ~substituted:false s
      else
        match Subst.line ctx s with
        | [] -> ()
        | first :: more ->
            Input.push_back_list ctx.input
              (List.map (fun l -> (l, ctx.loc, Input.Split true)) more);
            dispatch ctx ~physical:(mode = Ctx.Raw) ~substituted:true first)

let process ctx mode s =
  match ctx.Ctx.capture with
  | Some cap ->
      if mode = Ctx.Raw && ends_definition ctx s then
        Control.end_capture ctx cap
      else if mode = Ctx.Raw && starts_definition ctx s then begin
        Control.end_capture ctx cap;
        ctx.process ctx mode s
      end
      else if not cap.discard then cap.cbody <- s :: cap.cbody
  | None -> (
      if ctx.Ctx.skip > 0 then
        match mode with Ctx.Residual _ -> () | _ -> skip_line ctx s
      else
        match mode with
        | Ctx.Residual p ->
            if not (Control.cs_ignoring ctx) then
              Gmlproc.text ctx ~plain:false p s
        | Ctx.Split b -> dispatch ctx ~physical:false ~substituted:b s
        | (Ctx.Raw | Ctx.Force_subst) when ctx.literal <> 0 ->
            if literal_off ctx s then ctx.literal <- 0
            else begin
              if ctx.literal > 0 then ctx.literal <- ctx.literal - 1;
              literal_line ctx s
            end
        | Ctx.Raw | Ctx.Force_subst -> substitute_and_dispatch ctx mode s)

(* -set sym=val: global symbols, set before the first line; for a
   system symbol, the value it has throughout (-set '$PDEV=4250'). *)
let install_sets ctx =
  List.iter
    (fun (k, v) -> ignore (Symbols.set ctx.Ctx.syms k v))
    (Symbols.date_symbols ());
  List.iter
    (fun (k, v) ->
      if Symbols.is_local k then Ctx.error ctx "-set %s: not a global symbol" k
      else if Symbols.is_system ctx.Ctx.syms k then
        ctx.Ctx.sys_sets <- (Symbols.norm k, v) :: ctx.Ctx.sys_sets
      else
        Control.check_name ctx "-set" k (fun () ->
            match Symbols.set ctx.Ctx.syms k v with
            | Ok () -> ()
            | Error e -> Ctx.error ctx "-set: %s" e))
    ctx.Ctx.sets

let check_balance ctx =
  List.iter
    (fun e -> Ctx.error_at ctx e.Ctx.opened ".do begin without .do end")
    (List.rev ctx.Ctx.do_stack);
  if ctx.skip > 0 then
    Ctx.error_at ctx ctx.skip_from
      ".do begin without .do end (skipped to end of input)";
  Option.iter
    (fun cap ->
      Ctx.error_at ctx cap.Ctx.cfrom
        ".dm %s on without .dm off (definition ignored)" cap.Ctx.cname)
    ctx.capture;
  List.iter
    (fun e ->
      Ctx.warn ctx ".cs %d on without .cs %d off (opened at %s)" e.Ctx.section
        e.Ctx.section
        (Loc.to_string e.Ctx.cs_from))
    (List.rev ctx.cs_open);
  ctx.capture <- None;
  ctx.skip <- 0;
  ctx.do_stack <- [];
  ctx.cs_open <- [];
  Ctx.sync_mute ctx

(* One line of the input: its location, then [process] in its mode. *)
let process_line ctx (s, loc, kind) =
  ctx.Ctx.loc <- loc;
  process ctx
    (match kind with
    | Input.Source -> Ctx.Raw
    | Input.Residual p -> Ctx.Residual p
    | Input.Split b -> Ctx.Split b)
    s

(* Process lines until the input stack is empty. *)
let rec drain ctx =
  match Input.next_line ctx.Ctx.input with
  | None -> ()
  | Some line ->
      process_line ctx line;
      drain ctx

let run ctx =
  install_sets ctx;
  let rec loop () =
    drain ctx;
    (* the epifile: the rest of the profile after its .ef (p.51) *)
    match ctx.epifile with
    | Some (path, lines, idx) ->
        ctx.epifile <- None;
        Input.push_file_at ctx.input path lines idx;
        loop ()
    | None -> ()
  in
  loop ();
  check_balance ctx

(** Process the file [path] now, line by line like an imbedded file, on an empty
    input stack (before [run]: the coupling files of the pass model, [Aux]);
    returns when the file has ended. *)
let imbed_now ctx path =
  match Input.imbed ctx.Ctx.input ("(" ^ path ^ ")") with
  | Error e -> Ctx.error ctx "%s" e
  | Ok _ -> drain ctx

(** A context with the native control words installed. *)
let create ?include_path () =
  let ctx = Ctx.create ?include_path () in
  ctx.process <- process;
  Control.install ctx;
  Gmlproc.install ctx;
  Emit.install ctx;
  Hints.install ctx;
  Ctx.register ctx "li" li;
  ctx

(** Close the document; returns the root node. *)
let finish ctx =
  let root, unclosed = Doc.finish ctx.Ctx.doc in
  (* elements that are implicitly closable ([.xd]) close silently *)
  List.iter
    (fun n -> Ctx.warn ctx "element %s not closed at end of input" n)
    unclosed;
  root
