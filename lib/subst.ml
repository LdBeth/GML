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
   pieces.

   [&'name(args)] built-in functions are our extension (they are not in
   SH35-0069): their arguments, being to the right, are substituted
   first; quoted arguments lose their quotes; the result is not scanned
   again. *)

let max_steps = 10_000
let max_length = 100_000

exception Runaway of string
exception Fn_error of string

type st = {
  ctx : Ctx.t;
  amp : char;
  seen : (string, unit) Hashtbl.t;  (** messages already reported *)
  mutable steps : int;
  split : bool;  (** apply the extended symbol rule *)
}

(* Report each distinct message once per line. *)
let report st sev msg =
  if not (Hashtbl.mem st.seen msg) then begin
    Hashtbl.add st.seen msg ();
    match sev with
    | `Warn -> Ctx.warn st.ctx "%s" msg
    | `Err -> Ctx.error st.ctx "%s" msg
  end

(* A quote starts a delimited string only at the start of a function
   argument: after '(' or ',' and optional blanks. *)
let quote_starts s i =
  let rec back k =
    if k < 0 then true
    else match s.[k] with ' ' -> back (k - 1) | '(' | ',' -> true | _ -> false
  in
  Expr.is_quote s.[i] && back (i - 1)

(* Index of the ')' matching the '(' at [i]. *)
let find_close s i =
  let n = String.length s in
  let rec go k depth =
    if k >= n then None
    else
      match s.[k] with
      | '(' -> go (k + 1) (depth + 1)
      | ')' -> if depth = 1 then Some k else go (k + 1) (depth - 1)
      | _ when quote_starts s k -> go (Expr.close_quote s k + 1) depth
      | _ -> go (k + 1) depth
  in
  go (i + 1) 1

(* Split function arguments at top-level commas. *)
let split_args s =
  let n = String.length s in
  let args = ref [] and start = ref 0 in
  let rec go k depth =
    if k >= n then args := String.sub s !start (n - !start) :: !args
    else
      match s.[k] with
      | '(' -> go (k + 1) (depth + 1)
      | ')' -> go (k + 1) (depth - 1)
      | ',' when depth = 0 ->
          args := String.sub s !start (k - !start) :: !args;
          start := k + 1;
          go (k + 1) depth
      | _ when quote_starts s k -> go (Expr.close_quote s k + 1) depth
      | _ -> go (k + 1) depth
  in
  go 0 0;
  List.rev !args

(* ---- built-in functions ------------------------------------------------ *)

let num name a =
  match Expr.parse_int (String.trim a) with
  | Some v -> v
  | None -> raise (Fn_error (Printf.sprintf "&'%s: %s is not a number" name a))

let pad_char name = function
  | None -> ' '
  | Some p when String.length p = 1 -> p.[0]
  | Some p ->
      raise
        (Fn_error
           (Printf.sprintf "&'%s: pad must be one character, not '%s'" name p))

(* REXX-style: [n] chars of [s] starting at 1-based [start], padded. *)
let substr s start len pad =
  let l = String.length s in
  String.init (max 0 len) (fun k ->
      let p = start - 1 + k in
      if p >= 0 && p < l then s.[p] else pad)

let words_of s = String.split_on_char ' ' s |> List.filter (( <> ) "")

let find_sub hay needle from =
  let lh = String.length hay and ln = String.length needle in
  let rec go i =
    if i + ln > lh then 0
    else if String.sub hay i ln = needle then i + 1
    else go (i + 1)
  in
  if from < 0 then 0 else go from

let strip s opt ch =
  let n = String.length s in
  let i = ref 0 and j = ref n in
  if opt = 'B' || opt = 'L' then
    while !i < n && s.[!i] = ch do
      incr i
    done;
  if opt = 'B' || opt = 'T' then
    while !j > !i && s.[!j - 1] = ch do
      decr j
    done;
  String.sub s !i (!j - !i)

