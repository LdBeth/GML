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
  lines : (int * string) list;   (** subscript, line; ascending *)
  defined_at : Loc.t;
}

(** Macro name (lowercase) -> definition.  Names are case-insensitive
    (p.275), up to ten characters ([Line.max_macro_name]). *)
type store = (string, def) Hashtbl.t

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

(** [.dm name(n) /line] (or [name()]: the next multiple of ten after the
    highest line, p.273); the macro is created if needed. *)
let set_line (st : store) name ~at sub line =
  let old = match find st name with Some d -> d.lines | None -> [] in
  let n =
    match sub with
    | Some n -> n
    | None ->
      let top = List.fold_left (fun m (k, _) -> max m k) 0 old in
      (top / step + 1) * step
  in
  let lines = List.sort compare ((n, line) :: List.remove_assoc n old) in
  let defined_at = match find st name with Some d -> d.defined_at | None -> at in
  Hashtbl.replace st (key name) { lines; defined_at }

(** [.dm name(n) off]: remove line n (SH35-0050 p.16).  Returns false if
    the macro does not exist. *)
let delete_line (st : store) name n =
  match find st name with
  | None -> false
  | Some d ->
    Hashtbl.replace st (key name) { d with lines = List.remove_assoc n d.lines };
    true


(* ---- .dm operands ------------------------------------------------------- *)

type dm =
  | Begin of string                 (** [.dm name on] *)
  | End of string option            (** [.dm off]; [.dm name off] *)
  | Delete of string                (** [.dm name delete] *)
  | Lib of string                   (** [.dm name lib]: from the library *)
  | Lines of string * string list   (** [.dm name /l1/l2/] *)
  | Set_line of string * int option * string   (** [.dm name(n) /line] *)
  | Delete_line of string * int     (** [.dm name(n) off] *)
  | Bad of string                   (** a diagnostic *)

let scan_name s i =
  let n = String.length s in
  let j = ref i in
  while !j < n && Line.is_name_char s.[!j] do incr j done;
  !j

let skip_blanks s i =
  let n = String.length s in
  let i = ref i in
  while !i < n && Expr.is_blank s.[!i] do incr i done;
  !i

(** Parse the operands of [.dm].

    [.dm name /a/b/]: the first non-blank character after the name is the
    delimiter; each delimited piece is one body line, and the final
    delimiter is optional (p.272).  An empty piece is an empty line.
    [.dm name on] starts a definition ended by [.dm off] (p.272);
    [.dm name off] deletes the macro (SH35-0050 p.15), as does our
    synonym [.dm name delete].  [.dm name lib] defines it from the
    macro library ([Library], p.282).
    [.dm name(n) /line] and [.dm name() /line] set one line,
    [.dm name(n) off] removes it (p.273, SH35-0050 p.16).
    DCF-VERIFY: in the subscripted form everything after the delimiter is
    the line (a second delimiter is part of it). *)
let parse_dm ops =
  let n = String.length ops in
  let i = skip_blanks ops 0 in
  let j = scan_name ops i in
  if j = i then
    if String.trim ops = "" then Bad ".dm: macro name required"
    else Bad (Printf.sprintf ".dm: invalid macro name in %s" (String.trim ops))
  else begin
    let name = String.sub ops i (j - i) in
    if String.length name > Line.max_macro_name then
      Bad (Printf.sprintf ".dm: macro name %s longer than %d characters" name
             Line.max_macro_name)
    else if j < n && ops.[j] = '(' then
      match String.index_from_opt ops j ')' with
      | None -> Bad (Printf.sprintf ".dm %s: missing )" name)
      | Some e -> (
        let t = String.trim (String.sub ops (j + 1) (e - j - 1)) in
        let sub = if t = "" then Ok None else
            match int_of_string_opt t with
            | Some k when k > 0 -> Ok (Some k)
            | _ -> Error t
        in
        let k = skip_blanks ops (e + 1) in
        let rest = String.sub ops k (n - k) in
        match sub with
        | Error t -> Bad (Printf.sprintf ".dm %s: invalid line number %s" name t)
        | Ok sub ->
          if String.lowercase_ascii (String.trim rest) = "off" then
            match sub with
            | Some s -> Delete_line (name, s)
            | None -> Bad (Printf.sprintf ".dm %s(): line number required with OFF" name)
          else if rest = "" then Bad (Printf.sprintf ".dm %s(%s): line expected" name t)
          else Set_line (name, sub, String.sub rest 1 (String.length rest - 1)))
    else begin
      let k = skip_blanks ops j in
      let rest = String.sub ops k (n - k) in
      match String.lowercase_ascii (String.trim rest) with
      | "on" -> Begin name
      | "off" when k > j -> End (Some name)
      | "delete" when k > j -> Delete name
      | "lib" when k > j -> Lib name
      | "" ->
        if String.lowercase_ascii name = "off" then End None
        else Bad (Printf.sprintf ".dm %s: definition expected" name)
      | _ ->
        let d = rest.[0] in
        if Line.is_name_char d then
          Bad (Printf.sprintf ".dm %s: ON, OFF or a delimited definition expected" name)
        else
          let pieces = String.split_on_char d (String.sub rest 1 (String.length rest - 1)) in
          let pieces =
            match List.rev pieces with
            | "" :: r when r <> [] -> List.rev r
            | _ -> pieces
          in
          Lines (name, pieces)
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
      if k + 1 < n && s.[k + 1] = q then (Buffer.add_char b q; go (k + 2))
      else k + 1
    else (Buffer.add_char b s.[k]; go (k + 1))
  in
  let stop = go (i + 1) in
  (Buffer.contents b, stop)

let is_delim_op = function '+' | '-' | '*' | '/' | '(' | ')' -> true | _ -> false

(** Split invocation operands into tokens (SH35-0069 p.253, p.276):
    tokens are delimited by blanks, arithmetic operators and parentheses,
    and each operator or parenthesis is a token itself; a token in single
    quotation marks may contain any of these (the quotes are removed,
    [''] inside stands for one quote); [%] alone is a null token. *)
let tokens s =
  let n = String.length s in
  let rec go i acc =
    let i = skip_blanks s i in
    if i >= n then List.rev acc
    else if s.[i] = '\'' then
      let v, j = quoted s i in
      go j (v :: acc)
    else if is_delim_op s.[i] then go (i + 1) (String.make 1 s.[i] :: acc)
    else begin
      let j = ref i in
      while !j < n && not (Expr.is_blank s.[!j] || is_delim_op s.[!j]) do incr j done;
      let w = String.sub s i (!j - i) in
      go !j ((if w = "%" then "" else w) :: acc)
    end
  in
  go 0 []

(** Fill [scope] (the local scope of the frame about to be pushed) from
    the operand string [ops]: [&*] = [ops] (the whole line after the
    blank that ends the macro name, leading blanks kept), [&*0] = the
    number of tokens, [&*1]... = the tokens (p.253).  There are no
    keyword arguments. *)
let bind_args_list scope ops toks =
  Symbols.set_in scope "*" ops;
  List.iteri (fun k v -> Symbols.set_in scope ("*" ^ string_of_int (k + 1)) v) toks;
  Symbols.set_in scope "*0" (string_of_int (List.length toks))

let bind_args scope ops = bind_args_list scope ops (tokens ops)
