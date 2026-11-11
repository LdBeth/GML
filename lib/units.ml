(* Space units (SH35-0069 p.44-46, Figure 3; LR p.58, Table 6).

   A dimension operand is parsed into a value in hundredths of a unit
   and a normalised unit name.  Nothing is converted to device units:
   that is the backends' job.

   | Written            | Unit name | Note                                  |
   |--------------------|-----------|---------------------------------------|
   | [a] (horizontal)   | ch        | figure space of the initial font      |
   | [a] (vertical)     | line      | line spacing of the current font      |
   | [a]cm              | cm        |                                       |
   | [a]mm              | mm        |                                       |
   | [a]i               | i         | inches                                |
   | [a]mh, [a]m        | mh        | em-space, horizontal (see below)      |
   | [a]mv              | mv        | em-height, vertical                   |
   | [n]dh, [n]dv       | dh, dv    | device units, whole numbers           |
   | [n]p[p], p[p]      | pt        | picas and points, as points (12/pica) |
   | [n]c[p], c[p]      | dd        | ciceros and Didot points, as points   |

   [a] has up to two decimals, written with a period or a comma (p.45);
   points ([p]) may have one decimal.  A leading [+] or [-] makes the
   value relative; a lone sign followed by the number in the next token
   ([.in + 1i]) is joined by the caller.
   [m] is [mh] on either axis: "Em space (Horizontal) aMH or aM" (LR
   p.58, Table 6).  The table is [units], below. *)

type axis = Horizontal | Vertical

type v = { h : int; unit : string }
(** A dimension: [hundredths] of [unit]. *)

type operand = {
  sign : char option;  (** ['+'] or ['-'] if relative *)
  value : v;  (** the magnitude (non-negative) *)
}

(* "12", "1,5", ".75", "2.25" -> hundredths; at most [dec] decimals. *)
let number ?(dec = 2) s =
  let s = String.map (fun c -> if c = ',' then '.' else c) s in
  let ip, fp =
    match String.index_opt s '.' with
    | None -> (s, "")
    | Some i ->
        (String.sub s 0 i, String.sub s (i + 1) (String.length s - i - 1))
  in
  let digits t = String.for_all (fun c -> c >= '0' && c <= '9') t in
  if
    (ip = "" && fp = "")
    || (not (digits ip && digits fp))
    || String.length fp > dec
  then None
  else
    let i = if ip = "" then 0 else int_of_string ip in
    let f =
      if fp = "" then 0
      else int_of_string fp * if String.length fp = 1 then 10 else 1
    in
    Some ((i * 100) + f)

let integer s =
  if s <> "" && String.for_all (fun c -> c >= '0' && c <= '9') s then
    Some (int_of_string s * 100)
  else None

let ends s suf =
  let n = String.length s and k = String.length suf in
  n > k && String.sub s (n - k) k = suf

let chop s k = String.sub s 0 (String.length s - k)

(* The units of the table above.  [size]: an absolute unit is a
   fraction of an inch; a device unit and a relative one have no size
   without a device (the backends know it), and the engine takes the
   size given (EXT) where it must measure: the system symbols in figure
   spaces ([figure_spaces]) and &DH' / &DV' ([device_units]). *)
type size =
  | Absolute of (int * int)  (** num/den inch *)
  | Device of (int * int)  (** a device unit; EXT: num/den inch *)
  | Relative of string * (int * int)
      (** relative to the first; EXT: num/den inch *)

type def = {
  name : string;  (** the normalised name *)
  axis : axis option;  (** None: either axis *)
  default : axis option;  (** the unit of a bare number on this axis *)
  suffixes : string list;  (** written [a]SUFFIX *)
  compound : char option;  (** written [n]C[p]: whole units of 12 points *)
  whole : bool;  (** whole numbers only *)
  size : size;
}

let def ?axis ?default ?(suffixes = []) ?compound ?(whole = false) name size =
  { name; axis; default; suffixes; compound; whole; size }

