(* Symbol and macro libraries (SH35-0069 p.239-240, p.281-283).

   A library is a directory given with [-lib dir] (repeatable, searched
   in order; DCF allows up to eight on the LIB option, p.282).  A member
   is a file in it named after the member, the name in upper case,
   optionally with the extension [.scr]: [NAME], then [NAME.scr].
   Member names are up to eight characters (p.282); a longer macro or
   symbol name is never searched for (DCF-VERIFY: DCF may cut it to
   eight).

   A macro member is the whole macro body, every line of it (there is no
   [.dm] line in it, p.283); a symbol member is one line, its value
   ("only the first line of a macro library member is read for a symbol
   definition", p.282 note 63).  Symbol names are translated to upper
   case to find the member (p.240): [&libsym] and [&LIBSYM] are set from
   the same member.

   The library is searched for a macro or symbol that is not known
   when [.ly] allows it ([.ly on], [.ly mac], [.ly sym]; initially
   OFF), and always for [.dm name lib] / [.se name lib].  What is
   found is defined in the macro store or the symbol table, so the next
   reference does not search again (p.282); a member that is not found
   is remembered too, so that repeated lookups of an undefined symbol
   cost one table probe.  The members are read once: a macro that
   deletes itself ([.dm name off], SH35-0050 p.16) is fetched again,
   from the cache, at its next call. *)

let max_member = 8

let member_name name = String.uppercase_ascii name

let valid_member m =
  m <> "" && String.length m <= max_member && String.for_all Line.is_name_char m

(** The lines of member [name], if a library has it. *)
let member ctx name =
  let m = member_name name in
  if ctx.Ctx.libs = [] || not (valid_member m) then None
  else
    match Hashtbl.find_opt ctx.Ctx.lib_members m with
    | Some r -> r
    | None ->
      let is_file p = Sys.file_exists p && not (Sys.is_directory p) in
      let path =
        List.find_map
          (fun d ->
             List.find_opt is_file
               [ Filename.concat d m; Filename.concat d (m ^ ".scr") ])
          ctx.Ctx.libs
      in
      let r =
        match path with
        | None -> None
        | Some p -> (
          match Input.read_file p with
          | Ok lines -> Some (p, lines)
          | Error e -> Ctx.error ctx "library member %s: %s" m e; None)
      in
      let r = Option.map snd r in
      Hashtbl.replace ctx.Ctx.lib_members m r;
      r

(** Define macro [name] from the library; the definition replaces any
    existing one.  Returns the definition, if the member exists. *)
let load_macro ctx name =
  match member ctx name with
  | None -> None
  | Some lines ->
    Macro.define ctx.Ctx.macros name
      ~at:(Loc.make (member_name name) 1) (Array.to_list lines);
    Macro.find ctx.Ctx.macros name

(** An unresolved macro: from the library if [.ly on|mac]. *)
let find_macro ctx name =
  if ctx.Ctx.ly_mac then load_macro ctx name else None

(* The value of a symbol member: its first line.  DCF-VERIFY: trailing
   blanks (the padding of fixed-length records) are removed. *)
let symbol_value lines =
  if Array.length lines = 0 then ""
  else
    let l = lines.(0) in
    let n = ref (String.length l) in
    while !n > 0 && l.[!n - 1] = ' ' do decr n done;
    String.sub l 0 !n

(** Set symbol [name] (as written) from the library.  Returns false if
    the member does not exist. *)
let load_symbol ctx name =
  match member ctx name with
  | None -> false
  | Some lines -> (
    match Symbols.set ctx.Ctx.syms name (symbol_value lines) with
    | Ok () -> true
    | Error e -> Ctx.error ctx "%s" e; false)

(** An unresolved symbol during substitution, if [.ly on|sym]: local
    symbols ([&*x]) and system symbols are never searched for. *)
let resolve_symbol ctx name =
  ctx.Ctx.ly_sym && not (Symbols.is_local name)
  && not (Symbols.is_system ctx.Ctx.syms name)
  && load_symbol ctx name