let apply name args =
  let arity lo hi =
    let k = List.length args in
    if k < lo || k > hi then
      raise
        (Fn_error
           (Printf.sprintf "&'%s: %d argument%s given, %s expected" name k
              (if k = 1 then "" else "s")
              (if lo = hi then string_of_int lo
               else Printf.sprintf "%d to %d" lo hi)))
  in
  let arg k = List.nth_opt args k in
  let a k = Option.value (arg k) ~default:"" in
  let opt k = match arg k with Some "" | None -> None | Some v -> Some v in
  let int_opt k d = match opt k with None -> d | Some v -> num name v in
  match name with
  | "length" ->
      arity 1 1;
      string_of_int (String.length (a 0))
  | "substr" ->
      arity 2 4;
      let s = a 0 and n = num name (a 1) in
      if n < 1 then raise (Fn_error "&'substr: start must be positive");
      let len = int_opt 2 (max 0 (String.length s - n + 1)) in
      substr s n len (pad_char name (opt 3))
  | "index" ->
      arity 2 3;
      let st = int_opt 2 1 in
      string_of_int (find_sub (a 0) (a 1) (st - 1))
  | "left" ->
      arity 2 3;
      substr (a 0) 1 (num name (a 1)) (pad_char name (opt 2))
  | "right" ->
      arity 2 3;
      let s = a 0 and len = num name (a 1) in
      substr s (String.length s - len + 1) len (pad_char name (opt 2))
  | "upper" | "lower" ->
      arity 1 3;
      let s = a 0 in
      let l = String.length s in
      let st = int_opt 1 1 in
      let len = int_opt 2 (l - st + 1) in
      let f =
        if name = "upper" then Char.uppercase_ascii else Char.lowercase_ascii
      in
      String.mapi
        (fun i c -> if i >= st - 1 && i < st - 1 + len then f c else c)
        s
  | "strip" ->
      arity 1 3;
      let o =
        match opt 1 with None -> 'B' | Some o -> Char.uppercase_ascii o.[0]
      in
      if not (String.contains "BLT" o) then
        raise
          (Fn_error
             (Printf.sprintf "&'strip: option must be B, L or T, not %s" (a 1)));
      strip (a 0) o (pad_char name (opt 2))
  | "copies" ->
      arity 2 2;
      let k = num name (a 1) in
      if k < 0 then raise (Fn_error "&'copies: count must not be negative");
      String.concat "" (List.init k (fun _ -> a 0))
  | "delstr" ->
      arity 2 3;
      let s = a 0 and n = num name (a 1) in
      let l = String.length s in
      if n < 1 then raise (Fn_error "&'delstr: start must be positive");
      if n > l then s
      else
        let len = int_opt 2 (l - n + 1) in
        let e = min l (n - 1 + len) in
        String.sub s 0 (n - 1) ^ String.sub s e (l - e)
  | "insert" ->
      arity 2 5;
      let nw = a 0 and target = a 1 in
      let n = int_opt 2 0 in
      let pad = pad_char name (opt 4) in
      let len = int_opt 3 (String.length nw) in
      let nw = substr nw 1 len pad in
      let tl = String.length target in
      let target =
        if n > tl then target ^ String.make (n - tl) pad else target
      in
      let tl = String.length target in
      String.sub target 0 n ^ nw ^ String.sub target n (tl - n)
  | "word" -> (
      arity 2 2;
      let k = num name (a 1) in
      match List.nth_opt (words_of (a 0)) (k - 1) with
      | Some w when k >= 1 -> w
      | _ -> "")
  | "words" ->
      arity 1 1;
      string_of_int (List.length (words_of (a 0)))
  | "min" | "max" ->
      if args = [] then
        raise (Fn_error (Printf.sprintf "&'%s: arguments expected" name));
      let vs = List.map (num name) args in
      let f = if name = "min" then min else max in
      string_of_int (List.fold_left f (List.hd vs) (List.tl vs))
  | _ -> raise (Fn_error (Printf.sprintf "unknown function &'%s" name))

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
   number of digits or an invalid digit gives 0.  Modern edge: a code
   above 7F is taken as a Latin-1 character and written in UTF-8, so the
   output stays well-formed (DCF codes are EBCDIC). *)
