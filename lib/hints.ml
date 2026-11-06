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
     symbol.  [.li] (literal mode) is input processing ([Interp]).
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
   | .h0-.h6     | yes   | text                             | element gml:h level                       |
   | .dh         | no    | n options                        | dh level spec                             |
   | .tc         | yes   | [n] [title|/]                    | tc [reserve] [title]                      |
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
   | .dv         | -     | name [text|font f] /string       | (symbol)                                  |

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

let emit ctx name ~brk attrs = Doc.hint (doc ctx) name (attrs @ [ ("break", yn brk) ])

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
        let r, lead = match lead with r :: l -> (r, l) | [] -> (mode, []) in
        let w' = match r with Dim a -> norm a w | Plain -> w in
        go mode lead (w' :: acc) rest)
  in
  String.concat " " (go start lead [] (tokens ops))

let spec axis ops = read_spec (Dim axis) ops

let push_text ctx text =
  ignore
    (Input.push_residual ctx.input text ctx.loc { Input.had_text = false; eol = true })

(* ---- line scopes ------------------------------------------------------------ *)

let scope ?(next = []) ~word ~n ~brk attrs remaining =
  { Doc.word; first = (("n", n) :: attrs) @ [ ("break", yn brk) ];
    rest = ("cont", "yes") :: attrs; remaining; started = false; next }

(* [n|on|off|text]: no operand is one line; 0 or OFF ends the scope. *)
let counted ?(attrs = []) ~brk word ctx ops =
  let open_n n = Doc.open_scope (doc ctx) (scope ~word ~n:(string_of_int n) ~brk attrs (Some n)) in
  match lc (String.trim ops) with
  | "" -> open_n 1
  | "on" -> Doc.open_scope (doc ctx) (scope ~word ~n:"on" ~brk attrs None)
  | "off" -> ignore (Doc.close_scope (doc ctx) word)
  | s -> (
    match int_of_string_opt s with
    | Some 0 -> ignore (Doc.close_scope (doc ctx) word)
    | Some n when n > 0 -> open_n n
    | _ -> open_n 1; push_text ctx ops)

(* ---- indention ----------------------------------------------------------- *)

type side = { word : string; attr : string;
              get : Ctx.fmt -> Units.sum; set : Ctx.fmt -> Units.sum -> unit }

let left_side = { word = "in"; attr = "left"; get = (fun f -> f.left); set = (fun f v -> f.left <- v) }
let right_side = { word = "ir"; attr = "right"; get = (fun f -> f.right); set = (fun f v -> f.right <- v) }

let delta (o : Units.operand) sum =
  match o.sign with
  | None -> []
  | Some _ ->
    let u = match sum with [ (u, _) ] -> u | _ -> "" in
    [ ("delta", Units.show_operand o ^ (if o.value.unit = u then "" else o.value.unit)) ]

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
    let opt s k = match s with None -> k None | Some s -> dim ctx cw Units.Vertical s (fun o -> k (Some o)) in
    dim ctx cw Units.Horizontal (Option.value v ~default:"0") (fun o ->
        opt a (fun after ->
            opt f (fun for_ ->
                let st = fmt ctx in
                let perm = side.get st in
                let vattrs sum = Units.attrs ~default:"ch" side.attr sum in
                let after_n = Option.bind after Units.lines and for_n = Option.bind for_ Units.lines in
                let uncounted name = function
                  | Some o when Units.lines o = None -> amount_attrs o |> List.map (fun (k, x) -> ((if k = "n" then name else name ^ "-unit"), x))
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
                  emit ctx cw ~brk (vattrs now @ delta o now @ of_end @ uncounted "after" after);
                  Option.iter
                    (fun n ->
                       Doc.open_scope (doc ctx)
                         (scope ~word:cw ~n:(string_of_int n) ~brk:false
                            (("after", "yes") :: vattrs perm) (Some n)))
                    after_n
                | Some _ -> (
                  let temp = Units.add perm o.value.unit (Units.signed o) in
                  let tattrs = vattrs temp @ delta o temp in
                  match for_n with
                  | Some n ->
                    let s_for = scope ~word:cw ~n:(string_of_int n) ~brk:(brk && after_n = None) tattrs (Some n) in
                    (match after_n with
                     | Some a ->
                       Doc.open_scope (doc ctx)
                         (scope ~next:[ s_for ] ~word:cw ~n:(string_of_int a) ~brk
                            (("after", "yes") :: vattrs perm) (Some a))
                     | None -> Doc.open_scope (doc ctx) s_for)
                  | None ->
                    emit ctx cw ~brk
                      (tattrs @ uncounted "for" for_ @ uncounted "after" after
                       @ [ ("temporary", "yes") ])))))

(* .il h / .un h: the next line only, moved right / left (p.80). *)
let one_line word sign ctx ops =
  dim ctx word Units.Horizontal (if String.trim ops = "" then "0" else ops) (fun o ->
      let st = fmt ctx in
      let h = Units.signed o * sign in
      let sum = Units.add st.left o.value.unit h in
      Doc.open_scope (doc ctx)
        (scope ~word ~n:"1" ~brk:true (Units.attrs ~default:"ch" "left" sum) (Some 1)))

(* .of [h] (p.84) and .ll [h] (p.122). *)
let offset ctx ops =
  let st = fmt ctx in
  dim ctx "of" Units.Horizontal (if String.trim ops = "" then "0" else ops) (fun o ->
      let now = Units.apply st.offset o in
      st.offset <- now;
      emit ctx "of" ~brk:true (Units.attrs ~default:"ch" "offset" now @ delta o now))

let line_length ctx ops =
  let st = fmt ctx in
  if String.trim ops = "" then begin
    st.ll <- None;
    emit ctx "ll" ~brk:true [ ("length", "default") ]
  end
  else
    dim ctx "ll" Units.Horizontal ops (fun o ->
        match o.sign, st.ll with
        | Some _, None ->
          (* relative to the device default: left as a change *)
          emit ctx "ll" ~brk:true [ ("length", "default"); ("delta", Units.show_operand o ^ o.value.unit) ]
        | _ ->
          let now = Units.apply (Option.value st.ll ~default:Units.zero) o in
          st.ll <- Some now;
          emit ctx "ll" ~brk:true (Units.attrs ~default:"ch" "length" now @ delta o now))

(* ---- format mode ----------------------------------------------------------- *)

let mode_attrs st =
  [ ("fill", yn st.fill); ("align", st.align); ("overdraw", st.overdraw) ]

let aligns = [ "left"; "right"; "center"; "inside"; "outside" ]

(* .fo and .nf (p.71-76): [nf] is true for .nf. *)
let format nf ctx ops =
  let st = fmt ctx in
  let cw = if nf then "nf" else "fo" in
  let ws = List.map lc (tokens ops) in
  let ws = if List.exists (fun w -> w = "on" || w = "off" || List.mem w aligns) ws then ws else "on" :: ws in
  let ok =
    List.for_all
      (fun w ->
         match w with
         | "on" -> st.fill <- not nf; st.align <- (if nf then "left" else "justify"); true
         | "off" -> st.fill <- nf; st.align <- (if nf then "justify" else "left"); true
         | a when List.mem a aligns -> st.fill <- not nf; st.align <- a; true
         | "extend" | "fold" | "trunc" | "truncate" ->
           st.overdraw <- (if w = "truncate" then "trunc" else w); true
         | _ -> Ctx.error ctx ".%s: unknown operand %s" cw w; false)
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
  let flags, amounts = List.partition (fun w -> List.mem (lc w) [ "a"; "c" ]) ws in
  let fl = List.map (fun w -> if lc w = "a" then ("absolute", "yes") else ("conditional", "yes")) flags in
  match amounts with
  | [] -> emit ctx word ~brk:true ([ ("n", "1"); ("unit", "line") ] @ fl)
  | [ a ] -> dim ctx word Units.Vertical a (fun o -> emit ctx word ~brk:true (amount_attrs o @ fl))
  | _ -> Ctx.error ctx ".%s: one amount expected" word

let conditional_eject word ctx ops =
  match tokens ops with
  | [] -> emit ctx word ~brk:true []
  | [ a ] -> dim ctx word Units.Vertical a (fun o -> emit ctx word ~brk:true (amount_attrs o))
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
  | [ ("off" | "float" | "delay") as m ] -> emit ctx "kp" ~brk:true [ ("mode", m) ]
  | [ "inline" ] -> emit ctx "kp" ~brk:false [ ("mode", "inline") ]
  | _ ->
    (* .kp v / .kp v + v: an inline keep of that depth, no break (p.198) *)
    emit ctx "kp" ~brk:false [ ("mode", "inline"); ("depth", spec Units.Vertical ops) ]

(* ---- generic ---------------------------------------------------------------- *)

let generic ?(read = spec Units.Horizontal) word ~brk ctx ops =
  emit ctx word ~brk (if String.trim ops = "" then [] else [ ("spec", read ops) ])

let vertical = spec Units.Vertical
let plain = read_spec Plain
let factors = [ ("by", Plain); ("skip", Plain); ("space", Plain); ("text", Plain) ]
let line_spacing = read_spec (Dim Units.Vertical) ~after:(("normal", Dim Units.Vertical) :: factors)
let word_spacing = read_spec (Dim Units.Horizontal) ~after:[ ("normal", Dim Units.Horizontal); ("by", Plain) ]
let columns = read_spec ~lead:[ Plain ] (Dim Units.Horizontal)

let box ctx ops =
  match tokens ops with
  | [] -> emit ctx "bx" ~brk:true [ ("action", "line") ]
  | w :: rest when List.mem (lc w) [ "off"; "can"; "new"; "set"; "add"; "char" ] ->
    emit ctx "bx" ~brk:true
      (("action", lc w) :: (if rest = [] then [] else [ ("spec", spec Units.Horizontal (String.concat " " rest)) ]))
  | _ -> emit ctx "bx" ~brk:true [ ("action", "on"); ("spec", spec Units.Horizontal ops) ]

let tabs word ctx ops =
  match tokens ops with
  | [] -> emit ctx word ~brk:false [ ("action", "reset") ]
  | w :: rest when List.mem (lc w) [ "add"; "del"; "set" ] ->
    emit ctx word ~brk:false [ ("action", lc w); ("stops", spec Units.Horizontal (String.concat " " rest)) ]
  | _ -> emit ctx word ~brk:false [ ("action", "set"); ("stops", spec Units.Horizontal ops) ]

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
    (match st.fonts with f :: _ -> [ ("font", f) ] | [] -> [ ("initial", "yes") ])

let first_word s =
  let s = String.trim s in
  match String.index_opt s ' ' with
  | None -> (s, "")
  | Some i -> (String.sub s 0 i, String.trim (String.sub s i (String.length s - i)))

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
     @ (if opts = [] then [] else [ ("options", String.concat " " opts) ]))

