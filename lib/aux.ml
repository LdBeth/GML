(* The coupling files of the pass model, imbedded by the next pass.

   SCRIPT/VS formats a document in up to four passes and puts out only
   the last (FPASSES(n), TWOPASS: SH20-9186-06 p.126, p.129); what a
   pass learns about the pages it keeps for the next one (the TOC
   entries, TPG p.156; the index, p.213).  Here a pass is gml + TeX: TeX
   lays the pages out and writes what the engine asked for, the next
   gml run answers from it.  Both files are SCRIPT source, imbedded
   ([imbed]) before -set and the profile, so that these win:

   - the symbol file JOB.sym (gml -symbols-in), written by the engine:
     its format is described in lib/symbols.ml (Symbols.dump); a symbol
     with a page provenance (gml@pgq) gets the answer of the aux file
     written by the same pass ([resolve_pages], after both);
   - the aux file JOB.gmlaux (gml -aux), written by TeX: its format is
     described in share/tex/gml.tex (the header comment, "Page
     references and the aux file").  It sets pa@ENC (the page of an
     anchor), pr@N (gml.tex's own, not used here), pq@ENC (the answer
     to a question) and px@NAME (a tag set's own: written by its TeX
     file, read by its profile; not used here).  None of them is
     carried to the symbol file (Symbols.aux_prefixes).

   ENC(name): the name escaped as xslt/tex.xsl escapes it (t:name, [tex_name]
   here: a character other than A-Z a-z 0-9 . - becomes +code+),
   then letters and digits as they are, "." as "@" and any other byte as
   "#HH" (two upper-case hexadecimal digits), so that it is a symbol
   name (the length is not limited in these files, Ctx.coupling).  A
   question id loses its leading "q": q1.12.3 is pq@1@12@3; the anchor
   gml.tc.1 is pa@gml@tc@1.  Nothing decodes: the engine and gml.tex
   encode and look up.  The last line for a name wins (.se): a question
   inside content that TeX typesets twice (a measured table cell, a
   running heading on every page) is answered more than once.
   DCF-VERIFY: lc in a paragraph does not count the lines of the
   paragraph in progress. *)

(* t:name of xslt/tex.xsl: A-Z a-z 0-9 . - as they are, any other
   character (a code point; invalid UTF-8 is U+FFFD) as +code+ *)
let tex_name s =
  let b = Buffer.create (String.length s) in
  let n = String.length s in
  let rec go i =
    if i < n then begin
      let d = String.get_utf_8_uchar s i in
      let l = Uchar.utf_decode_length d in
      (match s.[i] with
      | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '.' | '-') as c when l = 1 ->
          Buffer.add_char b c
      | _ ->
          let u =
            if Uchar.utf_decode_is_valid d then
              Uchar.to_int (Uchar.utf_decode_uchar d)
            else 0xFFFD
          in
          Printf.bprintf b "+%d+" u);
      go (i + l)
    end
  in
  go 0;
  Buffer.contents b

let enc s =
  let b = Buffer.create (String.length s) in
  String.iter
    (function
      | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9') as c -> Buffer.add_char b c
      | '.' -> Buffer.add_char b '@'
      | c -> Printf.bprintf b "#%02X" (Char.code c))
    (tex_name s);
  Buffer.contents b

(** The symbol of question [id] (q1.12.3 -> pq@1@12@3). *)
let query_name id =
  let id =
    if id <> "" && id.[0] = 'q' then String.sub id 1 (String.length id - 1)
    else id
  in
  Symbols.query_prefix ^ enc id

(** The symbol of anchor [a] (gml.tc.1 -> pa@gml@tc@1). *)
let anchor_name a = Symbols.anchor_prefix ^ enc a

(** Imbed the coupling file [f] now (before the document run); a file that does
    not exist is empty (the first pass). Whether it existed. *)
let imbed (ctx : Ctx.t) f =
  Sys.file_exists f
  && begin
    ctx.Ctx.coupling <- true;
    Interp.imbed_now ctx f;
    ctx.Ctx.coupling <- false;
    true
  end

(** gml -symbols-in [f]: imbed the previous pass's symbols; its TOC entries are
    those of the previous pass and its array counters start again at 0. *)
let load_symbols (ctx : Ctx.t) f =
  if imbed ctx f then begin
    ctx.Ctx.toc.Toc.previous <- Some (Toc.carried ctx.Ctx.syms);
    Symbols.reset_counters ctx.Ctx.syms
  end

(** gml -aux [f]: imbed it and ask the questions of the pass model; the answers
    are its symbols. *)
let load (ctx : Ctx.t) f =
  ignore (imbed ctx f);
  ctx.Ctx.page_query <-
    Some (fun id -> Symbols.get ctx.Ctx.syms (query_name id));
  ctx.Ctx.page_of <- (fun a -> Symbols.get ctx.Ctx.syms (anchor_name a))

(** After [load_symbols] and [load] (either may be missing): the symbols of the
    previous pass that carry a page question (gml@pgq, Symbols.dump) get the
    answer of the aux file to it, the neutral default if it has none (no aux
    file, or TeX did not reach the place); gml@pgq is undefined again. *)
let resolve_pages (ctx : Ctx.t) =
  let syms = ctx.Ctx.syms in
  List.iter
    (fun e ->
      match String.split_on_char ' ' e with
      | [ name; sub; id; dflt ] -> (
          match int_of_string_opt sub with
          | Some sub ->
              let v =
                Option.value (Symbols.get syms (query_name id)) ~default:dflt
              in
              ignore (Symbols.set ~sub syms name v)
          | None -> ())
      | _ -> ())
    (Symbols.elements syms Symbols.page_name);
  ignore (Symbols.unset syms Symbols.page_name)
