(* GML markup scanning (SH35-0069 Chapter 24), one line at a time.  Pure:
   continuation of markup on the following lines is driven by [Gmlproc].

   Grammar (D = tag delimiter, E = end-tag delimiter, M = the MCS):

     tag     ::= (D | E) name attrs [M]
     name    ::= 1-8 of letters digits @ # $, not starting with a digit
                 (case-insensitive; p.287)
     attrs   ::= { blanks attr }
     attr    ::= aname blanks? '=' blanks? value       (named; p.288-289)
               | word                                   (value attribute)
     value   ::= "'" { char | "''" } "'"  |  bare
     bare    ::= characters up to a blank or M (LR p.186 allows only a
                 word of name characters; others are taken, with a
                 warning: EXT)
     word    ::= tag name characters, ending at a blank, M, the end of
                 the line or the start of another tag

   E is tried before D: with the Starter Set's ":e", ":eol" is the end
   tag of "ol" and no start tag can begin with "e" (SH35-0050 p.6).  The markup ends at M (consumed), at another tag, at the
   end of the line (the caller may continue it on the next line) or at
   an invalid attribute (under the rule [stop]; it and what follows are
   text).  An attribute never spans lines (p.289). *)

type delims = {
  tag : char;
  etag : string;  (** one or two characters; "": no end tags *)
  mcs : char;
}

let delims_of (ch : Chars.t) =
  Option.map
    (fun tag -> { tag; etag = ch.Chars.gml_end; mcs = ch.Chars.mcs })
    ch.Chars.gml_delim

let max_name = 8
let is_blank c = c = ' ' || c = '\t'
let is_digit c = c >= '0' && c <= '9'

let starts_with s i p =
  let n = String.length p in
  i + n <= String.length s && String.sub s i n = p

let name_end s i =
  let n = String.length s in
  let j = ref i in
  while !j < n && Chars.is_tag_char s.[!j] do
    incr j
  done;
  !j

(* A tag name at [i]: its end, if valid. *)
let tag_name s i =
  if i < String.length s && Chars.is_tag_char s.[i] && not (is_digit s.[i]) then
    let j = name_end s i in
    if j - i <= max_name then Some j else None
    (* DCF-VERIFY (not in LR Rel 4): a longer name is not a tag (it is
       text); LR p.62 gives the limit *)
  else None

type found = {
  at : int;  (** index of the delimiter *)
  is_end : bool;
  name : string;  (** lowercase *)
  after : int;  (** index after the name *)
}

(** A tag (start or end) beginning exactly at [i]. *)
let tag_at d s i =
  let try_delim is_end p =
    if starts_with s i p then
      let k = i + String.length p in
      Option.map
        (fun j ->
          {
            at = i;
            is_end;
            name = String.lowercase_ascii (String.sub s k (j - k));
            after = j;
          })
        (tag_name s k)
    else None
  in
  (* a null end-tag delimiter ([.dc gml c] alone): end tags are not
     recognized (LR p.113) *)
  match if d.etag = "" then None else try_delim true d.etag with
  | Some _ as r -> r
  | None -> try_delim false (String.make 1 d.tag)

(** The first tag at or after [i]. *)
let find_tag d s i =
  let n = String.length s in
  let rec go k =
    if k >= n then None
    else if s.[k] = d.tag || (d.etag <> "" && s.[k] = d.etag.[0]) then
      match tag_at d s k with Some _ as r -> r | None -> go (k + 1)
    else go (k + 1)
  in
  go i

(* ---- attributes --------------------------------------------------------- *)

type attr =
  | Named of string * string  (** name (uppercase), value *)
  | Vat of string  (** value attribute, as written *)

type stop =
  | Mcs of int  (** ended by the MCS; index after it *)
  | Eol  (** end of the line, no MCS *)
  | Next_tag of int  (** another tag starts here *)
  | Invalid of int  (** invalid attribute here (rule [stop]) *)

type result = {
  attrs : attr list;
  stop : stop;
  invalid : string list;  (** invalid attributes met (for [msg]) *)
  lax : string list;
      (** unquoted values that are not a word of name characters, as written (LR
          p.186; taken anyway) *)
}

let skip_blanks s i =
  let n = String.length s in
  let i = ref i in
  while !i < n && is_blank s.[!i] do
    incr i
  done;
  !i

(* A quoted value at [i], delimited by the quote s.[i] (a doubled quote
   stands for one): contents and index after it, or None if
   unterminated. *)
let quoted s i =
  let n = String.length s in
  let q = s.[i] in
  let b = Buffer.create 16 in
  let rec go k =
    if k >= n then None
    else if s.[k] = q then
      if k + 1 < n && s.[k + 1] = q then (
        Buffer.add_char b q;
        go (k + 2))
      else Some (Buffer.contents b, k + 1)
    else (
      Buffer.add_char b s.[k];
      go (k + 1))
  in
  go (i + 1)

