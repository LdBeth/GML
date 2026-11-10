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

(* The blank that delimits .se/.if operands, macro and imbed parameters is
   X'40' only (LR p.118: "Ordinary blanks (hexadecimal X'40')"; .DC RB,
   p.112-113, keeps X'05' apart from it).  A tab is X'05', a character of its own
   that .TB/.TP resolve when the text is formatted (LR p.374, p.400 r1-r2):
   in a value it is text, so .se x = a&$TAB.b is one word, not "blanks". *)
let is_blank c = c = ' '

(** The index of the first non-blank character at or after [i] (or [i] when [i]
    is past the end). *)
let skip_blanks s i =
  let n = String.length s in
  let rec go i = if i < n && is_blank s.[i] then go (i + 1) else i in
  go i

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

(* [Num d]: an unsigned integer as written (digits only); [Op c]: one of
   + - * / (LR p.339); [Word]: anything else, a quoted string included. *)
type tok = Num of string | Op of char | Word

let is_op c = c = '+' || c = '-' || c = '*' || c = '/'

let is_digits w =
  w <> "" && String.for_all (function '0' .. '9' -> true | _ -> false) w

(* The operators need no blanks around them ([&.3+1], LR p.340 r10). *)
let tokenize s =
  let n = String.length s in
  let rec go i acc =
    if i >= n then List.rev acc
    else
      match s.[i] with
      | c when is_blank c -> go (i + 1) acc
      | c when is_op c -> go (i + 1) (Op c :: acc)
      | c when is_quote c -> go (close_quote s i + 1) (Word :: acc)
      | _ ->
          let j = ref i in
          while
            !j < n && not (is_blank s.[!j] || is_op s.[!j] || is_quote s.[!j])
          do
            incr j
          done;
          let w = String.sub s i (!j - i) in
          go !j ((if is_digits w then Num w else Word) :: acc)
  in
  go 0 []

exception Bad of string

