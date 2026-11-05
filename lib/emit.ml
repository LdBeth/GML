(* Programmable output words (our own; namespaced with "x" so they do not
   clash with DCF control words):

   .xs name [attr=v ...]   start element (implicit closes per .xd models)
   .xe [name]              end element (the innermost one without a name)
   .xa attr=v ...          set attributes of the innermost open element
   .xr backend /text/      raw passthrough for a backend
   .xd name [closes=a,b] [closedby=x,y] [empty] [eol] [inline|block]
                           element model for the implicit-close engine
                           (eol: closed at the end of the input line it
                           was opened on)

   Names are case-insensitive (lowercased) and must be XML names.
   Values may be quoted with apostrophes or double quotes. *)

let words = Control.words

let split_name s =
  let s = String.trim s in
  match String.index_opt s ' ' with
  | None -> (s, "")
  | Some i -> (String.sub s 0 i, String.sub s (i + 1) (String.length s - i - 1))

let check_name ctx cw n k =
  let n = String.lowercase_ascii n in
  if n = "" then Ctx.error ctx ".%s: element name required" cw
  else if not (Tagscan.xml_name n) then Ctx.error ctx ".%s: invalid name %s" cw n
  else k n

let attrs ctx cw s k =
  match Tagscan.pairs s with
  | Error e -> Ctx.error ctx ".%s: %s" cw e
  | Ok l -> (
    (* the reserved xml: attributes (xml:space, xml:lang) are allowed *)
    let ok a =
      Tagscan.xml_name a
      || (String.length a > 4 && String.sub a 0 4 = "xml:"
          && Tagscan.xml_name (String.sub a 4 (String.length a - 4)))
    in
    match List.find_opt (fun (a, _) -> not (ok a)) l with
    | Some (a, _) -> Ctx.error ctx ".%s: invalid attribute name %s" cw a
    | None ->
      (* a repeated attribute: the last value wins *)
      k (List.fold_left (fun acc (a, v) -> List.remove_assoc a acc @ [ (a, v) ]) [] l))

let open_list ctx =
  match Doc.open_elements ctx.Ctx.doc with
  | [] -> "no element is open"
  | l -> "open: " ^ String.concat ", " l

let xs ctx ops =
  let n, rest = split_name ops in
  check_name ctx "xs" n (fun n ->
      attrs ctx "xs" rest (fun a -> Doc.start_element ctx.Ctx.doc n a))

let xe ctx ops =
  let close n =
    match Doc.end_element ctx.Ctx.doc n with
    | Doc.Closed _ -> ()
    | Doc.Not_open -> Ctx.error ctx ".xe %s: element %s is not open (%s)" n n (open_list ctx)
    | Doc.Mismatch y ->
      Ctx.error ctx ".xe %s: element %s, opened inside %s, must be closed first (%s)"
        n y n (open_list ctx)
  in
  match words ops with
  | [] -> (
    match Doc.current ctx.Ctx.doc with
    | Some n -> close n
    | None -> Ctx.error ctx ".xe: no element is open")
  | [ n ] -> check_name ctx "xe" n close
  | _ -> Ctx.error ctx ".xe: one element name expected"

let xa ctx ops =
  attrs ctx "xa" ops (fun l ->
      if l = [] then Ctx.error ctx ".xa: attr=value expected"
      else
        List.iter
          (fun (a, v) ->
             if not (Doc.set_attr ctx.Ctx.doc a v) then
               Ctx.error ctx ".xa %s: no element is open" a)
          l)

(* .xr backend /text/: the first non-blank character after the backend
   name delimits the text; the closing delimiter is optional. *)
let xr ctx ops =
  let b, rest = split_name ops in
  if b = "" then Ctx.error ctx ".xr: backend name required"
  else if not (Tagscan.xml_name b) then Ctx.error ctx ".xr: invalid backend name %s" b
  else
    let rest = String.trim rest in
    if rest = "" then Ctx.error ctx ".xr %s: delimited text expected" b
    else
      let d = rest.[0] in
      let body = String.sub rest 1 (String.length rest - 1) in
      let body =
        match String.index_opt body d with
        | Some i ->
          if i + 1 < String.length body then
            Ctx.warn ctx ".xr %s: text after the closing delimiter ignored" b;
          String.sub body 0 i
        | None -> body
      in
      Doc.raw ctx.Ctx.doc (String.lowercase_ascii b) body

let name_list ctx v k =
  let l = String.split_on_char ',' v |> List.filter (( <> ) "") |> List.map String.lowercase_ascii in
  match List.find_opt (fun n -> not (Tagscan.xml_name n)) l with
  | Some n -> Ctx.error ctx ".xd: invalid name %s" n
  | None -> k l

let xd ctx ops =
  match words ops with
  | [] -> Ctx.error ctx ".xd: element name required"
  | n :: opts ->
    check_name ctx "xd" n (fun n ->
        let rec go (m : Doc.model) = function
          | [] -> Doc.define_model ctx.Ctx.doc n m
          | o :: rest -> (
            let lo = String.lowercase_ascii o in
            match String.index_opt lo '=' with
            | Some i -> (
              let k = String.sub lo 0 i and v = String.sub o (i + 1) (String.length o - i - 1) in
              match k with
              | "closes" -> name_list ctx v (fun l -> go { m with closes = l } rest)
              | "closedby" -> name_list ctx v (fun l -> go { m with closedby = l } rest)
              | _ -> Ctx.error ctx ".xd %s: unknown option %s" n o)
            | None -> (
              match lo with
              | "empty" -> go { m with empty = true } rest
              | "eol" -> go { m with eol = true } rest
              | "inline" -> go { m with display = Doc.Inline } rest
              | "block" -> go { m with display = Doc.Block } rest
              | _ -> Ctx.error ctx ".xd %s: unknown option %s" n o))
        in
        go Doc.default_model opts)

let install ctx =
  Ctx.register ctx "xs" xs;
  Ctx.register ctx "xe" xe;
  Ctx.register ctx "xa" xa;
  Ctx.register ctx "xr" xr;
  Ctx.register ctx "xd" xd
