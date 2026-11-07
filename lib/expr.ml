(* Expressions: the right-hand side of [.se] and the conditions of [.if].

   Operands arrive already substituted (substitution is done on the
   whole input line), so this module is pure: it sees only text. *)

(** A SCRIPT number: optional sign, then decimal digits only. *)
let parse_int s =
  let n = String.length s in
  let start = if n > 0 && (s.[0] = '+' || s.[0] = '-') then 1 else 0 in
  if start >= n then None
  else
    let digits = String.sub s start (n - start) in
    if String.for_all (function '0' .. '9' -> true | _ -> false) digits then
      Option.map
        (fun v -> if s.[0] = '-' then -v else v)
        (int_of_string_opt digits)
    else None

let is_blank c = c = ' ' || c = '\t'

(** SCRIPT/VS delimits strings with the single quotation mark only (SH35-0069
    p.230: [.se type 'prepared on a "word processing" machine] keeps the double
    quotes). *)
let is_quote c = c = '\''

(* Index of the closing quote matching the one at [i] (or [n]).  A
   doubled quote inside the string stands for one quote and does not
   close it (DSMPROF3's [.se @oquote '"''"''...], SH35-0069 p.230; the
   symbol file of the pass model writes a quote in a value doubled,
   Symbols.se_line); [''] alone is still the null string. *)
let close_quote s i =
  let n = String.length s and q = s.[i] in
  let rec go j =
    match String.index_from_opt s j q with
    | None -> n
    | Some j when j + 1 < n && s.[j + 1] = q -> go (j + 2)
    | Some j -> j
  in
  go (i + 1)

(* The contents of the delimited string at [i] (doubled quotes made
   single) and the index of its closing quote (or [n]).  By [close_quote]
   every quote in the body is one of a doubled pair. *)
let delimited s i =
  let j = close_quote s i and q = s.[i] in
  match String.index_from_opt s (i + 1) q with
  | Some k when k < j ->
      let b = Buffer.create (j - i) in
      let rec go k =
        if k < j then begin
          Buffer.add_char b s.[k];
          go (if s.[k] = q then k + 2 else k + 1)
        end
      in
      go (i + 1);
      (Buffer.contents b, j)
  | _ -> (String.sub s (i + 1) (j - i - 1), j)

(** Remove the delimiters of every delimited string ('...') in [s]; other text
    is kept as written. *)
let unquote_all s =
  let n = String.length s in
  let b = Buffer.create n in
  let rec go i =
    if i < n then
      if is_quote s.[i] then begin
        let body, j = delimited s i in
        Buffer.add_string b body;
        go (j + 1)
      end
      else begin
        Buffer.add_char b s.[i];
        go (i + 1)
      end
  in
  go 0;
  Buffer.contents b

(* ---- arithmetic --------------------------------------------------------- *)

type tok = Num of int | Op of string | Lp | Rp | Word

let tokenize s =
  let n = String.length s in
  let rec go i acc =
    if i >= n then List.rev acc
    else
      match s.[i] with
      | c when is_blank c -> go (i + 1) acc
      | '(' -> go (i + 1) (Lp :: acc)
      | ')' -> go (i + 1) (Rp :: acc)
      | '/' when i + 1 < n && s.[i + 1] = '/' -> go (i + 2) (Op "//" :: acc)
      | ('+' | '-' | '*' | '/') as c -> go (i + 1) (Op (String.make 1 c) :: acc)
      | c when is_quote c -> go (close_quote s i + 1) (Word :: acc)
      | _ ->
          let j = ref i in
          while
            !j < n && not (is_blank s.[!j] || String.contains "()+-*/'" s.[!j])
          do
            incr j
          done;
          let w = String.sub s i (!j - i) in
          go !j
            ((match parse_int w with Some v -> Num v | None -> Word) :: acc)
  in
  go 0 []

exception Bad of string

