(* The head-level counter (SH20-9161-3 p.247 .DH NUM; LR p.185, p.188
   .GS HCTR).

   Up to 32 levels, each a number shown in arabic or as a letter (upper
   or lower case: A, B, ... Z, AA, ...).  Initially "1.0.0...": the
   first level one heading is 1.0, the first level two heading 1.1.
   [.gs hctr n1.n2...] sets the counter; a zero position resets all
   later ones, and "0" alone reinitialises it (LR p.185).  The first
   step after a set is ignored if its level is at most the deepest
   nonzero level set ([fresh]): after [.gs hctr 4.7.7.4] an [.h4] is
   4.7.7.4, an [.h5] 4.7.7.4.1, an [.h3] 4.7.7 (LR p.188).  A single
   number n ([.gs hctr 2]) steps level n and resets the levels below
   it.  The Starter Set relies on this: DSMAPPD sets A.0 and the first
   appendix heading, stepped by DSMHEAD1's [.gs hctr 1], is "A".
   DCF-VERIFY (not in LR Rel 4): an ignored step at a level above the
   deepest set leaves the levels below it. *)

type style = Arabic | Upper | Lower

let levels = 32

type t = {
  v : int array;  (** index 1 .. [levels] *)
  style : style array;
  mutable fresh : int;
      (** the first step at a level <= [fresh] is ignored; 0: none *)
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

(** Step level [n] (1 .. [levels]): increment it and reset the levels below,
    unless it is the first step after a set and [n <= fresh]. *)
let step t n =
  if n > t.fresh then begin
    t.v.(n) <- t.v.(n) + 1;
    for i = n + 1 to levels do
      t.v.(i) <- 0
    done
  end;
  t.fresh <- 0

(** [.gs hctr n1.n2...]: set the counter; the positions not given, and those
    after a zero, are 0; all zero reinitialises it. *)
let set t ps =
  let rec upto0 = function [] | (0, _) :: _ -> [] | p :: r -> p :: upto0 r in
  match upto0 ps with
  | [] -> reset t
  | ps ->
      Array.fill t.v 0 (levels + 1) 0;
      Array.fill t.style 0 (levels + 1) Arabic;
      List.iteri
        (fun i (v, s) ->
          t.v.(i + 1) <- v;
          t.style.(i + 1) <- s)
        ps;
      t.fresh <- List.length ps
