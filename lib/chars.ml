(* Definable special characters (.dc), with DCF defaults.

   [None] means the function is turned off (e.g. [.dc cw off]). *)

type t = {
  mutable cw_ind : char;  (** control word indicator, '.' *)
  mutable cw_sep : char option;  (** control word separator, ';' *)
  mutable gml_delim : char option;  (** GML tag delimiter, ':' *)
  mutable gml_end : string;
      (** GML end-tag delimiter, "::" (SH35-0069 p.288); one or two characters,
          if two the first is [gml_delim] (p.289) *)
  mutable mcs : char;  (** markup/content separator, '.' *)
  mutable symbol : char;  (** symbol substitution char, '&' *)
  mutable cont : char option;
      (** continuation character ([.dc cont c]); initially none (SH35-0069 p.47)
      *)
  mutable asep : string;
      (** array separator ([.dc asep]), up to four characters; initially a comma
          and a blank (p.254) *)
  mutable rb : string;
      (** the required blank ([.dc rb], [&$RB]), in UTF-8; initially EBCDIC 41,
          the no-break space (SX26-3723, .DC) *)
  mutable ps : char;
      (** the page number symbol ([.dc ps], [&$PS]), initially "&" *)
}

let create () =
  {
    cw_ind = '.';
    cw_sep = Some ';';
    gml_delim = Some ':';
    gml_end = "::";
    mcs = '.';
    symbol = '&';
    cont = None;
    asep = ", ";
    rb = "\xC2\xA0";
    ps = '&';
  }

(** Characters of GML tag and attribute names: letters, digits, [@ # $]
    (SH35-0069 p.287). *)
let is_tag_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '@' | '#' | '$' -> true
  | _ -> false

(** May [c] be a GML delimiter or the MCS: not a tag name character and not the
    ampersand (p.289). *)
let valid_gml_char c = (not (is_tag_char c)) && c <> '&'

(* ---- the marks of a text variable (.dv) -------------------------------- *)

(* The symbol of a text variable ([.dv name TEXT /string], SH35-0069
   p.258-261) has as its value the string between two characters of the
   private use plane 15: U+F0000 + the variable's number (from 1) before,
   U+F0000 after ([Doc.define_variable]).  In UTF-8 both are F3 B0..BF
   xx xx; the end mark is F3 B0 80 80.  They are here, below [Line] and
   [Doc], because the separator rule ([Line.split]) must not read the
   string either. *)
let dv_base = 0xF0000

let dv_mark n =
  let b = Buffer.create 4 in
  Buffer.add_utf_8_uchar b (Uchar.of_int (dv_base + n));
  Buffer.contents b

let dv_end = dv_mark 0

(** The plane-15 mark at [i] of [s]: its number (0 for the end mark) and its
    length. *)
let dv_char s i =
  if Char.code s.[i] <> 0xF3 then None
  else
    let d = String.get_utf_8_uchar s i in
    let u = Uchar.to_int (Uchar.utf_decode_uchar d) in
    if Uchar.utf_decode_is_valid d && u >= dv_base then
      Some (u - dv_base, Uchar.utf_decode_length d)
    else None

(** The index after the end mark of the text variable whose string starts at [i]
    of [s], or the length of [s] if it is unended. *)
let rec dv_skip s i =
  if i >= String.length s then String.length s
  else
    match dv_char s i with
    | Some (0, l) -> i + l
    | Some (_, l) -> dv_skip s (i + l)
    | None -> dv_skip s (i + 1)
