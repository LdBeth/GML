(* Macros: the store, the parsing of [.dm] and of invocation arguments.

   This module is pure (no interpreter context); the control words
   [.dm .ms .me .em .ec] and the invocation itself are in [Control], the
   capture of [.dm name on] bodies is in [Interp].

   A macro is a set of numbered lines (SH35-0069 p.273): the subscripted
   form [.dm name(n) /line] sets line n, and the macro runs in subscript
   order.  The inline and single-line forms define the whole macro, with
   the lines numbered 10, 20, 30... (the numbering SH35-0050 p.16 relies
   on: "&$LNUM ... is 10 because this is the first line").  A running
   macro reads its definition live ([Input.macro_frame]): a change to a
   later line takes effect in the same call (SH35-0050 p.181), a change
   to a line already read at the next call (p.16). *)

type def = {
  lines : (int * string) list;  (** subscript, line; ascending *)
  defined_at : Loc.t;
}

type store = (string, def) Hashtbl.t
(** Macro name (lowercase) -> definition. Names are case-insensitive (p.275), up
    to ten characters ([Line.max_macro_name]). *)

let create () : store = Hashtbl.create 32
let key = String.lowercase_ascii
let find (st : store) name = Hashtbl.find_opt st (key name)
let step = 10
let numbered body = List.mapi (fun i l -> ((i + 1) * step, l)) body

let define (st : store) name ~at body =
  Hashtbl.replace st (key name) { lines = numbered body; defined_at = at }

let delete (st : store) name =
  let k = key name in
  let had = Hashtbl.mem st k in
  Hashtbl.remove st k;
  had

(** [.dm name(n) /line] (or [name()]: the next multiple of ten after the highest
    line, p.273); the macro is created if needed. *)
let set_line (st : store) name ~at sub line =
  let old, defined_at =
    match find st name with
    | Some d -> (d.lines, d.defined_at)
    | None -> ([], at)
  in
  let n =
    match sub with
    | Some n -> n
    | None ->
        let top = List.fold_left (fun m (k, _) -> max m k) 0 old in
        ((top / step) + 1) * step
  in
  let lines = List.sort compare ((n, line) :: List.remove_assoc n old) in
  Hashtbl.replace st (key name) { lines; defined_at }

(** [.dm name(n) off]: remove line n (SH35-0050 p.16). Returns false if the
    macro does not exist. *)
let delete_line (st : store) name n =
  match find st name with
  | None -> false
  | Some d ->
      Hashtbl.replace st (key name)
        { d with lines = List.remove_assoc n d.lines };
      true

(* ---- .dm operands ------------------------------------------------------- *)

type dm =
  | Begin of string  (** [.dm name on] *)
  | End of string option  (** [.dm off]; [.dm name off] *)
  | Delete of string  (** [.dm name delete] *)
  | Lib of string  (** [.dm name lib]: from the library *)
  | Lines of string * string list  (** [.dm name /l1/l2/] *)
  | Set_line of string * int option * string  (** [.dm name(n) /line] *)
  | Delete_line of string * int  (** [.dm name(n) off] *)
  | Assign of string * int option * string
      (** [.dm name x], [.dm name(n) x]: the macro (line) into [&x] *)
  | Bad of string  (** a diagnostic *)

let scan_name s i =
  let n = String.length s in
  let j = ref i in
  while !j < n && Line.is_name_char s.[!j] do
    incr j
  done;
  !j

(* The delimited part of a .dm line ([rest] starts at its first non-blank
   character): the delimiter and what follows, without one final
   delimiter (LR p.142: "The final delimiter may be omitted").  A single
   alphanumeric character is the [.dm name x] form ([assign_operand],
   taken first by [parse_dm]); two or more characters are a delimiter and
   a line, whatever the first one is (p.143). *)
let delimited name rest =
  let e = String.length rest in
  let alnum = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' -> true
    | _ -> false
  in
  if e = 1 && alnum rest.[0] then
    Error
      (Printf.sprintf
         ".dm %s %s: assigning a macro to a symbol is not supported" name rest)
  else
    let d = rest.[0] in
    let e = if e > 1 && rest.[e - 1] = d then e - 1 else e in
    Ok (d, String.sub rest 1 (e - 1))

(* [.dm name x] (LR p.143): x, the operand alone, is one alphanumeric
   character; the symbol &x gets the current value of the macro or line *)
let assign_operand rest =
  match String.trim rest with
  | x
    when String.length x = 1
         && Line.is_name_char x.[0]
         && x.[0] <> '@'
         && x.[0] <> '#'
         && x.[0] <> '$' ->
      Some x
  | _ -> None