(* ---- headings, toc, split text ---------------------------------------------- *)

let heading n ctx ops =
  let d = doc ctx in
  Doc.start_element ~eol:true d "gml:h" [ ("level", string_of_int n); ("break", "yes") ];
  if String.trim ops = "" then ignore (Doc.end_element d "gml:h") else push_text ctx ops

let define_head ctx ops =
  match first_word ops with
  | "", _ -> Ctx.error ctx ".dh: head level expected"
  | n, rest -> emit ctx "dh" ~brk:false [ ("level", n); ("spec", rest) ]

let toc ctx ops =
  let n, rest = first_word ops in
  let reserve, title =
    match int_of_string_opt n with Some _ -> ([ ("reserve", n) ], rest) | None -> ([], String.trim ops)
  in
  emit ctx "tc" ~brk:true
    (reserve @ (if title = "" then [] else if title = "/" then [ ("title", "") ] else [ ("title", title) ]))

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
    | l :: f :: r :: _ -> emit ctx "sx" ~brk:true ([ ("left", l); ("fill", f); ("right", r) ] @ fl)
    | _ -> Ctx.error ctx ".sx: three delimited fields expected"

(* ---- footnotes, running headings ----------------------------------------------- *)

let close_flow ctx name =
  match Doc.end_element ~force:true (doc ctx) name with
  | Doc.Closed forced ->
    List.iter (fun n -> Ctx.warn ctx "element %s implicitly closed by .%s off" n
                  (String.sub name 4 2)) forced
  | Doc.Not_open -> Ctx.warn ctx ".%s off: no definition in progress" (String.sub name 4 2)
  | Doc.Mismatch _ -> ()

