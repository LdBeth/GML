(* Source locations and diagnostics.

   A location is a file and line, plus a chain of macro frames that were
   active when the line was produced (innermost first), reported as
   "file:line (in macro X line n, in macro Y line m)": [file:line] is the
   line of the outermost call, X the macro the line comes from, Y the
   macro that called X. *)

type via = {
  macro : string;  (** macro (or GML tag) name *)
  mline : int;  (** line number inside the macro body, 1-based *)
}

type t = {
  file : string;
  line : int;  (** 1-based; 0 = no line *)
  via : via list;  (** innermost macro first *)
}

let none = { file = ""; line = 0; via = [] }
let make file line = { file; line; via = [] }

let to_string l =
  let base =
    if l.file = "" then "gml"
    else if l.line = 0 then l.file
    else Printf.sprintf "%s:%d" l.file l.line
  in
  match l.via with
  | [] -> base
  | vs ->
      (* runs of identical entries (recursion) are shown once with a count *)
      let rec runs = function
        | [] -> []
        | v :: rest -> (
            match runs rest with
            | (w, k) :: r when w = v -> (v, k + 1) :: r
            | r -> (v, 1) :: r)
      in
      let show (v, k) =
        Printf.sprintf "in macro %s line %d%s" v.macro v.mline
          (if k > 1 then Printf.sprintf " [%d times]" k else "")
      in
      base ^ " (" ^ String.concat ", " (List.map show (runs vs)) ^ ")"

(* ---- diagnostics ------------------------------------------------------ *)

type severity = Info | Warning | Error

let severity_name = function
  | Info -> "info"
  | Warning -> "warning"
  | Error -> "error"

(** DCF-style return code: 0 none/info, 4 warning, 8 error. *)
let severity_code = function Info -> 0 | Warning -> 4 | Error -> 8

type diag = {
  mutable warnings : int;
  mutable errors : int;
  mutable worst : int;  (** highest return code seen so far *)
  mutable out : out_channel;
}

let create_diag () = { warnings = 0; errors = 0; worst = 0; out = stderr }

let report d sev loc fmt =
  Printf.ksprintf
    (fun msg ->
      (match sev with
      | Info -> ()
      | Warning -> d.warnings <- d.warnings + 1
      | Error -> d.errors <- d.errors + 1);
      d.worst <- max d.worst (severity_code sev);
      Printf.fprintf d.out "%s: %s: %s\n%!" (to_string loc) (severity_name sev)
        msg)
    fmt

let return_code d = d.worst
