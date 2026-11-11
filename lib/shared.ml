(* What the layers share (gmlshare, bin/gmlshare.ml), made from the
   engine's own declarations so that the stylesheets and gml.tex read
   them instead of copying them: one XML file for the stylesheets
   ([document]: xslt/gml-shared.xml, namespace urn:x-gml:shared) and one
   TeX file for gml.tex ([tex]: share/tex/gml-shared.tex, the part of
   it gml.tex uses: units, aux names, hints; described at [tex]).  Both
   walk the same values ([entries], [Units.units], [Symbols.aux_roles],
   [Aux.header]).  The XML:

   - nodes: every node the engine writes in the canonical tree ([Node]:
     the rows of [Hints.table], and the nodes declared where they are put
     out), one per name and kind: kind root|element|scope|hint|raw; a
     hint has class event|state, its break= values (yes|no|varies, merged
     over the words that put it out) and, when it is state, the
     properties it sets (sets=) and whether only some hints of the name
     are state (conditional="yes"); words= the control words that put it
     out, from= what puts out a node no word does;
   - properties: the formatting state properties of xslt/scope.xsl, in
     its order, with their tier and initial value ([Hints.P]);
   - words: the control words a context knows ([Interp.create]) and the
     DCF names it does not implement (supported="no"), with the break,
     grammar and nodes (puts=) of a row of [Hints.table];
   - units: the space units of [Units.units];
   - aux: the symbol prefixes, names and first lines of the coupling
     files of the pass model ([Symbols], [Aux]), and test vectors of
     the name encoding ([Aux.tex_name], [Aux.enc]) for the other
     implementations of it (tex.xsl's t:name, gml.tex's \gml@enc). *)

let ns = "urn:x-gml:shared"
let el name attrs children = Tree.Element (name, attrs, children)
let opt name = function Some v -> [ (name, v) ] | None -> []
let flag name b = if b then [ (name, "yes") ] else []
let words l = if l = [] then [] else [ ("words", String.concat " " l) ]

let brk_value = function
  | Node.Yes -> Some "yes"
  | No -> Some "no"
  | Varies -> Some "varies"
  | Not_a_hint -> None

let kind_name (n : Node.t) =
  match n.kind with
  | Root -> "root"
  | Element -> "element"
  | Scope -> "scope"
  | Hint _ -> "hint"
  | Raw -> "raw"

(* ---- nodes ---------------------------------------------------------------------- *)

type entry = {
  node : Node.t;
  mutable brk : Node.brk option;  (** merged over the words *)
  mutable by : string list;  (** the words, reversed *)
  mutable from : string option;
}

let merge a b =
  match a with
  | None -> Some b
  | Some a when a = b -> Some a
  | Some _ -> Some Node.Varies

let entries () =
  let tbl = Hashtbl.create 64 in
  let entry (n : Node.t) =
    let key = (n.name, kind_name n) in
    match Hashtbl.find_opt tbl key with
    | Some e when e.node = n -> e
    | Some _ -> invalid_arg ("Shared: gml:" ^ n.name ^ " declared twice")
    | None ->
        let e = { node = n; brk = None; by = []; from = None } in
        Hashtbl.add tbl key e;
        e
  in
  List.iter
    (fun (r : Hints.row) ->
      List.iter
        (fun (n, b) ->
          let e = entry n in
          if not (List.mem r.name e.by) then e.by <- r.name :: e.by;
          e.brk <- merge e.brk (Option.value b ~default:r.brk))
        r.puts)
    Hints.table;
  List.iter
    (fun (d : Node.declared) ->
      let e = entry d.node in
      e.brk <- merge e.brk d.brk;
      e.from <- Some d.from)
    (List.rev !Node.declared);
  Hashtbl.fold (fun k e acc -> (k, e) :: acc) tbl []
  |> List.sort (fun (a, _) (b, _) -> compare a b)
  |> List.map snd

let node_element e =
  let n = e.node in
  let hint =
    match n.kind with
    | Hint cls ->
        let b =
          match Option.bind e.brk brk_value with
          | Some b -> b
          | None -> invalid_arg ("Shared: hint gml:" ^ n.name ^ " without break")
        in
        (match cls with
          | Event -> [ ("class", "event") ]
          | State { sets; conditional } ->
              List.iter
                (fun p ->
                  if not (List.memq p Hints.P.all) then
                    invalid_arg
                      ("Shared: gml:" ^ n.name ^ " sets an unknown property "
                     ^ p.Node.prop))
                sets;
              [ ("class", "state") ]
              @ flag "conditional" conditional
              @ [
                  ( "sets",
                    String.concat " " (List.map (fun p -> p.Node.prop) sets) );
                ])
        @ [ ("break", b) ]
    | _ -> []
  in
  el "node"
    ((("name", n.name) :: ("kind", kind_name n) :: hint)
    @ words (List.rev e.by)
    @ opt "from" e.from)
    []

(* ---- properties ----------------------------------------------------------------- *)

