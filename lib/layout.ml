(* Layout mode: SCRIPT formats, TeX only lays out, and the interpreter
   asks TeX for the live page state.

   While the document is being processed, the TeX of what has been built
   so far ([Be_tex.flush], hint mode) is given to a layout engine, and
   the system symbols [&$PN] (the page number) and [&$LC] (the lines left
   on the page, SX26-3723) are answered by it ([Ctx.page_query]); so is
   [.se x = &] (SH35-0069 p.235: the page number).  Text goes to the
   engine only when a query needs it, and in whole lines.

   The engine is a [transport] (a record of functions), so that the TeX
   process behind a pipe ([pipe], the first implementation) can be
   replaced by TeX linked in as a library: [query text what] typesets
   [text] (the document's TeX source continues with it) and then answers
   [what] ("pn" or "lc"); [finish text] typesets the rest, ends the
   document and returns TeX's exit status.  An in-process engine would
   push [text] onto TeX's input and run it until the input is used up,
   then read [\pageno], [\pagegoal] and [\pagetotal].

   The pipe protocol (share/tex/gml-layout.tex), all of it initiated by
   gml: TeX (--interaction=scrollmode: \read-1 from the terminal is fatal
   in batch and nonstop mode) runs a driver file that inputs gml.tex and
   gml-layout.tex, begins the document and enters \gmlloop, which writes
   "GML:READY" on the terminal and reads one line from it.  Content goes
   through chunk files, one per query, \input from that line (no line or
   brace limits of \read); control goes through the pipe:
     gml -> TeX   \gmlchunk{k}\relax\gmlquery{pn}      (or lc)
     TeX -> gml   GML:ANS 12        then GML:READY
     gml -> TeX   \gmlchunk{k}\relax\gmlfinish         (the last chunk)
   TeX flushes the terminal before it reads, so request and reply cannot
   deadlock.  Other terminal lines are TeX's own (they are in its .log):
   a line starting with "!" (an error) is reported as a warning with the
   "l.N" context line after it, the rest is discarded.  If TeX dies or
   misbehaves, an error is reported and the page state is the neutral
   constant for the rest of the run. *)

type transport = {
  query : string -> string -> (string, string) result;
      (** [query text what]: typeset [text], then the page state [what] *)
  finish : string -> (int, string) result;
      (** [finish text]: typeset [text], end the document; the exit status *)
}

(* ---- the pipe to a TeX process -------------------------------------------- *)

(* the TEXINPUTS for TeX: the share/tex directory first, the user's value
   after it, a trailing ":" so the system directories stay *)
let texinputs share_tex =
  let old = Option.value (Sys.getenv_opt "TEXINPUTS") ~default:"" in
  let v = ".:" ^ share_tex ^ ":" ^ old in
  if v.[String.length v - 1] = ':' then v else v ^ ":"

let split_blanks s = List.filter (( <> ) "") (String.split_on_char ' ' s)

type reader = { fd : Unix.file_descr; buf : Buffer.t; mutable eof : bool }

(* the next line from TeX, or None at the end; [timeout] seconds *)
(* GML_LAYOUT_DEBUG=file: a transcript of the exchange with TeX *)
let debug =
  lazy
    (match Sys.getenv_opt "GML_LAYOUT_DEBUG" with
    | Some f when f <> "" -> (
        try Some (open_out_gen [ Open_append; Open_creat ] 0o644 f)
        with Sys_error _ -> None)
    | _ -> None)

let trace dir s =
  match Lazy.force debug with
  | Some oc ->
      output_string oc (dir ^ s ^ "\n");
      flush oc
  | None -> ()

let read_line r ~timeout =
  let chunk = Bytes.create 4096 in
  let rec go () =
    let s = Buffer.contents r.buf in
    match String.index_opt s '\n' with
    | Some i ->
        Buffer.clear r.buf;
        Buffer.add_string r.buf (String.sub s (i + 1) (String.length s - i - 1));
        trace "< " (String.sub s 0 i);
        Ok (Some (String.sub s 0 i))
    | None when r.eof ->
        if s = "" then Ok None
        else begin
          Buffer.clear r.buf;
          Ok (Some s)
        end
    | None -> (
        match Unix.select [ r.fd ] [] [] timeout with
        | [], _, _ -> Error "no answer from TeX (timeout)"
        | _ -> (
            match Unix.read r.fd chunk 0 (Bytes.length chunk) with
            | 0 ->
                r.eof <- true;
                go ()
            | n ->
                Buffer.add_subbytes r.buf chunk 0 n;
                go ()
            | exception Unix.Unix_error (Unix.EINTR, _, _) -> go ()))
    | exception Unix.Unix_error (Unix.EINTR, _, _) -> go ()
  in
  go ()

let rm_rf dir =
  (try Array.iter (fun f -> Sys.remove (Filename.concat dir f)) (Sys.readdir dir)
   with Sys_error _ -> ());
  try Sys.rmdir dir with Sys_error _ -> ()

(** The TeX process: [cmd] (words: the program and extra options, e.g.
    "aptex --output-format=pdf") is run with --interaction=scrollmode
    --jobname=[jobname] on a driver file whose text is [driver dir] ([dir]: the
    directory of the chunk files, with a trailing "/"), with [share_tex] on
    TEXINPUTS.  It is started at the first call.  [warn] reports TeX's errors;
    [timeout]: seconds to wait for an answer. *)
let pipe ?(timeout = 600.) ~cmd ~jobname ~share_tex ~driver ~warn () =
  let state = ref `Idle in
  let chunks = ref 0 in
  let dir = ref "" in
  let fail p msg =
    (match p with
    | `Run (pid, wr, _) -> (
        (try Unix.close wr with Unix.Unix_error _ -> ());
        (try Unix.kill pid Sys.sigterm with Unix.Unix_error _ -> ());
        try ignore (Unix.waitpid [] pid) with Unix.Unix_error _ -> ())
    | _ -> ());
    if !dir <> "" then rm_rf !dir;
    state := `Dead;
    Error msg
  in
  let pending = ref None in
  let flush_pending () =
    Option.iter (fun m -> warn m) !pending;
    pending := None
  in
  (* read until "GML:READY"; the last GML:ANS value *)
  let rec until_ready r ans =
    match read_line r ~timeout with
    | Error e -> Error e
    | Ok None -> flush_pending (); Error "TeX ended unexpectedly"
    | Ok (Some l) ->
        let n = String.length l in
        if n >= 4 && String.sub l 0 4 = "GML:" then begin
          flush_pending ();
          let m = String.sub l 4 (n - 4) in
          if m = "READY" then Ok ans
          else if String.length m >= 4 && String.sub m 0 4 = "ANS " then
            until_ready r (Some (String.trim (String.sub m 4 (String.length m - 4))))
          else until_ready r ans
        end
        else if n > 0 && l.[0] = '!' then begin
          flush_pending ();
          pending := Some ("TeX: " ^ l);
          (* a file TeX cannot read or write makes it prompt for another
             name on the terminal, even in scroll mode: give up *)
          let prefix p = String.length l >= String.length p
                         && String.sub l 0 (String.length p) = p in
          if prefix "! I can't find file" || prefix "! I can't write on file" then
            Error ("TeX: " ^ String.sub l 2 (n - 2))
          else until_ready r ans
        end
        else if n > 2 && l.[0] = 'l' && l.[1] = '.' && !pending <> None then begin
          pending := Option.map (fun m -> m ^ " (" ^ l ^ ")") !pending;
          flush_pending ();
          until_ready r ans
        end
        else until_ready r ans
  in
  let start () =
    match split_blanks cmd with
    | [] -> Error "-layout: empty command"
    | prog :: opts -> (
        try
          let d = Filename.temp_dir "gml-layout" "" in
          dir := d;
          let d = if Filename.check_suffix d "/" then d else d ^ "/" in
          if String.contains d ' ' then failwith "the temporary directory name has a blank";
          let drv = d ^ "driver.tex" in
          Out_channel.with_open_bin drv (fun oc -> output_string oc (driver d));
          let in_r, in_w = Unix.pipe ~cloexec:true () in
          let out_r, out_w = Unix.pipe ~cloexec:true () in
          let env =
            Array.append
              [| "TEXINPUTS=" ^ texinputs share_tex |]
              (Array.of_list
                 (List.filter
                    (fun e -> not (String.length e > 10 && String.sub e 0 10 = "TEXINPUTS="))
                    (Array.to_list (Unix.environment ()))))
          in
          let argv =
            Array.of_list
              ((prog :: opts)
              @ [ "--interaction=scrollmode"; "--jobname=" ^ jobname; drv ])
          in
          let pid = Unix.create_process_env prog argv env in_r out_w Unix.stderr in
          Unix.close in_r;
          Unix.close out_w;
          let r = { fd = out_r; buf = Buffer.create 4096; eof = false } in
          let p = `Run (pid, in_w, r) in
          state := p;
          match until_ready r None with
          | Ok _ -> Ok p
          | Error e -> fail p e
        with
        | Unix.Unix_error (e, f, _) ->
            fail !state (Printf.sprintf "%s: %s: %s" prog f (Unix.error_message e))
        | Sys_error e | Failure e -> fail !state e)
  in
  let running () =
    match !state with
    | `Idle -> start ()
    | `Run _ as p -> Ok p
    | `Dead -> Error "TeX is not running"
  in
  let send text request =
    match running () with
    | Error e -> Error e
    | Ok (`Run (pid, wr, r) as p) -> (
        try
          let cmd =
            if text = "" then request
            else begin
              incr chunks;
              let f = Printf.sprintf "%sc%d.tex" (Filename.concat !dir "") !chunks in
              Out_channel.with_open_bin f (fun oc -> output_string oc text);
              Printf.sprintf "\\gmlchunk{%d}\\relax%s" !chunks request
            end
          in
          trace "> " cmd;
          let line = Bytes.of_string (cmd ^ "\n") in
          ignore (Unix.write wr line 0 (Bytes.length line));
          Ok (pid, wr, r, p)
        with
        | Unix.Unix_error (e, _, _) -> fail p ("TeX: " ^ Unix.error_message e)
        | Sys_error e -> fail p e)
    | Ok _ -> Error "TeX is not running"
  in
  let query text what =
    match send text ("\\gmlquery{" ^ what ^ "}") with
    | Error e -> Error e
    | Ok (_, _, r, p) -> (
        match until_ready r None with
        | Ok (Some v) -> Ok v
        | Ok None -> fail p "TeX gave no answer"
        | Error e -> fail p e)
  in
  let finish text =
    match send text "\\gmlfinish" with
    | Error e -> Error e
    | Ok (pid, wr, r, p) -> (
        (try Unix.close wr with Unix.Unix_error _ -> ());
        (* the rest of TeX's terminal output: only its errors *)
        let rec drain () =
          match until_ready r None with
          | Ok _ -> drain ()
          | Error "TeX ended unexpectedly" -> Ok ()
          | Error e -> Error e
        in
        match drain () with
        | Error e -> fail p e
        | Ok () ->
            let _, status = Unix.waitpid [] pid in
            Unix.close r.fd;
            rm_rf !dir;
            state := `Dead;
            Ok (match status with Unix.WEXITED n -> n | _ -> 255))
  in
  { query; finish }

(* ---- a fake engine, for tests ------------------------------------------------ *)

(** No TeX: the text is kept in [buf]; a page has 50 lines of the TeX source,
    so pn = 1 + lines / 50 and lc = 50 - lines mod 50. *)
let fake buf =
  let lines () =
    let n = ref 0 in
    String.iter (fun c -> if c = '\n' then incr n) (Buffer.contents buf);
    !n
  in
  {
    query =
      (fun text what ->
        Buffer.add_string buf text;
        let l = lines () in
        match what with
        | "pn" -> Ok (string_of_int (1 + (l / 50)))
        | "lc" -> Ok (string_of_int (50 - (l mod 50)))
        | w -> Error ("unknown query " ^ w));
    finish = (fun text -> Buffer.add_string buf text; Ok 0);
  }

(* ---- the driver ---------------------------------------------------------------- *)

type t = {
  ctx : Ctx.t;
  stream : Be_tex.stream;
  transport : transport;
  mutable alive : bool;
  source : Buffer.t option;
      (** the whole TeX source as sent, with a comment line "%gml:query WHAT=VALUE"
          after each query (TeX ignores it) *)
}

(** The text of the driver file for [pipe]: the preamble of [config], with
    gml-layout.tex, then \gmlloop. *)
let driver config dir =
  let c =
    {
      config with
      Be_tex.preamble =
        Printf.sprintf "\\def\\gmllayoutdir{%s}%s" dir
          (if config.Be_tex.preamble = "" then "" else "\n" ^ config.Be_tex.preamble);
      extra_input = config.Be_tex.extra_input @ [ "gml-layout" ];
    }
  in
  Be_tex.preamble c ^ "\\gmlloop\n"

let query_name = function "$PN" -> Some "pn" | "$LC" -> Some "lc" | _ -> None

(** Start layout mode on [ctx]: [&$PN] and [&$LC] are asked of [transport].
    [source]: the TeX source is also kept there. *)
let install ?source ctx transport =
  let stream = Be_tex.stream ~warn:(fun m -> Ctx.warn ctx "%s" m) ctx.Ctx.doc in
  let t = { ctx; stream; transport; alive = true; source } in
  ctx.Ctx.page_query <-
    (fun sym ->
      match query_name sym with
      | Some what when t.alive -> (
          let text = Be_tex.flush ~force:true stream in
          Option.iter (fun b -> Buffer.add_string b text) source;
          match transport.query text what with
          | Ok v ->
              Option.iter (fun b -> Printf.bprintf b "%%gml:query %s=%s\n" what v) source;
              Some v
          | Error e ->
              t.alive <- false;
              Ctx.error ctx "layout: %s; &$PN and &$LC are constants from now on" e;
              None)
      | _ -> None);
  t

(** After [Interp.finish]: the rest of the document goes to the engine; TeX's
    exit status, or None if it failed. *)
let finish t =
  let text = Be_tex.flush ~final:true t.stream ^ "%\n" in
  Option.iter (fun b -> Buffer.add_string b text) t.source;
  t.ctx.Ctx.page_query <- (fun _ -> None);
  if not t.alive then None
  else
    match t.transport.finish text with
    | Ok n -> Some n
    | Error e ->
        Ctx.error t.ctx "layout: %s" e;
        None
