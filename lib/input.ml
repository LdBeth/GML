(* The input stack.

   Everything in SCRIPT/VS is line-driven: imbedded files, macro bodies
   and synthetic lines are all frames on one stack, and the interpreter
   just asks for the next line.  The top of the stack is the head of
   [frames].

   A Macro frame owns the local symbols of its call ([Symbols.local]
   resolves through [current_scope]); outside macros there is one more
   set of locals, [Symbols.base] (SH35-0069 p.276).  Each File and Macro
   frame also holds the result of its most recent comparison, for
   [.th]/[.el]: it is preserved across macro calls and imbeds (p.265).
   Every removal of a frame goes through [pop], which calls the [on_pop]
   hook: the interpreter uses it to discard state tied to the frame
   (open .do groups of a macro). *)

(* Every File and Macro frame gets a unique id, so that state tied to a
   frame (open .do groups) can refer to it. *)
let next_id = ref 0

let fresh_id () =
  incr next_id;
  !next_id

type file_frame = {
  id : int;
  path : string;
  lines : string array;
  mutable idx : int;  (** index of the next line to read, 0-based *)
  mutable labels : (string, int) Hashtbl.t option;
      (** lowercased label name -> line indexes (all occurrences, see
          [Hashtbl.find_all]); built lazily by [label_index] because recognising
          a label depends on the current control word indicator *)
  mutable fcond : bool option;  (** last comparison in this file *)
}