(** The current value of macro [name] ([.dm name x]): its lines in order, joined
    by [sep] (the control word separator, so that the value on a control word
    line runs them again; DCF-VERIFY: LR p.143 says only "the current value of a
    macro"); of line [n] ([.dm name(n) x]): that line, null if there is none.
    [None]: no such macro. *)
let value (st : store) name sub ~sep =
  Option.map
    (fun d ->
      match sub with
      | Some n -> Option.value (List.assoc_opt n d.lines) ~default:""
      | None -> String.concat sep (List.map snd d.lines))
    (find st name)

(** Parse the operands of [.dm] (LR p.141-145).

    [.dm name /a/b/]: the first non-blank character after the name is the
    delimiter; each delimited piece is one body line, and the final delimiter is
    optional. An empty piece is an empty line; [.dm name] alone defines a null
    macro. [.dm name on] starts a definition ended by [.dm off]; [.dm name off]
    deletes the macro, as does our synonym [.dm name delete] (EXT).
    [.dm name lib] defines it from the macro library ([Library]).
    [.dm name(n) /line/] and [.dm name() /line/] set one line (all after the
    delimiter, less one final delimiter, is that line; none: a null line), n
    from 0; [.dm name(n) off] removes it. *)
let parse_dm ops =
  let n = String.length ops in
  let i = Expr.skip_blanks ops 0 in
  let j = scan_name ops i in
  if j = i then
    if String.trim ops = "" then Bad ".dm: macro name required"
    else Bad (Printf.sprintf ".dm: invalid macro name in %s" (String.trim ops))
  else begin
    let name = String.sub ops i (j - i) in
    if String.length name > Line.max_macro_name then
      Bad
        (Printf.sprintf ".dm: macro name %s longer than %d characters" name
           Line.max_macro_name)
    else if j < n && ops.[j] = '(' then
      match String.index_from_opt ops j ')' with
      | None -> Bad (Printf.sprintf ".dm %s: missing )" name)
      | Some e -> (
          let t = String.trim (String.sub ops (j + 1) (e - j - 1)) in
          let sub =
            if t = "" then Ok None
            else
              match int_of_string_opt t with
              | Some k when k >= 0 -> Ok (Some k)
              | _ -> Error t
          in
          let k = Expr.skip_blanks ops (e + 1) in
          let rest = String.sub ops k (n - k) in
          match sub with
          | Error t ->
              Bad (Printf.sprintf ".dm %s: invalid line number %s" name t)
          | Ok sub -> (
              if String.lowercase_ascii (String.trim rest) = "off" then
                match sub with
                | Some s -> Delete_line (name, s)
                | None ->
                    Bad
                      (Printf.sprintf ".dm %s(): line number required with OFF"
                         name)
              else if rest = "" then Set_line (name, sub, "")
              else if assign_operand rest <> None then
                Assign (name, sub, Option.get (assign_operand rest))
              else
                match delimited name rest with
                | Ok (_, line) -> Set_line (name, sub, line)
                | Error m -> Bad m))
    else begin
      let k = Expr.skip_blanks ops j in
      let rest = String.sub ops k (n - k) in
      match String.lowercase_ascii (String.trim rest) with
      | "on" -> Begin name
      | "off" when k > j -> End (Some name)
      | "delete" when k > j -> Delete name
      | "lib" when k > j -> Lib name
      | "" ->
          if String.lowercase_ascii name = "off" then End None
          else Lines (name, [])
      | _ when assign_operand rest <> None ->
          Assign (name, None, Option.get (assign_operand rest))
      | _ -> (
          match delimited name rest with
          | Ok (d, body) -> Lines (name, String.split_on_char d body)
          | Error m -> Bad m)
    end
  end

(* ---- invocation arguments ----------------------------------------------- *)

(* A delimited string at [i] (s.[i] is the quote): its contents and the
   index after the closing quote.  A doubled quote inside stands for one.
   An unterminated string runs to the end. *)
let quoted s i =
  let n = String.length s and q = s.[i] in
  let b = Buffer.create 16 in
  let rec go k =
    if k >= n then n
    else if s.[k] = q then
      if k + 1 < n && s.[k + 1] = q then (
        Buffer.add_char b q;
        go (k + 2))
      else k + 1
    else (
      Buffer.add_char b s.[k];
      go (k + 1))
  in
  let stop = go (i + 1) in
  (Buffer.contents b, stop)

let is_delim_op = function
  | '+' | '-' | '*' | '/' | '(' | ')' -> true
  | _ -> false

(** Split invocation operands into tokens (SH35-0069 p.253, p.276): tokens are
    delimited by blanks, arithmetic operators and parentheses, and each operator
    or parenthesis is a token itself; a token in single quotation marks may
    contain any of these (the quotes are removed, [''] inside stands for one
    quote); [%] alone is a null token. *)
let tokens s =
  let n = String.length s in
  let rec go i acc =
    let i = Expr.skip_blanks s i in
    if i >= n then List.rev acc
    else if s.[i] = '\'' then
      let v, j = quoted s i in
      go j (v :: acc)
    else if is_delim_op s.[i] then go (i + 1) (String.make 1 s.[i] :: acc)
    else begin
      let j = ref i in
      while !j < n && not (Expr.is_blank s.[!j] || is_delim_op s.[!j]) do
        incr j
      done;
      let w = String.sub s i (!j - i) in
      go !j ((if w = "%" then "" else w) :: acc)
    end
  in
  go 0 []

(** Fill [scope] (the local scope of the frame about to be pushed) from the
    operand string [ops]: [&*] = [ops] (the whole line after the blank that ends
    the macro name, leading blanks kept), [&*0] = the number of tokens, [&*1]...
    = the tokens (p.253). There are no keyword arguments. *)
let bind_args_list scope ops toks =
  Symbols.set_in scope "*" ops;
  List.iteri
    (fun k v -> Symbols.set_in scope ("*" ^ string_of_int (k + 1)) v)
    toks;
  Symbols.set_in scope "*0" (string_of_int (List.length toks))

let bind_args scope ops = bind_args_list scope ops (tokens ops)
