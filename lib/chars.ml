(* Definable special characters (.dc), with DCF defaults.

   [None] means the function is turned off (e.g. [.dc cw off]). *)

type t = {
  mutable cw_ind : char;  (** control word indicator, '.' *)
  mutable cw_sep : char option;  (** control word separator, ';' *)
  mutable gml_delim : char option;  (** GML tag delimiter, ':' *)
  mutable gml_end : string;
      (** GML end-tag delimiter, "::"; one or two characters, or null: end tags
          are not recognized ([.dc gml c], LR p.113) *)
  mutable mcs : char;
      (** markup/content separator, '.'; a blank when it is off (the blank is
          always one, LR p.114) *)
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

(** May [c] be the MCS: not a tag name character and not the ampersand
    (SH35-0069 p.289). *)
let valid_gml_char c = (not (is_tag_char c)) && c <> '&'

(** May [c] be the GML tag or end-tag delimiter: not a blank, a period, an
    ampersand or a tag name character (LR p.113). *)
let valid_gml_delim c = valid_gml_char c && c <> '.' && c <> ' '

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

(** [s] without the marks of its text variables: their strings stay (the value
    of an element's attribute, which takes no hint). *)
let dv_plain s =
  if not (String.contains s '\xf3') then s
  else begin
    let b = Buffer.create (String.length s) in
    let rec go i =
      if i < String.length s then
        match dv_char s i with
        | Some (_, l) -> go (i + l)
        | None ->
            Buffer.add_char b s.[i];
            go (i + 1)
    in
    go 0;
    Buffer.contents b
  end

(* ---- the marks of a deferred symbol reference (running headings) ------- *)

(* Rel 4: a symbol in a running heading or footing is replaced when the
   heading is placed on a page (LR p.312 r7, p.315 r7, p.316).  While a
   definition is open, substitution ([Subst]) puts a reference to a global
   user symbol out as its current value between two characters of the
   private use plane 16: U+100000 + the reference's number ([Doc.symref])
   before, U+100000 after.  In UTF-8 they are F4 80..8F xx xx, the end
   mark F4 80 80 80.  A global symbol's value never holds them
   ([Symbols.set] strips them), so the spans do not nest; the value may
   hold a text variable (plane 15).  Like a text variable's string, the
   span is not read by the separator rule ([Line.index_sep]). *)
let sr_base = 0x100000

let sr_mark n =
  let b = Buffer.create 4 in
  Buffer.add_utf_8_uchar b (Uchar.of_int (sr_base + n));
  Buffer.contents b

let sr_end = sr_mark 0

(** The plane-16 mark at [i] of [s]: its number (0 for the end mark) and its
    length. *)
let sr_char s i =
  if Char.code s.[i] <> 0xF4 then None
  else
    let d = String.get_utf_8_uchar s i in
    let u = Uchar.to_int (Uchar.utf_decode_uchar d) in
    if Uchar.utf_decode_is_valid d && u >= sr_base then
      Some (u - sr_base, Uchar.utf_decode_length d)
    else None

(** The index of the end mark of the deferred reference whose value starts at
    [i] of [s], or the length of [s] if it is unended. *)
let rec sr_find_end s i =
  if i >= String.length s then String.length s
  else
    match sr_char s i with
    | Some (0, _) -> i
    | Some (_, l) -> sr_find_end s (i + l)
    | None -> sr_find_end s (i + 1)

(** Does [s] hold a deferred reference? *)
let has_sr s = String.contains s '\xf4'