(* An unquoted value ends at a blank or the MCS.  DCF-VERIFY (not in LR
   Rel 4): whether the tag delimiter also ends it. *)
let bare ~mcs s i =
  let n = String.length s in
  let j = ref i in
  while !j < n && (not (is_blank s.[!j])) && s.[!j] <> mcs do
    incr j
  done;
  !j

type token =
  | T_named of string * string * int * bool  (** [true]: a lax bare value *)
  | T_vat of string * int
  | T_bad of int  (** end of the invalid token *)

let token d s i =
  let n = String.length s in
  let j = name_end s i in
  let bad () = T_bad (max (bare ~mcs:d.mcs s i) (i + 1)) in
  if j = i then bad ()
  else begin
    let k = skip_blanks s j in
    if k < n && s.[k] = '=' && not (is_digit s.[i]) then begin
      let name = String.uppercase_ascii (String.sub s i (j - i)) in
      let v = skip_blanks s (k + 1) in
      if v < n && s.[v] = '\'' then
        match quoted s v with
        | Some (value, e) -> T_named (name, value, e, false)
        | None -> T_bad n
      else
        let e = bare ~mcs:d.mcs s v in
        if e = v then bad ()
        else
          let value = String.sub s v (e - v) in
          T_named (name, value, e, not (String.for_all Chars.is_tag_char value))
    end
    else if j >= n || is_blank s.[j] || s.[j] = d.mcs || tag_at d s j <> None
    then T_vat (String.sub s i (j - i), j)
    else bad ()
  end

(** Scan the attributes of a tag from [i] under the rules [att], [vat], [stop].
*)
let attributes d ~att ~vat ~stop s i =
  let n = String.length s in
  let lax = ref [] in
  let rec go i acc bad =
    let i = skip_blanks s i in
    let fin st =
      {
        attrs = List.rev acc;
        stop = st;
        invalid = List.rev bad;
        lax = List.rev !lax;
      }
    in
    if i >= n then fin Eol
    else if s.[i] = d.mcs then fin (Mcs (i + 1))
    else if tag_at d s i <> None then fin (Next_tag i)
    else
      let invalid e =
        let tok = String.sub s i (e - i) in
        if stop then { (fin (Invalid i)) with invalid = List.rev (tok :: bad) }
        else go e acc (tok :: bad)
      in
      match token d s i with
      | T_named (nm, v, e, l) ->
          if att then begin
            if l then lax := String.sub s i (e - i) :: !lax;
            go e (Named (nm, v) :: acc) bad
          end
          else invalid e
      | T_vat (w, e) -> if vat then go e (Vat w :: acc) bad else invalid e
      | T_bad e -> invalid e
  in
  go i [] []

(* ---- name=value operands (for .xs / .xa) -------------------------------- *)

(** [name=value] pairs separated by blanks; values may be quoted with
    apostrophes or double quotes; an unquoted value ends at a blank. Names are
    lowercased. *)
let pairs s =
  let n = String.length s in
  let rec go i acc =
    let i = skip_blanks s i in
    if i >= n then Ok (List.rev acc)
    else begin
      let j = ref i in
      while !j < n && s.[!j] <> '=' && not (is_blank s.[!j]) do
        incr j
      done;
      if !j >= n || s.[!j] <> '=' || !j = i then
        Error
          (Printf.sprintf "name=value expected at '%s'"
             (String.sub s i (n - i)))
      else
        let name = String.lowercase_ascii (String.sub s i (!j - i)) in
        let v = !j + 1 in
        if v < n && (s.[v] = '\'' || s.[v] = '"') then
          match quoted s v with
          | None -> Error (Printf.sprintf "unterminated string in %s=" name)
          | Some (value, e) -> go e ((name, value) :: acc)
        else
          let e = ref v in
          while !e < n && not (is_blank s.[!e]) do
            incr e
          done;
          go !e ((name, String.sub s v (!e - v)) :: acc)
    end
  in
  go 0 []

(** Attribute pairs with repeated names removed: the last value of a name wins,
    and the pairs stay in the order of the last occurrences. (The same list as
    [fold_left (fun acc (k, v) -> remove_assoc k acc @ [(k, v)])], in one pass:
    a pair is kept exactly when its name does not occur later.) *)
let last_wins l =
  List.fold_right
    (fun (k, v) acc -> if List.mem_assoc k acc then acc else (k, v) :: acc)
    l []

(** Is [s] usable as an XML element or attribute name (a conservative subset:
    ASCII letter or '_' first, then letters, digits, '_', '-', '.'). *)
let xml_name s =
  s <> ""
  && (match s.[0] with 'a' .. 'z' | 'A' .. 'Z' | '_' -> true | _ -> false)
  && String.for_all
       (function
         | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '.' -> true
         | _ -> false)
       s