let property (p : Node.property) =
  el "property"
    [
      ("name", p.prop);
      ("tier", match p.tier with Block -> "block" | Inline -> "inline");
      ("initial", p.initial);
    ]
    []

(* ---- words ---------------------------------------------------------------------- *)

let word_elements () =
  let ctx = Interp.create () in
  let registered = Hashtbl.fold (fun k _ acc -> k :: acc) ctx.Ctx.words [] in
  let rows = List.map (fun (r : Hints.row) -> r.name) Hints.table in
  List.sort_uniq compare (registered @ rows @ Line.dcf_names)
  |> List.map (fun w ->
      let row =
        match List.find_opt (fun (r : Hints.row) -> r.name = w) Hints.table with
        | None -> []
        | Some r ->
            let puts =
              List.fold_left
                (fun acc ((n : Node.t), _) ->
                  if List.mem n.name acc then acc else acc @ [ n.name ])
                [] r.puts
            in
            opt "break" (brk_value r.brk)
            @ [ ("grammar", r.grammar) ]
            @ if puts = [] then [] else [ ("puts", String.concat " " puts) ]
      in
      el "word"
        ([
           ("name", w);
           ("supported", if List.mem w registered then "yes" else "no");
         ]
        @ row)
        [])

(* ---- units ---------------------------------------------------------------------- *)

let rec gcd a b = if b = 0 then a else gcd b (a mod b)

let fraction (n, d) =
  let g = gcd n d in
  if d / g = 1 then string_of_int (n / g)
  else Printf.sprintf "%d/%d" (n / g) (d / g)

let axis_name = function Units.Horizontal -> "h" | Vertical -> "v"

let unit_element (u : Units.def) =
  el "unit"
    ([
       ("name", u.name);
       ("axis", match u.axis with Some a -> axis_name a | None -> "both");
     ]
    @ opt "default" (Option.map axis_name u.default)
    @ (if u.suffixes = [] then []
       else [ ("suffix", String.concat " " u.suffixes) ])
    @ opt "compound" (Option.map (String.make 1) u.compound)
    @ flag "whole" u.whole
    @
    match u.size with
    | Absolute f -> [ ("inch", fraction f) ]
    | Device f -> [ ("device", "yes"); ("nominal-inch", fraction f) ]
    | Relative (r, f) -> [ ("relative", r); ("nominal-inch", fraction f) ])
    []

(* ---- aux ------------------------------------------------------------------------ *)

(* the names encoded: letters and digits, the characters ENC treats
   apart, others of ASCII, Latin-1, a CJK character, one outside the BMP *)
let vectors =
  [
    "gml.tc.1";
    "abcXYZ";
    "0123456789";
    "fig-1";
    "a+b";
    "two words";
    "id_1";
    "a@b";
    "a#b";
    "a&b";
    "50%";
    "caf\u{E9}";
    "\u{56F3}1";
    "x\u{1D538}";
  ]

let aux () =
  el "aux" []
    (List.map
       (fun (role, v) -> el "prefix" [ ("role", role); ("value", v) ] [])
       Symbols.aux_roles
    @ [
        el "name" [ ("role", "toc"); ("value", Symbols.toc_name) ] [];
        el "name" [ ("role", "page"); ("value", Symbols.page_name) ] [];
        el "header" [ ("file", "aux"); ("value", Aux.header) ] [];
        el "header" [ ("file", "symbols"); ("value", Symbols.file_header) ] [];
        el "encoding" []
          (List.map
             (fun s ->
               el "vector"
                 [ ("plain", s); ("tex", Aux.tex_name s); ("enc", Aux.enc s) ]
                 [])
             vectors
          @ List.map
              (fun id ->
                el "symbol"
                  [
                    ("role", "query");
                    ("plain", id);
                    ("value", Aux.query_name id);
                  ]
                  [])
              [ "q1.12.3" ]
          @ List.map
              (fun a ->
                el "symbol"
                  [
                    ("role", "anchor");
                    ("plain", a);
                    ("value", Aux.anchor_name a);
                  ]
                  [])
              [ "gml.tc.1"; "fig-1" ]);
      ])

(* ---- the document --------------------------------------------------------------- *)

let tree () =
  el "shared"
    [
      ("xmlns", ns);
      ("canonical", Be_xml.ns_uri);
      ("root", Doc.root_node.Node.name);
    ]
    [
      el "nodes" [] (List.map node_element (entries ()));
      el "properties" [] (List.map property Hints.P.all);
      el "words" [] (word_elements ());
      el "units" [] (List.map unit_element Units.units);
      aux ();
    ]

let generated = "generated by gmlshare from lib/; do not edit"
let document () = Be_xml.data_file ~comment:generated (tree ())

(* ---- the TeX file --------------------------------------------------------------- *)

