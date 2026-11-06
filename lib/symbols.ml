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
   read-only system symbol whose value is computed on each reference.

   Arrays (p.254-257): every symbol is potentially an array; its plain
   value is element 0, the index counter.  [x(n)] for n >= 1 are the
   elements. *)

type sym = {
  mutable value : string option;     (** [&x] = [&x(0)] *)
  elems : (int, string) Hashtbl.t;   (** [&x(n)], n >= 1 *)
}

type scope = (string, sym) Hashtbl.t

type t = {
  global : scope;
  base : scope;                  (** locals when no macro is the source *)
  mutable local : unit -> scope; (** the current local scope *)
  mutable in_macro : unit -> bool;
  (** is a macro the current input source (undefined locals are null
      only then, p.276) *)
  mutable system : string -> string option;
  (** value of a system symbol (normalised name, with the [$]); installed
      by [Ctx.create] because the values depend on the context *)
}

(** DCF limit on symbol name length (p.229). *)
let max_name_len = 10

let new_scope () : scope = Hashtbl.create 8

let create () =
  let base = new_scope () in
  { global = Hashtbl.create 64;
    base;
    local = (fun () -> base);
    in_macro = (fun () -> false);
    system = (fun _ -> None) }

(** Names beginning with [$] are case-insensitive (p.241). *)
let norm name =
  if name <> "" && name.[0] = '$' then String.uppercase_ascii name else name

let is_local name = name <> "" && name.[0] = '*'

(** Characters of a symbol name (after an optional leading [*]): letters,
    digits, [@ # $] (p.229). *)
let is_name_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '$' | '#' | '@' -> true
  | _ -> false

(** Is [name] (with an optional leading [*]) a valid symbol name? *)
let valid_name name =
  let body = if is_local name then String.sub name 1 (String.length name - 1) else name in
  String.length body <= max_name_len
  && String.for_all is_name_char body
  && (body <> "" || is_local name)

let scope_for t name = if is_local name then t.local () else t.global

let new_sym () = { value = None; elems = Hashtbl.create 1 }

(** Set [name] in a given scope (macro arguments). *)
let set_in (sc : scope) name v =
  Hashtbl.replace sc (norm name) { value = Some v; elems = Hashtbl.create 1 }

let is_system t name =
  let n = norm name in
  n <> "" && n.[0] = '$' && t.system n <> None

let find t name = Hashtbl.find_opt (scope_for t name) (norm name)

(** Is [name] defined at all (a value or some element)? *)
let defined t name =
  is_system t name
  || match find t name with
     | Some s -> s.value <> None || Hashtbl.length s.elems > 0
     | None -> false

(** Value of [name], or of element [sub] of it.  Element 0 is the plain
    value.  An element that is not set, of a symbol that exists, is the
    null string (p.255). *)
let get ?(sub = 0) t name =
  let n = norm name in
  if sub = 0 then
    match (if n <> "" && n.[0] = '$' then t.system n else None) with
    | Some _ as v -> v
    | None -> Option.bind (find t n) (fun s -> s.value)
  else if not (defined t n) then None
  else
    Some (Option.value ~default:""
            (Option.bind (find t n) (fun s -> Hashtbl.find_opt s.elems sub)))

(** The elements [x(1)...] in ascending subscript order (p.256). *)
let elements t name =
  match find t name with
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
       with .gs vars and then appends with .se @title() (DCF-VERIFY) *)
    let v = String.trim v in
    if v = "" then Some 0 else int_of_string_opt v

(** Set [name] ([sub] = 0 or absent: the plain value).  Setting element
    n >= 1 makes n the index counter (p.257: "it will be incremented from
    the index value of the element last set"), unless element 0 holds a
    value that is not a number.
    DCF-VERIFY: a non-numeric element 0 is left alone (p.257 warns about
    it rather than saying it is replaced). *)
let set ?(sub = 0) t name v =
  Result.map
    (fun () ->
       let s = sym_of t name in
       if sub = 0 then s.value <- Some v
       else begin
         Hashtbl.replace s.elems sub v;
         if counter_of s <> None then s.value <- Some (string_of_int sub)
       end)
    (read_only t name)

(** [.se x() = v]: set the element after the index counter (p.256-257). *)
let append t name v =
  Result.bind (read_only t name) (fun () ->
      let s = sym_of t name in
      match counter_of s with
      | None ->
        Error (Printf.sprintf "index counter &%s is not a number" (norm name))
      | Some c ->
        Hashtbl.replace s.elems (c + 1) v;
        s.value <- Some (string_of_int (c + 1));
        Ok ())

(** [.se x off] removes the whole symbol, the whole array if it is one;
    [.se x(n) off] removes one element (p.235). *)
let unset ?(sub = 0) t name =
  Result.map
    (fun () ->
       let sc = scope_for t name and n = norm name in
       match Hashtbl.find_opt sc n with
       | None -> ()
       | Some s -> if sub = 0 then Hashtbl.remove sc n else Hashtbl.remove s.elems sub)
    (read_only t name)

(* ---- date and time ------------------------------------------------------ *)

let months =
  [| "January"; "February"; "March"; "April"; "May"; "June"; "July";
     "August"; "September"; "October"; "November"; "December" |]

(* SOURCE_DATE_EPOCH (reproducible builds) overrides the clock; it is
   interpreted as UTC. *)
let now () =
  match Option.bind (Sys.getenv_opt "SOURCE_DATE_EPOCH") float_of_string_opt with
  | Some e -> Unix.gmtime e
  | None -> Unix.localtime (Unix.time ())

(** DCF-VERIFY: format of [&$DATE] (we use "Month d, yyyy"; it is not in
    SH35-0069). *)
let date_string () =
  let tm = now () in
  Printf.sprintf "%s %d, %d" months.(tm.Unix.tm_mon) tm.Unix.tm_mday
    (tm.Unix.tm_year + 1900)

(** DCF-VERIFY: format of [&$TIME] (we use "hh:mm:ss", 24-hour; it is
    not in SH35-0069). *)
let time_string () =
  let tm = now () in
  Printf.sprintf "%02d:%02d:%02d" tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec

(** The date and time symbols of SH35-0069 p.241: set once, ordinary
    (settable) global symbols, upper-case names, zero-padded values. *)
let date_symbols () =
  let tm = now () in
  [ ("SYSYEAR", Printf.sprintf "%02d" (tm.Unix.tm_year mod 100));
    ("SYSMONTH", Printf.sprintf "%02d" (tm.Unix.tm_mon + 1));
    ("SYSDAYOFM", Printf.sprintf "%02d" tm.Unix.tm_mday);
    ("SYSDAYOFW", string_of_int (tm.Unix.tm_wday + 1));
    ("SYSDAYOFY", Printf.sprintf "%03d" (tm.Unix.tm_yday + 1));
    ("SYSHOUR", Printf.sprintf "%02d" tm.Unix.tm_hour);
    ("SYSMINUTE", Printf.sprintf "%02d" tm.Unix.tm_min);
    ("SYSSECOND", Printf.sprintf "%02d" tm.Unix.tm_sec) ]
