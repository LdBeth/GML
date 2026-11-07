(* The interpreter context.

   It lives in its own module so that [Control] (the native control
   words) and [Interp] (the main loop) can both see it without being
   mutually recursive: the dispatch table is part of the context, filled
   by [Control.install] and by later phases (symbols, macros, GML tags,
   hints) through [register].  For the same reason the line processor
   itself is reachable from control words through the [process] field,
   installed by [Interp.create]. *)

(** How [process] treats a line. *)
type mode =
  | Raw  (** a physical input line: the whole per-line processing *)
  | Force_subst  (** [.ur]: as [Raw] but always substituted *)
  | Split of bool
      (** the rest of a line after a split, or the object of [.if]/[.th]/ [.el]:
          classified, split and dispatched but not substituted again; [true] if
          the line it comes from was substituted *)
  | Residual of Input.piece  (** text after a GML tag (see [Input.kind]) *)

type rules = {
  att : bool;  (** [att]: name=value attributes are recognised *)
  vat : bool;  (** [vat]: value attributes are recognised *)
  stop : bool;
      (** [stop]: an invalid attribute ends the scan and is text; [step]: it is
          skipped *)
  msg : bool;  (** [msg]: an invalid attribute is reported *)
  elem : bool;  (** our extension: the tag opens an element *)
}
(** GML attribute scanning rules ([.gs rules], [.aa]; SH35-0069 p.291), plus our
    [elem]/[noelem]. *)

type assoc = {
  apf : string option;
  arules : string list;
  endapf : string option;
  endrules : string list;
}
(** [.aa tag apf (rules) endapf (rules)]: rule keywords are kept as written and
    applied over the [.gs rules] at each use. *)

type tag_scan = Tags_off | Tags_on | Tags_onno

(** What happens to a tag without an APF ([-undef-tags]). *)
type undef_tags = Undef_text | Undef_element | Undef_error

