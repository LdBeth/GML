(* The head-level counter (SH20-9161-3 p.247 .DH NUM, p.266-268 .GS HCTR).

   Up to 32 levels, each a number shown in arabic or as a letter (upper
   or lower case: A, B, ... Z, AA, ...).  Initially "1.0.0...": the
   first level one heading is 1.0, the first level two heading 1.1.  A
   value set with [.gs hctr n1.n2...] is the number of the next heading
   at its last level: after [.gs hctr 4.7.7.4] an [.h4] is 4.7.7.4, an
   [.h5] 4.7.7.4.1 and an [.h3] 4.7.8.  So the deepest level set is
   [fresh] (the deepest level given that is not 0: in "A.0" level 1):
   the next step at that level uses the value as it is.  A
   single number n ([.gs hctr 2]) steps level n and resets the levels
   below it.  The Starter Set relies on this: DSMAPPD sets A.0 and the
   first appendix heading, stepped by DSMHEAD1's [.gs hctr 1], is "A".
   DCF-VERIFY: that a step at the fresh level does not increment. *)

type style = Arabic | Upper | Lower

let levels = 32

type t = {
  v : int array;  (** index 1 .. [levels] *)
  style : style array;
  mutable fresh : int;  (** the level whose value is used as it is; 0: none *)
}

let reset t =
  Array.fill t.v 0 (levels + 1) 0;
  Array.fill t.style 0 (levels + 1) Arabic;
  t.v.(1) <- 1;
  t.fresh <- 1

let create () =
  let t =
    {
      v = Array.make (levels + 1) 0;
      style = Array.make (levels + 1) Arabic;
      fresh = 0;
    }
  in
  reset t;
  t

(* One position as written: digits, or letters (A = 1, Z = 26, AA = 27). *)
let position s =
  let all p = s <> "" && String.for_all p s in
  if all (function '0' .. '9' -> true | _ -> false) then
    Some (int_of_string s, Arabic)
  else if all (function 'A' .. 'Z' -> true | _ -> false) then
    Some (String.fold_left (fun n c -> (n * 26) + Char.code c - 64) 0 s, Upper)
  else if all (function 'a' .. 'z' -> true | _ -> false) then
    Some (String.fold_left (fun n c -> (n * 26) + Char.code c - 96) 0 s, Lower)
  else None

let letters base n =
  let rec go n acc =
    if n <= 0 then acc
    else
      let n = n - 1 in
      go (n / 26) (String.make 1 (Char.chr (base + (n mod 26))) ^ acc)
  in
  if n <= 0 then "0" else go n ""

let show_level t i =
  match t.style.(i) with
  | Arabic -> string_of_int t.v.(i)
  | Upper -> letters 65 t.v.(i)
  | Lower -> letters 97 t.v.(i)

(** The levels 1 .. [n], each as shown. *)
let parts t n = List.init n (fun i -> show_level t (i + 1))

(** The number of a level [n] heading: "1.0" for level 1, "1.2.3" below. *)
let number t n = String.concat "." (parts t n @ if n = 1 then [ "0" ] else [])

(** Step level [n] (1 .. [levels]): increment it unless it is the fresh level,
    and reset the levels below. *)
let step t n =
  if t.fresh <> n then begin
    t.v.(n) <- t.v.(n) + 1;
    for i = n + 1 to levels do
      t.v.(i) <- 0
    done
  end;
  t.fresh <- 0

(** [.gs hctr n1.n2...]: set the counter; the positions not given are 0. *)
let set t ps =
  Array.fill t.v 0 (levels + 1) 0;
  Array.fill t.style 0 (levels + 1) Arabic;
  (* fresh: the deepest position given that is not 0: "A.0" is the A of
     level 1 *)
  t.fresh <- 0;
  List.iteri
    (fun i (v, s) ->
      t.v.(i + 1) <- v;
      t.style.(i + 1) <- s;
      if v <> 0 then t.fresh <- i + 1)
    ps
