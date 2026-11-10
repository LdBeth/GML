(* Document builder: turns events into a [Tree.node].

   A stack of open elements; the bottom one is the root [gml:doc].
   Children are accumulated in reverse; adjacent text is merged.

   Element models ([.xd], see [model]) drive the implicit-close engine.
   All names are lowercase.  The algorithm is deliberately simple and
   deterministic:

   - An element [Y] is {e implicitly closable} if its model has a
     non-empty [closedby] list, or some model lists [Y] in its [closes]
     list.  Only such elements may be closed without their own end.
   - Opening [X] ([start_element]): while the innermost open element [T]
     (not the root) is closed by [X] — [X] is in T's [closedby], or [T]
     is in X's [closes] — close [T].  Only the top of the stack is
     examined, repeatedly; nothing deeper is searched, so a model must
     list every element that can be on top (e.g. "p closedby=p,li,ol").
     Then [X] is pushed; if its model is [empty] it is closed at once.
   - Ending [X] ([end_element]): [X] must be open.  The elements above
     it are closed first: silently if they are implicitly closable,
     otherwise ([~force:true], a GML end tag) with their names
     returned for a warning, or ([~force:false], [.xe]) not at all: the
     call fails with [Mismatch] and nothing changes.
   - End of input ([finish]): everything still open is closed; the names
     of those that are not implicitly closable are returned for a
     warning.

   - An element whose model is [eol] (or opened with [~eol:true]) is
     closed at the end of the input line it was opened on ([text],
     [end_line]): the heading, term and index entry tags, whose element
     is the text of the tag line.  The word space goes after it.
   - Line scopes ([gml:lines], see [scope]) wrap the text of a counted
     number of input lines.

   Every element is finished in [close_top].  Duplicate [id] attribute
   values are reported (cross references are resolved later, in XSLT). *)

type display = Unspecified | Inline | Block

type model = {
  closes : string list;  (** opening this element closes these *)
  closedby : string list;  (** these close this element when opened *)
  empty : bool;  (** closed as soon as it is opened *)
  display : display;  (** recorded for the backends *)
  eol : bool;
      (** closed at the end of the input line it was opened on (headings, terms,
          index entries: the text of the tag line) *)
  noid : bool;
      (** its [id] is a name of another kind (the Starter Set's row definitions,
          SH20-9187-06 3.31), not a document id: not checked for duplicates *)
}

let default_model =
  {
    closes = [];
    closedby = [];
    empty = false;
    display = Unspecified;
    eol = false;
    noid = false;
  }

type scope = {
  word : string;  (** the control word *)
  first : Tree.attrs;  (** attributes of the first piece *)
  rest : Tree.attrs;  (** attributes of later pieces *)
  mutable remaining : int option;  (** lines still covered; None: until ended *)
  mutable started : bool;  (** a non-empty piece was emitted *)
  next : scope list;  (** scopes that begin when this one ends *)
}
(** A line scope ([gml:lines]): the text of the next [remaining] input lines (or
    up to an explicit end) is wrapped in a [gml:lines] element carrying the
    formatting state that applies to them (see [Hints]). Scopes are always the
    innermost open elements: an element opened or closed while a scope is active
    splits it, the scope going on inside the new element (or the parent) as a
    piece marked [cont="yes"]. *)

let scope_name = "gml:lines"

type kind = Plain | Scope of scope

type open_elt = {
  name : string;
  mutable attrs : Tree.attrs;
  mutable children : Tree.node list;  (** reversed *)
  kind : kind;
  eol_close : bool;
  provisional : bool;
      (** an element nothing is known to close ([start_element]): unless its own
          end tag closes it, it becomes an empty marker followed by its content
          ([close_top]) *)
}

