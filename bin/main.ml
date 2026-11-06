(* gml [-I dir]... [-lib dir]... [-share dir] [-profile file|name] [-set sym=val]...
       [-maxgo n] [-undef-tags text|element|error] [-o out.xml] input.gml

   -profile NAME, when NAME is not a file, is the shipped profile
   share/profile/NAME.gml ("-profile starter": the GML Starter Set).  The
   share directory is -share dir, else $GML_SHARE, else ../share/gml
   next to the executable (the installed layout), else the share
   directory of the source tree when run from _build.  Its profile
   directory is also searched last by .im, so a profile can .im starter.

   -lib DIR (repeatable, searched in order) is a symbol and macro library
   (SH35-0069 p.281-283): its members are the files DIR/NAME or
   DIR/NAME.scr, NAME the member name in upper case.  They are used by
   .dm name lib, .se name lib, and with .ly on|mac|sym for unresolved
   macros, GML tag APFs and symbols. *)

let usage = "usage: gml [-I dir]... [-lib dir]... [-share dir] [-profile file|name] [-set sym=val]... [-maxgo n] [-undef-tags text|element|error] [-o out.xml] input.gml"

let share_candidates explicit =
  let exe = Sys.executable_name in
  let exe =
    if Filename.is_relative exe then Filename.concat (Sys.getcwd ()) exe else exe
  in
  let real = try Unix.realpath exe with Unix.Unix_error _ -> exe in
  let up d n = let rec go d n = if n = 0 then d else go (Filename.dirname d) (n - 1) in go d n in
  let near e =
    let bin = Filename.dirname e in
    [ Filename.concat (Filename.dirname bin) "share/gml";
      (* _build/default/bin/main.exe -> _build/default/share, then the
         source tree's share *)
      Filename.concat (up bin 1) "share";
      Filename.concat (up bin 3) "share" ]
  in
  Option.to_list explicit
  @ Option.to_list (Sys.getenv_opt "GML_SHARE")
  @ near exe @ near real

(* A profile name that is not a file is looked up in the share
   directories. *)
let resolve_profile share p =
  let is_file f = Sys.file_exists f && not (Sys.is_directory f) in
  if is_file p || is_file (p ^ ".gml") || String.contains p '/' then Some p
  else
    List.find_map
      (fun d ->
         let f = Filename.concat (Filename.concat d "profile") (p ^ ".gml") in
         if is_file f then Some f else None)
      (share_candidates share)

let () =
  let includes = ref [] in
  let libs = ref [] in
  let profile = ref None in
  let share = ref None in
  let sets = ref [] in
  let output = ref None in
  let max_go = ref None in
  let undef = ref Gml.Ctx.Undef_text in
  let inputs = ref [] in
  let bad = ref [] in
  let add_set s =
    match String.index_opt s '=' with
    | Some i when i > 0 ->
      sets := (String.sub s 0 i, String.sub s (i + 1) (String.length s - i - 1))
              :: !sets
    | _ -> bad := Printf.sprintf "-set %s: expected sym=val" s :: !bad
  in
  let spec =
    [ ("-I", Arg.String (fun d -> includes := d :: !includes),
       "dir  add dir to the .im/.ap search path");
      ("-lib", Arg.String (fun d -> libs := d :: !libs),
       "dir  add dir to the macro/symbol libraries (members NAME or NAME.scr)");
      ("-profile", Arg.String (fun f -> profile := Some f),
       "file|name  imbed file before the input; a name (starter) is a shipped profile");
      ("-share", Arg.String (fun d -> share := Some d),
       "dir  the share directory (default $GML_SHARE, or next to the executable)");
      ("-set", Arg.String add_set, "sym=val  set a symbol");
      ("-maxgo", Arg.Int (fun n -> max_go := Some n),
       "n  stop after n .go jumps (default 100000)");
      ("-undef-tags",
       Arg.Symbol
         ([ "text"; "element"; "error" ],
          fun s ->
            undef :=
              (match s with
               | "element" -> Gml.Ctx.Undef_element
               | "error" -> Gml.Ctx.Undef_error
               | _ -> Gml.Ctx.Undef_text)),
       "  a GML tag without APF: text (with a message, the DCF way), an element, or an error");
      ("-o", Arg.String (fun f -> output := Some f),
       "file  write XML to file (default stdout)") ]
  in
  (try Arg.parse_argv Sys.argv spec (fun f -> inputs := f :: !inputs) usage with
   | Arg.Help m -> print_string m; exit 0
   | Arg.Bad m -> prerr_string m; exit 8);
  let fail msg = Printf.eprintf "gml: error: %s\n%s\n" msg usage; exit 8 in
  List.iter fail (List.rev !bad);
  let input =
    match !inputs with
    | [ f ] -> f
    | [] -> fail "no input file"
    | _ -> fail "more than one input file"
  in
  (* the shipped profile directory comes last in the .im search path, so
     a user profile can .im starter the way the manual's profiles imbed
     DSMPROF3 (SH35-0069 p.297) *)
  let shipped =
    List.filter Sys.file_exists
      (List.map (fun d -> Filename.concat d "profile") (share_candidates !share))
  in
  let shipped = match shipped with d :: _ -> [ d ] | [] -> [] in
  let ctx = Gml.Interp.create ~include_path:(List.rev !includes @ shipped) () in
  ctx.sets <- List.rev !sets;
  ctx.libs <- List.rev !libs;
  List.iter
    (fun d ->
       if not (Sys.file_exists d && Sys.is_directory d) then
         Gml.Ctx.warn ctx "-lib %s: not a directory" d)
    ctx.libs;
  Option.iter (fun n -> ctx.max_go <- n) !max_go;
  ctx.undef_tags <- !undef;
  let open_or_fail name =
    match Gml.Input.imbed ctx.input name with
    | Ok id -> id
    | Error e -> Gml.Ctx.error ctx "%s" e; -1
  in
  (* the stack is LIFO: push the input first so the profile runs before
     it; a .ef in the profile makes the rest of it the epifile, run after
     the input (SH35-0069 p.51) *)
  ignore (open_or_fail input);
  Option.iter
    (fun p ->
       match resolve_profile !share p with
       | Some f -> ctx.profile_id <- open_or_fail f
       | None -> Gml.Ctx.error ctx "profile %s not found (no file, no shipped profile)" p)
    !profile;
  if ctx.diag.errors = 0 then Gml.Interp.run ctx;
  let root = Gml.Interp.finish ctx in
  let xml = Gml.Be_xml.document root in
  (match !output with
   | None -> print_string xml
   | Some f -> (
     try Out_channel.with_open_bin f (fun oc -> output_string oc xml)
     with Sys_error e -> Gml.Ctx.error ctx "%s" e));
  exit (Gml.Loc.return_code ctx.diag)
