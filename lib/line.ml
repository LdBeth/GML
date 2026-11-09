(* Classification of one input line, and the control word separator
   rule.

   Control word names are two characters; the blank after them is
   optional, so [.cecenter this line] is [.ce center this line]
   (SH35-0069 p.40).  A macro name is up to ten characters from
   A-Z 0-9 [@ # $] (p.42, p.275): when macro substitution is on, the
   longest such run after the indicator, ended by a blank or the end of
   the line, is tried as a macro first ([long]); otherwise the first two
   characters are the control word and the rest are its operands
   (p.40, p.271). *)

type control = {
  name : string;
      (** lowercase control word name: the first two name characters (one if
          only one is there) *)
  quoted : bool;  (** [.'xx] form: no macro search, no separator scan *)
  args : string;  (** everything after [name], unmodified *)
  long : string option;
      (** lowercase macro name candidate: the whole run of name characters when
          it is at most ten long and ended by a blank or the end *)
  long_args : string;  (** everything after [long] *)
}

type t =
  | Comment of string  (** [.*] text *)
  | Label of string * string  (** [...name] and the rest of the line *)
  | Control of control
  | Text of string

(** Characters of macro (and control word) names (p.42). *)
let is_name_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '@' | '#' | '$' -> true
  | _ -> false

let is_blank c = c = ' ' || c = '\t'
let max_macro_name = 10

let index_from_opt s i c =
  if i >= String.length s then None else String.index_from_opt s i c

let classify (ch : Chars.t) s =
  let n = String.length s in
  let ci = ch.cw_ind in
  if n = 0 || s.[0] <> ci then Text s
  else if n >= 2 && s.[1] = '*' then Comment (String.sub s 2 (n - 2))
  else if n >= 4 && s.[1] = '.' && s.[2] = '.' && s.[3] <> ' ' then begin
    (* label: indicator followed by ".." and the label name *)
    let e = Option.value (index_from_opt s 3 ' ') ~default:n in
    Label (String.sub s 3 (e - 3), String.sub s e (n - e))
  end
  else begin
    let quoted = n >= 2 && s.[1] = '\'' in
    let start = if quoted then 2 else 1 in
    let j = ref start in
    while !j < n && is_name_char s.[!j] do
      incr j
    done;
    if !j = start then Text s
    else begin
      let k = min !j (start + 2) in
      let long =
        if !j - start <= max_macro_name && (!j = n || is_blank s.[!j]) then
          Some (String.lowercase_ascii (String.sub s start (!j - start)))
        else None
      in
      Control
        {
          name = String.lowercase_ascii (String.sub s start (k - start));
          quoted;
          args = String.sub s k (n - k);
          long;
          long_args = String.sub s !j (n - !j);
        }
    end
  end

(** Label name of a line, if it is a label line (for [Input.label_index]). *)
let label_of ch s =
  match classify ch s with Label (n, _) -> Some n | _ -> None

(** [s] without the single blank that separates operands from a name. *)
let drop_blank a =
  if a <> "" && a.[0] = ' ' then String.sub a 1 (String.length a - 1) else a

(** The operands: [args] without the blank after the control word name. *)
let operands c = drop_blank c.args

(* The DCF SCRIPT/VS control word names (SCRIPT/VS Language Reference
   summary), for the text-line separator rule: a separator in a text line
   splits it only when a control word follows (p.41), whether or not we
   implement that word. *)
let dcf_names =
  [
    "aa";
    "an";
    "ap";
    "bc";
    "bf";
    "bl";
    "br";
    "bt";
    "bx";
    "cb";
    "cc";
    "cd";
    "ce";
    "cg";
    "cl";
    "cm";
    "co";
    "cp";
    "cs";
    "ct";
    "dc";
    "dd";
    "df";
    "dh";
    "dl";
    "dm";
    "do";
    "ds";
    "du";
    "dv";
    "ec";
    "ef";
    "el";
    "em";
    "eq";
    "fi";
    "fl";
    "fm";
    "fn";
    "fo";
    "fs";
    "ft";
    "go";
    "gs";
    "h0";
    "h1";
    "h2";
    "h3";
    "h4";
    "h5";
    "h6";
    "hm";
    "hn";
    "hs";
    "hw";
    "hy";
    "ie";
    "if";
    "il";
    "im";
    "in";
    "ir";
    "is";
    "it";
    "ix";
    "kp";
    "lb";
    "li";
    "ll";
    "ln";
    "ls";
    "lt";
    "ly";
    "mc";
    "me";
    "mg";
    "ms";
    "nl";
    "oc";
    "of";
    "or";
    "pa";
    "pf";
    "pi";
    "pl";
    "pm";
    "pn";
    "pp";
    "pt";
    "pw";
    "px";
    "qq";
    "qu";
    "rc";
    "rd";
    "re";
    "rf";
    "rh";
    "ri";
    "rn";
    "rt";
    "rv";
    "sa";
    "sc";
    "se";
    "sk";
    "sl";
    "sp";
    "ss";
    "su";
    "sv";
    "sx";
    "sy";
    "tb";
    "tc";
    "te";
    "th";
    "ti";
    "tm";
    "tp";
    "tr";
    "ts";
    "tu";
    "ty";
    "uc";
    "ud";
    "un";
    "up";
    "ur";
    "us";
    "vr";
    "wf";
    "wz";
  ]

(* The first separator [sep] at or after [i] of [s] that is not in a
   text variable.  A text variable's symbol value is its string between
   two plane-15 marks ([Chars.dv_mark], [Doc.define_variable]); the
   string is "known text" (SH35-0069 p.258-261): no code point is given
   up and it may be used anywhere, so a separator in it (DSMPROF3's
   [.'dv semi text /;]) is text, never a separator.  The span runs from
   a start mark through the next end mark, or to the end of the line if
   unended (as [Doc.split_dvars]); a stray end mark is passed over. *)
let rec index_sep s i sep =
  if i >= String.length s then None
  else if s.[i] = sep then Some i
  else
    match Chars.dv_char s i with
    | Some (0, l) -> index_sep s (i + l) sep
    | Some (_, l) -> index_sep s (Chars.dv_skip s (i + l)) sep
    | None -> index_sep s (i + 1) sep

(** [s] split at every [sep] that is not in a text variable ([index_sep]): the
    fields of [.mg] and [.sx], the pieces of a [.sx] field around the page
    number symbol. *)
let split_on sep s =
  let rec go i =
    match index_sep s i sep with
    | Some k -> String.sub s i (k - i) :: go (k + 1)
    | None -> [ String.sub s i (String.length s - i) ]
  in
  go 0

(** The control word separator rule (SH35-0069 p.40-41), applied to a line after
    symbol substitution. Returns the line up to the split and the rest, which
    becomes the next input line.

    - A control word line is split at the first separator, unless it has the
      [.'] modifier; an empty rest is dropped.
    - A text line is split only at a separator followed by the control word
      indicator (optionally the modifier) and a two-character control word name
      ([is_cw] decides); the part before it is text with continuation. Any other
      separator is text. *)
let split (ch : Chars.t) ~is_cw s =
  match ch.cw_sep with
  | None -> (s, None)
  | Some sep -> (
      let n = String.length s in
      let cut i = (String.sub s 0 i, Some (String.sub s (i + 1) (n - i - 1))) in
      match classify ch s with
      | Control c when c.quoted -> (s, None)
      | Comment _ | Label _ -> (s, None) (* the whole line is ignored, p.44 *)
      | Control _ -> (
          match index_sep s 0 sep with
          | None -> (s, None)
          | Some i ->
              let h, r = cut i in
              (h, if r = Some "" then None else r))
      | Text _ ->
          let names_cw i =
            let j = if i < n && s.[i] = '\'' then i + 1 else i in
            j + 2 <= n
            && is_name_char s.[j]
            && is_name_char s.[j + 1]
            && is_cw (String.lowercase_ascii (String.sub s j 2))
          in
          let rec go i =
            match index_sep s i sep with
            | None -> (s, None)
            | Some k ->
                if k + 1 < n && s.[k + 1] = ch.cw_ind && names_cw (k + 2) then
                  cut k
                else go (k + 1)
          in
          go 0)