(* A macro invocation.  It reads the definition live, in subscript
   order: the next line is the first one whose subscript is above that of
   the last line read, so a change to a later line of the running macro
   takes effect in this same call.  SH35-0050 p.181 (DSM#DUPL) relies on
   it: line 40 removes line 60 ("NOT DUPLEX - REMOVE THE EJECT LINE")
   before line 60 is reached.
   DCF-VERIFY: a running macro that is deleted ([.dm name off]) ends
   there; one that is redefined goes on in the new definition. *)
type macro_frame = {
  mid : int;
  name : string;
  lines : unit -> (int * string) array;
      (** the current definition: (subscript, line), ascending *)
  mutable last : int;  (** subscript of the last line read ([min_int]: none) *)
  called_from : Loc.t;
  mscope : Symbols.scope;  (** locals of the call, incl. the arguments *)
  mutable mcond : bool option;  (** last comparison in this call *)
}

type piece = {
  had_text : bool;  (** text came before it on its input line *)
  eol : bool;  (** it ends its input line (a word space follows) *)
}
(** Where a piece of a text line after a GML tag stands in its line. *)

(** How the interpreter treats a line. *)
type kind =
  | Source
      (** a physical input line of a file or macro: the whole per-line
          processing *)
  | Split of bool
      (** the rest of a line after a separator split (or after the extended
          symbol rule split it): never substituted again; [true] if the line it
          comes from was substituted *)
  | Residual of piece
      (** the residual text of a GML tag, or the rest of its line after the
          residual text (which starts with the next tag): already substituted,
          literal (never a control word), scanned for tags *)

(* Synthetic lines, each with the location it is attributed to. *)
type lines_frame = { src : (string * Loc.t * kind) array; mutable pos : int }
type frame = File of file_frame | Macro of macro_frame | Lines of lines_frame

type t = {
  mutable frames : frame list;
  mutable pending : (string * Loc.t * kind) list;
      (** lines pushed back in front of the stack: the rest of the current line
          after a split. They belong to the current file, so [.ef]/[.ap] discard
          them. *)
  search_path : string list;  (** -I directories, in order *)
  max_depth : int;  (** maximum nesting of File frames *)
  resume : (string, int) Hashtbl.t;
      (** files left by [.ef]: where the next imbed resumes (p.51) *)
  mutable cond0 : bool option;  (** comparison result outside any frame *)
  mutable on_pop : frame -> unit;
      (** called after a frame has been removed from the stack *)
}

let create ?(max_depth = 64) search_path =
  {
    frames = [];
    pending = [];
    search_path;
    max_depth;
    resume = Hashtbl.create 4;
    cond0 = None;
    on_pop = ignore;
  }

(* The one place where frames leave the stack. *)
let pop t =
  match t.frames with
  | [] -> ()
  | f :: rest ->
      t.frames <- rest;
      t.on_pop f

let macro_depth t =
  List.fold_left
    (fun n f -> match f with Macro _ -> n + 1 | _ -> n)
    0 t.frames

let file_depth t =
  List.fold_left (fun n f -> match f with File _ -> n + 1 | _ -> n) 0 t.frames

(* ---- file lookup and reading ----------------------------------------- *)

(** Candidates for [name]: as given, then with ".gml" appended; first relative
    to the working directory, then in each -I directory. [(long.name)] in
    parentheses is the real file name, used as written (SH35-0069 p.50: "the
    file-id, which in this case can be more than eight characters long, as the
    real file name"). *)
let candidates t name =
  let n = String.length name in
  let forms =
    if n >= 2 && name.[0] = '(' && name.[n - 1] = ')' then
      [ String.sub name 1 (n - 2) ]
    else if Filename.check_suffix name ".gml" then [ name ]
    else [ name; name ^ ".gml" ]
  in
  let in_dir d = List.map (Filename.concat d) forms in
  if List.for_all Filename.is_relative forms then
    forms @ List.concat_map in_dir t.search_path
  else forms

let resolve t name =
  List.find_opt
    (fun p -> Sys.file_exists p && not (Sys.is_directory p))
    (candidates t name)

let split_lines s =
  (* reversed, without the empty piece after a final newline *)
  let rls =
    match List.rev (String.split_on_char '\n' s) with "" :: r -> r | r -> r
  in
  let strip_cr l =
    let n = String.length l in
    if n > 0 && l.[n - 1] = '\r' then String.sub l 0 (n - 1) else l
  in
  Array.of_list (List.rev_map strip_cr rls)

let read_file path =
  match In_channel.with_open_bin path In_channel.input_all with
  | s -> Ok (split_lines s)
  | exception Sys_error e -> Error e

let file_frame ?(idx = 0) path lines =
  { id = fresh_id (); path; lines; idx; labels = None; fcond = None }

(* A file left by [.ef] resumes after that [.ef] (p.51). *)
let open_file t name =
  match resolve t name with
  | None -> Error (Printf.sprintf "file %s not found" name)
  | Some path ->
      Result.map
        (fun lines ->
          let idx = Option.value (Hashtbl.find_opt t.resume path) ~default:0 in
          Hashtbl.remove t.resume path;
          file_frame ~idx path lines)
        (read_file path)

(* ---- stack operations ------------------------------------------------ *)

(* Before pushing a new frame, pending pushed-back lines become a Lines
   frame below it, so they are resumed when the new frame is exhausted. *)
let flush_pending t =
  match t.pending with
  | [] -> ()
  | saved ->
      t.pending <- [];
      t.frames <- Lines { src = Array.of_list saved; pos = 0 } :: t.frames

let push_frame t f =
  flush_pending t;
  t.frames <- f :: t.frames

(** [.im]: push [name] on top of the stack; returns the new frame's id. *)
let imbed t name =
  if file_depth t >= t.max_depth then
    Error
      (Printf.sprintf "imbed nesting deeper than %d; .im %s ignored" t.max_depth
         name)
  else
    Result.map
      (fun ff ->
        push_frame t (File ff);
        ff.id)
      (open_file t name)

(** Push lines [idx..] of a file (the epifile of the profile). *)
let push_file_at t path lines idx =
  push_frame t (File (file_frame ~idx path lines))

(* Pop frames down to and including the topmost frame satisfying [p].
   Returns false (and changes nothing) if there is none. *)
let drop_through t p =
  if not (List.exists p t.frames) then false
  else begin
    let rec go () =
      match t.frames with
      | [] -> ()
      | f :: _ ->
          pop t;
          if not (p f) then go ()
    in
    go ();
    t.pending <- [];
    true
  end

let current_file t =
  List.find_map (function File ff -> Some ff | _ -> None) t.frames

(* Drop every frame down to and including the topmost File frame (the
   Macro frames above it are discarded too).  Returns false if there is
   no File frame. *)
let drop_current_file t =
  drop_through t (function File _ -> true | _ -> false)

(** [.ap]: the current file ends here and processing continues with [name],
    which takes its place (so the nesting depth does not grow and when [name]
    ends we return to whoever imbedded the current file). *)
let append t name =
  match open_file t name with
  | Error _ as e -> e
  | Ok ff ->
      ignore (drop_current_file t);
      t.frames <- File ff :: t.frames;
      Ok ()

(** [.ef] / [.ef close]: end the current file. Without [close] the next imbed of
    the same file resumes after this [.ef] (p.51). Returns the file frame that
    ended. *)
let end_file ?(close = false) t =
  match current_file t with
  | None -> None
  | Some ff ->
      if close then Hashtbl.remove t.resume ff.path
      else Hashtbl.replace t.resume ff.path ff.idx;
      ignore (drop_current_file t);
      Some ff

(** Push [line] back to be the next input line. *)
let push_back t ?(kind = Split true) line loc =
  t.pending <- (line, loc, kind) :: t.pending

(** Push several lines back, to be read in the given order. *)
let push_back_list t lines = t.pending <- lines @ t.pending

let push_lines ?(kind = Source) t src =
  if src <> [] then
    push_frame t
      (Lines
         {
           src = Array.of_list (List.map (fun (s, l) -> (s, l, kind)) src);
           pos = 0;
         })

(** Push the residual text of a GML tag; the frame is returned so that
    [.gs scan/copy/insert] can reach the text before it is processed. *)
let push_residual t text loc piece =
  let l = { src = [| (text, loc, Residual piece) |]; pos = 0 } in
  push_frame t (Lines l);
  l

let push_macro t ~name ~lines ~called_from ~scope =
  push_frame t
    (Macro
       {
         mid = fresh_id ();
         name;
         lines;
         last = min_int;
         called_from;
         mscope = scope;
         mcond = None;
       })

(** Remove every frame (processing stops). *)
let clear t =
  t.pending <- [];
  while t.frames <> [] do
    pop t
  done

(* The next line of a macro: its index in [m.lines ()], subscript, text. *)
let macro_next m =
  Array.find_mapi
    (fun i (sub, l) -> if sub > m.last then Some (i, sub, l) else None)
    (m.lines ())

let macro_loc m i =
  let cf = m.called_from in
  { cf with via = { Loc.macro = m.name; mline = i + 1 } :: cf.via }

(** The next line, its location and how to treat it. *)
let rec next_line t =
  match t.pending with
  | (s, loc, kind) :: rest ->
      t.pending <- rest;
      Some (s, loc, kind)
  | [] -> (
      match t.frames with
      | [] -> None
      | File ff :: _ ->
          if ff.idx < Array.length ff.lines then begin
            let i = ff.idx in
            ff.idx <- i + 1;
            Some (ff.lines.(i), Loc.make ff.path (i + 1), Source)
          end
          else begin
            pop t;
            next_line t
          end
      | Macro m :: _ -> (
          match macro_next m with
          | Some (i, sub, l) ->
              m.last <- sub;
              Some (l, macro_loc m i, Source)
          | None ->
              pop t;
              next_line t)
      | Lines l :: _ ->
          if l.pos < Array.length l.src then begin
            let i = l.pos in
            l.pos <- i + 1;
            Some l.src.(i)
          end
          else begin
            pop t;
            next_line t
          end)

(** The next physical input line of the current File or Macro frame, without
    taking it (GML markup may continue on it; it cannot span files, SH35-0069
    p.289). Exhausted Lines frames above are looked through; [None] if the frame
    has no more lines, or if other lines come first. [next_line] then returns
    this same line. *)
let peek_in_frame t =
  match t.pending with
  | (s, l, Source) :: _ -> Some (s, l)
  | _ :: _ -> None
  | [] ->
      let rec go = function
        | [] -> None
        | File ff :: _ ->
            if ff.idx < Array.length ff.lines then
              Some (ff.lines.(ff.idx), Loc.make ff.path (ff.idx + 1))
            else None
        | Macro m :: _ ->
            Option.map (fun (i, _, l) -> (l, macro_loc m i)) (macro_next m)
        | Lines l :: rest -> (
            if l.pos >= Array.length l.src then go rest
            else
              match l.src.(l.pos) with
              | s, loc, Source -> Some (s, loc)
              | _ -> None)
      in
      go t.frames

(* ---- the current frame ------------------------------------------------ *)

(* The frame a [.go] (or a .do group, or a comparison) belongs to: the
   topmost File or Macro frame.  Lines frames are transparent: they hold
   the rest of lines of the frame below. *)
let current_frame t =
  List.find_opt
    (function File _ | Macro _ -> true | Lines _ -> false)
    t.frames

let current_frame_id t =
  match current_frame t with
  | Some (File ff) -> ff.id
  | Some (Macro m) -> m.mid
  | Some (Lines _) | None -> 0

(** The ids of the File and Macro frames on the stack. *)
let frame_ids t =
  List.filter_map
    (function File ff -> Some ff.id | Macro m -> Some m.mid | Lines _ -> None)
    t.frames

let current_scope t =
  match current_frame t with Some (Macro m) -> Some m.mscope | _ -> None

let in_macro t =
  match current_frame t with Some (Macro _) -> true | _ -> false

(** [&$LNUM]: the number of the current line: in a macro its subscript
    (SH35-0050 p.16: 10 for the first line of an inline definition), else its
    line number in the file. *)
let current_lnum t =
  match current_frame t with
  | Some (Macro m) when m.last <> min_int -> Some m.last
  | Some (File ff) -> Some ff.idx
  | _ -> None

(** The result of the most recent comparison in the current file or macro
    (p.265). *)
let cond t =
  match current_frame t with
  | Some (File ff) -> ff.fcond
  | Some (Macro m) -> m.mcond
  | _ -> t.cond0

let set_cond t v =
  match current_frame t with
  | Some (File ff) -> ff.fcond <- v
  | Some (Macro m) -> m.mcond <- v
  | _ -> t.cond0 <- v

(** [.me]: leave the current macro (the frames above it are pushed-back
    remainders of its lines and go with it). Returns the macro name, or [None]
    if the current frame is not a macro. *)
let end_macro t =
  match current_frame t with
  | Some (Macro m) ->
      ignore
        (drop_through t (function Macro m' -> m'.mid = m.mid | _ -> false));
      Some m.name
  | _ -> None

(* ---- labels and .go ------------------------------------------------- *)

let build_labels lines ~label_of =
  let h = Hashtbl.create 16 in
  Array.iteri
    (fun i l ->
      match label_of l with
      | Some n -> Hashtbl.add h (String.lowercase_ascii n) i
      | None -> ())
    lines;
  h

(** Label index of a file frame. [label_of] recognises a label line and returns
    its name. *)
let label_index ff ~label_of =
  match ff.labels with
  | Some h -> h
  | None ->
      let h = build_labels ff.lines ~label_of in
      ff.labels <- Some h;
      h

(* Labels of a macro, by subscript; built from the current definition
   at each [.go] since the macro may have changed. *)
let macro_label_index m ~label_of =
  let a = m.lines () in
  let h = build_labels (Array.map snd a) ~label_of in
  let by_sub = Hashtbl.create (Hashtbl.length h) in
  Hashtbl.iter (fun k i -> Hashtbl.add by_sub k (fst a.(i))) h;
  by_sub

(* Pop the Lines frames above the current File/Macro frame. *)
let drop_lines_above t =
  let rec go () =
    match t.frames with
    | Lines _ :: _ ->
        pop t;
        go ()
    | _ -> ()
  in
  go ()

(* First index >= [from] (searching forward), else the first one (wrap
   around to the top). *)
let pick_target idxs ~from =
  let idxs = List.sort compare idxs in
  match List.find_opt (fun i -> i >= from) idxs with
  | Some _ as r -> r
  | None -> ( match idxs with i :: _ -> Some i | [] -> None)

(** [.go name]: continue in the current File or Macro frame at the label [name].
    In a file the search goes forward from the line after the current one, then
    from the top; in a macro it always begins at the top of the macro (SH35-0069
    p.266). Frames above it and pushed-back remainders are discarded. On error
    nothing changes. Returns the id of the frame jumped in. *)
let goto t ~label_of name =
  let key = String.lowercase_ascii name in
  match current_frame t with
  | None | Some (Lines _) -> Error "no current file"
  | Some (File ff) -> (
      match
        pick_target
          (Hashtbl.find_all (label_index ff ~label_of) key)
          ~from:ff.idx
      with
      | None -> Error (Printf.sprintf "label %s not found in %s" name ff.path)
      | Some i ->
          ff.idx <- i;
          drop_lines_above t;
          t.pending <- [];
          Ok ff.id)
  | Some (Macro m) -> (
      match
        pick_target
          (Hashtbl.find_all (macro_label_index m ~label_of) key)
          ~from:min_int
      with
      | None ->
          Error (Printf.sprintf "label %s not found in macro %s" name m.name)
      | Some sub ->
          m.last <- sub - 1;
          drop_lines_above t;
          t.pending <- [];
          Ok m.mid)