let footnote ctx ops =
  match List.map lc (tokens ops) with
  | [] | [ "on" ] -> Doc.start_element (doc ctx) "gml:fn" []
  | [ "leader" ] -> Doc.start_element (doc ctx) "gml:fn" [ ("kind", "leader") ]
  | [ "off" ] -> close_flow ctx "gml:fn"
  | _ -> Ctx.error ctx ".fn: ON, OFF or LEADER expected"

let running word ctx ops =
  let name = "gml:" ^ word in
  match List.map lc (tokens ops) with
  | [ "off" ] -> close_flow ctx name
  | [ ("cancel" | "sup" | "res" | "execute") as a ] -> emit ctx word ~brk:false [ ("action", a) ]
  | [] | [ "on" ] -> Doc.start_element (doc ctx) name []
  | [ ("odd" | "even") as p ] | [ ("odd" | "even") as p; "on" ] ->
    Doc.start_element (doc ctx) name [ ("page", p) ]
  | _ -> Ctx.error ctx ".%s: [ODD|EVEN] ON, OFF, CANCEL, SUP, RES or EXECUTE expected" word

(* ---- revision codes ------------------------------------------------------------ *)

let revision ctx ops =
  match tokens ops with
  | "*" :: c :: _ -> Doc.open_scope (doc ctx) (scope ~word:"rc" ~n:"1" ~brk:false [ ("char", c) ] (Some 1))
  | w :: rest when lc w = "adjust" ->
    emit ctx "rc" ~brk:false [ ("adjust", spec Units.Horizontal (String.concat " " rest)) ]
  | [ n ] -> emit ctx "rc" ~brk:false [ ("code", n); ("char", " ") ]
  | [ n; m ] when lc m = "on" || lc m = "off" -> emit ctx "rc" ~brk:false [ ("code", n); ("mode", lc m) ]
  | [ n; c ] -> emit ctx "rc" ~brk:false [ ("code", n); ("char", c) ]
  | _ -> Ctx.error ctx ".rc: invalid operands %s" ops

