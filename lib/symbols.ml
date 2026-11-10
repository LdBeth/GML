(* The symbol table.

   Names (SH35-0069 p.42, p.229) are up to ten characters from letters,
   digits and [@ # $]; a name may start with a digit ([&3z], p.269).
   Names are case-sensitive ([&libsym] and [&LIBSYM] are different
   symbols, p.239), except names beginning with [$], which may be written
   in either case (p.241): those are normalised to upper case.

   A name that starts with [*] is local (p.253, p.276).  There is one set
   of locals per macro call, plus one set for when no macro is the
   current source; [local] (installed by [Ctx.create]) returns the scope
   of the current macro frame, or [base].  Every other name is global.

   A name that starts with [$] and is known to the [system] callback is a
   read-only system symbol whose value is computed on each reference.  A
   system symbol may be an array ([&$CHAR(n)]): the callback gets the
   subscript, and element 0 is the number of elements.

   Arrays (p.254-257): every symbol is potentially an array; its plain
   value is element 0, the index counter.  [x(n)] for n >= 1 are the
   elements. *)

type sym = {
  mutable value : string option;  (** [&x] = [&x(0)] *)
  elems : (int, string) Hashtbl.t;  (** [&x(n)], n >= 1 *)
}

type scope = (string, sym) Hashtbl.t

type t = {
  global : scope;
  base : scope;  (** locals when no macro is the source *)
  mutable local : unit -> scope;  (** the current local scope *)
  mutable in_macro : unit -> bool;
      (** is a macro the current input source (undefined locals are null only
          then, p.276) *)
  mutable system : string -> int -> string option;
      (** value of a system symbol (normalised name, with the [$]) or of one of
          its elements; installed by [Ctx.create] because the values depend on
          the context *)
  mutable query : string -> string -> string;
      (** [query name v]: a reference to the plain value [v] of system symbol
          [name] by [get] (substitution, [.se x = &]), not by [defined] or
          [is_system]: the page state symbols ([&$PN], [&$LC]) are questions to
          the layout engine ([Ctx.query]); the identity for the others *)
}

(** DCF limit on symbol name length (SH35-0069 p.229; LR p.337). *)
let max_name_len = 10

let new_scope () : scope = Hashtbl.create 8

let create () =
  let base = new_scope () in
  {
    global = Hashtbl.create 64;
    base;
    local = (fun () -> base);
    in_macro = (fun () -> false);
    system = (fun _ _ -> None);
    query = (fun _ v -> v);
  }

(** Names beginning with [$] are case-insensitive (p.241). *)
let norm name =
  if name <> "" && name.[0] = '$' then String.uppercase_ascii name else name

let is_local name = name <> "" && name.[0] = '*'

(** Characters of a symbol name (after an optional leading [*]): letters,
    digits, [@ # $] (p.229). *)
let is_name_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '$' | '#' | '@' -> true
  | _ -> false

(** Is [name] (with an optional leading [*]) a valid symbol name? With
    [~long:true] the length is not limited (the coupling files of the pass
    model, [Ctx.coupling]). *)
let valid_name ?(long = false) name =
  let body =
    if is_local name then String.sub name 1 (String.length name - 1) else name
  in
  (long || String.length body <= max_name_len)
  && String.for_all is_name_char body
  && (body <> "" || is_local name)

let scope_for t name = if is_local name then t.local () else t.global
let new_sym () = { value = None; elems = Hashtbl.create 1 }

(** Set [name] in a given scope (macro arguments). *)
let set_in (sc : scope) name v =
  Hashtbl.replace sc (norm name) { value = Some v; elems = Hashtbl.create 1 }

let is_system t name =
  let n = norm name in
  n <> "" && n.[0] = '$' && t.system n 0 <> None

let find t name = Hashtbl.find_opt (scope_for t name) (norm name)

(** Is [name] defined at all (a value or some element)? *)
let defined t name =
  is_system t name
  ||
  match find t name with
  | Some s -> s.value <> None || Hashtbl.length s.elems > 0
  | None -> false

(** Value of [name], or of element [sub] of it. Element 0 is the plain value. An
    element that is not set, of a symbol that exists, is the null string
    (p.255). *)
let get ?(sub = 0) t name =
  let n = norm name in
  match if n <> "" && n.[0] = '$' then t.system n sub else None with
  | Some v -> Some (if sub = 0 then t.query n v else v)
  | None ->
      if sub = 0 then Option.bind (find t n) (fun s -> s.value)
      else if not (defined t n) then None
      else
        Some
          (Option.value ~default:""
             (Option.bind (find t n) (fun s -> Hashtbl.find_opt s.elems sub)))

(** The elements [x(1)...] in ascending subscript order (p.256). *)
let elements t name =
  let n = norm name in
  if is_system t n then
    let count =
      Option.value ~default:0 (Option.bind (t.system n 0) int_of_string_opt)
    in
    List.init count (fun i -> Option.value (t.system n (i + 1)) ~default:"")
  else
    match find t n with
    | None -> []
    | Some s ->
        Hashtbl.fold (fun k v acc -> (k, v) :: acc) s.elems []
        |> List.sort compare |> List.map snd

let sym_of t name =
  let sc = scope_for t name and n = norm name in
  match Hashtbl.find_opt sc n with
  | Some s -> s
  | None ->
      let s = new_sym () in
      Hashtbl.replace sc n s;
      s

let read_only t name =
  if is_system t name then
    Error (Printf.sprintf "system symbol &%s is read-only" (norm name))
  else Ok ()

let counter_of s =
  match s.value with
  | None -> Some 0
  | Some v ->
      (* a null value counts as 0: the Starter Set's DSMTTLEP nulls @title
       with .gs vars and then appends with .se @title() (DCF-VERIFY, not in LR Rel 4) *)
      let v = String.trim v in
      if v = "" then Some 0 else int_of_string_opt v

(** "There can be up to 32767 elements in a symbol array. Attempting to set any
    higher numbered array elements causes an error" (LR p.342 r18). *)
let max_elements = 32767

let in_range name sub =
  if sub <= max_elements then Ok ()
  else
    Error
      (Printf.sprintf "&%s(%d): an array has at most %d elements" (norm name)
         sub max_elements)

(** Set [name] ([sub] = 0 or absent: the plain value). Setting element n >= 1
    makes n the index counter (p.257: "it will be incremented from the index
    value of the element last set"), unless element 0 holds a value that is not
    a number. DCF-VERIFY: a non-numeric element 0 is left alone (p.257 warns
    about it rather than saying it is replaced; not in LR Rel 4). *)
let set ?(sub = 0) t name v =
  Result.bind (read_only t name) (fun () ->
      Result.map
        (fun () ->
          let s = sym_of t name in
          if sub = 0 then s.value <- Some v
          else begin
            Hashtbl.replace s.elems sub v;
            if counter_of s <> None then s.value <- Some (string_of_int sub)
          end)
        (in_range name sub))

(** [.se x() = v]: set the element after the index counter (p.256-257). *)
let append t name v =
  Result.bind (read_only t name) (fun () ->
      let s = sym_of t name in
      match counter_of s with
      | None ->
          Error (Printf.sprintf "index counter &%s is not a number" (norm name))
      | Some c ->
          Result.map
            (fun () ->
              Hashtbl.replace s.elems (c + 1) v;
              s.value <- Some (string_of_int (c + 1)))
            (in_range name (c + 1)))

(** [.se x off] removes the whole symbol, the whole array if it is one;
    [.se x(n) off] removes one element (p.235). *)
let unset ?(sub = 0) t name =
  Result.map
    (fun () ->
      let sc = scope_for t name and n = norm name in
      match Hashtbl.find_opt sc n with
      | None -> ()
      | Some s ->
          if sub = 0 then Hashtbl.remove sc n else Hashtbl.remove s.elems sub)
    (read_only t name)

(* ---- carried over between passes ------------------------------------------ *)

(* The symbol file of a multi-pass run (gml -symbols-out / -symbols-in,
   gmlpass) is SCRIPT source, imbedded by the next pass before the
   profile (Aux.imbed):

     .* gml symbols                   constant first line
     .su off                          a value with & stays as written
     .dc cw off                       a value with ; is not split
     .se NAME = 'value'               one line per symbol ...
     .se NAME(n) = 'value'            ... and per array element (n >= 1)
     .se gml@pgq(n) = 'NAME SUB ID D' the page provenance (below)
     .se gml@toc(n) = '...'           the TOC entries (lib/toc.ml)
     .dc cw
     .su on

   The value is always quoted, a quote in it doubled (Expr.close_quote).
   SCRIPT has no escape for a line end: one in a value is written as a
   blank (DCF-VERIFY: what DCF's own carry-over does with it, not in LR Rel 4).  Every
   global symbol that is defined at the end of the pass, except the date
   and time symbols ([date_names], set again by every pass: they would
   make two passes differ), the symbols of the aux file ([aux_prefixes]:
   pa@ pq@ pr@ px@, read again from it by every pass) and gml@toc (lib/toc.ml writes the
   entries itself).  Sorted by name and subscript, so that two passes
   that end in the same state write the same file.  DCF-VERIFY (not in LR Rel 4): the set
   of symbols DCF keeps from one pass to the next (TPG p.233: symbols
   unresolved on the first pass are resolved on the second) is not
   documented in our manuals.

   Modern edge: the page provenance.  A symbol that a .se set to the
   answer of one page question (.se fp@ID = &$PN, Ctx.page_syms) is not
   written with its value but as an element of gml@pgq: its name, its
   subscript, the question id and the neutral default (1, 60).  The next
   pass sets it to the answer of its own aux file to that question, the
   default when there is none (Aux.resolve_pages): the page TeX put the
   target on in the pass that set the symbol.  A forward reference to a
   page is then right on pass 2, as in LaTeX (and in DCF, where &$PN is
   the page on pass 1), not on pass 3; and the file stays the same from
   one pass to the next when the questions are the same (gmlpass compares
   it), though the answer changed. *)

(** [.se NAME = 'value'] ([sub] = 0) or [.se NAME(sub) = 'value']. *)
let se_line ?(sub = 0) name v =
  let b = Buffer.create (String.length v + 16) in
  Buffer.add_string b ".se ";
  Buffer.add_string b name;
  if sub <> 0 then Printf.bprintf b "(%d)" sub;
  Buffer.add_string b " = '";
  String.iter
    (function
      | '\'' -> Buffer.add_string b "''"
      | '\n' | '\r' -> Buffer.add_char b ' '
      | c -> Buffer.add_char b c)
    v;
  Buffer.add_char b '\'';
  Buffer.contents b

(* ---- date and time ------------------------------------------------------ *)

(* SOURCE_DATE_EPOCH (reproducible builds) overrides the clock; it is
   interpreted as UTC. *)
let now () =
  match
    Option.bind (Sys.getenv_opt "SOURCE_DATE_EPOCH") float_of_string_opt
  with
  | Some e -> Unix.gmtime e
  | None -> Unix.localtime (Unix.time ())

(** [&$YEAR], the current year in 4 digits (LR p.443, Table 17): a read-only
    system symbol (Ctx.system_value). There is no [&$DATE] or [&$TIME] in DCF
    (Table 17 lists the date and time symbols). *)
let year_string () = Printf.sprintf "%04d" ((now ()).Unix.tm_year + 1900)

(** The date and time symbols of LR p.443 (Table 17): set once, ordinary
    (settable) global symbols, upper-case names, zero-padded values ("these
    symbols can contain leading zeros"); [&SYSDAYOFW] is 1-7, 1 is Sunday. *)
let date_symbols () =
  let tm = now () in
  [
    ("SYSYEAR", Printf.sprintf "%02d" (tm.Unix.tm_year mod 100));
    ("SYSMONTH", Printf.sprintf "%02d" (tm.Unix.tm_mon + 1));
    ("SYSDAYOFM", Printf.sprintf "%02d" tm.Unix.tm_mday);
    ("SYSDAYOFW", string_of_int (tm.Unix.tm_wday + 1));
    ("SYSDAYOFY", Printf.sprintf "%03d" (tm.Unix.tm_yday + 1));
    ("SYSHOUR", Printf.sprintf "%02d" tm.Unix.tm_hour);
    ("SYSMINUTE", Printf.sprintf "%02d" tm.Unix.tm_min);
    ("SYSSECOND", Printf.sprintf "%02d" tm.Unix.tm_sec);
  ]

let date_names = List.map fst (date_symbols ())

(** The prefixes of the aux file's symbols (lib/aux.ml): [pa@] the page of an
    anchor, [pq@] the answer to a question, [pr@] gml.tex's own auto page
    references, [px@] a tag set's own (written by its TeX file, read by its
    profile, e.g. examples/tate's ruby widths). *)
let anchor_prefix = "pa@"

let query_prefix = "pq@"
let tagset_prefix = "px@"

(** The symbols of the aux file (lib/aux.ml): not carried, every pass reads them
    again from the file. *)
let aux_prefixes = [ anchor_prefix; query_prefix; "pr@"; tagset_prefix ]

(** The array the TOC entries travel in (lib/toc.ml). *)
let toc_name = "gml@toc"

(** The array the page provenance travels in ([dump]). *)
let page_name = "gml@pgq"

let carried name =
  name <> ""
  && (not (String.starts_with ~prefix:"$" name))
  && name <> toc_name && name <> page_name
  && (not (List.mem name date_names))
  && not
       (List.exists
          (fun prefix -> String.starts_with ~prefix name)
          aux_prefixes)

(** The [.se] lines of the symbols (without line ends). [pages]: the page
    provenance ([Ctx.page_syms]): a symbol whose value is still the answer it
    was set to is written as an element of gml@pgq, not with its value. *)
let dump ?(pages = Hashtbl.create 0) t =
  let entries name s =
    List.map (fun v -> ((name, 0), v)) (Option.to_list s.value)
    @ Hashtbl.fold (fun k v acc -> ((name, k), v) :: acc) s.elems []
  in
  let page ((name, sub), v) =
    match Hashtbl.find_opt pages (name, sub) with
    | Some (id, ans, dflt) when ans = v ->
        Some (Printf.sprintf "%s %d %s %s" name sub id dflt)
    | _ -> None
  in
  let all =
    Hashtbl.fold
      (fun name s acc -> if carried name then entries name s @ acc else acc)
      t.global []
    |> List.sort (fun (a, _) (b, _) -> compare a b)
  in
  let plain, pgq =
    List.partition_map
      (fun (((name, sub), v) as e) ->
        match page e with
        | None -> Either.Left (se_line ~sub name v)
        | Some q -> Either.Right q)
      all
  in
  plain @ List.mapi (fun i q -> se_line ~sub:(i + 1) page_name q) pgq

(** The whole symbol file around [lines] (the [.se] lines of [dump] and
    [Toc.dump]), with line ends. *)
let file lines =
  String.concat "\n"
    ([ ".* gml symbols"; ".su off"; ".dc cw off" ]
    @ lines @ [ ".dc cw"; ".su on" ])
  ^ "\n"

(** After loading the symbol file: "all array index counters are reset to zero
    for the second pass but the individual elements are not reset" (TPG p.256,
    TWOPASS): every global symbol with elements whose element 0 is a counter (a
    number or null) gets 0. *)
let reset_counters t =
  Hashtbl.iter
    (fun _ s ->
      if Hashtbl.length s.elems > 0 && counter_of s <> None then
        s.value <- Some "0")
    t.global
