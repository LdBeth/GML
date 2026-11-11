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
     The column below follows the Language Reference (SH35-0070-07,
     "LR"): Table 13 "Control Words That Cause a Break" (LR p.441) and
     the Notes of each entry.
   - Dimensions are normalised by [Units] into [n="2.5" unit="i"] (lists
     of positions into tokens such as ["1ch 45ch"]); nothing is
     converted to device units.
   - Words that count input lines ([.ce n], [.ri n], [.us n], [.up n],
     [.uc n], [.rc * c]) do not leave the counting to the backends: the
     text of the lines they cover is wrapped in a
     [<gml:lines word="ce" n="2" ...>] scope ([Doc.scope]) carrying the
     state that applies inside it.  The operand forms are a number of
     lines, ON ... OFF (n="on"), or text on the control word line itself
     (one covered line).  Words that count OUTPUT lines are hints only:
     the FOR/AFTER distances of [.in]/[.ir] (LR p.210-211, counted from
     the first nonblank text line) and the next output line of [.il]/
     [.un] are measured by the backend that makes the lines (gml.tex).
   - [.h0]-[.h6] give an element [<gml:h level="n">text</gml:h>].
     [.fn on/off] and [.rh]/[.rf] definitions give elements too
     ([gml:fn], [gml:rh], [gml:rf]): they hold text of another flow.
     Rel 4: symbols in a running heading or footing are replaced when it
     is placed on the page, substitution being off while it is defined
     (LR p.312 r7, p.315 r7, p.316: "the value of the symbol at the time
     the page is started").  The definition is processed where it is
     defined, but a reference to a global user symbol in its text (a
     text line, the line of [.ce .ri .us .up .uc], a [.sx] field) is
     deferred ([Subst.deferred], [Doc.symref]): the element
     [<gml:symref name="NAME">value now</gml:symref>] (in a [.sx] field
     the value between U+E001 NAME U+E002 and U+E003), and wherever a
     symbol so referred to is set or removed afterwards the hint
     [<gml:symval name="NAME" value="..." break="no"/>] ([Ctx]) gives
     its new value at that point of the flow (as written, [&NAME], when
     removed).  The backend that places the heading uses the value in
     effect where the page starts, the value inside gml:symref before
     any change.  Other operands (.if .se .sk ...) take the value now.
     Its text is translated with the initial [.tr] table as changed
     inside it (LR p.404 r4, [Doc.tr_table]).
   - [.tr] (p.207) is not a hint: it sets the translate table that
     [Doc] applies to text entering the tree.  [.dv] (p.258) sets a
     symbol to a text variable, the hint [gml:dv] where it is used.  [.li] (literal mode) is input processing ([Interp]).
   - Words with no typesetting meaning (system, terminal, spelling
     words) are warned about once: "ignored device control word .xx".

   The table ([table], at the end) has one row per control word: its
   name, whether it breaks, its operand grammar, the nodes it puts in
   the tree (the last column below, declared in [N]: a state hint with
   the properties it sets, [P]) and the builder.

   | Word        | Break | Operands                         | Hint / attributes                         |
   |-------------|-------|----------------------------------|-------------------------------------------|
   | .br         | yes   |                                  | br                                        |
   | .lb .lt     | yes   | (implicit leading blank/tab)     | br                                        |
   | .bl         | yes   | (implicit blank line)            | sp n="1" unit="line"                      |
   | .nl         | -     | (implicit null line)             | none: cancels a continuation              |
   | .sp .sk     | yes   | [v] [a] [c]                      | sp/sk n unit [absolute] [conditional]     |
   | .ce .ri     | yes   | [n|on|off|text]                  | gml:lines word n                          |
   | .us .up .uc | no    | [n|on|off|text]                  | gml:lines word n                          |
   | .in .ir     | yes*  | [h] [[for] v1] [[after] v2] [nobreak] | in left/ir right unit [delta] [offset="0"] [temporary="yes" for for-unit] [after after-unit] |
   | .il .un     | yes   | h                                | il/un shift unit (signed, right positive) |
   | .of         | yes   | [h]                              | of offset unit [delta]                    |
   | .ll         | yes   | [h]                              | ll length unit [delta] | length="default" |
   | .fo         | yes   | [on|off|left|right|center|inside|outside] [extend|fold|trunc] | fo fill align overdraw |
   | .nf         | yes   | [on|off|left|...] [extend|...]   | nf fill align overdraw                    |
   | .ju         | yes   | [on|off]                         | ju fill align overdraw                    |
   | .pa         | yes   | [n|+n|-n|nostart] | odd|even [on|off] | pa [page] [side] [nostart] [mode]   |
   | .cp .cc     | yes   | [v]                              | cp/cc [n unit]                            |
   | .cb         | yes   |                                  | cb                                        |
   | .bx         | yes   | [off|can|new|set|...] positions  | bx [action] [spec]                        |
   | .hr         | yes   | [rule] h1|left [[to] h2|for l|right] ... | hr spec | repeat="yes"            |
   | .vr         | yes   | rule spec                        | vr spec                                   |
   | .kp         | yes*  | on|off|float|delay|inline|v[+v]  | kp mode [n unit]                          |
   | .fn         | no    | on|off|leader                    | element gml:fn [kind]                     |
   | .rh .rf     | yes   | [odd|even] on|off|cancel|sup|res|execute | element gml:rh/rf [page] / hint action [page] |
   | .dh         | no    | n options                        | dh level spec (NUM and TC options kept)   |
   | .tc         | yes   | [n] [title|/]                    | tc action=begin|end [reserve]; gml:h title; tcentry per entry |
   | .pt         | -     | text | .xx line                  | tcmark anchor (a .pt text line)           |
   | .h0-.h6     | yes   | text                             | gml:h element; tcmark anchor (TC levels)  |
   | .sx         | yes   | [f] [c] /left/fill/right/        | sx left fill right [fold] [center]        |
   | .tp .tb     | yes   | [add|del|clr|delete|set] stops   | tp/tb [action] stops                      |
   | .bf         | no    | [font...] [=]                    | bf font [restart]                         |
   | .pf         | no    |                                  | pf font | initial="yes"                   |
   | .df         | no    | name spec                        | df name spec                              |
   | .hy         | no    | [on|off] [options]               | hy [mode] [options]                       |
   | .hw         | no    | word                             | hw word                                   |
   | .rc         | no    | n [on|off|c], adjust h, * c      | rc code [mode] [char] / gml:lines word="rc"|
   | .bc         | no    | on|off                           | bc mode                                   |
   | .ls         | yes*  | as written [nobreak]             | ls spec                                   |
   | .wz .pm     | yes   | as written                       | NAME spec                                 |
   | .sb .ws .es .is .ic .ud .pn .pl .pw .tm .bm | no | as written | NAME spec                    |
   | .cl .cd .sc .mc | yes | as written                     | NAME spec                                 |
   | .bc .fl     | no    | as written                       | NAME spec                                 |
   | .sa         | no    | [envname]                        | sa [name]                                 |
   | .re         | yes*  | [envname]                        | re [name], then the restoring hints       |
   | .tr         | -     | pairs of c|hh                    | (translate table)                         |
   | .dv         | -     | name [font f] [baseline b] /string | (symbol) dv name font baseline text (where used) |

   yes* : depends on the operands (NOBREAK, LR p.441; inline keeps,
   LR p.228; .re: whether the format mode or centring changes, p.309).
   The break column is LR Table 13 (p.441) and the Notes of the entries:
   .pa (p.276), .vr (p.423), .rh/.rf (p.314, p.310), .ls (p.237), .wz
   (p.434), .pm (p.284), .tb/.tp (p.374, p.401), .re (p.309).  [spec]
   is the operand list with each space-unit
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

(* ---- the nodes ------------------------------------------------------------------- *)

(* The properties of the formatting state that the state hints set, as
   xslt/scope.xsl scopes them, in its order (the order of the attributes
   of its gml:scope): the block properties, then the inline ones.  The
   initial values are those of [Ctx.initial_fmt] where the engine tracks
   the property (written as scope.xsl writes values: a dimension n+unit,
   zero "0"); the others start as "default", the device's. *)
module P = struct
  let f = Ctx.initial_fmt ()

  let dim s =
    match Units.attrs ~default:"" "v" s with
    | [ (_, "0"); _ ] -> "0"
    | [ (_, v); (_, "mixed") ] -> v
    | [ (_, v); (_, u) ] -> v ^ u
    | _ -> assert false

  let block prop initial = { Node.prop; tier = Node.Block; initial }
  let inline prop initial = { Node.prop; tier = Node.Inline; initial }
  let in_ = block "in" (dim f.left)
  let ir = block "ir" (dim f.right)
  let of_ = block "of" (dim f.offset)
  let ll = block "ll" (match f.ll with None -> "default" | Some l -> dim l)
  let fill = block "fill" (yn f.fill)
  let align = block "align" f.align
  let overdraw = block "overdraw" f.overdraw
  let tp = block "tp" "default"
  let tb = block "tb" "default"
  let ls = block "ls" "default"
  let wz = block "wz" "default"
  let bc = block "bc" "default"

  let font =
    inline "font"
      (match f.fonts with x :: _ when x <> "" -> x | _ -> "initial")

  let hy = inline "hy" (if f.hyph then "on" else "off")
  let ws = inline "ws" "default"
  let es = inline "es" "default"
  let sb = inline "sb" "default"
  let ud = inline "ud" "default"

  let all =
    [
      in_;
      ir;
      of_;
      ll;
      fill;
      align;
      overdraw;
      tp;
      tb;
      ls;
      wz;
      bc;
      font;
      hy;
      ws;
      es;
      sb;
      ud;
    ]
end

(* The nodes the words put out (the last column of the header table):
   the hints, events or state hints with the properties they set
   (scope.xsl), and the elements.  A hint .in/.ir for a distance
   (temporary="yes") is not state, nor is a .hy without ON or OFF. *)
module N = struct
  open Node

  let br = event "br"
  let sp = event "sp"
  let sk = event "sk"
  let in_ = state ~conditional:true "in" [ P.in_; P.of_ ]
  let ir = state ~conditional:true "ir" [ P.ir ]
  let il = event "il"
  let un = event "un"
  let of_ = state "of" [ P.of_ ]
  let ll = state "ll" [ P.ll ]
  let mode = [ P.fill; P.align; P.overdraw ]
  let fo = state "fo" mode
  let nf = state "nf" mode
  let ju = state "ju" mode
  let pa = event "pa"
  let cp = event "cp"
  let cc = event "cc"
  let cb = event "cb"
  let bx = event "bx"
  let hr = event "hr"
  let vr = event "vr"
  let kp = event "kp"
  let fn = element "fn"
  let rh_element = element "rh"
  let rf_element = element "rf"
  let rh = event "rh"
  let rf = event "rf"
  let h = element "h"
  let dh = event "dh"
  let tc = event "tc"
  let tcmark = event "tcmark"
  let tcentry = event "tcentry"
  let sx = event "sx"
  let tp = state "tp" [ P.tp ]
  let tb = state "tb" [ P.tb ]
  let bf = state "bf" [ P.font ]
  let pf = state "pf" [ P.font ]
  let df = event "df"
  let hy = state ~conditional:true "hy" [ P.hy ]
  let hw = event "hw"
  let rc = event "rc"
  let bc = state "bc" [ P.bc ]
  let fl = event "fl"
  let ls = state "ls" [ P.ls ]
  let sb = state "sb" [ P.sb ]
  let ws = state "ws" [ P.ws ]
  let es = state "es" [ P.es ]
  let wz = state "wz" [ P.wz ]
  let is = event "is"
  let ic = event "ic"
  let ud = state "ud" [ P.ud ]
  let dr = event "dr"
  let pn = event "pn"
  let pl = event "pl"
  let pw = event "pw"
  let pm = event "pm"
  let tm = event "tm"
  let bm = event "bm"
  let cl = event "cl"
  let cd = event "cd"
  let sc = event "sc"
  let mc = event "mc"
  let sa = event "sa"
  let re = event "re"
  let fv = event "fv"
  let pi = event "pi"
  let ix = event "ix"
end

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

let scope ~word ~n ~brk attrs remaining =
  {
    Doc.word;
    first = (("n", n) :: attrs) @ [ ("break", yn brk) ];
    rest = ("cont", "yes") :: attrs;
    remaining;
    started = false;
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
  set_tmp : Ctx.fmt -> Units.sum option -> unit;
}

let left_side =
  {
    word = "in";
    attr = "left";
    get = (fun f -> f.left);
    set = (fun f v -> f.left <- v);
    set_tmp = (fun f v -> f.left_tmp <- v);
  }

let right_side =
  {
    word = "ir";
    attr = "right";
    get = (fun f -> f.right);
    set = (fun f v -> f.right <- v);
    set_tmp = (fun f v -> f.right_tmp <- v);
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

(* .in [h] [[FOR] v1] [[AFTER] v2] [NOBREAK] (LR p.210-212): absolute
   or relative to the permanent indention.  Without FOR the number after
   h is v1, without AFTER the number after v1 is v2 (r6, r7: ".in .7i
   1" is FOR 1).  v1 omitted or * is a permanent change; 0 a temporary
   one that lasts until another .in (the hint says the margin, the
   permanent indention a relative .in starts from is unchanged; the
   engine keeps it as [left_tmp] for &$IN and .sa/.re); any
   other v1 a temporary change for that distance: the margin is the
   permanent one plus the operand (r1), and the hint says
   temporary=yes.  v2 (0 or omitted: at once) is the distance before
   the change.
   FOR and AFTER are vertical distances of output (r1, r3): the hint
   carries them as given, for and for-unit, after and after-unit (a
   number of lines is unit=line), and the backend measures them (gml.tex counts;
   html.xsl makes a float of that height).  Nothing here counts
   lines: the engine state is the permanent indention and a temporary
   one until changed (&$IN, [Ctx.margin]).
   Any .in, temporary ones too, clears all offsets ("any .IN request
   clears all offsets", LR p.260; ".in" alone cancels .in and .of,
   p.211): the hint carries offset="0".  .ir does not (p.260 speaks of
   .IN only). *)
type duration = Permanent | Until_changed | For of Units.operand

let distance name = function
  | Some (o : Units.operand) ->
      [ (name, Units.show_operand o); (name ^ "-unit", o.value.unit) ]
  | None -> []

let indent side ctx ops =
  let cw = side.word in
  let kw w = List.mem (lc w) [ "for"; "after"; "nobreak" ] in
  let rec parse h v1 v2 nb = function
    | [] -> Ok (h, v1, v2, nb)
    | w :: rest when lc w = "nobreak" -> parse h v1 v2 true rest
    | w :: x :: rest when lc w = "for" && not (kw x) ->
        parse h (Some x) v2 nb rest
    | w :: x :: rest when lc w = "after" && not (kw x) ->
        parse h v1 (Some x) nb rest
    (* FOR or AFTER without its value: the defaults, permanent and at once *)
    | w :: rest when lc w = "for" -> parse h (Some "*") v2 nb rest
    | w :: rest when lc w = "after" -> parse h v1 (Some "0") nb rest
    | w :: rest when h = None && v1 = None && v2 = None ->
        parse (Some w) v1 v2 nb rest
    | w :: rest when v1 = None -> parse h (Some w) v2 nb rest
    | w :: rest when v2 = None -> parse h v1 (Some w) nb rest
    | w :: _ -> Error w
  in
  match parse None None None false (tokens ops) with
  | Error w -> Ctx.error ctx ".%s: unexpected operand %s" cw w
  | Ok (h, v1, v2, nb) ->
      let duration k =
        match v1 with
        | None | Some "*" -> k Permanent
        | Some s ->
            dim ctx cw Units.Vertical s (fun o ->
                k (if o.value.h = 0 then Until_changed else For o))
      in
      let after k =
        match v2 with
        | None -> k None
        | Some s ->
            dim ctx cw Units.Vertical s (fun o ->
                k (if o.value.h = 0 then None else Some o))
      in
      dim ctx cw Units.Horizontal (Option.value h ~default:"0") (fun o ->
          duration (fun dur ->
              after (fun after ->
                  let st = fmt ctx in
                  let perm = side.get st in
                  let margin, temp =
                    match dur with
                    | Permanent ->
                        let now = Units.apply perm o in
                        side.set st now;
                        side.set_tmp st None;
                        (now, [])
                    | Until_changed ->
                        let now =
                          Units.add perm o.value.unit (Units.signed o)
                        in
                        side.set_tmp st (Some now);
                        (now, [])
                    | For f ->
                        ( Units.add perm o.value.unit (Units.signed o),
                          ("temporary", "yes") :: distance "for" (Some f) )
                  in
                  let of_end =
                    if cw = "in" && st.offset <> Units.zero then begin
                      st.offset <- Units.zero;
                      [ ("offset", "0") ]
                    end
                    else []
                  in
                  emit ctx cw ~brk:(not nb)
                    (Units.attrs ~default:"ch" side.attr margin
                    @ delta o margin @ of_end @ temp @ distance "after" after))))

(* .il h / .un h: the next output line only, shifted "from the current
   margin (which includes any indent or offset values in effect)" (LR
   p.206 r1; p.416 r2): +h or h to the right and -h to the left for .il,
   the reverse for .un (r3: .un 5 = .il -5).  A sign is a direction,
   not an increment: successive ones without text, the last counts (r5;
   p.416 r3).  The hint il/un carries shift (signed, to the right) and
   unit; the backend adds the margin of that line, which only it knows
   (FOR/AFTER, .of), and finds the line: the next text, skip or space
   line triggers the word (p.206 r7, p.416 r4). *)
let one_line word sign ctx ops =
  dim ctx word Units.Horizontal
    (if String.trim ops = "" then "0" else ops)
    (fun o ->
      emit ctx word ~brk:true
        (Units.attrs ~default:"ch" "shift"
           (Units.add Units.zero o.value.unit (Units.signed o * sign))))

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

(* .pa [n|+n|-n|NOSTART] | .pa ODD|EVEN [ON|OFF] (LR p.276): always a
   break ("causes a break and a section break"); it has no NOBREAK
   operand. *)
let page ctx ops =
  let ws = tokens ops in
  if List.exists (fun w -> lc w = "nobreak") ws then
    Ctx.error ctx ".pa: NOBREAK is not an operand of .pa; ignored"
  else
    emit ctx "pa" ~brk:true
      (List.map
         (fun w ->
           match lc w with
           | "odd" | "even" -> ("side", lc w)
           | "nostart" -> ("nostart", "yes")
           | "on" | "off" -> ("mode", lc w)
           | _ -> ("page", w))
         ws)

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
  [
    ("by", Plain);
    ("skip", Plain);
    ("space", Plain);
    ("text", Plain);
    ("all", Plain);
  ]

(* .ls (LR p.235-237): NORMAL v, INCREMENT v and EXTRA v are vertical
   amounts, BY f and the SKIP/SPACE/TEXT/ALL ranges factors *)
let line_spacing =
  read_spec (Dim Units.Vertical)
    ~after:
      ([
         ("normal", Dim Units.Vertical);
         ("increment", Dim Units.Vertical);
         ("extra", Dim Units.Vertical);
       ]
      @ factors)

(* .ls breaks unless NOBREAK is given (LR p.237) *)
let line_spacing_word ctx ops =
  let nb = List.exists (fun w -> lc w = "nobreak") (tokens ops) in
  generic ~read:line_spacing "ls" ~brk:(not nb) ctx ops

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

(* .tb [SET|ADD|CLR|DEL] stops (LR p.374), .tp [SET|ADD|DELETE] stops
   (p.401): both break; CLR and DELETE are action="del". *)
let tabs word ctx ops =
  let action w =
    match lc w with
    | ("add" | "set" | "del") as a -> Some a
    | "clr" when word = "tb" -> Some "del"
    | "delete" when word = "tp" -> Some "del"
    | _ -> None
  in
  match tokens ops with
  | [] when word = "tp" ->
      (* .tp alone clears the tab table (LR p.400: "Default: Clears the
         tab table") *)
      emit ctx word ~brk:true [ ("action", "set"); ("stops", "") ]
  | [] -> emit ctx word ~brk:true [ ("action", "reset") ]
  | w :: rest when action w <> None ->
      emit ctx word ~brk:true
        [
          ("action", Option.get (action w));
          ("stops", spec Units.Horizontal (String.concat " " rest));
        ]
  | _ ->
      emit ctx word ~brk:true
        [ ("action", "set"); ("stops", spec Units.Horizontal ops) ]

(* .hr [rulename] LEFT|h1 [[TO] h2 | FOR length | RIGHT] ... (LR
   p.192-193): a word that is a valid space unit is a displacement (r7),
   any other word but the keywords a rule name; a rule name needs at
   least one displacement; no operands repeat the previous rule (r6:
   repeat="yes", the backend knows the rule it drew). *)
let hrule ctx ops =
  let ws = tokens ops in
  let is_unit w =
    String.exists (fun c -> c >= '0' && c <= '9') w
    && Result.is_ok (Units.parse Units.Horizontal w)
  in
  let position w = is_unit w || List.mem (lc w) [ "left"; "right" ] in
  let rule w = not (position w || List.mem (lc w) [ "to"; "for" ]) in
  if ws = [] then emit ctx "hr" ~brk:true [ ("repeat", "yes") ]
  else if List.exists rule ws && not (List.exists position ws) then
    Ctx.error ctx ".hr %s: a rule name needs a horizontal displacement"
      (String.concat " " ws)
  else emit ctx "hr" ~brk:true [ ("spec", spec Units.Horizontal ops) ]

(* ---- fonts -------------------------------------------------------------------- *)

(* .bf [font...] [=] (LR p.75-77): the first usable font of the list;
   "=" restarts the current font when none is usable, without a message
   (restart="yes": the backend keeps the font quietly).  No font (".bf",
   or ".bf &$CHAR(2)" with a null value) restarts the current font: it
   is saved for a .pf and goes on. *)
let begin_font ctx ops =
  let st = fmt ctx in
  let ws = tokens ops in
  let fonts = List.filter (( <> ) "=") ws in
  let restart = List.mem "=" ws || fonts = [] in
  let font =
    if fonts <> [] then String.concat " " fonts
    else match st.fonts with f :: _ -> f | [] -> ""
  in
  st.fonts <- font :: st.fonts;
  emit ctx "bf" ~brk:false
    ((("font", font) :: (if font = "" then [ ("initial", "yes") ] else []))
    @ if restart then [ ("restart", "yes") ] else [])

let previous_font ctx _ =
  let st = fmt ctx in
  (match st.fonts with _ :: rest -> st.fonts <- rest | [] -> ());
  emit ctx "pf" ~brk:false
    (match st.fonts with
    | f :: _ when f <> "" -> [ ("font", f) ]
    | _ -> [ ("initial", "yes") ])

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
    Option.iter
      (fun e -> emit ctx "tcmark" ~brk:false [ ("anchor", e.Toc.id) ])
      entry
  in
  if def.Toc.only then mark ()
  else begin
    Doc.start_element ~eol:true d (Node.qname N.h)
      ((("level", string_of_int n) :: num) @ [ ("break", "yes") ]);
    mark ();
    if text = "" then ignore (Doc.end_element d (Node.qname N.h))
    else push_text ctx ops
  end

(* .dh n options (LR p.136-138): kept as a hint (the backends read the
   layout options from it); NUM / NONUM (the last one given) are also
   recorded for the numbering of .hn, and the table of contents options
   (TC NTC TO NTO TS NTS DOT NODOT TCIN h TFONT f) for its entries
   ([Toc]); .dh n alone restores the level's initial definition.  The
   Rel 4 options: BR NBR PA NPA TC NTC TO NTO TS NTS UP NUP US NUS DOT
   NODOT NUM NONUM SECT NOSECT AUTOHY NOHY CENTER LEFT INSIDE OUTSIDE
   RIGHT, OJ NOJ (Rel 2: OUTSIDE, LEFT, r8), NOHANG, HANG n | HANG AUTO,
   FONT f (f may be missing when FONT is last), SKBF v, SPAF v, SPBF v,
   TCIN h, TFONT f; any other word is warned about and skipped. *)
let dh_flags =
  [
    "br";
    "nbr";
    "pa";
    "npa";
    "tc";
    "ntc";
    "to";
    "nto";
    "ts";
    "nts";
    "up";
    "nup";
    "us";
    "nus";
    "dot";
    "nodot";
    "num";
    "nonum";
    "sect";
    "nosect";
    "autohy";
    "nohy";
    "center";
    "left";
    "inside";
    "outside";
    "right";
    "oj";
    "noj";
    "nohang";
  ]

let dh_valued = [ "font"; "tfont"; "skbf"; "spaf"; "spbf"; "tcin"; "hang" ]

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
                | "num" ->
                    Hashtbl.replace ctx.dh_num l ();
                    go rest
                | "nonum" ->
                    Hashtbl.remove ctx.dh_num l;
                    go rest
                | k when List.mem k dh_flags ->
                    ignore (Toc.option ctx.toc l w ~value:None);
                    go rest
                | k when List.mem k dh_valued -> (
                    let value =
                      match rest with v :: _ -> Some v | [] -> None
                    in
                    let value =
                      if k = "tcin" then
                        Option.map (norm Units.Horizontal) value
                      else value
                    in
                    match k with
                    | "tcin" | "tfont" -> (
                        match Toc.option ctx.toc l w ~value with
                        | `Took -> go (List.tl rest)
                        | `Missing ->
                            Ctx.error ctx ".dh %d: %s: a value expected" l w
                        | `Done | `Other -> go rest)
                    | "font" when value = None -> ()
                    | _ when value = None ->
                        Ctx.error ctx ".dh %d: %s: a value expected" l w
                    | _ -> go (List.tl rest))
                | _ ->
                    Ctx.warn ctx ".dh %d: unknown option %s (ignored)" l w;
                    go rest)
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
  if ops <> "" && ops.[0] = '.' then
    ignore (Toc.add ctx.toc (Toc.Control ops) "")
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
      match Ctx.Sym.get ctx "SYSCONTENT" with
      | Some v when v <> "" -> Some v
      | _ -> Some "CONTENTS"
  in
  emit ctx "tc" ~brk:true (("action", "begin") :: reserve);
  if not d.Doc.mute then begin
    Option.iter
      (fun t ->
        Doc.start_element ~eol:true d (Node.qname N.h)
          [ ("level", "1"); ("break", "yes") ];
        Doc.text d t)
      title;
    List.iter
      (fun (e : Toc.entry) ->
        match e.kind with
        | Toc.Control line -> ctx.Ctx.process ctx (Ctx.Split true) line
        | Toc.Head _ | Toc.Line ->
            if e.skip then
              emit ctx "sk" ~brk:true [ ("n", "1"); ("unit", "line") ];
            let page =
              match e.page with
              | Some p -> Some p
              | None -> ctx.Ctx.page_of e.id
            in
            emit ctx "tcentry" ~brk:true
              ([
                 ( "level",
                   match e.kind with Toc.Head l -> string_of_int l | _ -> "pt"
                 );
                 ("text", e.text);
               ]
              @ (if e.indent = "0" then []
                 else [ ("indent", norm Units.Horizontal e.indent) ])
              @ (match e.font with Some f -> [ ("font", f) ] | None -> [])
              @ [ ("dot", yn e.dot) ]
              @
              match page with
              | Some p -> [ ("page", p) ]
              | None -> [ ("anchor", e.id) ]))
      (Toc.printable ctx.toc)
  end;
  emit ctx "tc" ~brk:true (("action", "end") :: reserve)

(* [p] without the deferred references written in it by [Doc.field_text]
   (U+E001 NAME U+E002 value U+E003) *)
let outside_symrefs p =
  let o = "\u{E001}" and c = "\u{E003}" in
  let find sub i =
    let n = String.length p and k = String.length sub in
    let rec go i =
      if i + k > n then None
      else if String.sub p i k = sub then Some i
      else go (i + 1)
    in
    go i
  in
  let b = Buffer.create (String.length p) in
  let rec go i =
    match find o i with
    | None -> Buffer.add_string b (String.sub p i (String.length p - i))
    | Some j -> (
        Buffer.add_string b (String.sub p i (j - i));
        match find c j with Some e -> go (e + String.length c) | None -> ())
  in
  go 0;
  Buffer.contents b

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
    match Line.split_on d (String.sub s 1 (String.length s - 1)) with
    | l :: f :: r :: _ ->
        (* in a running heading or footing the page number symbol stands for
           the page number (SH35-0069 p.128: ".sx c //Introduction/Page &/");
           pagesym= tells the backends which character it is *)
        let ps = ctx.chars.Chars.ps in
        (* a deferred reference (Doc.symref) is written U+E001 NAME U+E002
           value U+E003 *)
        let out = Doc.field_text (doc ctx) in
        if
          Doc.in_running (doc ctx)
          && List.exists (fun f -> Line.index_sep f 0 ps <> None) [ l; f; r ]
        then begin
          (* the fields are put out (translated, text variables) piece by
             piece between the page number symbols, which are written as
             the pagesym= character: the symbol itself, or U+E000 when a
             piece holds it as text (a text variable's "&", DSMPROF3's
             &amp., or a translated one, p.259); the symbol in a text
             variable is text ([Line.split_on]); so is the value of a
             deferred reference (U+E001 ... U+E003): the backend never
             splits it, so it does not count here *)
          let pieces =
            List.map (fun f -> List.map out (Line.split_on ps f)) [ l; f; r ]
          in
          let m =
            if
              List.exists
                (List.exists (fun p -> String.contains (outside_symrefs p) ps))
                pieces
            then "\u{E000}"
            else String.make 1 ps
          in
          emit ctx "sx" ~brk:true
            (List.combine
               [ "left"; "fill"; "right" ]
               (List.map (String.concat m) pieces)
            @ fl
            @ [ ("pagesym", m) ])
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

(* .sa/.re save and restore "the active and page environments along
   with the .TI and .TR translate tables" (LR p.451, Table 25).  Of
   them the engine tracks: the indention (with a temporary one until
   changed), offset and right indention, the formatting mode (.fo/.nf),
   the current font and font save stack, hyphenation and the line
   length ([Ctx.fmt]); the .tr table; the .dc characters of the active
   environment, CONT CW GML MCS PS (LR p.451; [Ctx.chars]); and the .ce
   .ri .us .up .uc line counts (the lines remaining, or ON; Table 25
   note 2).  The rest of the indention (Table 25 note 3: .IN .IL .UN
   .OF "individually saved"), the FOR/AFTER distances left and a
   pending .il/.un, is the backend's: gml.tex saves it at gml:sa and
   puts it back at gml:re.  Not tracked: .ti (not implemented), tabs,
   line spacing, baseline, revision codes and the page layout words,
   which are hints only.  A footnote saves the active environment when
   it starts and restores it when it ends (LR p.451). *)

let fn_env = " fn" (* a name no .sa operand can give *)
let line_words = [ "ce"; "ri"; "us"; "up"; "uc" ]

let line_state d =
  List.fold_right
    (fun (sc : Doc.scope) acc ->
      if List.mem sc.word line_words && not (List.mem_assoc sc.word acc) then
        (sc.word, sc.remaining) :: acc
      else acc)
    (Doc.active_scopes d) []

let copy_chars (c : Chars.t) = { c with Chars.cw_ind = c.Chars.cw_ind }

let snapshot ?(initial = false) ctx env =
  if initial then
    {
      env;
      sfmt = initial_fmt ();
      str = Hashtbl.create 1;
      schars = Chars.create ();
      slines = [];
    }
  else
    {
      env;
      sfmt = copy_fmt (fmt ctx);
      str = Hashtbl.copy (Doc.tr_table (doc ctx));
      schars = copy_chars ctx.chars;
      slines = line_state (doc ctx);
    }

(* .sa name replaces an environment saved with that name; the unnamed
   ones are a stack (LR p.323) *)
let save ctx env =
  let sv = snapshot ctx env in
  if env = "" || env = fn_env then ctx.saved <- sv :: ctx.saved
  else begin
    ctx.saved <- sv :: List.filter (fun s -> s.env <> env) ctx.saved
  end

(* Does restoring [sv] change the formatting mode (.fo/.nf) or the
   centring (.ce/.ri)?  Then .re breaks (LR p.309 r3, r4).  The column
   definition, which also makes it break, is not tracked. *)
let re_breaks ctx sv =
  let st = fmt ctx and old = sv.sfmt in
  st.fill <> old.fill || st.align <> old.align
  || st.overdraw <> old.overdraw
  ||
  let cur = line_state (doc ctx) in
  List.exists
    (fun w -> List.assoc_opt w cur <> List.assoc_opt w sv.slines)
    [ "ce"; "ri" ]

(* Restore [sv]; with [hints], emit for each part that changes the hint
   that establishes it again (restore="yes", break="no": the break, if
   any, is the gml:re's), so a backend that does not know gml:re still
   follows: .in/.of, .ir, .ll, the format mode, .hy and the fonts (.pf
   while the saved font stack is a tail of the current one, else .bf of
   the saved font); and the line scopes .ce .ri .us .up .uc in force
   when it was saved begin again with the lines they had left. *)
let restore ?(hints = true) ctx sv =
  let st = fmt ctx and old = sv.sfmt in
  let tbl = Doc.tr_table (doc ctx) in
  Hashtbl.reset tbl;
  Hashtbl.iter (Hashtbl.replace tbl) sv.str;
  (let c = ctx.chars and s = sv.schars in
   c.Chars.cont <- s.Chars.cont;
   c.Chars.cw_sep <- s.Chars.cw_sep;
   c.Chars.gml_delim <- s.Chars.gml_delim;
   c.Chars.gml_end <- s.Chars.gml_end;
   c.Chars.mcs <- s.Chars.mcs;
   c.Chars.ps <- s.Chars.ps);
  let re name changed attrs =
    if hints && changed then
      emit ctx name ~brk:false (attrs @ [ ("restore", "yes") ])
  in
  let cur = copy_fmt st in
  st.left <- old.left;
  st.left_tmp <- old.left_tmp;
  st.right <- old.right;
  st.right_tmp <- old.right_tmp;
  st.offset <- old.offset;
  st.ll <- old.ll;
  st.fill <- old.fill;
  st.align <- old.align;
  st.overdraw <- old.overdraw;
  st.fonts <- old.fonts;
  st.hyph <- old.hyph;
  let lm (f : Ctx.fmt) = Ctx.margin f.left f.left_tmp
  and rm (f : Ctx.fmt) = Ctx.margin f.right f.right_tmp in
  re "in" (lm cur <> lm old) (Units.attrs ~default:"ch" "left" (lm old));
  re "of" (cur.offset <> old.offset)
    (Units.attrs ~default:"ch" "offset" old.offset);
  re "ir" (rm cur <> rm old) (Units.attrs ~default:"ch" "right" (rm old));
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
          | f :: _ when f <> "" -> [ ("font", f) ]
          | _ -> [ ("initial", "yes") ])
      done
    else
      re "bf" true
        (match old.fonts with
        | f :: _ when f <> "" -> [ ("font", f) ]
        | _ -> [ ("font", ""); ("initial", "yes") ])
  end;
  if hints then begin
    let d = doc ctx in
    let cur = line_state d in
    List.iter
      (fun w ->
        let now = List.assoc_opt w cur and was = List.assoc_opt w sv.slines in
        if now <> was then begin
          if now <> None then ignore (Doc.close_scope d w);
          match was with
          | Some r ->
              let n = match r with Some n -> string_of_int n | None -> "on" in
              Doc.open_scope d (scope ~word:w ~n ~brk:false [] r)
          | None -> ()
        end)
      line_words
  end

(* .sa [envname] (LR p.323) *)
let save_env ctx ops =
  let env = String.uppercase_ascii (String.trim ops) in
  save ctx env;
  emit ctx "sa" ~brk:false (if env = "" then [] else [ ("name", env) ])

(* .re [envname] (LR p.309): without a name the most recently saved
   unnamed environment, taken off the stack; with one the environment
   saved with that name, which stays (the others are not dropped).  With
   no unnamed environment saved, .re restores the initial values (r2).
   A footnote's environment is not restored by .re.  The gml:re breaks
   when the formatting mode or centring changes ([re_breaks]). *)
let restore_env ctx ops =
  let env = String.uppercase_ascii (String.trim ops) in
  let found =
    if env = "" then List.find_opt (fun sv -> sv.env = "") ctx.saved
    else List.find_opt (fun sv -> sv.env = env) ctx.saved
  in
  let apply sv =
    emit ctx "re" ~brk:(re_breaks ctx sv)
      (if env = "" then [] else [ ("name", env) ]);
    restore ctx sv
  in
  match found with
  | None when env = "" -> apply (snapshot ~initial:true ctx "")
  | None -> Ctx.warn ctx ".re %s: no environment saved with this name" env
  | Some sv ->
      if env = "" then ctx.saved <- List.filter (fun s -> s != sv) ctx.saved;
      apply sv

(* .fn on saves the environment and clears the offset (SH20-9161-3
   p.110); .fn off restores it, without hints: the footnote is a flow of
   its own in the tree. *)
let footnote ctx ops =
  let start attrs =
    save ctx fn_env;
    (fmt ctx).offset <- Units.zero;
    Doc.start_element (doc ctx) (Node.qname N.fn) attrs
  in
  match List.map lc (tokens ops) with
  | [] | [ "on" ] -> start []
  | [ "leader" ] -> start [ ("kind", "leader") ]
  | [ "off" ] ->
      close_flow ctx (Node.qname N.fn);
      Option.iter
        (fun sv ->
          ctx.saved <- List.filter (fun s -> s != sv) ctx.saved;
          restore ~hints:false ctx sv)
        (List.find_opt (fun sv -> sv.env = fn_env) ctx.saved)
  | _ -> Ctx.error ctx ".fn: ON, OFF or LEADER expected"

(* .rh/.rf [ODD|EVEN] [ON|OFF|CANCEL|SUP|RES|EXECUTE] (LR p.310-314):
   a break (p.310, p.314); ODD or EVEN limits the definition, or the
   CANCEL, SUP and RES action, to those pages (page=); the element
   gml:rh/gml:rf carries break="yes" as gml:h does. *)
let running word ctx ops =
  let name = "gml:" ^ word in
  let page p = match p with Some p -> [ ("page", p) ] | None -> [] in
  let parity, rest =
    match List.map lc (tokens ops) with
    | (("odd" | "even") as p) :: rest -> (Some p, rest)
    | l -> (None, l)
  in
  (* .rh or .rf inside a definition ends it (LR p.311 r4, p.315 r4):
     DSMPROF3's duplex footings are .rf odd ... .rf even ... .rf off *)
  let end_open () =
    List.iter
      (fun n -> if Doc.is_open (doc ctx) n then close_flow ctx n)
      [ "gml:rh"; "gml:rf" ]
  in
  match (parity, rest) with
  | None, [ "off" ] -> close_flow ctx name
  | _, [ (("cancel" | "sup" | "res" | "execute") as a) ] ->
      end_open ();
      emit ctx word ~brk:true (("action", a) :: page parity)
  | _, ([] | [ "on" ]) ->
      end_open ();
      Doc.start_running (doc ctx);
      Doc.start_element (doc ctx) name (page parity @ [ ("break", "yes") ])
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

(* .tr [s t ...] (LR p.404): pairs of a source and its output
   character; no operands restores the initial table.  A source without
   its output character is an error (the pairs before it are taken). *)
let translate ctx ops =
  let tbl = Doc.tr_table (doc ctx) in
  let rec go = function
    | [] -> ()
    | [ a ] when char_operand a = None ->
        Ctx.error ctx ".tr: invalid character %s" a
    | [ a ] -> Ctx.error ctx ".tr: no output character for %s" a
    | a :: b :: rest -> (
        match (char_operand a, char_operand b) with
        | Some src, Some dst ->
            if dst = src then Hashtbl.remove tbl src
            else Hashtbl.replace tbl src (utf8 dst);
            go rest
        | _ -> Ctx.error ctx ".tr: invalid character %s %s" a b)
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
   without a closing delimiter.  The name is at most 10 characters and
   not an array (LR p.157); FONT and BASELINE each exclude TEXT, the
   last one given counting (p.159 r12); BASELINE without FONT is allowed
   (the syntax, p.157).  DCF-VERIFY (not in LR Rel 4): with no string
   the variable is the null string. *)
let define_variable ctx ops =
  let name, rest = first_word ops in
  if name = "" then Ctx.error ctx ".dv: symbol name expected"
  else if String.contains name '(' then
    Ctx.error ctx ".dv %s: an array symbol is not allowed" name
  else if String.length name > 10 then
    Ctx.error ctx ".dv %s: a name of at most 10 characters expected" name
  else
    let rec keys acc rest =
      let w, r = first_word rest in
      match lc w with
      | "text" ->
          keys
            (("", "text")
            :: List.remove_assoc "font" (List.remove_assoc "baseline" acc))
            r
      | ("font" | "baseline") as k ->
          let v, r = first_word r in
          if v = "" then Error (Printf.sprintf "%s: value expected" k)
          else
            let v = if k = "baseline" then norm Units.Vertical v else v in
            keys ((k, v) :: List.remove_assoc k (List.remove_assoc "" acc)) r
      | _ -> Ok (List.rev acc, rest)
    in
    match keys [] rest with
    | Error e -> Ctx.error ctx ".dv %s: %s" name e
    | Ok (_, rest) when rest <> "" && Chars.is_tag_char rest.[0] ->
        Ctx.error ctx ".dv %s: FONT, BASELINE, TEXT or /string expected, not %s"
          name
          (fst (first_word rest))
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
            match Ctx.Sym.set ctx name value with
            | Ok () -> ()
            | Error e -> Ctx.error ctx ".dv: %s" e)

(* ---- index ---------------------------------------------------------------------- *)

(* The fields of a delimited string: the first nonblank character is the
   delimiter; a delimiter at the end closes the last field, one in a text
   variable is text ([Line.index_sep]).  Returns the fields and the rest
   after [max] fields. *)
let delimited ?(max = max_int) s =
  let s = String.trim s in
  if s = "" then ([], "")
  else
    let d = s.[0] in
    let rec go i n acc =
      if n = max then (List.rev acc, String.sub s i (String.length s - i))
      else
        match Line.index_sep s i d with
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
  if Ctx.Sym.get ctx "$INDX" = Some "1" then
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

type brk = Node.brk = Yes | No | Varies | Not_a_hint

(* [puts]: the nodes a word puts out, each with its break when it is not
   the word's ([None]); a gml:lines scope is [Doc.lines_node]. *)
type row = {
  name : string;
  brk : brk;
  grammar : string;
  puts : (Node.t * brk option) list;
  run : Ctx.t -> string -> unit;
}

let row name brk grammar puts run = { name; brk; grammar; puts; run }

(* a node with the word's break; with break="no" whatever the word does *)
let p n = (n, None)
let quiet n = (n, Some No)
let lines = p Doc.lines_node

let table =
  [
    row "br" Yes "" [ p N.br ] break_;
    row "lb" Yes "(leading blank)" [ p N.br ] break_;
    row "lt" Yes "(leading tab)" [ p N.br ] break_;
    row "bl" Yes "(blank line)" [ p N.sp ] blank_line;
    row "nl" Not_a_hint "(null line)" [] null_line;
    row "sp" Yes "[v] [a]" [ p N.sp ] (space "sp");
    row "sk" Yes "[v] [a|c]" [ p N.sk ] (space "sk");
    row "ce" Yes "[n|on|off|text]" [ lines ] (counted ~brk:true "ce");
    row "ri" Yes "[n|on|off|text]" [ lines ] (counted ~brk:true "ri");
    row "us" No "[n|on|off|text]" [ lines ] (counted ~brk:false "us");
    row "up" No "[n|on|off|text]" [ lines ] (counted ~brk:false "up");
    row "uc" No "[n|on|off|text]" [ lines ] (counted ~brk:false "uc");
    row "in" Varies "[h] [[for] v1] [[after] v2] [nobreak]"
      [ p N.in_ ]
      (indent left_side);
    row "ir" Varies "[h] [[for] v1] [[after] v2] [nobreak]"
      [ p N.ir ]
      (indent right_side);
    row "il" Yes "h" [ p N.il ] (one_line "il" 1);
    row "un" Yes "h" [ p N.un ] (one_line "un" (-1));
    row "of" Yes "[h]" [ p N.of_ ] offset;
    row "ll" Yes "[h]" [ p N.ll ] line_length;
    row "fo" Yes "[on|off|left|right|center|inside|outside] [extend|fold|trunc]"
      [ p N.fo ]
      (format false);
    row "nf" Yes "[on|off|left|right|center|inside|outside] [extend|fold|trunc]"
      [ p N.nf ]
      (format true);
    row "ju" Yes "[on|off]" [ p N.ju ] justify;
    row "pa" Yes "[n|+n|-n|nostart] | odd|even [on|off]" [ p N.pa ] page;
    row "cp" Yes "[v]" [ p N.cp ] (conditional_eject "cp");
    row "cc" Yes "[v]" [ p N.cc ] (conditional_eject "cc");
    row "cb" Yes "" [ p N.cb ] (generic "cb" ~brk:true);
    row "bx" Yes "[off|can|new|set|add|char] positions" [ p N.bx ] box;
    row "hr" Yes "[rule] h1|left [[to] h2|for l|right] ..." [ p N.hr ] hrule;
    row "vr" Yes "rule spec" [ p N.vr ] (generic "vr" ~brk:true);
    row "kp" Varies "on|off|float|delay|inline|v[+v]" [ p N.kp ] keep;
    row "fn" No "on|off|leader" [ p N.fn ] footnote;
    row "rh" Yes "[odd|even] on|off|cancel|sup|res|execute"
      [ p N.rh_element; p N.rh ]
      (running "rh");
    row "rf" Yes "[odd|even] on|off|cancel|sup|res|execute"
      [ p N.rf_element; p N.rf ]
      (running "rf");
    row "h0" Yes "text" [ p N.h; quiet N.tcmark ] (heading 0);
    row "h1" Yes "text" [ p N.h; quiet N.tcmark ] (heading 1);
    row "h2" Yes "text" [ p N.h; quiet N.tcmark ] (heading 2);
    row "h3" Yes "text" [ p N.h; quiet N.tcmark ] (heading 3);
    row "h4" Yes "text" [ p N.h; quiet N.tcmark ] (heading 4);
    row "h5" Yes "text" [ p N.h; quiet N.tcmark ] (heading 5);
    row "h6" Yes "text" [ p N.h; quiet N.tcmark ] (heading 6);
    row "dh" No "n options" [ p N.dh ] define_head;
    row "tc" Yes "[n] [title|/]" [ p N.tc; p N.h; p N.sk; p N.tcentry ] toc;
    row "pt" No "text | .xx line" [ p N.tcmark ] put_toc;
    row "sx" Yes "[f] [c] /left/fill/right/" [ p N.sx ] split_text;
    row "tp" Yes "[add|delete|set] stops" [ p N.tp ] (tabs "tp");
    row "tb" Yes "[add|clr|del|set] stops" [ p N.tb ] (tabs "tb");
    row "bf" No "[font...] [=]" [ p N.bf ] begin_font;
    row "pf" No "" [ p N.pf ] previous_font;
    row "df" No "name spec" [ p N.df ] define_font;
    row "hy" No "[on|off] [options]" [ p N.hy ] hyphenate;
    row "hw" No "word"
      [ p N.hw ]
      (fun ctx ops -> emit ctx "hw" ~brk:false [ ("word", String.trim ops) ]);
    row "rc" No "n [on|off|c] | adjust h | * c" [ p N.rc; lines ] revision;
    row "bc" No "on|off" [ p N.bc ] (generic ~read:plain "bc" ~brk:false);
    row "fl" No "on|off|dump ..."
      [ p N.fl ]
      (generic ~read:plain "fl" ~brk:false);
    row "ls" Varies
      "normal v | by f | skip|space|text|all f [f] | ... [nobreak]"
      [ p N.ls ]
      line_spacing_word;
    row "sb" No "[v]" [ p N.sb ] (generic ~read:vertical "sb" ~brk:false);
    row "ws" No "normal h | by f"
      [ p N.ws ]
      (generic ~read:word_spacing "ws" ~brk:false);
    row "es" No "normal h | by f"
      [ p N.es ]
      (generic ~read:word_spacing "es" ~brk:false);
    row "wz" Yes "on|off" [ p N.wz ] (generic ~read:plain "wz" ~brk:true);
    row "is" No "[to] h [blank|break|absolute]"
      [ p N.is ]
      (generic "is" ~brk:false);
    row "ic" No "..." [ p N.ic ] (generic "ic" ~brk:false);
    row "ud" No "on|off|rule v"
      [ p N.ud ]
      (generic ~read:vertical "ud" ~brk:false);
    row "dr" No "name spec" [ p N.dr ] (generic "dr" ~brk:false);
    row "pn" No "on|off|offno|roman|arabic|alpha|... | n | pref x"
      [ p N.pn ]
      (generic ~read:plain "pn" ~brk:false);
    row "pl" No "[v]" [ p N.pl ] (generic ~read:vertical "pl" ~brk:false);
    row "pw" No "[h]" [ p N.pw ] (generic "pw" ~brk:false);
    row "pm" Yes "[nobind] h [h]" [ p N.pm ] (generic "pm" ~brk:true);
    row "tm" No "[v]" [ p N.tm ] (generic ~read:vertical "tm" ~brk:false);
    row "bm" No "[v]" [ p N.bm ] (generic ~read:vertical "bm" ~brk:false);
    row "cl" Yes "[h]" [ p N.cl ] (generic "cl" ~brk:true);
    row "cd" Yes "n positions" [ p N.cd ] (generic ~read:columns "cd" ~brk:true);
    row "sc" Yes "" [ p N.sc ] (generic "sc" ~brk:true);
    row "mc" Yes "" [ p N.mc ] (generic "mc" ~brk:true);
    row "tr" Not_a_hint "pairs of c|hh" [] translate;
    (* the hint gml:dv is put out where the symbol is used ([Doc]) *)
    row "dv" Not_a_hint "name [font f] [baseline b] [text] /string"
      [ quiet Doc.dv_node ]
      define_variable;
    row "sa" No "[envname]" [ p N.sa ] save_env;
    (* .re: the hints that establish the restored state again, and the
       line scopes in force when it was saved ([restore]) *)
    row "re" Varies "[envname]"
      (p N.re
      :: List.map quiet
           [ N.in_; N.of_; N.ir; N.ll; N.fo; N.hy; N.pf; N.bf; Doc.lines_node ]
      )
      restore_env;
    row "fv" No "top|bottom|center|justify"
      [ p N.fv ]
      (generic ~read:plain "fv" ~brk:false);
    row "pi" No "[start|end|order|ref] [key /k1/k2/k3/] /t1[/t2[/t3[/page]]]"
      [ p N.pi ]
      put_index;
    row "ix" Yes "[n] [name|control|/]" [ p N.ix ] index;
  ]
  @ List.map
      (fun w -> row w Not_a_hint "(ignored)" [] (device w))
      [ "dd"; "it"; "sv"; "dl"; "uw"; "oc"; "sy"; "te"; "lo" ]

let install ctx = List.iter (fun r -> Ctx.register ctx r.name r.run) table

(** The native implicit words, for [Interp]. *)
let implicit ctx w line = (List.find (fun r -> r.name = w) table).run ctx line