(* ---- .tr and .dv --------------------------------------------------------------- *)

(* A character operand: itself, or two hexadecimal digits, taken as the
   code point U+00hh (modern edge: the manual's codes are EBCDIC). *)
let char_operand s =
  if String.length s = 1 then Some (`Char s.[0])
  else if String.length s = 2 then
    Option.map (fun c -> `Code c) (int_of_string_opt ("0x" ^ s))
  else None

let utf8 c =
  let b = Buffer.create 2 in
  Buffer.add_utf_8_uchar b (Uchar.of_int c);
  Buffer.contents b

(* .tr [c1 c2 ...]: no operands resets the table; an odd last character
   translates to a blank (DCF-VERIFY). *)
let translate ctx ops =
  let tbl = (doc ctx).Doc.tr in
  let dst_of = function
    | None -> Some " "
    | Some b ->
      Option.map (function `Char c -> String.make 1 c | `Code c -> utf8 c) (char_operand b)
  in
  let rec go = function
    | [] -> ()
    | a :: rest -> (
      let b, rest = match rest with b :: r -> (Some b, r) | [] -> (None, []) in
      match char_operand a, dst_of b with
      | Some src, Some dst ->
        let src = match src with `Char c -> c | `Code c -> Char.chr (c land 0xFF) in
        if dst = String.make 1 src then Hashtbl.remove tbl src else Hashtbl.replace tbl src dst;
        go rest
      | _ -> Ctx.error ctx ".tr: invalid character %s" (String.concat " " (a :: Option.to_list b)))
  in
  match Control.words ops with
  | [] -> Hashtbl.reset tbl
  | ws -> go ws

(* .dv name [text | font f] /string (p.258): the symbol gets the
   string.  DCF-VERIFY: the font is ignored; the value is not protected
   from being read again as markup. *)
let define_variable ctx ops =
  let name, rest = first_word ops in
  if name = "" then Ctx.error ctx ".dv: symbol name expected"
  else
    let rest =
      let w, r = first_word rest in
      match lc w with
      | "text" -> r
      | "font" ->
        Ctx.warn_once ctx "dv-font" ".dv: the font of a defined variable is ignored";
        snd (first_word r)
      | _ -> rest
    in
    if rest = "" then Ctx.error ctx ".dv %s: /string expected" name
    else
      let v = String.sub rest 1 (String.length rest - 1) in
      Control.check_name ctx ".dv" name (fun () ->
          match Symbols.set ctx.syms name v with
          | Ok () -> ()
          | Error e -> Ctx.error ctx ".dv: %s" e)

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
  [ row "br" Yes "" break_;
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
    row "fo" Yes "[on|off|left|right|center|inside|outside] [extend|fold|trunc]" (format false);
    row "nf" Yes "[on|off|left|right|center|inside|outside] [extend|fold|trunc]" (format true);
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
    row "sx" Yes "[f] [c] /left/fill/right/" split_text;
    row "tp" No "[add|del|set] stops" (tabs "tp");
    row "tb" No "[add|del|set] stops" (tabs "tb");
    row "bf" No "font... [=]" begin_font;
    row "pf" No "" previous_font;
    row "df" No "name spec" define_font;
    row "hy" No "[on|off] [options]" hyphenate;
    row "hw" No "word" (fun ctx ops -> emit ctx "hw" ~brk:false [ ("word", String.trim ops) ]);
    row "rc" No "n [on|off|c] | adjust h | * c" revision;
    row "bc" No "on|off" (generic ~read:plain "bc" ~brk:false);
    row "fl" No "on|off|dump ..." (generic ~read:plain "fl" ~brk:false);
    row "ls" No "[v] | normal v | by f | skip|space|text f [f]" (generic ~read:line_spacing "ls" ~brk:false);
    row "sb" No "[v]" (generic ~read:vertical "sb" ~brk:false);
    row "ws" No "normal h | by f" (generic ~read:word_spacing "ws" ~brk:false);
    row "es" No "normal h | by f" (generic ~read:word_spacing "es" ~brk:false);
    row "wz" No "on|off" (generic ~read:plain "wz" ~brk:false);
    row "is" No "[to] h [blank|break|absolute]" (generic "is" ~brk:false);
    row "ic" No "..." (generic "ic" ~brk:false);
    row "ud" No "on|off|rule v" (generic ~read:vertical "ud" ~brk:false);
    row "dr" No "name spec" (generic "dr" ~brk:false);
    row "pn" No "on|off|offno|roman|arabic|alpha|... | n | pref x" (generic ~read:plain "pn" ~brk:false);
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
    row "dv" Not_a_hint "name [text|font f] /string" define_variable ]
  @ List.map (fun w -> row w Not_a_hint "(ignored)" (device w))
    [ "dd"; "it"; "sv"; "dl"; "uw"; "oc"; "sy"; "te"; "lo" ]

let install ctx = List.iter (fun r -> Ctx.register ctx r.name r.run) table

(** The native implicit words, for [Interp]. *)
let implicit ctx w line = (List.find (fun r -> r.name = w) table).run ctx line