type t = {
  mutable stack : open_elt list;
  models : (string, model) Hashtbl.t;
  ids : (string, string) Hashtbl.t;  (** id -> where first used *)
  mutable report : string -> unit;  (** a warning *)
  mutable here : unit -> string;  (** current location, for [ids] *)
  mutable mute : bool;
      (** nothing is added to the tree: set while an ignored conditional section
          is open. Its GML tags and macros are still "resolved" (SH35-0069
          p.268), so APFs run and their symbol side effects happen, but their
          elements, hints, raw output and text are dropped, and the tree is left
          as if the section were absent: no implicit closes, no id checks, no
          line-scope counting. *)
  tr : (int, string) Hashtbl.t;
      (** the output translate table ([.tr], SH35-0069 p.207), by Unicode code
          point: applied to text as it enters the tree. Rel 4: DCF translates
          the output line just before its widths are measured (LR p.404 r8), so
          a [.tr] change in the middle of an output line would also affect the
          text before it there, and running headings and footings use the
          initial table as changed inside them (r4): while a definition is open,
          [run_tr] is the table instead ([tr_table]). *)
  run_tr : (int, string) Hashtbl.t;
      (** the translate table of a running heading or footing definition: empty
          (the initial table) when the definition starts ([start_running]),
          changed by [.tr] inside it (LR p.404 r4) *)
  symrefs : (string, int) Hashtbl.t;
      (** the global symbols referred to in running headings and footings so far
          ([symref]), by name: their numbers in the marks ([Chars.sr_mark]) *)
  sr_names : (int, string) Hashtbl.t;  (** the names of [symrefs], by number *)
  sr_used : (string, unit) Hashtbl.t;
      (** the names of the deferred references that entered the tree (the text
          of a running heading or footing, a [.sx] field): [tracked] *)
  mutable page_symbol : unit -> char option;
      (** the page number symbol ([.dc ps]; [Ctx] installs it): in the text of a
          running heading or footing ([gml:rh], [gml:rf]) it stands for the page
          number (SH35-0069 p.125, p.128, p.259) and becomes the hint
          [gml:pageno] ([text]) *)
  dvars : (int, Tree.attrs) Hashtbl.t;
      (** the text variables of [.dv] ([define_variable]), by number *)
}

let root_name = "gml:doc"

let elt ?(kind = Plain) ?(eol_close = false) ?(provisional = false) name attrs =
  { name; attrs; children = []; kind; eol_close; provisional }

let create () =
  {
    stack = [ elt root_name [] ];
    models = Hashtbl.create 16;
    ids = Hashtbl.create 16;
    report = ignore;
    here = (fun () -> "");
    mute = false;
    tr = Hashtbl.create 8;
    run_tr = Hashtbl.create 1;
    symrefs = Hashtbl.create 4;
    sr_names = Hashtbl.create 4;
    sr_used = Hashtbl.create 4;
    page_symbol = (fun () -> None);
    dvars = Hashtbl.create 8;
  }

let top t = List.hd t.stack
let is_scope e = match e.kind with Scope _ -> true | Plain -> false

let add t node =
  let e = top t in
  match (node, e.children) with
  | Tree.Text b, Tree.Text a :: rest -> e.children <- Tree.Text (a ^ b) :: rest
  | _ -> e.children <- node :: e.children

(* Close the top element into its parent; an empty scope piece is
   dropped.  A provisional element closed by anything but its own end tag
   ([own]) is left empty, its content following it. *)
let close_top ?(own = false) t =
  match t.stack with
  | e :: (parent :: _ as rest) ->
      t.stack <- rest;
      if e.provisional && not own then
        parent.children <-
          e.children @ (Tree.Element (e.name, e.attrs, []) :: parent.children)
      else if not (is_scope e && e.children = []) then begin
        (match e.kind with Scope sc -> sc.started <- true | Plain -> ());
        parent.children <-
          Tree.Element (e.name, e.attrs, List.rev e.children) :: parent.children
      end
  | _ -> invalid_arg "Doc.close_top: root"

(* ---- scopes --------------------------------------------------------------- *)

(* Close the active scope pieces (the top of the stack); returns their
   scopes, outermost first. *)
let suspend t =
  let rec go acc =
    match t.stack with
    | { kind = Scope sc; _ } :: _ :: _ ->
        close_top t;
        go (sc :: acc)
    | _ -> acc
  in
  go []

let push_scope t sc =
  let attrs = ("word", sc.word) :: (if sc.started then sc.rest else sc.first) in
  t.stack <- elt ~kind:(Scope sc) scope_name attrs :: t.stack

let resume t scs = List.iter (push_scope t) scs

