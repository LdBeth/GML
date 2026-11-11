(* gmlshare [xml|tex] [-o file]

   Writes what the engine, the stylesheets and gml.tex share (Shared:
   the nodes of the canonical tree, the scope properties, the control
   words, the space units, the names of the pass model's coupling files)
   to -o FILE, else to standard output: as XML (xml, the default: for
   the stylesheets) or as the TeX declarations gml.tex reads (tex: the
   units, the aux file's names, the hints).  A build tool: xslt/dune runs
   it to keep xslt/gml-shared.xml current, share/dune for
   share/tex/gml-shared.tex. *)

let usage = "usage: gmlshare [xml|tex] [-o file]"

let () =
  let out = ref None and format = ref None in
  Arg.parse
    [ ("-o", Arg.String (fun f -> out := Some f), "file  write to file") ]
    (fun a ->
      match (a, !format) with
      | ("xml" | "tex"), None -> format := Some a
      | _ -> raise (Arg.Bad ("unexpected argument " ^ a)))
    usage;
  let text =
    match !format with
    | Some "tex" -> Gml.Shared.tex ()
    | _ -> Gml.Shared.document ()
  in
  match !out with
  | None -> print_string text
  | Some f -> Out_channel.with_open_bin f (fun oc -> output_string oc text)