(* EXT: no device; a 240-pel page printer (3800 Model 3, 3820): a figure
   space and an em 1/10 inch (the 10-pitch font), a line and an em-height
   1/6 inch, a device unit 1/240 inch *)
let units =
  [
    def "ch" ~axis:Horizontal ~default:Horizontal
      (Relative ("figure space of the initial font", (1, 10)));
    def "line" ~axis:Vertical ~default:Vertical
      (Relative ("line spacing of the current font", (1, 6)));
    def "cm" ~suffixes:[ "cm" ] (Absolute (100, 254));
    def "mm" ~suffixes:[ "mm" ] (Absolute (10, 254));
    def "i" ~suffixes:[ "i" ] (Absolute (1, 1));
    def "mh" ~axis:Horizontal ~suffixes:[ "mh"; "m" ]
      (Relative ("em-space of the current font", (1, 10)));
    def "mv" ~axis:Vertical ~suffixes:[ "mv" ]
      (Relative ("em-height of the current font", (1, 6)));
    def "dh" ~axis:Horizontal ~suffixes:[ "dh" ] ~whole:true (Device (1, 240));
    def "dv" ~axis:Vertical ~suffixes:[ "dv" ] ~whole:true (Device (1, 240));
    def "pt" ~compound:'p' (Absolute (1, 72));
    (* a cicero is 0.1776 inch (LR glossary, "cicero"), 12 Didot points:
       1 Didot point = 0.0148 inch = 1.0656 points *)
    def "dd" ~compound:'c' (Absolute (37, 2500));
  ]

let inches u = match u.size with Absolute f | Device f | Relative (_, f) -> f
let default_unit axis = (List.find (fun u -> u.default = Some axis) units).name

(* the suffixes, longest first: "cm" and "mm" end in "m" *)
let suffixed =
  List.concat_map (fun u -> List.map (fun x -> (x, u)) u.suffixes) units
  |> List.stable_sort (fun (a, _) (b, _) ->
      compare (String.length b) (String.length a))

(* "3p2", "p6", "3p", "p1.5" with [c] = 'p'; whole units and points. *)
let compound c s =
  match String.index_opt s c with
  | None -> None
  | Some i -> (
      let a = String.sub s 0 i
      and b = String.sub s (i + 1) (String.length s - i - 1) in
      if a = "" && b = "" then None
      else
        let whole = if a = "" then Some 0 else integer a in
        let pts = if b = "" then Some 0 else number ~dec:1 b in
        match (whole, pts) with
        | Some w, Some p -> Some ((w * 12) + p)
        | _ -> None)

let magnitude axis s =
  let s = String.lowercase_ascii s in
  let mk u = Option.map (fun h -> { h; unit = u }) in
  match List.find_opt (fun (x, _) -> ends s x) suffixed with
  | Some (x, u) ->
      mk u.name
        (let n = chop s (String.length x) in
         if u.whole then integer n else number n)
  | None -> (
      match
        List.find_map
          (fun u ->
            match u.compound with
            | Some c when String.contains s c -> Some (u, c)
            | _ -> None)
          units
      with
      | Some (u, c) -> mk u.name (compound c s)
      | None -> mk (default_unit axis) (number s))

(** Parse one dimension operand. *)
let parse axis s =
  let s = String.trim s in
  if s = "" then Error "dimension expected"
  else
    let sign, body =
      match s.[0] with
      | ('+' | '-') as c -> (Some c, String.sub s 1 (String.length s - 1))
      | _ -> (None, s)
    in
    match magnitude axis body with
    | Some value -> Ok { sign; value }
    | None -> Error (Printf.sprintf "invalid space unit %s" s)