let active_scopes t =
  List.filter_map
    (fun e -> match e.kind with Scope sc -> Some sc | Plain -> None)
    t.stack

(* Close the scope pieces down to and including the one of [word];
   returns the scopes that were above it, outermost first. *)

(** Start a scope; an active scope of the same word ends first (a new [.ce n]
    replaces the one in progress). *)
let suspend_to t word =
  let rec go acc =
    match t.stack with
    | { kind = Scope sc; _ } :: _ :: _ ->
        close_top t;
        if sc.word = word then acc else go (sc :: acc)
    | _ -> acc
  in
  go []

let scope_active t word =
  List.exists (fun sc -> sc.word = word) (active_scopes t)

(** End the scope of [word] (e.g. [.ce off]); false if none is active. The
    scopes inside it go on. *)
let close_scope t word =
  if t.mute then true
  else if not (scope_active t word) then false
  else begin
    resume t (suspend_to t word);
    true
  end

let open_scope t sc =
  if not t.mute then begin
    ignore (close_scope t sc.word);
    push_scope t sc
  end

(* ---- models ------------------------------------------------------------- *)

let define_model t name m = Hashtbl.replace t.models name m
let model t name = Hashtbl.find_opt t.models name
let has_model t name = Hashtbl.mem t.models name
let model_or_default t name = Option.value (model t name) ~default:default_model

let closable t name =
  let m = model_or_default t name in
  m.closedby <> [] || m.eol
  || Hashtbl.fold (fun _ m acc -> acc || List.mem name m.closes) t.models false

(* Does opening [x] close the open element [y]? *)
let closed_by t ~y ~x =
  List.mem x (model_or_default t y).closedby
  || List.mem y (model_or_default t x).closes

(* ---- ids ---------------------------------------------------------------- *)

let check_id t attrs =
  match List.assoc_opt "id" attrs with
  | None -> ()
  | Some v -> (
      match Hashtbl.find_opt t.ids v with
      | Some first ->
          t.report (Printf.sprintf "duplicate id %s (first used at %s)" v first)
      | None -> Hashtbl.add t.ids v (t.here ()))

(* ---- elements ----------------------------------------------------------- *)

let plain_stack t = List.filter (fun e -> not (is_scope e)) t.stack

(** Names of the open elements, innermost first (root and scopes excluded). *)
let open_elements t =
  let l = plain_stack t in
  List.take (List.length l - 1) l |> List.map (fun e -> e.name)

let is_open t name = List.mem name (open_elements t)

(** Is a running heading or footing definition open? *)
let in_running t = is_open t "gml:rh" || is_open t "gml:rf"

(** The translate table in effect: a running heading or footing has its own
    ([run_tr]). *)
let tr_table t = if in_running t then t.run_tr else t.tr

(** A running heading or footing definition starts (before its element is
    opened): its text is translated with the initial table, as changed by [.tr]
    inside it (LR p.404 r4). *)
let start_running t = if not (in_running t) then Hashtbl.reset t.run_tr

let current t = match open_elements t with [] -> None | n :: _ -> Some n

(** [s] with its deferred references ([symref], below) replaced by their values:
    the marks ([Chars.sr_mark]) taken out (the operands of a control word that
    takes no text, a value stored in a symbol, an attribute). *)
let strip_symrefs _t s =
  if not (Chars.has_sr s) then s
  else begin
    let b = Buffer.create (String.length s) in
    let rec go i =
      if i < String.length s then
        match Chars.sr_char s i with
        | Some (_, l) -> go (i + l)
        | None ->
            Buffer.add_char b s.[i];
            go (i + 1)
    in
    go 0;
    Buffer.contents b
  end

let strip_attrs t attrs =
  if Hashtbl.length t.symrefs = 0 then attrs
  else List.map (fun (k, v) -> (k, strip_symrefs t v)) attrs

let start_element ?(eol = false) ?(provisional = false) t name attrs =
  if not t.mute then begin
    let attrs = strip_attrs t attrs in
    let s = suspend t in
    let rec implicit () =
      match t.stack with
      | y :: _ :: _ when closed_by t ~y:y.name ~x:name ->
          close_top t;
          implicit ()
      | _ -> ()
    in
    implicit ();
    let m = model_or_default t name in
    if not m.noid then check_id t attrs;
    t.stack <- elt ~eol_close:(eol || m.eol) ~provisional name attrs :: t.stack;
    if m.empty then close_top t;
    resume t s
  end

