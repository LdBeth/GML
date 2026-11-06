(* Space units (SH35-0069 p.44-46, Figure 3).

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
   DCF-VERIFY: [m] on a vertical operand is taken as [mv]. *)

type axis = Horizontal | Vertical

type v = { h : int; unit : string }
(** A dimension: [hundredths] of [unit]. *)

type operand = {
  sign : char option;  (** ['+'] or ['-'] if relative *)
  value : v;  (** the magnitude (non-negative) *)
}

let default_unit = function Horizontal -> "ch" | Vertical -> "line"

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
  let mk unit = Option.map (fun h -> { h; unit }) in
  if ends s "cm" then mk "cm" (number (chop s 2))
  else if ends s "mm" then mk "mm" (number (chop s 2))
  else if ends s "mh" then mk "mh" (number (chop s 2))
  else if ends s "mv" then mk "mv" (number (chop s 2))
  else if ends s "dh" then mk "dh" (integer (chop s 2))
  else if ends s "dv" then mk "dv" (integer (chop s 2))
  else if ends s "m" then
    mk
      (match axis with Horizontal -> "mh" | Vertical -> "mv")
      (number (chop s 1))
  else if ends s "i" then mk "i" (number (chop s 1))
  else if String.contains s 'p' then mk "pt" (compound 'p' s)
  else if String.contains s 'c' then mk "dd" (compound 'c' s)
  else mk (default_unit axis) (number s)

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
    space units used in setting them"). DCF-VERIFY: there is no device, so a
    figure space is taken as 1/10 inch (the 10-pitch font of the 3800) and an em
    as one figure space; device units count 0. *)
let figure_spaces (s : sum) =
  let per_inch_100 = function
    | "i" -> Some 100
    | "cm" -> Some 254
    | "mm" -> Some 2540
    | "pt" -> Some 7200
    | "dd" -> Some 6767 (* 1 Didot point = 1.0640 points *)
    | _ -> None
  in
  let hundredths =
    List.fold_left
      (fun acc (u, h) ->
        match u with
        | "ch" | "mh" -> acc + h
        | u -> (
            match per_inch_100 u with
            | Some d -> acc + (h * 1000 / d)
            | None -> acc))
      0 s
  in
  hundredths / 100

(** [&DH'] / [&DV'] (SH35-0069 p.237-238): a dimension in device units.
    DCF-VERIFY: there is no device; the units are those of a 240-pel page
    printer (3800 Model 3, 3820): 240 per inch, a figure space or an em 1/10
    inch (24), a line 1/6 inch (40). *)
let device_units axis s =
  match parse axis s with
  | Error _ -> None
  | Ok o ->
      (* device units per unit, as a fraction *)
      let per =
        match o.value.unit with
        | "ch" | "mh" -> Some (24, 1)
        | "line" | "mv" -> Some (40, 1)
        | "i" -> Some (240, 1)
        | "cm" -> Some (24000, 254)
        | "mm" -> Some (2400, 254)
        | "pt" -> Some (10, 3)
        | "dd" -> Some (10640, 3000)
        | "dh" | "dv" -> Some (1, 1)
        | _ -> None
      in
      Option.map
        (fun (num, den) ->
          let n = o.value.h * num / (den * 100) in
          if o.sign = Some '-' then -n else n)
        per