(** Hundredths as a decimal string: 500 -> "5", 250 -> "2.5", -75 -> "-0.75". *)
let show h =
  let neg = h < 0 in
  let a = abs h in
  let i = a / 100 and f = a mod 100 in
  let fs =
    if f = 0 then ""
    else if f mod 10 = 0 then Printf.sprintf ".%d" (f / 10)
    else Printf.sprintf ".%02d" f
  in
  (if neg then "-" else "") ^ string_of_int i ^ fs

(** The operand as written, normalised: "+2", "-0.5". *)
let show_operand o =
  (match o.sign with Some c -> String.make 1 c | None -> "") ^ show o.value.h

let signed o = match o.sign with Some '-' -> -o.value.h | _ -> o.value.h

type sum = (string * int) list
(** A sum of dimensions in several units (the result of relative changes in
    different units), kept per unit in order of appearance. *)

let zero : sum = []
let of_v (v : v) : sum = if v.h = 0 then [] else [ (v.unit, v.h) ]

(* Every sum (built by [zero], [of_v], [add], [apply]) has unique units
   and no zero amounts, so only the entry for [unit] can become zero. *)
let add (s : sum) unit h : sum =
  let rec go = function
    | [] -> if h = 0 then [] else [ (unit, h) ]
    | (u, x) :: rest when u = unit ->
        let y = x + h in
        if y = 0 then rest else (u, y) :: rest
    | p :: rest -> p :: go rest
  in
  go s

(** [apply cur o]: an absolute operand replaces, a relative one adds. *)
let apply (cur : sum) o : sum =
  match o.sign with
  | None -> of_v o.value
  | Some _ -> add cur o.value.unit (signed o)

(** Attributes for a sum: [name="5" unit="ch"]; zero is ["0"] in the default
    unit; a mixed sum is written ["3ch+1i"] with [unit="mixed"]. *)
let attrs ~default name (s : sum) =
  match s with
  | [] -> [ (name, "0"); ("unit", default) ]
  | [ (u, h) ] -> [ (name, show h); ("unit", u) ]
  | l ->
      (* a "+" between terms; a negative one carries its own "-" *)
      let txt =
        String.concat ""
          (List.mapi
             (fun i (u, h) -> (if i = 0 || h < 0 then "" else "+") ^ show h ^ u)
             l)
      in
      [ (name, txt); ("unit", "mixed") ]

(** A dimension written as one token: "5ch", "2.5i". *)
let token (v : v) = show v.h ^ v.unit

(** A whole number of lines, if [o] is an unsigned dimension in lines. *)
let lines o =
  if o.sign = None && o.value.unit = "line" && o.value.h mod 100 = 0 then
    Some (o.value.h / 100)
  else None

(** A sum in whole figure spaces, as the system symbols [&$IN], [&$LL] ... give
    it (SH35-0069 p.243: "represented in character spaces, regardless of the
    space units used in setting them"). EXT: there is no device, so a figure
    space is taken as 1/10 inch (the 10-pitch font of the 3800) and an em as one
    figure space ([units]); device units and vertical ones count 0. *)
let figure_spaces (s : sum) =
  let hundredths =
    List.fold_left
      (fun acc (u, h) ->
        match List.find_opt (fun d -> d.name = u) units with
        | Some ({ size = Absolute _ | Relative _; _ } as d)
          when d.axis <> Some Vertical ->
            let num, den = inches d in
            acc + (h * 10 * num / den)
        | _ -> acc)
      0 s
  in
  hundredths / 100

(** [&DH'] / [&DV'] (SH35-0069 p.237-238): a dimension in device units. EXT:
    there is no device; the units are those of a 240-pel page printer (3800
    Model 3, 3820): 240 per inch, a figure space or an em 1/10 inch (24), a line
    1/6 inch (40). *)
let device_units axis s =
  match parse axis s with
  | Error _ -> None
  | Ok o ->
      Option.map
        (fun d ->
          let num, den = inches d in
          let n = o.value.h * 240 * num / (den * 100) in
          if o.sign = Some '-' then -n else n)
        (List.find_opt (fun d -> d.name = o.value.unit) units)