type end_result =
  | Closed of string list
      (** done; the elements that had to be closed although they are not
          implicitly closable (innermost first) *)
  | Not_open
  | Mismatch of string
      (** the innermost element above [name] that cannot be closed implicitly;
          nothing was changed *)

(** Close [name] and the elements opened inside it (see the algorithm at the
    top). *)
let end_element ?(force = false) t name =
  let opened = open_elements t in
  if t.mute then Closed []
  else if not (List.mem name opened) then Not_open
  else begin
    let inner = List.take_while (fun n -> n <> name) opened in
    let provisional n =
      List.exists (fun e -> e.name = n && e.provisional) t.stack
    in
    let forced =
      List.filter (fun n -> not (closable t n || provisional n)) inner
    in
    match forced with
    | n :: _ when not force -> Mismatch n
    | _ ->
        let s = suspend t in
        List.iter (fun _ -> close_top t) inner;
        close_top ~own:true t;
        resume t s;
        Closed forced
  end

(** Set (or replace) attribute [k] of the innermost open element; false if there
    is none. *)
let set_attr t k v =
  let v = strip_symrefs t v in
  if t.mute then true
  else
    match plain_stack t with
    | [ _ ] | [] -> false
    | e :: _ ->
        if k = "id" && not (model_or_default t e.name).noid then
          check_id t [ (k, v) ];
        e.attrs <-
          (if List.mem_assoc k e.attrs then
             List.map
               (fun (k', v') -> if k' = k then (k, v) else (k', v'))
               e.attrs
           else e.attrs @ [ (k, v) ]);
        true

(* ---- content ------------------------------------------------------------ *)

let translate t s =
  let tr = tr_table t in
  if Hashtbl.length tr = 0 then s
  else begin
    let b = Buffer.create (String.length s) in
    let rec go i =
      if i < String.length s then begin
        let d = String.get_utf_8_uchar s i in
        let n = Uchar.utf_decode_length d in
        (match
           Hashtbl.find_opt tr (Uchar.to_int (Uchar.utf_decode_uchar d))
         with
        | Some r -> Buffer.add_string b r
        | None -> Buffer.add_string b (String.sub s i n));
        go (i + n)
      end
    in
    go 0;
    Buffer.contents b
  end

(* The end of an input line: line scopes count it ([counted], a text
   line), and elements opened on the line with an [eol] model are
   closed; then the word space ("\n", [text]) follows. *)
let line_end t ~counted ~text =
  let expired =
    if not counted then []
    else
      List.filter
        (fun sc ->
          match sc.remaining with
          | Some n ->
              sc.remaining <- Some (n - 1);
              n - 1 <= 0
          | None -> false)
        (active_scopes t)
  in
  let has_eol = List.exists (fun e -> e.eol_close) t.stack in
  if has_eol then begin
    let s = suspend t in
    let rec close_eol () =
      if List.exists (fun e -> e.eol_close) t.stack then begin
        close_top t;
        close_eol ()
      end
    in
    close_eol ();
    if text then add t (Tree.Text "\n");
    resume t
      (List.concat_map
         (fun sc ->
           match sc.remaining with Some n when n <= 0 -> sc.next | _ -> [ sc ])
         s)
  end
  else begin
    (* innermost first; the scopes inside an expired one go on *)
    List.iter (fun sc -> resume t (suspend_to t sc.word)) expired;
    if text then add t (Tree.Text "\n");
    List.iter (fun sc -> resume t sc.next) (List.rev expired)
  end

(* ---- .dv text variables ------------------------------------------------ *)

(* A text variable with a font, a baseline shift or TEXT ([.dv name
   [FONT f] [BASELINE b] /string], [.dv name TEXT /string], SH35-0069
   p.258-261, SX26-3723) is "known text": it needs no code point and no
   translate table, may be used anywhere (a heading, a running heading
   or footing, split text), and is put out in its font, shifted.  Its
   symbol's value is the string between two characters of the private
   use plane 15: U+F0000 + its number (from 1) before, U+F0000 after
   ([Chars.dv_mark], [Chars.dv_end]).  The string is substituted like
   any symbol value (IBM's DSMPROF3 defines its list item labels as
   ".dv @id@l@o1 /&@item#.." under .su off); no other rule reads its
   characters (tags, the separator ([Line.split]), the page number
   symbol, .tr); when text enters the tree the variable becomes the
   hint [gml:dv] with [text=] the string and the font and baseline of
   the definition, and a message ([.ty], [.mg]) writes the string
   ([dvar_text]).  A plain [.dv name /string] is a symbol
   ([Hints.define_variable]). *)

(** Define a text variable with the attributes of its hint (without [text]);
    returns the value its symbol gets for [string]. *)
let define_variable t attrs string =
  let i = Hashtbl.length t.dvars + 1 in
  Hashtbl.replace t.dvars i attrs;
  Chars.dv_mark i ^ string ^ Chars.dv_end

let dv_char = Chars.dv_char

(* [s] as pieces: [Either.Left text] and [Either.Right attrs] (a text
   variable, with [text=]); an unmatched end mark is dropped, an
   unended variable runs to the end of [s] *)
let split_dvars t s =
  if Hashtbl.length t.dvars = 0 || not (String.contains s '\xf3') then
    [ Either.Left s ]
  else begin
    let n = String.length s in
    let left acc i j =
      if j > i then Either.Left (String.sub s i (j - i)) :: acc else acc
    in
    (* the end mark after [i] *)
    let rec find_end i =
      if i >= n then (n, n)
      else
        match dv_char s i with
        | Some (0, l) -> (i, i + l)
        | Some (_, l) -> find_end (i + l)
        | None -> find_end (i + 1)
    in
    let rec go i start acc =
      if i >= n then List.rev (left acc start n)
      else
        match dv_char s i with
        | Some (0, l) -> go (i + l) (i + l) (left acc start i)
        | Some (k, l) when Hashtbl.mem t.dvars k ->
            let e, next = find_end (i + l) in
            let text = String.sub s (i + l) (e - i - l) in
            let a = Hashtbl.find t.dvars k in
            let attrs =
              List.filter (fun (k, _) -> k <> "break") a
              @ [ ("text", text); ("break", "no") ]
            in
            go next next (Either.Right attrs :: left acc start i)
        | Some (_, l) -> go (i + l) start acc
        | None -> go (i + 1) start acc
    in
    go 0 0 []
  end

(* [s] with its text variables replaced by their text, [left] applied to
   the text around them *)
let join_dvars t left s =
  match split_dvars t s with
  | [ Either.Left s ] -> left s
  | l ->
      String.concat ""
        (List.map
           (function
             | Either.Left s -> left s
             | Either.Right a ->
                 Option.value (List.assoc_opt "text" a) ~default:"")
           l)

(* ---- deferred symbol references (running headings) -------------------- *)

(* Rel 4 (LR p.312 r7, p.315 r7, p.316): a symbol in a running heading or
   footing is replaced with "the value of the symbol at the time the page
   is started".  While a definition is open, [Subst] puts a reference to a
   global user symbol out as [symref name value]: its value now between
   two plane-16 marks ([Chars.sr_mark]), the start mark numbered for the
   name.  The span is text that travels with the line (a text line, the
   text of [.ce], a [.sx] field, a macro argument); [Interp] strips the
   marks from the operands of the other control words, [Symbols.set] from
   a value it stores.  When the text enters the tree the span becomes the
   element [<gml:symref name="NAME">value</gml:symref>] ([add_text]): the
   value is the fallback (for HTML, for a page before any change, and for
   a TeX without e-TeX marks), translated like the text around it; in a
   [.sx] field it is written [U+E001 NAME U+E002 value U+E003]
   ([field_text]).  The names referred to are [tracked]: [Ctx] puts the
   hint [gml:symval] out where one of them is set again. *)

(** The span of a deferred reference to [name] with the value [value]. *)
let symref t name value =
  let n =
    match Hashtbl.find_opt t.symrefs name with
    | Some n -> n
    | None ->
        let n = Hashtbl.length t.symrefs + 1 in
        Hashtbl.replace t.symrefs name n;
        Hashtbl.replace t.sr_names n name;
        n
  in
  Chars.sr_mark n ^ value ^ Chars.sr_end

(** Has a running heading or footing referred to the global symbol [name] in its
    text? (A span taken out of a control word's operands, [.sk &n], does not
    count.) *)
let tracked t name = Hashtbl.mem t.sr_used name

let use_symref t name = if not t.mute then Hashtbl.replace t.sr_used name ()

(* [s] as pieces: [Either.Left text] and [Either.Right (name, value)] (a
   deferred reference); a stray mark is dropped, an unended span runs to
   the end of [s] *)
let split_symrefs t s =
  if not (Chars.has_sr s) then [ Either.Left s ]
  else begin
    let n = String.length s in
    let left acc i j =
      if j > i then Either.Left (String.sub s i (j - i)) :: acc else acc
    in
    let rec go i start acc =
      if i >= n then List.rev (left acc start n)
      else
        match Chars.sr_char s i with
        | Some (k, l) when Hashtbl.mem t.sr_names k ->
            let e = Chars.sr_find_end s (i + l) in
            let next =
              match if e < n then Chars.sr_char s e else None with
              | Some (_, l') -> e + l'
              | None -> n
            in
            go next next
              (Either.Right
                 (Hashtbl.find t.sr_names k, String.sub s (i + l) (e - i - l))
              :: left acc start i)
        | Some (_, l) -> go (i + l) (i + l) (left acc start i)
        | None -> go (i + 1) start acc
    in
    go 0 0 []
  end

(* [s] with its text variables replaced by their text (an attribute value) *)
let dvar_text t s = join_dvars t Fun.id (strip_symrefs t s)

(** [s] as it is put out, for text in a hint's attribute (the fields of [.sx]):
    translated ([.tr]), its text variables replaced by their text (which is not
    translated). *)
let output_text t s = join_dvars t (translate t) (strip_symrefs t s)

(** A field of [.sx]: [output_text], a deferred reference written
    [U+E001 NAME U+E002 value U+E003]. *)
let field_text t s =
  String.concat ""
    (List.map
       (function
         | Either.Left s -> output_text t s
         | Either.Right (name, v) ->
             use_symref t name;
             "\u{E001}" ^ name ^ "\u{E002}" ^ output_text t v ^ "\u{E003}")
       (split_symrefs t s))

(* Text enters the tree translated ([.tr]).  A deferred reference is the
   element [gml:symref] around its value.  In a running heading or
   footing the page number symbol is split off first, as the hint
   [gml:pageno]: it is the page number symbol before any translation
   (SH35-0069 p.259: "&amp." is X'08 translated to "&" on output, a text
   ampersand). *)
let rec add_text t s =
  match split_symrefs t s with
  | [ Either.Left s ] -> add_dv_text t s
  | l ->
      List.iter
        (function
          | Either.Left s -> if s <> "" then add_dv_text t s
          | Either.Right (name, v) ->
              use_symref t name;
              add t
                (Tree.Element
                   ( "gml:symref",
                     [ ("name", name) ],
                     List.filter_map
                       (function
                         | Either.Left "" -> None
                         | Either.Left s -> Some (Tree.Text (translate t s))
                         | Either.Right a -> Some (Tree.Hint ("dv", a)))
                       (split_dvars t v) )))
        l

and add_dv_text t s =
  match split_dvars t s with
  | [ Either.Left s ] -> add_plain_text t s
  | l ->
      List.iter
        (function
          | Either.Left s -> if s <> "" then add_plain_text t s
          | Either.Right a -> add t (Tree.Hint ("dv", a)))
        l

and add_plain_text t s =
  match if in_running t then t.page_symbol () else None with
  | Some c when String.contains s c ->
      List.iteri
        (fun i piece ->
          if i > 0 then add t (Tree.Hint ("pageno", [ ("break", "no") ]));
          if piece <> "" then add t (Tree.Text (translate t piece)))
        (String.split_on_char c s)
  | _ -> add t (Tree.Text (translate t s))

(** One text line; the line end (the word space) is kept as "\n". *)
let text t s =
  if not t.mute then begin
    if s <> "" then add_text t s;
    line_end t ~counted:true ~text:true
  end

(** The end of an input line that put no text out (a tag alone on its line):
    only the [eol] elements are closed. *)
let end_line t = if not t.mute then line_end t ~counted:false ~text:false

(** Text without a line end (a piece of a line before a GML tag, or a line with
    continuation). *)
let text_inline t s = if s <> "" && not t.mute then add_text t s

(* ---- .ct: the previous output word ------------------------------------- *)

(* DCF has no tree: [.ct] continues the last word put out, whatever hints
   and element ends came after it (SH35-0069 p.48; p.107: "5" [.sb .15cm]
   [.ct 3]), unless a control word that breaks came between (p.47: "If a
   formatter control that causes a break follows the continued word,
   continuation is cancelled").  [last_text] finds that word in a list of
   nodes, newest first: [Found (text, rebuild)] where [rebuild t'] is the
   list with the text replaced by [t'] (None: the text is removed). *)
type last =
  | Found of string * (string option -> Tree.node list)
  | Blocked  (** a breaking hint or raw output comes first *)
  | Absent

let rec last_text nodes =
  match nodes with
  | [] -> Absent
  | Tree.Text "" :: rest -> skip (Tree.Text "") rest
  | Tree.Text a :: rest ->
      Found (a, function None -> rest | Some t -> Tree.Text t :: rest)
  | (Tree.Hint (_, attrs) as h) :: rest
    when List.assoc_opt "break" attrs <> Some "yes" ->
      skip h rest
  | Tree.Hint _ :: _ | Tree.Raw _ :: _ -> Blocked
  | (Tree.Element (n, a, ch) as e) :: rest -> (
      match last_text (List.rev ch) with
      | Found (s, rebuild) ->
          Found (s, fun t -> Tree.Element (n, a, List.rev (rebuild t)) :: rest)
      | Blocked -> Blocked
      | Absent -> skip e rest)

and skip node rest =
  match last_text rest with
  | Found (s, rebuild) -> Found (s, fun t -> node :: rebuild t)
  | r -> r

(* The last output word: in the open elements from the innermost out
   (an open element's content follows its parent's children).  [f] gets
   the element holding it, the text and how to replace it. *)
let with_last_text t f =
  let rec go = function
    | [] -> ()
    | e :: outer -> (
        match last_text e.children with
        | Absent -> go outer
        | Blocked -> ()
        | Found (s, rebuild) -> f e s rebuild)
  in
  go t.stack

(** [.ct text] (SH35-0069 p.48): the word space after the previous text line
    goes, so [text] continues it, across non-breaking hints and element ends. *)
let join_previous t =
  if not t.mute then
    with_last_text t (fun e a rebuild ->
        let n = String.length a in
        if a.[n - 1] = '\n' then
          e.children <-
            rebuild (if n = 1 then None else Some (String.sub a 0 (n - 1))))

(** [.ct] alone: a continuation in effect (the previous text line ended without
    a word space) is cancelled. *)
let cancel_continuation t =
  if not t.mute then
    with_last_text t (fun _ a _ ->
        if a.[String.length a - 1] <> '\n' then add t (Tree.Text "\n"))

let hint t name attrs =
  if not t.mute then
    add t
      (Tree.Hint
         ( name,
           if Hashtbl.length t.dvars = 0 && Hashtbl.length t.symrefs = 0 then
             attrs
           else List.map (fun (k, v) -> (k, dvar_text t v)) attrs ))

let raw t backend content =
  if not t.mute then add t (Tree.Raw (backend, content))

(** Close everything still open and return the root element. Returns the names
    of the elements that had to be closed and are not implicitly closable
    (innermost first), so the caller can diagnose them. *)
let finish t =
  (* [acc]: the names collected so far, the latest (outermost) first *)
  let rec close_all acc =
    match t.stack with
    | e :: _ :: _ ->
        let acc =
          if not (is_scope e || e.provisional || closable t e.name) then
            e.name :: acc
          else acc
        in
        close_top t;
        close_all acc
    | _ -> List.rev acc
  in
  let unclosed = close_all [] in
  let r = top t in
  (Tree.Element (r.name, r.attrs, List.rev r.children), unclosed)
