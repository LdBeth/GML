(* Formatting control words -> hints.

   Formatting is not done here: a formatting control word becomes a hint
   node in the tree ([Tree.Hint (name, attrs)], serialized
   [<gml:NAME .../>]) for the backends.  The rules (plan, "Design
   decisions added after approval"):

   - A hint carries the NEW state explicitly: [.in +2] after [.in 3]
     gives [<gml:in left="5" unit="ch" delta="+2" break="yes"/>] (the
     absolute value, and the operand as written, normalised).  The state
     is kept in [Ctx.fmt].
   - Every hint has [break="yes|no"]: whether the word causes a break.
     SH35-0069 p.77 refers to the Language Reference for the complete
     list; the column below follows the guide where it says so (p.43,
     p.78, p.81, p.198, p.205) and is marked DCF-VERIFY otherwise.
   - Dimensions are normalised by [Units] into [n="2.5" unit="i"] (lists
     of positions into tokens such as ["1ch 45ch"]); nothing is
     converted to device units.
   - Words that count input lines ([.ce n], [.ri n], [.us n], [.up n],
     [.uc n], [.il], [.un], [.in x for n], [.in x after n], [.rc * c])
     do not leave the counting to the backends: the text of the lines
     they cover is wrapped in a [<gml:lines word="ce" n="2" ...>] scope
     ([Doc.scope]) carrying the state that applies inside it.  The
     operand forms are a number of lines, ON ... OFF (n="on"), or text
     on the control word line itself (one covered line).  DCF counts
     the FOR/AFTER amounts of [.in]/[.ir] in output lines (p.79-81); a
     scope counts input lines, so an amount in lines is scoped and any
     other amount is left on the hint ([for]/[after] attributes).
     DCF-VERIFY.
   - [.h0]-[.h6] give an element [<gml:h level="n">text</gml:h>].
     [.fn on/off] and [.rh]/[.rf] definitions give elements too
     ([gml:fn], [gml:rh], [gml:rf]): they hold text of another flow.
     DCF-VERIFY: a running heading is processed (substituted, tags
     resolved) where it is defined, not when each page starts (p.127).
   - [.tr] (p.207) is not a hint: it sets the translate table that
     [Doc] applies to text entering the tree.  [.dv] (p.258) sets a
     symbol to a text variable, the hint [gml:dv] where it is used.  [.li] (literal mode) is input processing ([Interp]).
   - Words with no typesetting meaning (system, terminal, spelling
     words) are warned about once: "ignored device control word .xx".

   The table ([table], at the end) has one row per control word: its
   name, whether it breaks, its operand grammar, and the builder.

   | Word        | Break | Operands                         | Hint / attributes                         |
   |-------------|-------|----------------------------------|-------------------------------------------|
   | .br         | yes   |                                  | br                                        |
   | .lb .lt     | yes   | (implicit leading blank/tab)     | br                                        |
   | .bl         | yes   | (implicit blank line)            | sp n="1" unit="line"                      |
   | .nl         | -     | (implicit null line)             | none: cancels a continuation              |
   | .sp .sk     | yes   | [v] [a] [c]                      | sp/sk n unit [absolute] [conditional]     |
   | .ce .ri     | yes   | [n|on|off|text]                  | gml:lines word n                          |
   | .us .up .uc | no    | [n|on|off|text]                  | gml:lines word n                          |
   | .in .ir     | yes*  | [h] [after v] [for v] [nobreak]  | in left/ir right unit [delta] [offset="0"] [after for] |
   | .il .un     | yes   | h                                | gml:lines word n="1" left unit            |
   | .of         | yes   | [h]                              | of offset unit [delta]                    |
   | .ll         | yes   | [h]                              | ll length unit [delta] | length="default" |
   | .fo         | yes   | [on|off|left|right|center|inside|outside] [extend|fold|trunc] | fo fill align overdraw |
   | .nf         | yes   | [on|off|left|...] [extend|...]   | nf fill align overdraw                    |
   | .ju         | yes   | [on|off]                         | ju fill align overdraw                    |
   | .pa         | yes*  | [n|odd|even|nostart|nobreak] [on|off] | pa [page] [side] [nostart] [mode]    |
   | .cp .cc     | yes   | [v]                              | cp/cc [n unit]                            |
   | .cb         | yes   |                                  | cb                                        |
   | .bx         | yes   | [off|can|new|set|...] positions  | bx [action] [spec]                        |
   | .hr         | yes   | rule spec                        | hr spec                                   |
   | .kp         | yes*  | on|off|float|delay|inline|v[+v]  | kp mode [n unit]                          |
   | .fn         | no    | on|off|leader                    | element gml:fn [kind]                     |
   | .rh .rf     | no    | [odd|even] on|off, cancel|sup|res|execute | element gml:rh/rf [page] / hint action |
   | .dh         | no    | n options                        | dh level spec (NUM and TC options kept)   |
   | .tc         | yes   | [n] [title|/]                    | tc action=begin|end [reserve]; gml:h title; tcentry per entry |
   | .pt         | -     | text | .xx line                  | tcmark anchor (a .pt text line)           |
   | .h0-.h6     | yes   | text                             | gml:h element; tcmark anchor (TC levels)  |
   | .sx         | yes   | [f] [c] /left/fill/right/        | sx left fill right [fold] [center]        |
   | .tp .tb     | no    | [add|del|set] stops              | tp/tb [action] stops                      |
   | .bf         | no    | font... [=]                      | bf font [restart]                         |
   | .pf         | no    |                                  | pf font | initial="yes"                   |
   | .df         | no    | name spec                        | df name spec                              |
   | .hy         | no    | [on|off] [options]               | hy [mode] [options]                       |
   | .hw         | no    | word                             | hw word                                   |
   | .rc         | no    | n [on|off|c], adjust h, * c      | rc code [mode] [char] / gml:lines word="rc"|
   | .bc         | no    | on|off                           | bc mode                                   |
   | .ls .sb .ws .es .wz .is .ic .ud .pn .pl .pw .pm .tm .bm | no | as written | NAME spec |
   | .cl .cd .sc .mc | yes | as written                     | NAME spec                                 |
   | .bc .fl     | no    | as written                       | NAME spec                                 |
   | .tr         | -     | pairs of c|hh                    | (translate table)                         |
   | .dv         | -     | name [font f] [baseline b] /string | (symbol) dv name font baseline text (where used) |

   yes* : depends on the operands (NOBREAK; .pa NOBREAK; inline keeps).
   DCF-VERIFY for every row not cited above: the break column of .ju,
   .pa, .cp, .cc, .cb, .bx, .tc, .sx, .cl, .cd, .sc, .mc and the page
   layout words.  [spec] is the operand list with each space-unit
   operand normalised to a token ("2" -> "2line" for .sp, "5ch" for
   .cl); the other numbers stay as written ([read_spec]): the factors of
   .ls/.ws/.es BY (".ls by 2"), the .wz/.pn/.fl/.bc operands, the
   column count of .cd. *)

open Ctx

let doc ctx = ctx.Ctx.doc
let fmt ctx = ctx.Ctx.fmt
let yn b = if b then "yes" else "no"

let emit ctx name ~brk attrs =
  Doc.hint (doc ctx) name (attrs @ [ ("break", yn brk) ])

(* Operand words; a lone sign is joined to the next word ("+ 1i"). *)
let tokens s =
  let rec join = function
    | (("+" | "-") as sg) :: w :: rest -> (sg ^ w) :: join rest
    | w :: rest -> w :: join rest
    | [] -> []
  in
  join (Control.words s)

let lc = String.lowercase_ascii

let dim ctx cw axis s k =
  match Units.parse axis s with
  | Ok o -> k o
  | Error e -> Ctx.error ctx ".%s: %s" cw e

let amount_attrs (o : Units.operand) =
  [ ("n", Units.show_operand o); ("unit", o.value.unit) ]

(* A token that looks like a dimension (it has a digit) is normalised. *)
let norm axis w =
  if String.exists (fun c -> c >= '0' && c <= '9') w then
    match Units.parse axis w with
    | Ok o -> Units.show_operand o ^ o.value.unit
    | Error _ -> w
  else w

(* How the operands of a word are read: [Dim axis] numbers are space
   units (p.44-46), normalised by [norm]; [Plain] numbers are kept as
   written (factors, counts, page numbers, line counts).  [lead] gives
   the readings of the first operands by position; a keyword of [after]
   changes the reading of the operands that follow it.  E.g. .ls
   (p.106, p.114): [normal v], [by f], [skip f f], [space f f], [text f
   f]; .ws/.es (p.92-93): [normal h], [by f]; .cd (p.130): [n] then
   positions. *)
type reading = Dim of Units.axis | Plain

let read_spec ?(lead = []) ?(after = []) start ops =
  let rec go mode lead acc = function
    | [] -> List.rev acc
    | w :: rest -> (
        match List.assoc_opt (lc w) after with
        | Some m -> go m [] (w :: acc) rest
        | None ->
            let r, lead =
              match lead with r :: l -> (r, l) | [] -> (mode, [])
            in
            let w' = match r with Dim a -> norm a w | Plain -> w in
            go mode lead (w' :: acc) rest)
  in
  String.concat " " (go start lead [] (tokens ops))

let spec axis ops = read_spec (Dim axis) ops

let push_text ctx text =
  ignore
    (Input.push_residual ctx.input text ctx.loc
       { Input.had_text = false; eol = true })

(* ---- line scopes ------------------------------------------------------------ *)

let scope ?(next = []) ~word ~n ~brk attrs remaining =
  {
    Doc.word;
    first = (("n", n) :: attrs) @ [ ("break", yn brk) ];
    rest = ("cont", "yes") :: attrs;
    remaining;
    started = false;
    next;
  }

(* [n|on|off|text]: no operand is one line; 0 or OFF ends the scope. *)
let counted ?(attrs = []) ~brk word ctx ops =
  let open_n n =
    Doc.open_scope (doc ctx)
      (scope ~word ~n:(string_of_int n) ~brk attrs (Some n))
  in
  match lc (String.trim ops) with
  | "" -> open_n 1
  | "on" -> Doc.open_scope (doc ctx) (scope ~word ~n:"on" ~brk attrs None)
  | "off" -> ignore (Doc.close_scope (doc ctx) word)
  | s -> (
      match int_of_string_opt s with
      | Some 0 -> ignore (Doc.close_scope (doc ctx) word)
      | Some n when n > 0 -> open_n n
      | _ ->
          open_n 1;
          push_text ctx ops)

(* ---- indention ----------------------------------------------------------- *)

type side = {
  word : string;
  attr : string;
  get : Ctx.fmt -> Units.sum;
  set : Ctx.fmt -> Units.sum -> unit;
}

let left_side =
  {
    word = "in";
    attr = "left";
    get = (fun f -> f.left);
    set = (fun f v -> f.left <- v);
  }

let right_side =
  {
    word = "ir";
    attr = "right";
    get = (fun f -> f.right);
    set = (fun f v -> f.right <- v);
  }

let delta (o : Units.operand) sum =
  match o.sign with
  | None -> []
  | Some _ ->
      let u = match sum with [ (u, _) ] -> u | _ -> "" in
      [
        ( "delta",
          Units.show_operand o ^ if o.value.unit = u then "" else o.value.unit
        );
      ]

(* .in [h] [after v] [for v] [nobreak] (p.78-82): absolute or relative;
   with FOR the change is temporary: the margin is the permanent one
   plus the operand; with AFTER it begins after that amount.
   A permanent .in also ends the offset: "the offset remains in effect
   until changed by another offset or indent control word" (Figure 6,
   p.80); the hint then carries offset="0".  DCF-VERIFY: a temporary
   .in (FOR) keeps the offset; .ir does not end it. *)
let indent side ctx ops =
  let cw = side.word in
  let rec parse v a f nb = function
    | [] -> Ok (v, a, f, nb)
    | w :: x :: rest when lc w = "after" -> parse v (Some x) f nb rest
    | w :: x :: rest when lc w = "for" -> parse v a (Some x) nb rest
    | w :: rest when lc w = "nobreak" -> parse v a f true rest
    | w :: rest when v = None -> parse (Some w) a f nb rest
    | w :: _ -> Error w
  in
  match parse None None None false (tokens ops) with
  | Error w -> Ctx.error ctx ".%s: unexpected operand %s" cw w
  | Ok (v, a, f, nb) ->
      let brk = not nb in
      let opt s k =
        match s with
        | None -> k None
        | Some s -> dim ctx cw Units.Vertical s (fun o -> k (Some o))
      in
      dim ctx cw Units.Horizontal (Option.value v ~default:"0") (fun o ->
          opt a (fun after ->
              opt f (fun for_ ->
                  let st = fmt ctx in
                  let perm = side.get st in
                  let vattrs sum = Units.attrs ~default:"ch" side.attr sum in
                  let after_n = Option.bind after Units.lines
                  and for_n = Option.bind for_ Units.lines in
                  let uncounted name = function
                    | Some o when Units.lines o = None ->
                        amount_attrs o
                        |> List.map (fun (k, x) ->
                            ((if k = "n" then name else name ^ "-unit"), x))
                    | _ -> []
                  in
                  match for_ with
                  | None ->
                      let now = Units.apply perm o in
                      side.set st now;
                      let of_end =
                        if cw = "in" && st.offset <> Units.zero then begin
                          st.offset <- Units.zero;
                          [ ("offset", "0") ]
                        end
                        else []
                      in
                      emit ctx cw ~brk
                        (vattrs now @ delta o now @ of_end
                       @ uncounted "after" after);
                      Option.iter
                        (fun n ->
                          Doc.open_scope (doc ctx)
                            (scope ~word:cw ~n:(string_of_int n) ~brk:false
                               (("after", "yes") :: vattrs perm)
                               (Some n)))
                        after_n
                  | Some _ -> (
                      let temp = Units.add perm o.value.unit (Units.signed o) in
                      let tattrs = vattrs temp @ delta o temp in
                      match for_n with
                      | Some n -> (
                          let s_for =
                            scope ~word:cw ~n:(string_of_int n)
                              ~brk:(brk && after_n = None)
                              tattrs (Some n)
                          in
                          match after_n with
                          | Some a ->
                              Doc.open_scope (doc ctx)
                                (scope ~next:[ s_for ] ~word:cw
                                   ~n:(string_of_int a) ~brk
                                   (("after", "yes") :: vattrs perm)
                                   (Some a))
                          | None -> Doc.open_scope (doc ctx) s_for)
                      | None ->
                          emit ctx cw ~brk
                            (tattrs @ uncounted "for" for_
                           @ uncounted "after" after
                            @ [ ("temporary", "yes") ])))))

(* .il h / .un h: the next line only, moved right / left (p.80). *)
let one_line word sign ctx ops =
  dim ctx word Units.Horizontal
    (if String.trim ops = "" then "0" else ops)
    (fun o ->
      let st = fmt ctx in
      let h = Units.signed o * sign in
      let sum = Units.add st.left o.value.unit h in
      Doc.open_scope (doc ctx)
        (scope ~word ~n:"1" ~brk:true
           (Units.attrs ~default:"ch" "left" sum)
           (Some 1)))

(* .of [h] (p.84) and .ll [h] (p.122). *)
let offset ctx ops =
  let st = fmt ctx in
  dim ctx "of" Units.Horizontal
    (if String.trim ops = "" then "0" else ops)
    (fun o ->
      let now = Units.apply st.offset o in
      st.offset <- now;
      emit ctx "of" ~brk:true
        (Units.attrs ~default:"ch" "offset" now @ delta o now))

let line_length ctx ops =
  let st = fmt ctx in
  if String.trim ops = "" then begin
    st.ll <- None;
    emit ctx "ll" ~brk:true [ ("length", "default") ]
  end
  else
    dim ctx "ll" Units.Horizontal ops (fun o ->
        match (o.sign, st.ll) with
        | Some _, None ->
            (* relative to the device default: left as a change *)
            emit ctx "ll" ~brk:true
              [
                ("length", "default");
                ("delta", Units.show_operand o ^ o.value.unit);
              ]
        | _ ->
            let now = Units.apply (Option.value st.ll ~default:Units.zero) o in
            st.ll <- Some now;
            emit ctx "ll" ~brk:true
              (Units.attrs ~default:"ch" "length" now @ delta o now))

(* ---- format mode ----------------------------------------------------------- *)

let mode_attrs st =
  [ ("fill", yn st.fill); ("align", st.align); ("overdraw", st.overdraw) ]

let aligns = [ "left"; "right"; "center"; "inside"; "outside" ]

(* .fo and .nf (p.71-76): [nf] is true for .nf. *)
let format nf ctx ops =
  let st = fmt ctx in
  let cw = if nf then "nf" else "fo" in
  let ws = List.map lc (tokens ops) in
  let ws =
    if List.exists (fun w -> w = "on" || w = "off" || List.mem w aligns) ws then
      ws
    else "on" :: ws
  in
  let ok =
    List.for_all
      (fun w ->
        match w with
        | "on" ->
            st.fill <- not nf;
            st.align <- (if nf then "left" else "justify");
            true
        | "off" ->
            st.fill <- nf;
            st.align <- (if nf then "justify" else "left");
            true
        | a when List.mem a aligns ->
            st.fill <- not nf;
            st.align <- a;
            true
        | "extend" | "fold" | "trunc" | "truncate" ->
            st.overdraw <- (if w = "truncate" then "trunc" else w);
            true
        | _ ->
            Ctx.error ctx ".%s: unknown operand %s" cw w;
            false)
      ws
  in
  if ok then emit ctx cw ~brk:true (mode_attrs st)

(* .ju on|off (p.72) *)
let justify ctx ops =
  let st = fmt ctx in
  (match lc (String.trim ops) with
  | "" | "on" -> st.align <- "justify"
  | "off" -> if st.align = "justify" then st.align <- "left"
  | o -> Ctx.error ctx ".ju: ON or OFF expected, not %s" o);
  emit ctx "ju" ~brk:true (mode_attrs st)

(* ---- vertical space and ejects -------------------------------------------- *)

let space word ctx ops =
  let ws = tokens ops in
  let flags, amounts =
    List.partition (fun w -> List.mem (lc w) [ "a"; "c" ]) ws
  in
  let fl =
    List.map
      (fun w ->
        if lc w = "a" then ("absolute", "yes") else ("conditional", "yes"))
      flags
  in
  match amounts with
  | [] -> emit ctx word ~brk:true ([ ("n", "1"); ("unit", "line") ] @ fl)
  | [ a ] ->
      dim ctx word Units.Vertical a (fun o ->
          emit ctx word ~brk:true (amount_attrs o @ fl))
  | _ -> Ctx.error ctx ".%s: one amount expected" word

let conditional_eject word ctx ops =
  match tokens ops with
  | [] -> emit ctx word ~brk:true []
  | [ a ] ->
      dim ctx word Units.Vertical a (fun o ->
          emit ctx word ~brk:true (amount_attrs o))
  | _ -> Ctx.error ctx ".%s: one amount expected" word

let page ctx ops =
  let ws = tokens ops in
  let brk = not (List.exists (fun w -> lc w = "nobreak") ws) in
  let attrs =
    List.map
      (fun w ->
        match lc w with
        | "odd" | "even" -> ("side", lc w)
        | "nostart" -> ("nostart", "yes")
        | "nobreak" -> ("nobreak", "yes")
        | "on" | "off" -> ("mode", lc w)
        | _ -> ("page", w))
      ws
  in
  emit ctx "pa" ~brk attrs

let keep ctx ops =
  match List.map lc (tokens ops) with
  | [] | [ "on" ] -> emit ctx "kp" ~brk:true [ ("mode", "on") ]
  | [ (("off" | "float" | "delay") as m) ] ->
      emit ctx "kp" ~brk:true [ ("mode", m) ]
  | [ "inline" ] -> emit ctx "kp" ~brk:false [ ("mode", "inline") ]
  | _ ->
      (* .kp v / .kp v + v: an inline keep of that depth, no break (p.198) *)
      emit ctx "kp" ~brk:false
        [ ("mode", "inline"); ("depth", spec Units.Vertical ops) ]

(* ---- generic ---------------------------------------------------------------- *)

let generic ?(read = spec Units.Horizontal) word ~brk ctx ops =
  emit ctx word ~brk
    (if String.trim ops = "" then [] else [ ("spec", read ops) ])

let vertical = spec Units.Vertical
let plain = read_spec Plain

let factors =
  [ ("by", Plain); ("skip", Plain); ("space", Plain); ("text", Plain) ]

let line_spacing =
  read_spec (Dim Units.Vertical)
    ~after:(("normal", Dim Units.Vertical) :: factors)

let word_spacing =
  read_spec (Dim Units.Horizontal)
    ~after:[ ("normal", Dim Units.Horizontal); ("by", Plain) ]

let columns = read_spec ~lead:[ Plain ] (Dim Units.Horizontal)

let box ctx ops =
  match tokens ops with
  | [] -> emit ctx "bx" ~brk:true [ ("action", "line") ]
  | w :: rest when List.mem (lc w) [ "off"; "can"; "new"; "set"; "add"; "char" ]
    ->
      emit ctx "bx" ~brk:true
        (("action", lc w)
        ::
        (if rest = [] then []
         else [ ("spec", spec Units.Horizontal (String.concat " " rest)) ]))
  | _ ->
      emit ctx "bx" ~brk:true
        [ ("action", "on"); ("spec", spec Units.Horizontal ops) ]

let tabs word ctx ops =
  match tokens ops with
  | [] -> emit ctx word ~brk:false [ ("action", "reset") ]
  | w :: rest when List.mem (lc w) [ "add"; "del"; "set" ] ->
      emit ctx word ~brk:false
        [
          ("action", lc w);
          ("stops", spec Units.Horizontal (String.concat " " rest));
        ]
  | _ ->
      emit ctx word ~brk:false
        [ ("action", "set"); ("stops", spec Units.Horizontal ops) ]

(* ---- fonts -------------------------------------------------------------------- *)

let begin_font ctx ops =
  let st = fmt ctx in
  let ws = tokens ops in
  let restart = List.mem "=" ws in
  let fonts = List.filter (( <> ) "=") ws in
  if fonts = [] then Ctx.error ctx ".bf: font name expected"
  else begin
    let font = String.concat " " fonts in
    st.fonts <- font :: st.fonts;
    emit ctx "bf" ~brk:false
      (("font", font) :: (if restart then [ ("restart", "yes") ] else []))
  end

let previous_font ctx _ =
  let st = fmt ctx in
  (match st.fonts with _ :: rest -> st.fonts <- rest | [] -> ());
  emit ctx "pf" ~brk:false
    (match st.fonts with
    | f :: _ -> [ ("font", f) ]
    | [] -> [ ("initial", "yes") ])

let first_word s =
  let s = String.trim s in
  match String.index_opt s ' ' with
  | None -> (s, "")
  | Some i ->
      (String.sub s 0 i, String.trim (String.sub s i (String.length s - i)))

let define_font ctx ops =
  match first_word ops with
  | "", _ -> Ctx.error ctx ".df: font name expected"
  | n, rest -> emit ctx "df" ~brk:false [ ("name", n); ("spec", rest) ]

let hyphenate ctx ops =
  let st = fmt ctx in
  let ws = List.map lc (tokens ops) in
  let modes, opts = List.partition (fun w -> w = "on" || w = "off") ws in
  let mode = match modes with m :: _ -> Some m | [] -> None in
  Option.iter (fun m -> st.hyph <- m = "on") mode;
  emit ctx "hy" ~brk:false
    ((match mode with Some m -> [ ("mode", m) ] | None -> [])
    @ if opts = [] then [] else [ ("options", String.concat " " opts) ])

(* ---- headings, toc, split text ---------------------------------------------- *)

(* .h0-.h6; a level defined NUM ([.dh n num], SH20-9161-3 p.247) is
   numbered with the head-level counter ([Headctr]): num="1.0", "1.2".
   A level with a table of contents entry (TC, SH35-0069 Figure 14:
   levels 0-3) records it ([Toc]: the text as put out, with its number)
   and marks the heading with the hint gml:tcmark anchor=ID, whose page
   is the entry's; a TO level (level 0 initially) puts out only the mark,
   no heading (SH20-9161-3 .DH TO). *)
let heading n ctx ops =
  let d = doc ctx in
  let num =
    if n > 0 && Hashtbl.mem ctx.dh_num n then begin
      Headctr.step ctx.hctr n;
      [ ("num", Headctr.number ctx.hctr n) ]
    end
    else []
  in
  let def = Toc.def ctx.toc n in
  let text = String.trim ops in
  let entry =
    if def.Toc.tc && not d.Doc.mute then
      let prefix = match num with [ (_, v) ] -> v ^ " " | _ -> "" in
      Some (Toc.add ctx.toc (Toc.Head n) (prefix ^ Doc.output_text d text))
    else None
  in
  let mark () =
    Option.iter (fun e -> emit ctx "tcmark" ~brk:false [ ("anchor", e.Toc.id) ]) entry
  in
  if def.Toc.only then mark ()
  else begin
    Doc.start_element ~eol:true d "gml:h"
      ((("level", string_of_int n) :: num) @ [ ("break", "yes") ]);
    mark ();
    if text = "" then ignore (Doc.end_element d "gml:h")
    else push_text ctx ops
  end

(* .dh n options: kept as a hint; NUM / NONUM (the last one given) are
   also recorded for the numbering of .hn, and the table of contents
   options (TC NTC TO NTO TS NTS DOT NODOT TCIN h TFONT f, SH20-9161-3
   p.247) for its entries ([Toc]); .dh n alone restores the level's
   initial definition. *)
let define_head ctx ops =
  match first_word ops with
  | "", _ -> Ctx.error ctx ".dh: head level expected"
  | n, rest ->
      (match int_of_string_opt n with
      | Some l when l >= 0 && l <= 6 ->
          let ws = tokens rest in
          if ws = [] then begin
            Hashtbl.remove ctx.dh_num l;
            Toc.reset ctx.toc l
          end;
          let rec go = function
            | [] -> ()
            | w :: rest -> (
                match lc w with
                | "num" -> Hashtbl.replace ctx.dh_num l (); go rest
                | "nonum" -> Hashtbl.remove ctx.dh_num l; go rest
                | _ -> (
                    let value = match rest with v :: _ -> Some v | [] -> None in
                    let value =
                      if lc w = "tcin" then Option.map (norm Units.Horizontal) value
                      else value
                    in
                    match Toc.option ctx.toc l w ~value with
                    | `Took -> go (List.tl rest)
                    | `Missing -> Ctx.error ctx ".dh %d: %s: a value expected" l w
                    | `Done | `Other -> go rest))
          in
          go ws
      | Some l -> Ctx.error ctx ".dh: head level 0 to 6 expected, not %d" l
      | None -> ());
      emit ctx "dh" ~brk:false [ ("level", n); ("spec", rest) ]

(* .pt text | .pt .xx ... (SH35-0069 p.155-156): a line of the table of
   contents with the current page (DSMUTTOC gets ".'sx F /text/./page/"),
   or a control word line put into it as it is; leading blanks of a text
   line go.  The page is that of the hint gml:tcmark put out here. *)
let put_toc ctx ops =
  if ops <> "" && ops.[0] = '.' then ignore (Toc.add ctx.toc (Toc.Control ops) "")
  else
    let text = String.trim ops in
    if text <> "" && not (doc ctx).Doc.mute then begin
      let e = Toc.add ctx.toc Toc.Line (Doc.output_text (doc ctx) text) in
      emit ctx "tcmark" ~brk:false [ ("anchor", e.Toc.id) ]
    end

(* .tc [n] [title | /] (SH35-0069 p.156-157): a page eject (the hint
   gml:tc action=begin), the title as a level one heading (the title
   given, else &SYSCONTENT if it is not null, else CONTENTS; "/": none),
   one hint gml:tcentry per entry made so far ([Toc.printable]: text=,
   level= (pt for a .pt line), indent= (TCIN, normalised), font= (TFONT),
   dot=yes|no, and page= when its page is known ([Toc.entry.page], or
   [Ctx.page_of] its anchor: the pass model's aux file, gml -aux),
   anchor= otherwise: gml.tex's page reference),
   with a gml:sk 1 before an entry whose level asks for it (TS); then
   gml:tc action=end (reserve=n: the page after the table is numbered n
   pages after its first). *)
let toc ctx ops =
  let d = doc ctx in
  let n, rest = first_word ops in
  let reserve, title =
    match int_of_string_opt n with
    | Some _ -> ([ ("reserve", n) ], rest)
    | None -> ([], String.trim ops)
  in
  let title =
    if title = "/" then None
    else if title <> "" then Some title
    else
      match Symbols.get ctx.syms "SYSCONTENT" with
      | Some v when v <> "" -> Some v
      | _ -> Some "CONTENTS"
  in
  emit ctx "tc" ~brk:true (("action", "begin") :: reserve);
  if not d.Doc.mute then begin
    Option.iter
      (fun t ->
        Doc.start_element ~eol:true d "gml:h" [ ("level", "1"); ("break", "yes") ];
        Doc.text d t)
      title;
    List.iter
      (fun (e : Toc.entry) ->
        match e.kind with
        | Toc.Control line -> ctx.Ctx.process ctx (Ctx.Split true) line
        | Toc.Head _ | Toc.Line ->
            if e.skip then emit ctx "sk" ~brk:true [ ("n", "1"); ("unit", "line") ];
            let page =
              match e.page with
              | Some p -> Some p
              | None -> ctx.Ctx.page_of e.id
            in
            emit ctx "tcentry" ~brk:true
              ([ ("level", (match e.kind with Toc.Head l -> string_of_int l | _ -> "pt"));
                 ("text", e.text) ]
              @ (if e.indent = "0" then [] else [ ("indent", norm Units.Horizontal e.indent) ])
              @ (match e.font with Some f -> [ ("font", f) ] | None -> [])
              @ [ ("dot", if e.dot then "yes" else "no") ]
              @ match page with
                | Some p -> [ ("page", p) ]
                | None -> [ ("anchor", e.id) ]))
      (Toc.printable ctx.toc)
  end;
  emit ctx "tc" ~brk:true (("action", "end") :: reserve)

(* .sx [f] [c] /left/fill/right/ (p.76) *)
let split_text ctx ops =
  let rec opts acc s =
    let w, rest = first_word s in
    match lc w with
    | "f" -> opts (("fold", "yes") :: acc) rest
    | "c" -> opts (("center", "yes") :: acc) rest
    | _ -> (List.rev acc, String.trim s)
  in
  let fl, s = opts [] ops in
  if s = "" then Ctx.error ctx ".sx: delimited text expected"
  else
    let d = s.[0] in
    match String.split_on_char d (String.sub s 1 (String.length s - 1)) with
    | l :: f :: r :: _ ->
        (* in a running heading or footing the page number symbol stands for
           the page number (SH35-0069 p.128: ".sx c //Introduction/Page &/");
           pagesym= tells the backends which character it is *)
        let ps = ctx.chars.Chars.ps in
        let out = Doc.output_text (doc ctx) in
        if
          Doc.in_running (doc ctx)
          && List.exists (fun f -> String.contains f ps) [ l; f; r ]
        then begin
          (* the fields are put out (translated, text variables) piece by
             piece between the page number symbols, which are written as
             the pagesym= character: the symbol itself, or U+E000 when a
             piece holds it as text ("&amp." translated to "&", p.259) *)
          let pieces = List.map (fun f -> List.map out (String.split_on_char ps f)) [ l; f; r ] in
          let m =
            if List.exists (List.exists (fun p -> String.contains p ps)) pieces
            then "\u{E000}"
            else String.make 1 ps
          in
          match List.map (String.concat m) pieces with
          | [ l; f; r ] ->
              emit ctx "sx" ~brk:true
                ([ ("left", l); ("fill", f); ("right", r) ] @ fl @ [ ("pagesym", m) ])
          | _ -> assert false
        end
        else
          emit ctx "sx" ~brk:true
            ([ ("left", out l); ("fill", out f); ("right", out r) ] @ fl)
    | _ -> Ctx.error ctx ".sx: three delimited fields expected"

(* ---- footnotes, running headings ----------------------------------------------- *)

let close_flow ctx name =
  match Doc.end_element ~force:true (doc ctx) name with
  | Doc.Closed forced ->
      List.iter
        (fun n ->
          Ctx.warn ctx "element %s implicitly closed by .%s off" n
            (String.sub name 4 2))
        forced
  | Doc.Not_open ->
      Ctx.warn ctx ".%s off: no definition in progress" (String.sub name 4 2)
  | Doc.Mismatch _ -> ()

(* ---- saved environments ------------------------------------------------------ *)

(* The formatting environment that [Ctx.fmt] tracks, with the translate
   table, is saved by .sa and restored by .re (SH20-9161-3 p.110: "the
   active environment, the page control area, the .TI and .TR translate
   tables"; the font stack is in it, SH35-0069 p.179).  The page control
   area is not tracked.  A footnote saves the environment when it starts
   and restores it when it ends (SH20-9161-3 p.110). *)

let fn_env = " fn" (* a name no .sa operand can give *)

let save ctx env =
  ctx.saved <-
    { env; sfmt = copy_fmt (fmt ctx); str = Hashtbl.copy (doc ctx).Doc.tr }
    :: ctx.saved

(* Restore [sv]; with [hints], emit for each part that changes the hint
   that establishes it again (restore="yes"), so a backend that does not
   know gml:re still follows: .in/.of, .ir, .ll, the format mode, .hy and
   the fonts (.pf while the saved font stack is a tail of the current
   one, else .bf of the saved font).  DCF-VERIFY: none of them breaks. *)
let restore ?(hints = true) ctx sv =
  let st = fmt ctx and old = sv.sfmt in
  let tbl = (doc ctx).Doc.tr in
  Hashtbl.reset tbl;
  Hashtbl.iter (Hashtbl.replace tbl) sv.str;
  let re name changed attrs =
    if hints && changed then
      emit ctx name ~brk:false (attrs @ [ ("restore", "yes") ])
  in
  let cur = copy_fmt st in
  st.left <- old.left;
  st.right <- old.right;
  st.offset <- old.offset;
  st.ll <- old.ll;
  st.fill <- old.fill;
  st.align <- old.align;
  st.overdraw <- old.overdraw;
  st.fonts <- old.fonts;
  st.hyph <- old.hyph;
  re "in" (cur.left <> old.left) (Units.attrs ~default:"ch" "left" old.left);
  re "of" (cur.offset <> old.offset)
    (Units.attrs ~default:"ch" "offset" old.offset);
  re "ir" (cur.right <> old.right) (Units.attrs ~default:"ch" "right" old.right);
  re "ll" (cur.ll <> old.ll)
    (match old.ll with
    | None -> [ ("length", "default") ]
    | Some l -> Units.attrs ~default:"ch" "length" l);
  re "fo"
    (cur.fill <> old.fill || cur.align <> old.align
    || cur.overdraw <> old.overdraw)
    (mode_attrs old);
  re "hy" (cur.hyph <> old.hyph) [ ("mode", if old.hyph then "on" else "off") ];
  if cur.fonts <> old.fonts then begin
    let n = List.length cur.fonts - List.length old.fonts in
    let rec drop k l = if k = 0 then l else drop (k - 1) (List.tl l) in
    if n > 0 && drop n cur.fonts = old.fonts then
      for i = 1 to n do
        re "pf" true
          (match drop i cur.fonts with
          | f :: _ -> [ ("font", f) ]
          | [] -> [ ("initial", "yes") ])
      done
    else
      re "bf" true
        (match old.fonts with
        | f :: _ -> [ ("font", f) ]
        | [] -> [ ("font", ""); ("initial", "yes") ])
  end

(* .sa [envname] (SX26-3723: Save Environment) *)
let save_env ctx ops =
  let env = String.uppercase_ascii (String.trim ops) in
  save ctx env;
  emit ctx "sa" ~brk:false (if env = "" then [] else [ ("name", env) ])

(* .re [envname]: the last environment saved, or the one saved with that
   name (the ones saved after it are dropped, DCF-VERIFY); a footnote's
   environment is not restored by .re. *)
let restore_env ctx ops =
  let env = String.uppercase_ascii (String.trim ops) in
  let rec find = function
    | sv :: _ when sv.env = fn_env -> None
    | sv :: rest ->
        if env = "" || sv.env = env then Some (sv, rest) else find rest
    | [] -> None
  in
  match find ctx.saved with
  | None ->
      if env = "" then Ctx.warn ctx ".re: no environment saved"
      else Ctx.warn ctx ".re %s: no environment saved with this name" env
  | Some (sv, rest) ->
      ctx.saved <- rest;
      emit ctx "re" ~brk:false (if env = "" then [] else [ ("name", env) ]);
      restore ctx sv

(* .fn on saves the environment and clears the offset (SH20-9161-3
   p.110); .fn off restores it, without hints: the footnote is a flow of
   its own in the tree. *)
let footnote ctx ops =
  let start attrs =
    save ctx fn_env;
    (fmt ctx).offset <- Units.zero;
    Doc.start_element (doc ctx) "gml:fn" attrs
  in
  match List.map lc (tokens ops) with
  | [] | [ "on" ] -> start []
  | [ "leader" ] -> start [ ("kind", "leader") ]
  | [ "off" ] ->
      close_flow ctx "gml:fn";
      let rec pop = function
        | sv :: rest when sv.env = fn_env ->
            ctx.saved <- rest;
            restore ~hints:false ctx sv
        | _ :: rest -> pop rest
        | [] -> ()
      in
      pop ctx.saved
  | _ -> Ctx.error ctx ".fn: ON, OFF or LEADER expected"

let running word ctx ops =
  let name = "gml:" ^ word in
  match List.map lc (tokens ops) with
  | [ "off" ] -> close_flow ctx name
  | [ (("cancel" | "sup" | "res" | "execute") as a) ] ->
      emit ctx word ~brk:false [ ("action", a) ]
  | [] | [ "on" ] -> Doc.start_element (doc ctx) name []
  | [ (("odd" | "even") as p) ] | [ (("odd" | "even") as p); "on" ] ->
      Doc.start_element (doc ctx) name [ ("page", p) ]
  | _ ->
      Ctx.error ctx
        ".%s: [ODD|EVEN] ON, OFF, CANCEL, SUP, RES or EXECUTE expected" word

(* ---- revision codes ------------------------------------------------------------ *)

let revision ctx ops =
  match tokens ops with
  | "*" :: c :: _ ->
      Doc.open_scope (doc ctx)
        (scope ~word:"rc" ~n:"1" ~brk:false [ ("char", c) ] (Some 1))
  | w :: rest when lc w = "adjust" ->
      emit ctx "rc" ~brk:false
        [ ("adjust", spec Units.Horizontal (String.concat " " rest)) ]
  | [ n ] -> emit ctx "rc" ~brk:false [ ("code", n); ("char", " ") ]
  | [ n; m ] when lc m = "on" || lc m = "off" ->
      emit ctx "rc" ~brk:false [ ("code", n); ("mode", lc m) ]
  | [ n; c ] -> emit ctx "rc" ~brk:false [ ("code", n); ("char", c) ]
  | _ -> Ctx.error ctx ".rc: invalid operands %s" ops

(* ---- .tr and .dv --------------------------------------------------------------- *)

(* A character operand: one character (in UTF-8) or two hexadecimal
   digits, an EBCDIC code ([Ebcdic]); its Unicode code point. *)
let char_operand s =
  if s = "" then None
  else
    let d = String.get_utf_8_uchar s 0 in
    if Uchar.utf_decode_length d = String.length s then
      Some (Uchar.to_int (Uchar.utf_decode_uchar d))
    else Option.map Ebcdic.to_unicode (Ebcdic.of_hex s)

let utf8 c =
  let b = Buffer.create 2 in
  Buffer.add_utf_8_uchar b (Uchar.of_int c);
  Buffer.contents b

(* .tr [c1 c2 ...]: no operands resets the table; an odd last character
   translates to a blank (DCF-VERIFY). *)
let translate ctx ops =
  let tbl = (doc ctx).Doc.tr in
  let rec go = function
    | [] -> ()
    | a :: rest -> (
        let b, rest =
          match rest with b :: r -> (Some b, r) | [] -> (None, [])
        in
        let dst = match b with None -> Some 0x20 | Some b -> char_operand b in
        match (char_operand a, dst) with
        | Some src, Some dst ->
            if dst = src then Hashtbl.remove tbl src
            else Hashtbl.replace tbl src (utf8 dst);
            go rest
        | _ ->
            Ctx.error ctx ".tr: invalid character %s"
              (String.concat " " (a :: Option.to_list b)))
  in
  match Control.words ops with [] -> Hashtbl.reset tbl | ws -> go ws

(* .dv name [FONT f] [BASELINE b] [/string[/]] | .dv name [TEXT] [/string[/]]
   (SH35-0069 p.258-261; SX26-3723 .DV): a text variable, "known text" with
   an optional font and baseline shift (positive is up, as for .sb, p.107).
   With FONT, BASELINE or TEXT the symbol's value is the string between
   two marks ([Doc.define_variable]) and it becomes the hint gml:dv where
   it enters the text: text= the string (substituted like any value),
   font=, baseline= (vertical space units, normalised), name=, break="no";
   a plain [.dv name /string] is a symbol with that value (IBM's DSMPROF3
   defines its list labels so, under .su off, and one as a control word
   line, ".dv @id@l@o9 /.dsm#supr &@item#.").  The string is the rest of
   the line after its delimiter (the first character after the keywords),
   without a closing delimiter.  DCF-VERIFY: with no string the variable
   is the null string; BASELINE without FONT is allowed. *)
let is_name_start c =
  match c with 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '@' | '#' | '$' -> true | _ -> false

let define_variable ctx ops =
  let name, rest = first_word ops in
  if name = "" then Ctx.error ctx ".dv: symbol name expected"
  else
    let rec keys acc rest =
      let w, r = first_word rest in
      match lc w with
      | "text" -> keys (("", "text") :: acc) r
      | ("font" | "baseline") as k ->
          let v, r = first_word r in
          if v = "" then Error (Printf.sprintf "%s: value expected" k)
          else
            let v = if k = "baseline" then norm Units.Vertical v else v in
            keys ((k, v) :: List.remove_assoc k acc) r
      | _ -> Ok (List.rev acc, rest)
    in
    match keys [] rest with
    | Error e -> Ctx.error ctx ".dv %s: %s" name e
    | Ok (_, rest) when rest <> "" && is_name_start rest.[0] ->
        Ctx.error ctx ".dv %s: FONT, BASELINE, TEXT or /string expected, not %s"
          name (fst (first_word rest))
    | Ok (k, rest) ->
        let v =
          if rest = "" then ""
          else
            let d = rest.[0] in
            let v = String.sub rest 1 (String.length rest - 1) in
            let n = String.length v in
            if n > 0 && v.[n - 1] = d then String.sub v 0 (n - 1) else v
        in
        let text_form = List.mem_assoc "" k in
        let k = List.remove_assoc "" k in
        Control.check_name ctx ".dv" name (fun () ->
            let value =
              if k = [] && not text_form then v
              else Doc.define_variable (doc ctx) (("name", name) :: k) v
            in
            match Symbols.set ctx.syms name value with
            | Ok () -> ()
            | Error e -> Ctx.error ctx ".dv: %s" e)

(* ---- index ---------------------------------------------------------------------- *)

(* The fields of a delimited string: the first nonblank character is the
   delimiter; a delimiter at the end closes the last field.  Returns the
   fields and the rest after [max] fields. *)
let delimited ?(max = max_int) s =
  let s = String.trim s in
  if s = "" then ([], "")
  else
    let d = s.[0] in
    let rec go i n acc =
      if n = max then (List.rev acc, String.sub s i (String.length s - i))
      else
        match String.index_from_opt s i d with
        | Some j -> go (j + 1) (n + 1) (String.sub s i (j - i) :: acc)
        | None ->
            let last = String.sub s i (String.length s - i) in
            (List.rev (if last = "" then acc else last :: acc), "")
    in
    go 1 0 []

(* .pi [start|end|order|ref] [key /k1/k2/k3/] /t1[/t2[/t3[/page]]]
   (SH20-9161-3 p.297, SH35-0069 p.213-218): an index entry, the hint
   gml:pi with the terms t1 t2 t3 and the keys k1 k2 k3 given; a fourth
   field is the page text: absent or the page number symbol (&$PS) is the
   current page, null is no page (pageref="no"), anything else is
   page="text"; REF makes the last term a cross reference (see="term").
   It is ignored unless &$INDX is 1, the INDEX option (SH35-0069 p.213).
   resolve.xsl builds the index from these. *)
let put_index ctx ops =
  let rec opts acc s =
    let w, rest = first_word s in
    match lc w with
    | ("start" | "end" | "order" | "ref") as o -> opts ((o, "yes") :: acc) rest
    | "key" ->
        let keys, rest = delimited ~max:3 rest in
        let keys =
          List.mapi (fun i k -> (Printf.sprintf "k%d" (i + 1), k)) keys
        in
        opts
          (List.rev_append (List.filter (fun (_, k) -> k <> "") keys) acc)
          rest
    | _ -> (List.rev acc, s)
  in
  if Symbols.get ctx.syms "$INDX" = Some "1" then
    let o, rest = opts [] ops in
    let fields, _ = delimited rest in
    let terms, page =
      match fields with
      | t1 :: t2 :: t3 :: p :: _ -> ([ t1; t2; t3 ], Some p)
      | l -> (l, None)
    in
    let rec trim = function "" :: l -> trim l | l -> l in
    let terms = List.rev (trim (List.rev terms)) in
    let ps = String.make 1 ctx.chars.Chars.ps in
    let page =
      match page with
      | None -> []
      | Some p when String.trim p = ps -> []
      | Some "" -> [ ("pageref", "no") ]
      | Some p -> [ ("page", p) ]
    in
    let terms, see =
      if List.mem_assoc "ref" o then (
        match List.rev terms with
        | r :: (_ :: _ as l) -> (List.rev l, [ ("see", r) ])
        | _ ->
            Ctx.error ctx ".pi ref: at least two terms expected";
            (terms, []))
      else (terms, [])
    in
    if terms = [] then Ctx.error ctx ".pi: index term expected"
    else
      emit ctx "pi" ~brk:false
        (List.mapi (fun i t -> (Printf.sprintf "t%d" (i + 1), t)) terms
        @ List.filter (fun (k, _) -> k.[0] = 'k') o
        @ List.filter (fun (k, _) -> k <> "ref" && k.[0] <> 'k') o
        @ see @ page)

(* .ix [n] [name | control | /] (SH20-9161-3 p.291, SH35-0069 p.213):
   the index of the .pi entries made so far (since the last .ix) goes
   here: the hint gml:ix, where resolve.xsl puts it.  title= the name
   (none: the backend's default, DCF's "INDEX"); "/" is title=""; a
   control word (a leading control word indicator) is processed here
   instead of the heading, and the hint has title="". *)
let index ctx ops =
  let n, rest = first_word ops in
  let reserve, rest =
    match int_of_string_opt n with
    | Some _ -> ([ ("reserve", n) ], rest)
    | None -> ([], String.trim ops)
  in
  let title =
    if rest = "" then []
    else if rest = "/" then [ ("title", "") ]
    else if rest.[0] = ctx.chars.Chars.cw_ind then begin
      ctx.process ctx (Ctx.Split ctx.line_substituted) rest;
      [ ("title", "") ]
    end
    else [ ("title", rest) ]
  in
  emit ctx "ix" ~brk:true (reserve @ title)

(* ---- implicit words ------------------------------------------------------------ *)

let break_ ctx _ = emit ctx "br" ~brk:true []
let blank_line ctx _ = emit ctx "sp" ~brk:true [ ("n", "1"); ("unit", "line") ]
let null_line ctx _ = Doc.cancel_continuation (doc ctx)

let device word ctx _ =
  Ctx.warn_once ctx ("device-" ^ word) "ignored device control word .%s" word

(* ---- the table ------------------------------------------------------------------- *)

type brk = Yes | No | Varies | Not_a_hint

type row = {
  name : string;
  brk : brk;
  grammar : string;
  run : Ctx.t -> string -> unit;
}

let row name brk grammar run = { name; brk; grammar; run }

let table =
  [
    row "br" Yes "" break_;
    row "lb" Yes "(leading blank)" break_;
    row "lt" Yes "(leading tab)" break_;
    row "bl" Yes "(blank line)" blank_line;
    row "nl" Not_a_hint "(null line)" null_line;
    row "sp" Yes "[v] [a]" (space "sp");
    row "sk" Yes "[v] [a|c]" (space "sk");
    row "ce" Yes "[n|on|off|text]" (counted ~brk:true "ce");
    row "ri" Yes "[n|on|off|text]" (counted ~brk:true "ri");
    row "us" No "[n|on|off|text]" (counted ~brk:false "us");
    row "up" No "[n|on|off|text]" (counted ~brk:false "up");
    row "uc" No "[n|on|off|text]" (counted ~brk:false "uc");
    row "in" Varies "[h] [after v] [for v] [nobreak]" (indent left_side);
    row "ir" Varies "[h] [after v] [for v] [nobreak]" (indent right_side);
    row "il" Yes "h" (one_line "il" 1);
    row "un" Yes "h" (one_line "un" (-1));
    row "of" Yes "[h]" offset;
    row "ll" Yes "[h]" line_length;
    row "fo" Yes "[on|off|left|right|center|inside|outside] [extend|fold|trunc]"
      (format false);
    row "nf" Yes "[on|off|left|right|center|inside|outside] [extend|fold|trunc]"
      (format true);
    row "ju" Yes "[on|off]" justify;
    row "pa" Varies "[n|odd|even|nostart|nobreak] [on|off]" page;
    row "cp" Yes "[v]" (conditional_eject "cp");
    row "cc" Yes "[v]" (conditional_eject "cc");
    row "cb" Yes "" (generic "cb" ~brk:true);
    row "bx" Yes "[off|can|new|set|add|char] positions" box;
    row "hr" Yes "rule spec" (generic "hr" ~brk:true);
    row "vr" No "rule spec" (generic "vr" ~brk:false);
    row "kp" Varies "on|off|float|delay|inline|v[+v]" keep;
    row "fn" No "on|off|leader" footnote;
    row "rh" No "[odd|even] on|off|cancel|sup|res|execute" (running "rh");
    row "rf" No "[odd|even] on|off|cancel|sup|res|execute" (running "rf");
    row "h0" Yes "text" (heading 0);
    row "h1" Yes "text" (heading 1);
    row "h2" Yes "text" (heading 2);
    row "h3" Yes "text" (heading 3);
    row "h4" Yes "text" (heading 4);
    row "h5" Yes "text" (heading 5);
    row "h6" Yes "text" (heading 6);
    row "dh" No "n options" define_head;
    row "tc" Yes "[n] [title|/]" toc;
    row "pt" No "text | .xx line" put_toc;
    row "sx" Yes "[f] [c] /left/fill/right/" split_text;
    row "tp" No "[add|del|set] stops" (tabs "tp");
    row "tb" No "[add|del|set] stops" (tabs "tb");
    row "bf" No "font... [=]" begin_font;
    row "pf" No "" previous_font;
    row "df" No "name spec" define_font;
    row "hy" No "[on|off] [options]" hyphenate;
    row "hw" No "word" (fun ctx ops ->
        emit ctx "hw" ~brk:false [ ("word", String.trim ops) ]);
    row "rc" No "n [on|off|c] | adjust h | * c" revision;
    row "bc" No "on|off" (generic ~read:plain "bc" ~brk:false);
    row "fl" No "on|off|dump ..." (generic ~read:plain "fl" ~brk:false);
    row "ls" No "[v] | normal v | by f | skip|space|text f [f]"
      (generic ~read:line_spacing "ls" ~brk:false);
    row "sb" No "[v]" (generic ~read:vertical "sb" ~brk:false);
    row "ws" No "normal h | by f" (generic ~read:word_spacing "ws" ~brk:false);
    row "es" No "normal h | by f" (generic ~read:word_spacing "es" ~brk:false);
    row "wz" No "on|off" (generic ~read:plain "wz" ~brk:false);
    row "is" No "[to] h [blank|break|absolute]" (generic "is" ~brk:false);
    row "ic" No "..." (generic "ic" ~brk:false);
    row "ud" No "on|off|rule v" (generic ~read:vertical "ud" ~brk:false);
    row "dr" No "name spec" (generic "dr" ~brk:false);
    row "pn" No "on|off|offno|roman|arabic|alpha|... | n | pref x"
      (generic ~read:plain "pn" ~brk:false);
    row "pl" No "[v]" (generic ~read:vertical "pl" ~brk:false);
    row "pw" No "[h]" (generic "pw" ~brk:false);
    row "pm" No "[nobind] h [h]" (generic "pm" ~brk:false);
    row "tm" No "[v]" (generic ~read:vertical "tm" ~brk:false);
    row "bm" No "[v]" (generic ~read:vertical "bm" ~brk:false);
    row "cl" Yes "[h]" (generic "cl" ~brk:true);
    row "cd" Yes "n positions" (generic ~read:columns "cd" ~brk:true);
    row "sc" Yes "" (generic "sc" ~brk:true);
    row "mc" Yes "" (generic "mc" ~brk:true);
    row "tr" Not_a_hint "pairs of c|hh" translate;
    row "dv" Not_a_hint "name [font f] [baseline b] [text] /string" define_variable;
    row "sa" No "[envname]" save_env;
    row "re" No "[envname]" restore_env;
    row "fv" No "top|bottom|center|justify"
      (generic ~read:plain "fv" ~brk:false);
    row "pi" No "[start|end|order|ref] [key /k1/k2/k3/] /t1[/t2[/t3[/page]]]"
      put_index;
    row "ix" Yes "[n] [name|control|/]" index;
  ]
  @ List.map
      (fun w -> row w Not_a_hint "(ignored)" (device w))
      [ "dd"; "it"; "sv"; "dl"; "uw"; "oc"; "sy"; "te"; "lo" ]

let install ctx = List.iter (fun r -> Ctx.register ctx r.name r.run) table

(** The native implicit words, for [Interp]. *)
let implicit ctx w line = (List.find (fun r -> r.name = w) table).run ctx line