type do_entry = {
  saved_cond : bool option;  (** the frame's comparison when the group began *)
  owner : int;  (** [Input.current_frame_id] at [.do begin] *)
  opened : Loc.t;
}

type capture = {
  cname : string;
  mutable cbody : string list;  (** captured raw lines, last first *)
  cfrom : Loc.t;  (** the [.dm name on] line *)
  discard : bool;
      (** the [.dm] is inside a skipped [.do] group: its body is only skipped
          over (so [.do] lines in it do not count), nothing is defined *)
}
(** A [.dm name on] definition in progress. *)

type fmt = {
  mutable left : Units.sum;  (** [.in], permanent left indention *)
  mutable right : Units.sum;  (** [.ir], right indention *)
  mutable offset : Units.sum;  (** [.of] *)
  mutable ll : Units.sum option;  (** [.ll]; None: the device default *)
  mutable fill : bool;  (** concatenation ([.fo]/[.nf]) *)
  mutable align : string;  (** justify, left, right, center, inside, outside *)
  mutable overdraw : string;  (** extend, fold, trunc *)
  mutable fonts : string list;  (** [.bf] stack, innermost first *)
  mutable hyph : bool;  (** [.hy on|off] *)
}
(** The formatting state that the hints record ([Hints]): each hint carries the
    new value, so the state is tracked here. *)

let initial_fmt () =
  {
    left = Units.zero;
    right = Units.zero;
    offset = Units.zero;
    ll = None;
    fill = true;
    align = "justify";
    overdraw = "extend";
    fonts = [];
    hyph = false;
  }

let copy_fmt (f : fmt) = { f with left = f.left }

type saved = {
  env : string;  (** the [.sa] name, upper case; "" without one *)
  sfmt : fmt;
  str : (int, string) Hashtbl.t;  (** the translate table ([.tr]) *)
}
(** A saved formatting environment ([.sa], SH20-9161-3 p.110). *)

type cs_entry = { section : int; ignored : bool; cs_from : Loc.t }
(** The open conditional sections ([.cs n on]), innermost first. *)

type t = {
  chars : Chars.t;
  input : Input.t;
  doc : Doc.t;
  diag : Loc.diag;
  include_path : string list;  (** -I directories *)
  mutable sets : (string * string) list;
      (** -set sym=val, in command-line order; [Interp.run] makes them global
          symbols *)
  mutable sys_sets : (string * string) list;
      (** -set values of system symbols (normalised names): they override the
          computed value ([system_symbol]) *)
  words : (string, word) Hashtbl.t;  (** native control words *)
  mutable loc : Loc.t;  (** location of the current line *)
  syms : Symbols.t;
  mutable subst_on : bool;  (** [.su on|off] *)
  mutable su_lines : int;
      (** [.su n]: lines still to be substituted before substitution goes off
          (0: not counting) *)
  mutable line_substituted : bool;
      (** the line being dispatched was substituted (with [.su off] [.se] and
          [.if] substitute their operands themselves) *)
  mutable ret : int;  (** [&$RET] *)
  mutable do_stack : do_entry list;  (** executed [.do begin]s *)
  mutable skip : int;
      (** > 0: skipping a [.do] group; nesting depth of the skipped groups *)
  mutable skip_from : Loc.t;  (** where the skipped group began *)
  mutable skip_owner : int;
      (** [Input.current_frame_id] where the skipped group began: a skip that
          reaches the end of its macro ends there *)
  cs_modes : (int, bool) Hashtbl.t;  (** [.cs n ignore] (true) / include *)
  mutable cs_open : cs_entry list;  (** open conditional sections *)
  mutable cs_frames : int list;
      (** the file and macro frames ([Input.frame_ids]) on the stack when the
          outermost ignored section began: their lines are in the section; the
          lines of macros invoked from it (new frames: the APFs of its tags) are
          processed *)
  macros : Macro.store;
  mutable ms_on : bool;  (** [.ms on|off] *)
  mutable capture : capture option;  (** [.dm name on] in progress *)
  mutable max_macro_depth : int;  (** nesting limit of macro calls *)
  mutable go_count : int;  (** [.go] jumps so far *)
  mutable max_go : int;  (** limit on [.go] jumps *)
  mutable profile_id : int;  (** frame id of the -profile file *)
  mutable epifile : (string * string array * int) option;
      (** the rest of the profile after its [.ef] (path, lines, index) *)
  warned : (string, unit) Hashtbl.t;  (** one-time warnings given *)
  mutable tag_scan : tag_scan;  (** [.gs tag on|onno|off] *)
  mutable tag_rules : rules;  (** [.gs rules (tags) ...] *)
  mutable end_rules : rules;  (** [.gs rules ... (end tags)] *)
  mutable prefix : char option;  (** [.gs prefix c] (class mapping) *)
  assocs : (string, assoc) Hashtbl.t;  (** [.aa], by lowercase tag name *)
  mutable undef_tags : undef_tags;
  mutable gml_attrs : (string * string) list;
      (** the attribute stack: name=value attributes of the last tag, names
          uppercase, in order; purged by the next tag (p.291) *)
  mutable residual : Input.lines_frame option;
      (** the residual text of the last tag ([.gs scan/copy/insert]) *)
  mutable process : t -> mode -> string -> unit;
      (** the line processor ([Interp.process]) *)
  fmt : fmt;  (** formatting state ([Hints]) *)
  mutable saved : saved list;
      (** environments saved by [.sa] (and by [.fn on]), innermost first *)
  hctr : Headctr.t;  (** the head-level counter ([.gs hctr], [.dh n num]) *)
  dh_num : (int, unit) Hashtbl.t;  (** head levels defined NUM ([.dh]) *)
  toc : Toc.t;  (** table of contents entries and definitions ([.dh], [.hn], [.pt], [.tc]) *)
  mutable literal : int;
      (** [.li]: input lines still to be taken literally; -1: [.li on] *)
  mutable last_tag : string;  (** [&$TAG] *)
  mutable last_tagd : string;  (** [&$TAGD] *)
  mutable libs : string list;
      (** [-lib] directories, searched in order ([Library]) *)
  mutable ly_mac : bool;  (** [.ly on|mac]: search for macros *)
  mutable ly_sym : bool;  (** [.ly on|sym]: search for symbols *)
  lib_members : (string, string array option) Hashtbl.t;
      (** library members read so far, by member name; [None]: not found *)
  mutable pass : int;  (** [&$PASS]: this formatting pass (gml -pass) *)
  mutable passes : int;
      (** the number of formatting passes (gml -passes; SCRIPT's FPASSES(n),
          TWOPASS = 2, SH20-9186-06 p.126, p.129): [&$TWO] is 1 when it is
          more than 1, [&$PASSES] is it *)
  query_files : (string, int) Hashtbl.t;
      (** the files questions were asked in, numbered in order of the first
          question ([query]) *)
  query_lines : (string, int) Hashtbl.t;
      (** questions asked so far per input line ("file.line") *)
  mutable page_query : (string -> string option) option;
      (** [Some f]: the pass model is on (gml -aux, set by [Aux.load]): each
          reference to [&$PN] or [&$LC] is a question to the layout engine
          ([query]), and [f id] is the answer to question [id] (q2.14.1 ...)
          from the previous pass's aux file (the symbol [pq@ENC] TeX set);
          [f id = None]: not known (the first pass, or a question the previous
          pass did not ask): the neutral constant (1, 60).  [None]: no
          questions *)
  mutable page_of : string -> string option;
      (** the page (as printed) of an anchor, for [.tc]: the page TeX put the
          anchor on in the previous pass ([Aux], the symbol [pa@ENC]); [None]:
          not known, the entry carries [anchor=] and gml.tex's page references
          give the page *)
  mutable coupling : bool;
      (** a coupling file of the pass model (the aux file, the symbol file) is
          being imbedded ([Aux.imbed]): its [.se] names may be longer than ten
          characters *)
}

and word = { run : t -> string -> unit  (** receives the operands *) }

let char_value = function Some c -> String.make 1 c | None -> ""

(* The fonts of the CHARS option of the SCRIPT command, [&$CHAR(n)]
   (SH35-0069 p.178-179, p.242): -set '$CHAR=f1 f2 ...' gives the list.
   DCF-VERIFY: without it, two neutral names (font names have 1-4
   characters, p.242): the text font and the bold font, as on a 3800
   Model 1 with "two complete upper- and lowercase fonts" (p.178);
   IBM's DSMPROF3 selects its 3800f2 font set with these. *)
let fonts ctx =
  match List.assoc_opt "$CHAR" ctx.sys_sets with
  | Some v -> List.filter (( <> ) "") (String.split_on_char ' ' v)
  | None -> [ "TEXT"; "BOLD" ]

(* The current input file name (&$FNAM): the file name without
   directory and extension, in upper case, like a CMS file name.
   DCF-VERIFY: no truncation to eight characters. *)
let file_name ctx =
  String.uppercase_ascii
    (Filename.remove_extension (Filename.basename ctx.loc.Loc.file))

let spaces sum = string_of_int (Units.figure_spaces sum)

(* The system symbols (SH35-0069 Figure 15, p.242-244; SX26-3723).
   There is no output device: the device, command option and page
   symbols have neutral values, chosen so that IBM's Starter Set runs as
   on a 3800 printer in one pass under CMS with indexing.  DCF-VERIFY:
   every one of those values; -set '$NAME=value' overrides any of them. *)
let system_value ctx name sub =
  let st = ctx.fmt in
  let ll = match st.ll with Some l -> spaces l | None -> "65" in
  match (name, sub) with
  | "$CHAR", 0 -> Some (string_of_int (List.length (fonts ctx)))
  | "$CHAR", n ->
      (* "null values when there is no corresponding font" (SH20-9161 .DH) *)
      Some (Option.value (List.nth_opt (fonts ctx) (n - 1)) ~default:"")
  | _, 0 -> (
      match name with
      | "$LINE" -> Some (string_of_int ctx.loc.Loc.line)
      | "$LNUM" ->
          (* the last line number read: in a macro the line's subscript
             (SH35-0050 p.16) *)
          Some
            (string_of_int
               (Option.value
                  (Input.current_lnum ctx.input)
                  ~default:ctx.loc.Loc.line))
      | "$FILE" -> Some ctx.loc.Loc.file
      | "$FNAM" -> Some (file_name ctx)
      | "$RET" -> Some (string_of_int ctx.ret)
      | "$DATE" -> Some (Symbols.date_string ())
      | "$TIME" -> Some (Symbols.time_string ())
      | "$CW" -> Some (char_value ctx.chars.Chars.cw_sep)
      | "$CONT" -> Some (char_value ctx.chars.Chars.cont)
      | "$GML" -> Some (char_value ctx.chars.Chars.gml_delim)
      | "$EGML" -> Some ctx.chars.Chars.gml_end
      | "$RB" -> Some ctx.chars.Chars.rb
      | "$PS" -> Some (String.make 1 ctx.chars.Chars.ps)
      | "$SU" -> Some (if ctx.subst_on then "ON" else "OFF")
      | "$TAB" -> Some "\t" (* the tab character (SH35-0069 p.85, p.246) *)
      | "$BS" -> Some "\b" (* backspace, EBCDIC 16 *)
      | "$ENV" -> Some "BODY" (* modern edge: no keeps, floats, footnotes *)
      (* the page state: a neutral constant here (modern edge: no
         pagination); with the pass model [query] asks TeX and answers
         from the previous pass *)
      | "$PN" -> Some "1"
      | "$KP" | "$VR" -> Some "OFF"
      | "$LST" -> Some "0"
      (* the last GML tag found, as written, and its delimiter (p.251).
         DCF-VERIFY: the case of the name. *)
      | "$TAG" -> Some ctx.last_tag
      | "$TAGD" -> Some ctx.last_tagd
      (* output device (p.242): a 3800 printer, written to a file *)
      | "$PDEV" -> Some "3800"
      | "$LDEV" -> Some "3800N6"
      | "$OUT" -> Some "FILE"
      (* SCRIPT command options (p.242): release 3.0 under CMS, one pass,
         the INDEX option (so .pi is honoured), no bind *)
      | "$DCF" -> Some "3.0"
      | "$SYS" -> Some "CMS"
      | "$PASS" -> Some (string_of_int ctx.pass)
      | "$TWO" -> Some (if ctx.passes > 1 then "1" else "0")
      (* not a DCF symbol: the n of FPASSES(n), so that a profile can tell
         its last pass when there are more than two (TPG p.247 tests
         &$PASS eq 2 for TWOPASS) *)
      | "$PASSES" -> Some (string_of_int ctx.passes)
      | "$UNF" | "$DDUT" | "$BE" | "$BO" -> Some "0"
      | "$INDX" -> Some "1"
      | "$LIB" -> Some (if ctx.libs = [] then "0" else "1")
      | "$PRT" -> Some "ON"
      | "$PARM" -> Some "DEVICE 3800N6 INDEX"
      (* page characteristics (p.243): figure spaces and lines *)
      | "$IN" -> Some (spaces st.left)
      | "$IR" -> Some (spaces st.right)
      | "$OF" -> Some (spaces st.offset)
      | "$LL" | "$CL" -> Some ll
      | "$PW" -> Some "85"
      | "$PL" -> Some "66"
      | "$LC" -> Some "60"
      | "$TM" | "$BM" | "$FM" | "$RH" | "$RF" -> Some "0"
      | _ -> None)
  | _ -> None

(* A reference to &$PN or &$LC with the pass model on (gml -aux): a
   question to the layout engine.  It is the hint gml:query id=ID
   what=pn|lc at the output cursor (the place in the text where the
   line is processed); TeX answers in the aux file (gml.tex \gmlquery:
   pn the page that place is put out on, lc the lines left on the page
   there), and the next pass answers from it ([page_query]).

   The id is qF.L.N: the N-th question asked while line L of input file
   F is processed (the topmost file on the input stack: for an APF, the
   document line with the tag), F counting the files in the order of
   their first question).  Two passes that take the
   same decisions ask the same questions with the same ids; a pass that
   takes another decision on a line (a forward reference resolved on
   pass 2 asks for the page where it is) shifts only the ids of that
   line, so the other answers stay right (a plain counter would make
   every later answer wrong for one more pass).  Every reference asks:
   a .se x = &$PN in a macro asks once per call, which is right (each
   call is at another place); a reference whose value is only tested
   is a question nobody needs, harmless.  No question in ignored output
   (.cs ignore: no hint), nor for a value given by -set. *)
let query_id ctx =
  let path, line =
    match Input.current_file ctx.input with
    | Some ff -> (ff.Input.path, ff.Input.idx)
    | None -> ("", 0)
  in
  let f =
    match Hashtbl.find_opt ctx.query_files path with
    | Some f -> f
    | None ->
        let f = Hashtbl.length ctx.query_files + 1 in
        Hashtbl.add ctx.query_files path f;
        f
  in
  let key = Printf.sprintf "%d.%d" f line in
  let n = 1 + Option.value (Hashtbl.find_opt ctx.query_lines key) ~default:0 in
  Hashtbl.replace ctx.query_lines key n;
  Printf.sprintf "q%s.%d" key n

let query ctx name v =
  match (name, ctx.page_query) with
  | ("$PN" | "$LC"), Some answer
    when (not ctx.doc.Doc.mute) && not (List.mem_assoc name ctx.sys_sets) ->
      let id = query_id ctx in
      Doc.hint ctx.doc "query"
        [ ("id", id); ("what", if name = "$PN" then "pn" else "lc"); ("break", "no") ];
      Option.value (answer id) ~default:v
  | _ -> v

let system_symbol ctx name sub =
  match List.assoc_opt name ctx.sys_sets with
  | Some v when sub = 0 && name <> "$CHAR" -> Some v
  | _ -> system_value ctx name sub

let create ?(include_path = []) () =
  let ctx =
    {
      chars = Chars.create ();
      input = Input.create include_path;
      doc = Doc.create ();
      diag = Loc.create_diag ();
      include_path;
      sets = [];
      sys_sets = [];
      words = Hashtbl.create 64;
      loc = Loc.none;
      syms = Symbols.create ();
      subst_on = true;
      (* SH35-0069 p.230: ON is the initial value *)
      su_lines = 0;
      line_substituted = true;
      ret = 0;
      do_stack = [];
      skip = 0;
      skip_from = Loc.none;
      skip_owner = 0;
      cs_modes = Hashtbl.create 9;
      cs_open = [];
      cs_frames = [];
      macros = Macro.create ();
      ms_on = false;
      (* SH35-0069 p.271: .ms on must be given explicitly *)
      capture = None;
      max_macro_depth = 100;
      go_count = 0;
      max_go = 100_000;
      profile_id = -1;
      epifile = None;
      warned = Hashtbl.create 4;
      tag_scan = Tags_off;
      (* SH35-0069 p.287: enabled by .gs tag on *)
      (* DCF-VERIFY: the initial rules; we start from the Starter Set's
         .gs rules (att novat stop nomsg) (noatt) (p.291) *)
      tag_rules =
        { att = true; vat = false; stop = true; msg = false; elem = true };
      end_rules =
        { att = false; vat = false; stop = true; msg = false; elem = true };
      prefix = None;
      assocs = Hashtbl.create 16;
      undef_tags = Undef_text;
      gml_attrs = [];
      residual = None;
      process = (fun _ _ _ -> ());
      fmt = initial_fmt ();
      saved = [];
      hctr = Headctr.create ();
      dh_num = Hashtbl.create 7;
      toc = Toc.create ();
      literal = 0;
      last_tag = "";
      last_tagd = "";
      libs = [];
      ly_mac = false;
      (* SH35-0069 p.240: the initial setting is OFF *)
      ly_sym = false;
      lib_members = Hashtbl.create 16;
      pass = 1;
      passes = 1;
      query_files = Hashtbl.create 4;
      query_lines = Hashtbl.create 64;
      page_query = None;
      page_of = (fun _ -> None);
      coupling = false;
    }
  in
  ctx.doc.Doc.page_symbol <- (fun () -> Some ctx.chars.Chars.ps);
  ctx.syms.Symbols.system <- system_symbol ctx;
  ctx.syms.Symbols.query <- query ctx;
  ctx.doc.Doc.report <-
    (fun m -> Loc.report ctx.diag Loc.Warning ctx.loc "%s" m);
  ctx.doc.Doc.here <- (fun () -> Loc.to_string ctx.loc);
  ctx.syms.Symbols.local <-
    (fun () ->
      match Input.current_scope ctx.input with
      | Some sc -> sc
      | None -> ctx.syms.Symbols.base);
  ctx.syms.Symbols.in_macro <- (fun () -> Input.in_macro ctx.input);
  ctx

let register ctx name run =
  Hashtbl.replace ctx.words (String.lowercase_ascii name) { run }

let info ctx fmt = Loc.report ctx.diag Loc.Info ctx.loc fmt
let warn ctx fmt = Loc.report ctx.diag Loc.Warning ctx.loc fmt
let error ctx fmt = Loc.report ctx.diag Loc.Error ctx.loc fmt
let error_at ctx loc fmt = Loc.report ctx.diag Loc.Error loc fmt

(** A warning given once per [key]. *)
let warn_once ctx key fmt =
  Printf.ksprintf
    (fun m ->
      if not (Hashtbl.mem ctx.warned key) then begin
        Hashtbl.add ctx.warned key ();
        warn ctx "%s" m
      end)
    fmt

(** The document builder drops all output while an ignored conditional section
    is open (see [Doc.t.mute]). *)
let sync_mute ctx =
  ctx.doc.Doc.mute <- List.exists (fun e -> e.ignored) ctx.cs_open

(** Stop processing: the input stack is emptied. *)
let stop ctx =
  ctx.do_stack <- [];
  ctx.skip <- 0;
  ctx.capture <- None;
  ctx.cs_open <- [];
  sync_mute ctx;
  ctx.epifile <- None;
  Input.clear ctx.input

(** Stop processing after an error. *)
let abort = stop

(** The comparison result for [.th]/[.el]: the current frame's. *)
let cond ctx = Input.cond ctx.input

let set_cond ctx v = Input.set_cond ctx.input v

(** Is [.name] an invocation of a macro? Only with [.ms on] and without the [.']
    modifier (p.41, p.271); the macro name is the whole run of name characters
    ([Line.control.long]). Returns the name and the operands ([&*]: what follows
    the blank after the name, p.253). *)
let macro_of ctx (c : Line.control) =
  if ctx.ms_on && not c.Line.quoted then
    match c.Line.long with
    | Some name -> (
        match Macro.find ctx.macros name with
        | Some m -> Some (name, m, Line.drop_blank c.Line.long_args)
        | None -> None)
    | None -> None
  else None

(** Is [name] a control word name, for the text-line separator rule. *)
let is_cw_name ctx name =
  Hashtbl.mem ctx.words name || List.mem name Line.dcf_names
