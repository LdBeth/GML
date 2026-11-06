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
