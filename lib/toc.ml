(* The table of contents (SH35-0069 ch.13, p.151-157; SH20-9161-3 .DH
   p.247 and .TC, .PT).

   DCF writes an entry into the DSMUTTOC file for each head level
   ([.h0]-[.h6]) whose definition asks for one (TC), and a line for each
   [.pt]; [.tc] formats the file.  An entry is saved with the head-level
   definition in effect when the heading is processed (.DH note 2): its
   indention (TCIN), font (TFONT), a skip before it (TS), a dot leader
   to a right-aligned page number (DOT, the default) or two blanks
   before the number (NODOT).  The table holds "all the entries made
   prior to the .TC control word during the current or previous pass"
   (p.156): with one pass a .tc at the start of the document is empty.

   The page of an entry is the page its heading is put out on.  The
   heading carries an anchor ([id], the hint gml:tcmark); the entry
   carries [anchor=] and the page is left to TeX (gml.tex's page
   references, from its .gmlaux file, on a second run).  With the pass
   model (gml -aux, gmlpass) [Ctx.page_of] knows the anchors of the
   previous pass (Aux): such an entry gets [page=].

   [previous]: the entries of the previous formatting pass, carried in
   the symbol file (gml -symbols-in, [dump] and [carried] below); None
   on a first pass. *)

type level_def = {
  mutable tc : bool;  (** TC / NTC *)
  mutable only : bool;  (** TO / NTO: an entry only, no heading in the text *)
  mutable skip : bool;  (** TS / NTS: a space before the entry *)
  mutable indent : string;  (** TCIN h, as written *)
  mutable font : string option;  (** TFONT f *)
  mutable dot : bool;  (** DOT / NODOT *)
}

(* SH35-0069 Figure 14 (p.153): entries for levels 0-3, level 0 only an
   entry, a skip before a level 1 entry, indention 0 0 0 2 4 6 8 *)
let default n =
  {
    tc = n <= 3;
    only = n = 0;
    skip = n = 1;
    indent = string_of_int [| 0; 0; 0; 2; 4; 6; 8 |].(n);
    font = None;
    dot = true;
  }

type kind =
  | Head of int  (** a heading of that level *)
  | Line  (** [.pt text] *)
  | Control of string  (** [.pt .xx ...]: a control word line *)

type entry = {
  id : string;  (** the anchor of the heading or [.pt] *)
  kind : kind;
  text : string;  (** as put out (translated) *)
  skip : bool;
  indent : string;
  font : string option;
  dot : bool;
  page : string option;  (** the page, when it was known as the entry was made *)
}

type t = {
  defs : level_def array;
  mutable entries : entry list;  (** this pass, newest first *)
  mutable count : int;
  mutable previous : entry list option;
      (** the previous pass's entries, in order (gml -symbols-in) *)
}

let create () =
  { defs = Array.init 7 default; entries = []; count = 0; previous = None }

let def t n = t.defs.(n)
let reset t n = t.defs.(n) <- default n

(** A [.dh n] option word that concerns the table of contents; [value] gives the
    operand of TCIN and TFONT. Returns false for any other word, and whether the
    operand was taken. *)
let option t n w ~value =
  let d = t.defs.(n) in
  match String.lowercase_ascii w with
  | "tc" ->
      d.tc <- true;
      `Done
  | "ntc" ->
      d.tc <- false;
      `Done
  | "to" ->
      d.only <- true;
      `Done
  | "nto" ->
      d.only <- false;
      `Done
  | "ts" ->
      d.skip <- true;
      `Done
  | "nts" ->
      d.skip <- false;
      `Done
  | "dot" ->
      d.dot <- true;
      `Done
  | "nodot" ->
      d.dot <- false;
      `Done
  | "tcin" -> (
      match value with
      | Some v ->
          d.indent <- v;
          `Took
      | None -> `Missing)
  | "tfont" -> (
      match value with
      | Some v when String.lowercase_ascii v = "off" ->
          d.font <- None;
          `Took
      | Some v when v <> "" && v.[0] <> '&' ->
          d.font <- Some v;
          `Took
      | Some _ -> `Took
      | None -> `Done (* last on the line: no error (the FONT rule) *))
  | _ -> `Other

let next_id t =
  t.count <- t.count + 1;
  Printf.sprintf "gml.tc.%d" t.count

(** Record the entry of a heading of level [n] (its definition decides) or a
    [.pt] line; returns it. *)
let add t ?page kind text =
  let id = next_id t in
  let skip, indent, font, dot =
    match kind with
    | Head n ->
        let d = t.defs.(n) in
        (d.skip, d.indent, d.font, d.dot)
    | Line | Control _ -> (false, "0", None, true)
  in
  let e = { id; kind; text; skip; indent; font; dot; page } in
  t.entries <- e :: t.entries;
  e

(** The entries a [.tc] prints (p.156). *)
let printable t =
  match t.previous with Some l -> l | None -> List.rev t.entries

(* ---- carried over between passes --------------------------------------------- *)

(* DCF keeps the DSMUTTOC file from one pass to the next, so that a .tc
   at the start of the document prints the entries of the previous pass
   (p.156).  Here they travel in the symbol file of the pass model
   (gml -symbols-out/-symbols-in, the format in lib/symbols.ml) as the
   array gml@toc: one element per entry, its value the fields kind, TS,
   TCIN, TFONT, DOT, anchor and text separated by tabs (the text last:
   it may hold a tab).  kind is the head level 0-6, "pt" for a .pt
   line, "cw" for a .pt control word line (its text the line).  After
   the file is imbedded the array is moved here ([carried]).  The page
   is not carried: it is the page of the anchor in the previous pass's
   aux file ([Ctx.page_of]). *)

let to_line n (e : entry) =
  let kind, text =
    match e.kind with
    | Head l -> (string_of_int l, e.text)
    | Line -> ("pt", e.text)
    | Control c -> ("cw", c)
  in
  let flag b = if b then "1" else "0" in
  Symbols.se_line ~sub:n Symbols.toc_name
    (String.concat "\t"
       [
         kind;
         flag e.skip;
         e.indent;
         Option.value e.font ~default:"";
         flag e.dot;
         e.id;
         text;
       ])

(** The [.se gml@toc(n)] lines of this pass's entries, in order. *)
let dump t = List.mapi (fun i e -> to_line (i + 1) e) (List.rev t.entries)

(** The entry of one element of gml@toc; [None] if it is not one. *)
let of_value v =
  match String.split_on_char '\t' v with
  | kind :: skip :: indent :: font :: dot :: id :: (_ :: _ as rest) ->
      let text = String.concat "\t" rest in
      let kind =
        match kind with
        | "pt" -> Some Line
        | "cw" -> Some (Control text)
        | l ->
            Option.bind (int_of_string_opt l) (fun l ->
                if l >= 0 && l <= 6 then Some (Head l) else None)
      in
      Option.map
        (fun kind ->
          {
            id;
            kind;
            text = (match kind with Control _ -> "" | _ -> text);
            skip = skip = "1";
            indent;
            font = (if font = "" then None else Some font);
            dot = dot = "1";
            page = None;
          })
        kind
  | _ -> None

(** The entries of the previous pass, taken out of the symbol table (the array
    gml@toc of the symbol file, now undefined). *)
let carried syms =
  let es = List.filter_map of_value (Symbols.elements syms Symbols.toc_name) in
  ignore (Symbols.unset syms Symbols.toc_name);
  es