(* share/tex/gml-shared.tex, read by gml.tex (\input gml-shared, @ a
   letter), which defines the macros it calls; one declaration a line:

   - units: \gml@unitkw{NAME}{KW} when the unit is exactly TeX's unit KW
     ([tex_units]: TeX scans "1.5cm" as exactly as it can);
     \gml@unitsp{NAME}{S}{F} otherwise: S + F/10000 sp (rounded), which
     gml.tex multiplies in two parts so that 240dh is 1in to the sp;
     \gml@unitrel{NAME} a relative unit (gml.tex gives its meaning);
     \gml@unitsfx{SUFFIX}{NAME}, \gml@unitcpd{C}{NAME} the written forms;
   - aux: \def\gml@auxheader{...}, \gml@auxprefix{ROLE}{PREFIX};
   - hints: \gml@enginehint{NAME} for every node of kind hint. *)

(* TeX's units as fractions of an inch (TeXbook p.57; pt is 1/72.27in,
   dd 1238/1157pt) *)
let tex_units =
  [
    ("in", (1, 1));
    ("cm", (50, 127));
    ("mm", (5, 127));
    ("bp", (1, 72));
    ("pc", (1, 6));
    ("pt", (100, 7227));
    ("dd", (1238 * 100, 1157 * 7227));
    ("cc", (12 * 1238 * 100, 1157 * 7227));
  ]

let tex_unit (n, d) =
  List.find_map
    (fun (kw, (n', d')) -> if n * d' = n' * d then Some kw else None)
    tex_units

(* n/d inch in sp (1in = 7227/100 * 65536 sp): whole sp and the rest in
   ten-thousandths, rounded *)
let tex_sp (n, d) =
  let num = n * 7227 * 65536 and den = 100 * d in
  let s = num / den in
  let f = ((2 * (num mod den) * 10000) + den) / (2 * den) in
  if f = 10000 then (s + 1, 0) else (s, f)

let hints () =
  List.filter_map
    (fun e -> match e.node.kind with Hint _ -> Some e.node.name | _ -> None)
    (entries ())

(* what goes in a TeX argument: no special character, a blank only
   inside ([blank]) *)
let tex_word ?(blank = false) what s =
  let n = String.length s in
  let ok i = function
    | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '@' | '.' | '*' | '-' -> true
    | ' ' -> blank && i > 0 && i < n - 1
    | _ -> false
  in
  let rec all i = i >= n || (ok i s.[i] && all (i + 1)) in
  if s = "" || not (all 0) then
    invalid_arg ("Shared: " ^ what ^ " not plain for TeX: " ^ s)
  else s

(* a comment: printable ASCII *)
let tex_comment s =
  if String.for_all (fun c -> c >= ' ' && c <= '~') s then s
  else invalid_arg ("Shared: comment not plain for TeX: " ^ s)

let tex () =
  let b = Buffer.create 4096 in
  let line fmt = Printf.kbprintf (fun b -> Buffer.add_char b '\n') b fmt in
  line "%% %s" generated;
  line "%% What gml.tex shares with the engine (lib/shared.ml; the same facts";
  line "%% as xslt/gml-shared.xml): the space units (lib/units.ml), the names";
  line "%% of the aux file (lib/symbols.ml, lib/aux.ml) and the engine's hints.";
  line "%% gml.tex reads it (@ a letter) and defines the macros it calls.";
  line "%%";
  line "%% space units: \\gml@unitkw{NAME}{TeX unit of the same size},";
  line
    "%% \\gml@unitsp{NAME}{sp}{ten-thousandths of an sp}, \\gml@unitrel{NAME}";
  line "%% (gml.tex's own); the written forms [a]SUFFIX and [n]C[p]";
  List.iter
    (fun (u : Units.def) ->
      let name = tex_word "unit" u.name in
      match u.size with
      | Relative (r, _) -> line "\\gml@unitrel{%s}%% %s" name (tex_comment r)
      | Absolute f | Device f -> (
          let what =
            (match u.size with Device _ -> "device unit, " | _ -> "")
            ^ fraction f ^ " inch"
          in
          match tex_unit f with
          | Some kw -> line "\\gml@unitkw{%s}{%s}%% %s" name kw what
          | None ->
              let s, f' = tex_sp f in
              line "\\gml@unitsp{%s}{%d}{%d}%% %s" name s f' what))
    Units.units;
  List.iter
    (fun (u : Units.def) ->
      List.iter
        (fun x -> line "\\gml@unitsfx{%s}{%s}" (tex_word "suffix" x) u.name)
        u.suffixes;
      Option.iter
        (fun c ->
          line "\\gml@unitcpd{%s}{%s}"
            (tex_word "compound" (String.make 1 c))
            u.name)
        u.compound)
    Units.units;
  line "%% the aux file: its first line; the symbol prefixes by role";
  line "\\def\\gml@auxheader{%s}" (tex_word ~blank:true "header" Aux.header);
  List.iter
    (fun (role, v) ->
      line "\\gml@auxprefix{%s}{%s}" (tex_word "role" role)
        (tex_word "prefix" v))
    Symbols.aux_roles;
  line "%% the hints of the canonical tree (gml:NAME of kind hint)";
  List.iter
    (fun n -> line "\\gml@enginehint{%s}" (tex_word "hint" n))
    (hints ());
  Buffer.contents b
