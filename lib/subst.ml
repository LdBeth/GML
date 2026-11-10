(* Symbol substitution of a line (SH35-0069 chapter 21).

   References.  [&name] where the name is up to ten characters of
   letters, digits and [@ # $] (a leading [*] makes it local).  A
   reference ends at a blank, at a period (which is removed) or at the end
   of the line (p.232), and at a [)], as in the subscript of
   [.se array(&elem) = &] (p.256); after any other character it is not a
   reference at all ([&prodname,] is left as written), nor is a name
   longer than
   ten characters (p.235).  [&name(n)] is an element of an array,
   [&name( * )] all its elements joined by the array separator, in index
   order (p.254-256); a period after the [)] is removed.  A reference to
   an undefined symbol is left as written; an undefined local symbol is
   the null string when the current source is a macro (p.276).

   Order.  The line is resolved right to left: the scanner takes the
   rightmost [&] not yet looked at, resolves what starts there, and goes
   on to the left; a symbol value that replaced a reference is scanned
   again (from its end), so compound symbols build up from the right:
   [&type&x] -> [&type1] -> [first] (p.233), [&&x] -> [&ry] -> [4]
   (p.256), [&a.&b] -> [&a.K] -> [&JK] -> [TIMOTHY] (p.238).

   Attributes ([&L'] etc., p.235-239) apply to the symbol or string
   right after them, up to the next period or blank: they are evaluated
   when the scan reaches their operand, with the operand's value as it
   was set, and their result is not scanned again.  So [&L'&a&b] is 3
   ([&b] is resolved first, then the length of the undefined [&aK] is
   taken), [&L'&a.&b] is [2K], [&L'&V'&a] the length of the value of
   [&a] as set.  An attribute whose operand is the result of another
   attribute takes that whole result as a character string.

   The extended symbol rule (p.257-258): when a value begins with the
   control word separator, the line is split there and the rest of the
   value starts a new input line (substituted on its own; the rest of the
   line after the reference is already substituted).  [line] returns the
   pieces. *)

let max_steps = 10_000
let max_length = 100_000

exception Runaway of string

type st = {
  ctx : Ctx.t;
  amp : char;
  mutable steps : int;
  split : bool;  (** apply the extended symbol rule *)
  defer : bool;
      (** a running heading or footing definition is open: references to global
          user symbols are deferred ([deferred]) *)
}

(* ---- attribute values ------------------------------------------------------ *)

(* &A' (p.236): 1 = A, 26 = Z, 27 = AA ...; up to 65535, else 0. *)
let base26 ~upper v =
  match Expr.parse_int (String.trim v) with
  | Some n when n >= 1 && n <= 65535 ->
      let rec go n acc =
        if n = 0 then acc
        else
          let n = n - 1 in
          go (n / 26)
            (String.make 1 (Char.chr (Char.code 'A' + (n mod 26))) ^ acc)
      in
      let r = go n "" in
      if upper then r else String.lowercase_ascii r
  | _ -> "0"

(* &R' (p.236-237): roman numerals up to 3999; up to 9999 with ? for 5000
   and 10000 (&R'6020 = ?MXX, &R'9020 = M?XX); else 0. *)
let roman ~upper v =
  match Expr.parse_int (String.trim v) with
  | Some n when n >= 1 && n <= 9999 ->
      let digit d one five ten =
        match d with
        | 0 -> ""
        | 1 -> one
        | 2 -> one ^ one
        | 3 -> one ^ one ^ one
        | 4 -> one ^ five
        | 5 -> five
        | 6 -> five ^ one
        | 7 -> five ^ one ^ one
        | 8 -> five ^ one ^ one ^ one
        | _ -> one ^ ten
      in
      let r =
        digit (n / 1000) "M" "?" "?"
        ^ digit (n / 100 mod 10) "C" "D" "M"
        ^ digit (n / 10 mod 10) "X" "L" "C"
        ^ digit (n mod 10) "I" "V" "X"
      in
      if upper then r else String.lowercase_ascii r
  | _ -> "0"

(* &X' (p.238-239): pairs of hexadecimal digits to characters; an odd
   number of digits or an invalid digit gives 0.  The codes are EBCDIC,
   translated to Unicode by [Ebcdic] and written in UTF-8. *)
let hex v =
  let n = String.length v in
  let rec go i acc =
    if i >= n then Some (String.concat "" (List.rev acc))
    else
      match Ebcdic.of_hex (String.sub v i 2) with
      | Some c -> go (i + 2) (Ebcdic.utf8 c :: acc)
      | None -> None
  in
  if n = 0 || n mod 2 <> 0 then "0" else Option.value (go 0 []) ~default:"0"

(* ---- the scanner ---------------------------------------------------------- *)

type subscript = Plain | Elem of int | All

type found =
  | Nothing
  | Value of int * int * string  (** a reference [a, b) and its value *)
  | Attr of int * int * string  (** a final result for [a, b) *)
  | Deferred of int * int * string
      (** a deferred reference for [a, b) ([Doc.symref]), not scanned again *)

let is_blank c = c = ' ' || c = '\t'

(* A reference at [k] (s.[k] is the symbol character): its end, name,
   subscript and text as written (without the ending period). *)
let parse_ref s k =
  let n = String.length s in
  let j = if k + 1 < n && s.[k + 1] = '*' then k + 2 else k + 1 in
  let e = ref j in
  while !e < n && Symbols.is_name_char s.[!e] do
    incr e
  done;
  let e = !e in
  let name = String.sub s (k + 1) (e - k - 1) in
  if (e = j && j = k + 1) || e - j > Symbols.max_name_len then None
  else
    let after_period b = if b < n && s.[b] = '.' then b + 1 else b in
    if e < n && s.[e] = '(' then
      match String.index_from_opt s e ')' with
      | None -> None
      | Some c -> (
          let t = String.trim (String.sub s (e + 1) (c - e - 1)) in
          let written = String.sub s k (c + 1 - k) in
          if t = "*" then Some (after_period (c + 1), name, All, written)
          else
            match Expr.parse_int t with
            | Some x when x >= 0 ->
                Some (after_period (c + 1), name, Elem x, written)
            | _ -> None)
    else if e = n || is_blank s.[e] || s.[e] = ')' then
      Some (e, name, Plain, String.sub s k (e - k))
    else if s.[e] = '.' then Some (e + 1, name, Plain, String.sub s k (e - k))
    else None

let lookup st name sub =
  let syms = st.ctx.Ctx.syms in
  (* an unresolved symbol may come from the library ([.ly on|sym]) *)
  if st.ctx.Ctx.ly_sym && not (Symbols.defined syms name) then
    ignore (Library.resolve_symbol st.ctx name);
  let v =
    match sub with
    | Plain -> Symbols.get syms name
    | Elem x -> Symbols.get ~sub:x syms name
    | All ->
        if Symbols.defined syms name then
          Some
            (String.concat st.ctx.Ctx.chars.Chars.asep
               (Symbols.elements syms name))
        else None
  in
  match v with
  | None when Symbols.is_local name && syms.Symbols.in_macro () -> Some ""
  | v -> v

let attr1 = "ELTVWUARXeltvwuarx"
let attr2 = [ "dh"; "dv"; "ad"; "sw"; "sd" ]

(* An attribute prefix at [k]: its name and length. *)
let attr_at s k =
  let n = String.length s in
  if
    k + 3 < n
    && s.[k + 3] = '\''
    && List.mem (String.lowercase_ascii (String.sub s (k + 1) 2)) attr2
  then Some (String.uppercase_ascii (String.sub s (k + 1) 2), 4)
  else if k + 2 < n && s.[k + 2] = '\'' && String.contains attr1 s.[k + 1] then
    Some (String.make 1 s.[k + 1], 3)
  else None

(* The attribute prefix whose operand starts at [k], if any. *)
let attr_before st s k =
  if k >= 1 && s.[k - 1] = '\'' then
    if
      k >= 4
      && s.[k - 4] = st.amp
      && match attr_at s (k - 4) with Some (_, 4) -> true | _ -> false
    then Some (k - 4)
    else if k >= 3 && s.[k - 3] = st.amp && attr_at s (k - 3) <> None then
      Some (k - 3)
    else None
  else None

type operand =
  | Str of string  (** a character string *)
  | Ref of bool * string option * string  (** defined, value, as written *)

(* The attribute with prefix at [a] and operand at [o]. *)
let eval_attr st s prot a o =
  let n = String.length s in
  let name = String.sub s (a + 1) (o - a - 2) in
  let operand, stop =
    match List.assoc_opt o prot with
    | Some len -> (Str (String.sub s o len), o + len)
    | None ->
        let literal () =
          let e = ref o in
          while !e < n && not (is_blank s.[!e] || s.[!e] = '.') do
            incr e
          done;
          ( Str (String.sub s o (!e - o)),
            if !e < n && s.[!e] = '.' then !e + 1 else !e )
        in
        if o < n && s.[o] = st.amp then
          match parse_ref s o with
          | Some (b, nm, sub, written) ->
              let defined = Symbols.defined st.ctx.Ctx.syms nm in
              (Ref (defined, lookup st nm sub, written), b)
          | None -> literal ()
        else literal ()
  in
  let text =
    match operand with
    | Str t -> t
    | Ref (_, Some v, _) -> v
    | Ref (_, None, w) -> w
  in
  let device () =
    let name = String.uppercase_ascii name in
    let key = "attribute &" ^ name ^ "'" in
    Ctx.warn_once st.ctx key
      "&%s' has no meaning without an output device; 0 is used" name;
    "0"
  in
  let r =
    match name with
    | "E" | "e" -> ( match operand with Ref (true, _, _) -> "1" | _ -> "0")
    | "L" | "l" | "W" | "w" -> string_of_int (String.length text)
    | "T" | "t" ->
        if Expr.parse_int (String.trim text) <> None then "N" else "C"
    | "V" | "v" -> ( match operand with Ref (_, Some v, _) -> v | _ -> "")
    | "U" | "u" -> String.uppercase_ascii text
    | "A" -> base26 ~upper:true text
    | "a" -> base26 ~upper:false text
    | "R" -> roman ~upper:true text
    | "r" -> roman ~upper:false text
    | "X" | "x" -> hex text
    | "DH" | "dh" | "DV" | "dv" -> (
        let axis =
          if String.lowercase_ascii name = "dh" then Units.Horizontal
          else Units.Vertical
        in
        match Units.device_units axis (String.trim text) with
        | Some n -> string_of_int n
        | None -> "0")
    | _ -> device () (* AD SW SD *)
  in
  Attr (a, stop, r)

(* Is the reference at [k] the end of a compound one: right after the
   symbol character ([&&x]) or after the name of another reference
   ([&type&x], [&*a&x]), whose name its value completes? *)
let compound st s k =
  let j = ref (k - 1) in
  while !j >= 0 && Symbols.is_name_char s.[!j] do
    decr j
  done;
  let j = if !j >= 0 && !j < k - 1 && s.[!j] = '*' then !j - 1 else !j in
  j >= 0 && s.[j] = st.amp

(* Rel 4: while a running heading or footing is defined, a reference to a
   global user symbol is replaced when the heading is placed on the page
   (LR p.312 r7, p.315 r7, p.316: "Unresolved symbols included in a
   running heading definition are substituted on each page").  Such a
   reference [&name] or [&name.] becomes a span ([Doc.symref]) with the
   value it has now, or as written when it has none (an unresolved
   symbol).  Not deferred: a local symbol (a macro parameter), a system
   symbol ([$] names), an array element, the operand of an attribute
   (taken before, [attr_before]), the end of a compound reference
   ([compound]: in [&type&x] the value of [&x] builds the name of the
   other; [part&x] is deferred), and a value that would split the line
   (the extended rule).  A value with references in it (DSM#SET's
   [@shead = '&@stitle.']) is carried substituted, as is the value of
   the hint [gml:symval] ([Interp.create]): the symbols in it are taken
   where it is defined or set, not per page.  DCF-VERIFY (not in LR Rel
   4): every global user symbol is deferred, also one that is never set
   again (a text variable such as [&amp.]): the output is the same, the
   reference is only marked.  [expand_fwd] is [expand] (below). *)
let expand_fwd : (st -> string -> string list) ref = ref (fun _ s -> [ s ])

let deferred st s k b name sub v =
  let ok =
    st.defer && sub = Plain
    && (not (Symbols.is_local name))
    && name.[0] <> '$'
    && not (compound st s k)
  in
  if not ok then None
  else
    match v with
    | None -> Some (Doc.symref st.ctx.Ctx.doc name (String.sub s k (b - k)))
    | Some v ->
        let sep = if st.split then st.ctx.Ctx.chars.Chars.cw_sep else None in
        if
          Chars.has_sr v
          || match sep with Some c -> v <> "" && v.[0] = c | None -> false
        then None
        else
          (* a value with references (DSM#SET's @shead = '&@stitle.') is
             substituted now, without deferring: the value carried *)
          let v =
            if String.contains v st.amp then
              String.concat ""
                (!expand_fwd { st with split = false; defer = false } v)
            else v
          in
          Some (Doc.symref st.ctx.Ctx.doc name v)

let at st s prot k =
  match attr_before st s k with
  | Some a -> eval_attr st s prot a k
  | None -> (
      match attr_at s k with
      | Some (_, plen) -> eval_attr st s prot k (k + plen)
      | None -> (
          match parse_ref s k with
          | None -> Nothing
          | Some (b, name, sub, _) -> (
              let v = lookup st name sub in
              match deferred st s k b name sub v with
              | Some r -> Deferred (k, b, r)
              | None -> (
                  match v with Some v -> Value (k, b, v) | None -> Nothing))))

let rec expand st s =
  let buf = ref s in
  let prot = ref [] in
  (* (start, length) of attribute results *)
  let more = ref [] in
  (* lines split off by the extended rule *)
  let i = ref (String.length s) in
  let sep = if st.split then st.ctx.Ctx.chars.Chars.cw_sep else None in
  let replace a b v ~protect =
    let s = !buf in
    let d = String.length v - (b - a) in
    buf := String.sub s 0 a ^ v ^ String.sub s b (String.length s - b);
    prot :=
      List.filter_map
        (fun (p, l) ->
          if p >= b then Some (p + d, l)
          else if p + l <= a then Some (p, l)
          else None)
        !prot;
    if protect then prot := (a, String.length v) :: !prot;
    if String.length !buf > max_length then
      raise (Runaway "symbol substitution result too long")
  in
  let rec loop () =
    if !i > 0 then
      match String.rindex_from_opt !buf (!i - 1) st.amp with
      | None -> ()
      | Some k ->
          st.steps <- st.steps + 1;
          if st.steps > max_steps then
            raise
              (Runaway
                 (Printf.sprintf
                    "symbol substitution does not terminate (more than %d \
                     steps)"
                    max_steps));
          (match at st !buf !prot k with
          | Nothing -> i := k
          | Attr (a, b, r) ->
              replace a b r ~protect:true;
              i := a
          | Deferred (a, b, r) ->
              replace a b r ~protect:false;
              i := a
          | Value (a, b, v) -> (
              match sep with
              | Some c when v <> "" && v.[0] = c ->
                  let s = !buf in
                  let rest = String.sub s b (String.length s - b) in
                  let tail = expand st (String.sub v 1 (String.length v - 1)) in
                  let tail =
                    match List.rev tail with
                    | last :: r -> List.rev ((last ^ rest) :: r)
                    | [] -> [ rest ]
                  in
                  more := tail @ !more;
                  buf := String.sub s 0 a;
                  prot := List.filter (fun (p, l) -> p + l <= a) !prot;
                  i := a
              | _ ->
                  if v = String.sub !buf a (b - a) then i := k
                  else begin
                    replace a b v ~protect:false;
                    i := a + String.length v
                  end));
          loop ()
  in
  loop ();
  !buf :: !more

let () = expand_fwd := expand

let run ctx ~split ~defer s =
  let amp = ctx.Ctx.chars.Chars.symbol in
  if not (String.contains s amp) then [ s ]
  else
    let defer =
      defer && (not ctx.Ctx.doc.Doc.mute) && Doc.in_running ctx.Ctx.doc
    in
    let st = { ctx; amp; steps = 0; split; defer } in
    try expand st s
    with Runaway m ->
      Ctx.error ctx "%s" m;
      [ s ]

(** Substitute the symbols of an input line, with the extended symbol rule: the
    result is the line and the new lines split off it. On a runaway substitution
    the line is returned unchanged (after an error). *)
let line ctx s = run ctx ~split:true ~defer:true s

(** Substitute the symbols of a string (no line splitting: a value that begins
    with the separator is kept as it is). With [~defer:true] (text: a literal
    line, residual text) references are deferred in a running heading as by
    [line]. *)
let string ?(defer = false) ctx s =
  String.concat "" (run ctx ~split:false ~defer s)