(* [[op1] n [op2 n op2 n ...]] (LR p.339): op1 an optional sign before the
   first number only ([5+-3] is invalid, p.341 r12), op2 one of + - * /,
   evaluated strictly from left to right, no operator taking precedence
   ([1 + 2 * 4 + 6] is 18, p.340 r8); there are no parentheses.  Division
   truncates toward zero (DCF-VERIFY: the rounding of / is not in LR
   Rel 4).  [warn]: a number of 9 digits or more, which "can produce
   unpredictable results" (p.339). *)
let eval_tokens ?(warn = ignore) toks =
  let operand = function
    | Num d :: r -> (
        if String.length d >= 9 then
          warn
            (Printf.sprintf
               "%s: an integer in an expression must have fewer than 9 digits" d);
        match int_of_string_opt d with
        | Some v -> (v, r)
        | None -> raise (Bad (d ^ " is too large")))
    | Op ('+' | '-') :: _ ->
        raise (Bad "a sign is allowed only before the first number")
    | Op c :: _ -> raise (Bad (Printf.sprintf "operand expected before %c" c))
    | Word :: _ | [] -> raise (Bad "operand expected")
  in
  let first, rest =
    match toks with
    | Op (('+' | '-') as s) :: r ->
        let v, r = operand r in
        ((if s = '-' then -v else v), r)
    | r -> operand r
  in
  let apply c v d =
    match c with
    | '+' -> v + d
    | '-' -> v - d
    | '*' -> v * d
    | _ -> if d = 0 then raise (Bad "division by zero") else v / d
  in
  let rec go v = function
    | [] -> v
    | Op c :: r ->
        let d, r = operand r in
        go (apply c v d) r
    | _ -> raise (Bad "operator expected")
  in
  go first rest

(* The tokens of a [.se] right-hand side: quoted strings (the closing
   quote is optional, p.230) and blank-delimited words, with their
   extents in [s]. *)
type setok = Q of string | W of string
type term = { text : string; quoted : bool; stop : int }

(* One blank-delimited or quoted token starting at or after [i]. *)
let read_term s i =
  let n = String.length s in
  let i = skip_blanks s i in
  if i >= n then None
  else if is_quote s.[i] then
    let text, j = delimited s i in
    Some { text; quoted = true; stop = min n (j + 1) }
  else
    let j = ref i in
    while !j < n && not (is_blank s.[!j]) do
      incr j
    done;
    Some { text = String.sub s i (!j - i); quoted = false; stop = !j }

let se_tokens s =
  let rec go i acc =
    let i = skip_blanks s i in
    match read_term s i with
    | None -> List.rev acc
    | Some t ->
        go t.stop (((if t.quoted then Q t.text else W t.text), i, t.stop) :: acc)
  in
  go 0 []

let is_expression toks =
  List.exists (function Op _ -> true | _ -> false) toks
  && not (List.mem Word toks)

(* An unquoted string longer than 16 characters is an error (LR p.341
   r14).  A word that starts with & is a symbol that [sub] substitutes
   (.su off: "the error does not happen if substitution is off"). *)
let max_unquoted = 16

let long_word = function
  | W w when w <> "" && w.[0] <> '&' && String.length w > max_unquoted ->
      Some
        (Printf.sprintf
           "%s: an unquoted string has at most %d characters (put it in quotes)"
           w max_unquoted)
  | _ -> None

(* Diagnostics for a character value (not an arithmetic expression): a
   value with blanks or special characters "must be enclosed in single
   quotation marks" (LR p.338); we warn about blanks and keep the text as
   written.  A single word with special characters is taken silently:
   IBM's own Starter Set macros, which ran under DCF, have such values
   (DSM#XLST ".se @ = ;", DSMELIST ".se @sk@l = .75"). *)
let check_char_value ~warn toks =
  match toks with
  | [ ((W w as t), _, _) ] when w <> "" && w.[0] <> '&' -> (
      match long_word t with Some m -> Error m | None -> Ok ())
  | _ :: _ :: _ ->
      warn "a value with blanks must be in quotes";
      Ok ()
  | _ -> Ok ()

(** The value of [.se name 'qstring] (LR p.337): the string after the quote. A
    single quote in it need not be doubled ([.se title 'Mrs. O'Grady's Cat'],
    p.338-339), but a doubled quote is still one quote, read left to right:
    DSMPROF3's [@oquote] (a double quote and a doubled single quote, seven
    times, unclosed) must give alternating double and single quotes for
    DSMQUOTE's [substr &@oquote &@nest@q 1]. DCF-VERIFY: the manual shows only
    the undoubled case. A quote left alone at the end of the line is the closing
    quote and is removed (it is needed only to keep trailing blanks, which are
    removed otherwise). [s] starts with the quote. *)
let qstring s =
  let n = String.length s in
  let b = if n > 0 && is_quote s.[0] then String.sub s 1 (n - 1) else s in
  let n = String.length b in
  let rec stop i = if i > 0 && is_blank b.[i - 1] then stop (i - 1) else i in
  let e = stop n in
  let buf = Buffer.create e in
  let rec go i =
    if i < e then
      if is_quote b.[i] && i + 1 < e && is_quote b.[i + 1] then (
        Buffer.add_char buf b.[i];
        go (i + 2))
      else if is_quote b.[i] && i = e - 1 then ()
      else (
        Buffer.add_char buf b.[i];
        go (i + 1))
  in
  go 0;
  Buffer.contents buf

(** Value of the right-hand side of [.se name = rhs] (LR p.337-342):
    - empty: the null string (p.340 r5);
    - ['string] (the closing quote is optional): the string, a doubled quote in
      it one quote (p.338);
    - [substr STR [n [len]]]: [len] characters (default: the rest) of STR from
      the n-th (default: all of STR); [index STR [SUB]]: the position of SUB in
      STR, 0 if it is not there or SUB is omitted or null (STR, SUB quoted or a
      word; the rest of the line is ignored, p.339);
    - an arithmetic expression ([[op1] n [op2 n ...]], [eval_tokens], e.g.
      [&a + 1], [-&n], [&.3+1]): its integer value, so leading zeros go;
    - anything else, including a single number ([.se 3z = 00] must keep both
      zeros, SH35-0069 p.269): the text as written, with the delimiters of
      quoted strings removed. Blanks or special characters in it are diagnosed
      with [warn] (they need quotes, p.338); an unquoted word of more than 16
      characters, here or as the string of substr or index, is an error (p.341
      r14). [sub] substitutes one unquoted word: with [.su off] the symbols of a
      [.se] line outside quotes are still substituted (p.341 r13), word by word,
      so that [substr &corp 1 6] works when the value of [&corp] contains blanks
      (p.339). With [.su on] the line is already substituted and [sub] is the
      identity. EXT: several character operands are kept as written (DCF does
      not say what it does with them). *)
let se_value ?(sub = Fun.id) ?(warn = ignore) rhs =
  let rhs = String.trim rhs in
  let toks = se_tokens rhs in
  let arg = function Q s -> s | W w -> sub w in
  let number what t =
    match parse_int (String.trim (arg t)) with
    | Some v -> Ok v
    | None -> Error (Printf.sprintf "%s: %s is not a number" what (arg t))
  in
  let ( let* ) = Result.bind in
  let short t = match long_word t with Some m -> Error m | None -> Ok () in
  match toks with
  | [] -> Ok ""
  | [ (Q s, _, _) ] -> Ok s
  | (W op, _, _) :: args
    when String.lowercase_ascii op = "substr" && List.length args >= 1 -> (
      match List.map (fun (t, _, _) -> t) args with
      | ([ str ] | [ str; _ ] | [ str; _; _ ]) as l ->
          let* () = short str in
          let s = arg str in
          let* start =
            match l with _ :: n :: _ -> number "substr" n | _ -> Ok 1
          in
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
    when String.lowercase_ascii op = "index" && List.length args >= 1 -> (
      match List.map (fun (t, _, _) -> t) args with
      | str :: rest ->
          let* () = short str in
          let h = arg str in
          let nd = match rest with nd :: _ -> arg nd | [] -> "" in
          let lh = String.length h and ln = String.length nd in
          let rec find i =
            if i + ln > lh then 0
            else if String.sub h i ln = nd then i + 1
            else find (i + 1)
          in
          Ok (string_of_int (if ln = 0 then 0 else find 0))
      | [] -> Error "index: string and search string expected")
  | _ ->
      (* substitute the words in place, keeping the spacing *)
      let b = Buffer.create (String.length rhs) in
      let last =
        List.fold_left
          (fun pos (t, i, j) ->
            Buffer.add_string b (String.sub rhs pos (i - pos));
            Buffer.add_string b
              (match t with W w -> sub w | Q _ -> String.sub rhs i (j - i));
            j)
          0 toks
      in
      Buffer.add_string b (String.sub rhs last (String.length rhs - last));
      let r = Buffer.contents b in
      let atoks = tokenize r in
      if is_expression atoks then
        match eval_tokens ~warn atoks with
        | v -> Ok (string_of_int v)
        | exception Bad m ->
            Error (Printf.sprintf "bad expression '%s': %s" r m)
      else
        let* () = check_char_value ~warn toks in
        Ok (unquote_all r)

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

(* The shorter comparand is padded with blanks (LR p.204 r4). *)
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
  let i = skip_blanks s i in
  String.sub s i (String.length s - i)

(** Parse and evaluate [term1 op term2 [remainder]]. Returns the truth value and
    the remainder (leading blanks removed). Numeric comparison when both
    operands are unquoted numbers, else character comparison, the shorter
    operand padded with blanks (LR p.204 r4). The first token is always the
    first comparand: [.if = ON .go next] (from a null [&a]) is an error, "ON is
    not a valid comparison" (p.266). [sub] substitutes an unquoted comparand:
    with [.su off] each comparand is substituted on its own (p.267); with
    [.su on] the line is already substituted and [sub] is the identity.
    DCF-VERIFY: a quoted number compares as characters (not in LR Rel 4, which
    does not say when a comparison is numeric). *)
let condition ?(sub = Fun.id) s =
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
                Option.value (read_term s opt.stop)
                  ~default:{ text = ""; quoted = true; stop = opt.stop }
              in
              Ok
                ( test op (compare_terms (subst t0) (subst rhs)),
                  rest_from s rhs.stop )))