(* expr := term {(+|-) term}; term := unary {( * | / | // ) unary};
   unary := (-|+) unary | primary; primary := number | ( expr ).
   DCF-VERIFY: SCRIPT/VS may evaluate strictly left to right without
   operator precedence or parentheses; we use the usual precedence. *)
let eval_tokens toks =
  let toks = ref toks in
  let peek () = match !toks with t :: _ -> Some t | [] -> None in
  let advance () = match !toks with _ :: r -> toks := r | [] -> () in
  let rec expr () =
    let v = ref (term ()) in
    let rec more () =
      match peek () with
      | Some (Op "+") ->
          advance ();
          v := !v + term ();
          more ()
      | Some (Op "-") ->
          advance ();
          v := !v - term ();
          more ()
      | _ -> ()
    in
    more ();
    !v
  and term () =
    let v = ref (unary ()) in
    let rec more () =
      match peek () with
      | Some (Op "*") ->
          advance ();
          v := !v * unary ();
          more ()
      | Some (Op (("/" | "//") as o)) ->
          advance ();
          let d = unary () in
          if d = 0 then raise (Bad "division by zero");
          (* integer division truncates toward zero; // is the remainder
           (DCF-VERIFY: // remainder operator) *)
          v := if o = "/" then !v / d else !v mod d;
          more ()
      | _ -> ()
    in
    more ();
    !v
  and unary () =
    match peek () with
    | Some (Op "-") ->
        advance ();
        -unary ()
    | Some (Op "+") ->
        advance ();
        unary ()
    | _ -> primary ()
  and primary () =
    match peek () with
    | Some (Num v) ->
        advance ();
        v
    | Some Lp -> (
        advance ();
        let v = expr () in
        match peek () with
        | Some Rp ->
            advance ();
            v
        | _ -> raise (Bad "missing )"))
    | Some Rp -> raise (Bad "unexpected )")
    | Some (Op o) -> raise (Bad ("operand expected before " ^ o))
    | Some Word | None -> raise (Bad "operand expected")
  in
  let v = expr () in
  match peek () with
  | None -> v
  | Some Rp -> raise (Bad "unbalanced )")
  | Some _ -> raise (Bad "operator expected")

(* The tokens of a [.se] right-hand side: quoted strings (the closing
   quote is optional, p.230) and blank-delimited words, with their
   extents in [s]. *)
type setok = Q of string | W of string

let se_tokens s =
  let n = String.length s in
  let rec go i acc =
    let i = ref i in
    while !i < n && is_blank s.[!i] do
      incr i
    done;
    let i = !i in
    if i >= n then List.rev acc
    else if is_quote s.[i] then begin
      let body, j = delimited s i in
      go (j + 1) ((Q body, i, min n (j + 1)) :: acc)
    end
    else begin
      let j = ref i in
      while !j < n && not (is_blank s.[!j]) do
        incr j
      done;
      go !j ((W (String.sub s i (!j - i)), i, !j) :: acc)
    end
  in
  go 0 []

let is_expression toks =
  List.exists (function Op _ | Lp | Rp -> true | _ -> false) toks
  && not (List.mem Word toks)

(** Value of the right-hand side of [.se name = rhs] (SH35-0069 p.230-231,
    p.241):
    - empty: the null string;
    - ['string] (the closing quote is optional): the string;
    - [substr STR n [len]]: [len] characters (default: the rest) of STR from the
      n-th; [index STR SUB]: the position of SUB in STR, 0 if it is not there
      (STR, SUB quoted or a word);
    - an arithmetic expression (numbers with [+ - * / //] or parentheses, e.g.
      [&a + 1], [-&n]): its integer value, so leading zeros go (p.241);
    - anything else, including a single number ([.se 3z = 00] must keep both
      zeros, p.269): the text as written, with the delimiters of quoted strings
      removed. [sub] substitutes one unquoted word: with [.su off] the symbols
      of a [.se] line outside quotes are still substituted (p.230), word by
      word, so that [substr &corp 1 6] works when the value of [&corp] contains
      blanks (p.231). With [.su on] the line is already substituted and [sub] is
      the identity. DCF-VERIFY: how SCRIPT/VS combines several character
      operands (we keep the text as written) and whether operators need
      surrounding blanks (we accept [1-2] as an arithmetic expression). *)
let se_value ?(sub = Fun.id) rhs =
  let rhs = String.trim rhs in
  let toks = se_tokens rhs in
  let arg = function Q s -> s | W w -> sub w in
  let number what t =
    match parse_int (String.trim (arg t)) with
    | Some v -> Ok v
    | None -> Error (Printf.sprintf "%s: %s is not a number" what (arg t))
  in
  let ( let* ) = Result.bind in
  match toks with
  | [] -> Ok ""
  | [ (Q s, _, _) ] -> Ok s
  | (W op, _, _) :: args
    when String.lowercase_ascii op = "substr" && List.length args >= 2 -> (
      match List.map (fun (t, _, _) -> t) args with
      | ([ str; n ] | [ str; n; _ ]) as l ->
          let s = arg str in
          let* start = number "substr" n in
          let* len =
            match l with
            | [ _; _; len ] -> number "substr" len
            | _ -> Ok (String.length s - start + 1)
          in
          if start < 1 then Error "substr: the start must be at least 1"
          else
            let l = String.length s in
            let a = min l (start - 1) in
            Ok (String.sub s a (max 0 (min len (l - a))))
      | _ -> Error "substr: string, start and length expected")
  | (W op, _, _) :: args
    when String.lowercase_ascii op = "index" && List.length args >= 2 -> (
      match List.map (fun (t, _, _) -> t) args with
      | [ str; needle ] ->
          let h = arg str and nd = arg needle in
          let lh = String.length h and ln = String.length nd in
          let rec find i =
            if i + ln > lh then 0
            else if String.sub h i ln = nd then i + 1
            else find (i + 1)
          in
          Ok (string_of_int (if ln = 0 then 0 else find 0))
      | _ -> Error "index: string and search string expected")
  | _ ->
      (* substitute the words in place, keeping the spacing *)
      let b = Buffer.create (String.length rhs) in
      let last =
        List.fold_left
          (fun pos (t, i, j) ->
            Buffer.add_string b (String.sub rhs pos (i - pos));
            (match t with
            | W w -> Buffer.add_string b (sub w)
            | Q _ -> Buffer.add_string b (String.sub rhs i (j - i)));
            j)
          0 toks
      in
      Buffer.add_string b (String.sub rhs last (String.length rhs - last));
      let r = Buffer.contents b in
      let atoks = tokenize r in
      if is_expression atoks then
        match eval_tokens atoks with
        | v -> Ok (string_of_int v)
        | exception Bad m ->
            Error (Printf.sprintf "bad expression '%s': %s" r m)
      else Ok (unquote_all r)

(* ---- conditions ------------------------------------------------------- *)

type op = Eq | Ne | Lt | Gt | Le | Ge

let op_of_string s =
  match String.lowercase_ascii s with
  | "eq" | "=" -> Some Eq
  | "ne" | "\xc2\xac=" | "^=" | "/=" | "<>" | "\\=" -> Some Ne
  | "lt" | "<" | "\xc2\xac>=" -> Some Lt
  | "gt" | ">" | "\xc2\xac<=" -> Some Gt
  | "le" | "<=" | "\xc2\xac>" | "^>" -> Some Le
  | "ge" | ">=" | "\xc2\xac<" | "^<" -> Some Ge
  | _ -> None

type term = { text : string; quoted : bool; stop : int }

(* One blank-delimited or quoted token starting at or after [i]. *)
let read_term s i =
  let n = String.length s in
  let i = ref i in
  while !i < n && is_blank s.[!i] do
    incr i
  done;
  if !i >= n then None
  else if is_quote s.[!i] then begin
    let text, j = delimited s !i in
    Some { text; quoted = true; stop = min n (j + 1) }
  end
  else begin
    let j = ref !i in
    while !j < n && not (is_blank s.[!j]) do
      incr j
    done;
    Some { text = String.sub s !i (!j - !i); quoted = false; stop = !j }
  end

(* The shorter comparand is padded with blanks (SH35-0069 p.264). *)
let compare_strings a b =
  let la = String.length a and lb = String.length b in
  let n = max la lb in
  let pad s l = if l < n then s ^ String.make (n - l) ' ' else s in
  compare (pad a la) (pad b lb)

let compare_terms a b =
  if a.quoted || b.quoted then compare_strings a.text b.text
  else
    match (parse_int a.text, parse_int b.text) with
    | Some x, Some y -> compare x y
    | _ -> compare_strings a.text b.text

let test op c =
  match op with
  | Eq -> c = 0
  | Ne -> c <> 0
  | Lt -> c < 0
  | Gt -> c > 0
  | Le -> c <= 0
  | Ge -> c >= 0

let rest_from s i =
  let n = String.length s in
  let i = ref i in
  while !i < n && is_blank s.[!i] do
    incr i
  done;
  String.sub s !i (n - !i)

(** Parse and evaluate [term1 op term2 [remainder]]. Returns the truth value and
    the remainder (leading blanks removed). Numeric comparison when both
    operands are unquoted numbers, else character comparison, the shorter
    operand padded with blanks (SH35-0069 p.264). The first token is always the
    first comparand: [.if = ON .go next] (from a null [&a]) is an error, "ON is
    not a valid comparison" (p.266). [sub] substitutes an unquoted comparand:
    with [.su off] each comparand is substituted on its own (p.267); with
    [.su on] the line is already substituted and [sub] is the identity.
    DCF-VERIFY: a quoted number compares as characters. *)
let condition ?(sub = Fun.id) s =
  let empty i = { text = ""; quoted = true; stop = i } in
  let subst t = if t.quoted then t else { t with text = sub t.text } in
  match read_term s 0 with
  | None -> Error "condition expected"
  | Some t0 -> (
      match read_term s t0.stop with
      | None -> Error "comparison operator expected"
      | Some opt -> (
          match op_of_string opt.text with
          | None ->
              Error (Printf.sprintf "invalid comparison operator %s" opt.text)
          | Some op ->
              let rhs =
                match read_term s opt.stop with
                | Some t -> t
                | None -> empty opt.stop
              in
              Ok
                ( test op (compare_terms (subst t0) (subst rhs)),
                  rest_from s rhs.stop )))