let hex v =
  let n = String.length v in
  let ok =
    n > 0
    && n mod 2 = 0
    && String.for_all
         (function '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true | _ -> false)
         v
  in
  if not ok then "0"
  else begin
    let b = Buffer.create (n / 2) in
    for i = 0 to (n / 2) - 1 do
      let c = int_of_string ("0x" ^ String.sub v (2 * i) 2) in
      Buffer.add_utf_8_uchar b (Uchar.of_int c)
    done;
    Buffer.contents b
  end

(* ---- the scanner ---------------------------------------------------------- *)

type subscript = Plain | Elem of int | All

type found =
  | Nothing
  | Value of int * int * string  (** a reference [a, b) and its value *)
  | Attr of int * int * string  (** a final result for [a, b) *)

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

(* [&'name(args)] at [i]; [None] if it is not a well-formed call.  The
   arguments are already substituted. *)
let call st s i =
  let n = String.length s in
  let j = ref (i + 2) in
  while
    !j < n && match s.[!j] with 'a' .. 'z' | 'A' .. 'Z' -> true | _ -> false
  do
    incr j
  done;
  if !j = i + 2 || !j >= n || s.[!j] <> '(' then None
  else
    match find_close s !j with
    | None -> None
    | Some k -> (
        let name = String.lowercase_ascii (String.sub s (i + 2) (!j - i - 2)) in
        let arg a =
          let a = String.trim a in
          let l = String.length a in
          if l >= 2 && Expr.is_quote a.[0] && a.[l - 1] = a.[0] then
            String.sub a 1 (l - 2)
          else a
        in
        let inner = String.sub s (!j + 1) (k - !j - 1) in
        let args =
          if String.trim inner = "" then [] else List.map arg (split_args inner)
        in
        match apply name args with
        | v -> Some (k + 1, v)
        | exception Fn_error m ->
            report st `Err m;
            Some (k + 1, String.sub s i (k + 1 - i)))

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
          if o + 1 < n && s.[o + 1] = '\'' then
            match call st s o with
            | Some (stop, v) -> (Str v, stop)
            | None -> literal ()
          else
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
    | _ -> device () (* DH DV AD SW SD *)
  in
  Attr (a, stop, r)

let at st s prot k =
  match attr_before st s k with
  | Some a -> eval_attr st s prot a k
  | None -> (
      let n = String.length s in
      if k + 1 < n && s.[k + 1] = '\'' then
        match call st s k with
        | Some (stop, v) -> Attr (k, stop, v)
        | None -> Nothing
      else
        match attr_at s k with
        | Some (_, plen) -> eval_attr st s prot k (k + plen)
        | None -> (
            match parse_ref s k with
            | None -> Nothing
            | Some (b, name, sub, _) -> (
                match lookup st name sub with
                | Some v -> Value (k, b, v)
                | None -> Nothing)))

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

let run ctx ~split s =
  let amp = ctx.Ctx.chars.Chars.symbol in
  if not (String.contains s amp) then [ s ]
  else
    let st = { ctx; amp; seen = Hashtbl.create 4; steps = 0; split } in
    match expand st s with
    | r -> r
    | exception Runaway m ->
        Ctx.error ctx "%s" m;
        [ s ]

(** Substitute the symbols of an input line, with the extended symbol rule: the
    result is the line and the new lines split off it. On a runaway substitution
    the line is returned unchanged (after an error). *)
let line ctx s = run ctx ~split:true s

(** Substitute the symbols of a string (no line splitting: a value that begins
    with the separator is kept as it is). *)
let string ctx s = String.concat "" (run ctx ~split:false s)
