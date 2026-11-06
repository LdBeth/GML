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
}

and word = { run : t -> string -> unit  (** receives the operands *) }

let char_value = function Some c -> String.make 1 c | None -> ""

let system_symbol ctx = function
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
  | "$RET" -> Some (string_of_int ctx.ret)
  | "$DATE" -> Some (Symbols.date_string ())
  | "$TIME" -> Some (Symbols.time_string ())
  | "$CW" -> Some (char_value ctx.chars.Chars.cw_sep)
  | "$CONT" -> Some (char_value ctx.chars.Chars.cont)
  | "$GML" -> Some (char_value ctx.chars.Chars.gml_delim)
  | "$EGML" -> Some ctx.chars.Chars.gml_end
  | "$SU" -> Some (if ctx.subst_on then "ON" else "OFF")
  | "$TAB" -> Some "\t" (* the tab character (SH35-0069 p.85, p.246) *)
  | "$ENV" -> Some "BODY" (* modern edge: no keeps, floats, footnotes *)
  | "$PN" -> Some "1" (* modern edge: no pagination *)
  (* the last GML tag found, as written, and its delimiter (p.251).
     DCF-VERIFY: the case of the name. *)
  | "$TAG" -> Some ctx.last_tag
  | "$TAGD" -> Some ctx.last_tagd
  | _ -> None

let create ?(include_path = []) () =
  let ctx =
    {
      chars = Chars.create ();
      input = Input.create include_path;
      doc = Doc.create ();
      diag = Loc.create_diag ();
      include_path;
      sets = [];
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
      literal = 0;
      last_tag = "";
      last_tagd = "";
      libs = [];
      ly_mac = false;
      (* SH35-0069 p.240: the initial setting is OFF *)
      ly_sym = false;
      lib_members = Hashtbl.create 16;
    }
  in
  ctx.syms.Symbols.system <- system_symbol ctx;
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
