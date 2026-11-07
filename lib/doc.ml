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
          point: applied to text as it enters the tree. DCF-VERIFY: DCF
          translates when the line is put out, so a [.tr] change in the middle
          of an output line would also affect the text before it there. *)
  mutable page_symbol : unit -> char option;
      (** the page number symbol ([.dc ps]; [Ctx] installs it): in the text of
          a running heading or footing ([gml:rh], [gml:rf]) it stands for the
          page number (SH35-0069 p.125, p.128, p.259) and becomes the hint
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
  let n = List.length l - 1 in
  List.filteri (fun i _ -> i < n) l |> List.map (fun e -> e.name)

let is_open t name = List.mem name (open_elements t)

(** Is a running heading or footing definition open? *)
let in_running t = is_open t "gml:rh" || is_open t "gml:rf"
let current t = match open_elements t with [] -> None | n :: _ -> Some n

let start_element ?(eol = false) ?(provisional = false) t name attrs =
  if not t.mute then begin
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
    let rec above = function
      | n :: _ when n = name -> []
      | n :: rest -> n :: above rest
      | [] -> []
    in
    let inner = above opened in
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
  if Hashtbl.length t.tr = 0 then s
  else begin
    let b = Buffer.create (String.length s) in
    let rec go i =
      if i < String.length s then begin
        let d = String.get_utf_8_uchar s i in
        let n = Uchar.utf_decode_length d in
        (match
           Hashtbl.find_opt t.tr (Uchar.to_int (Uchar.utf_decode_uchar d))
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
    List.iter (fun sc -> List.iter (push_scope t) sc.next) (List.rev expired)
  end

(* ---- .dv text variables ------------------------------------------------ *)

(* A text variable with a font, a baseline shift or TEXT ([.dv name
   [FONT f] [BASELINE b] /string], [.dv name TEXT /string], SH35-0069
   p.258-261, SX26-3723) is "known text": it needs no code point and no
   translate table, may be used anywhere (a heading, a running heading
   or footing, split text), and is put out in its font, shifted.  Its
   symbol's value is the string between two characters of the private
   use plane 15: U+F0000 + its number (from 1) before, U+F0000 after.
   The string is substituted like any symbol value (IBM's DSMPROF3
   defines its list item labels as ".dv @id@l@o1 /&@item#.." under
   .su off); no other rule reads the two characters (tags, separators,
   the page number symbol, .tr); when text enters the tree the variable
   becomes the hint [gml:dv] with [text=] the string and the font and
   baseline of the definition.  A plain [.dv name /string] is a symbol
   ([Hints.define_variable]). *)
let dv_base = 0xF0000

let utf8_of u =
  let b = Buffer.create 4 in
  Buffer.add_utf_8_uchar b (Uchar.of_int u);
  Buffer.contents b

let dv_end = utf8_of dv_base

(** Define a text variable with the attributes of its hint (without
    [text]); returns the value its symbol gets for [string]. *)
let define_variable t attrs string =
  let i = Hashtbl.length t.dvars + 1 in
  Hashtbl.replace t.dvars i attrs;
  utf8_of (dv_base + i) ^ string ^ dv_end

(* the plane-15 code point at [i] of [s] (>= U+F0000), with its length *)
let dv_char s i =
  if Char.code s.[i] <> 0xF3 then None
  else
    let d = String.get_utf_8_uchar s i in
    let u = Uchar.to_int (Uchar.utf_decode_uchar d) in
    if Uchar.utf_decode_is_valid d && u >= dv_base then
      Some (u - dv_base, Uchar.utf_decode_length d)
    else None

(* [s] as pieces: [Either.Left text] and [Either.Right attrs] (a text
   variable, with [text=]); an unmatched end mark is dropped, an
   unended variable runs to the end of [s] *)
let split_dvars t s =
  if Hashtbl.length t.dvars = 0 || not (String.contains s '\xf3') then
    [ Either.Left s ]
  else begin
    let n = String.length s in
    let left acc i j = if j > i then Either.Left (String.sub s i (j - i)) :: acc else acc in
    (* the end mark after [i] *)
    let rec find_end i =
      if i >= n then (n, n)
      else match dv_char s i with
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

(* [s] with its text variables replaced by their text (an attribute value) *)
let dvar_text t s =
  match split_dvars t s with
  | [ Either.Left s ] -> s
  | l ->
      String.concat ""
        (List.map
           (function
             | Either.Left s -> s
             | Either.Right a -> Option.value (List.assoc_opt "text" a) ~default:"")
           l)

(** [s] as it is put out, for text in a hint's attribute (the fields of
    [.sx]): translated ([.tr]), its text variables replaced by their text
    (which is not translated). *)
let output_text t s =
  String.concat ""
    (List.map
       (function
         | Either.Left s -> translate t s
         | Either.Right a -> Option.value (List.assoc_opt "text" a) ~default:"")
       (split_dvars t s))

(* Text enters the tree translated ([.tr]).  In a running heading or
   footing the page number symbol is split off first, as the hint
   [gml:pageno]: it is the page number symbol before any translation
   (SH35-0069 p.259: "&amp." is X'08 translated to "&" on output, a text
   ampersand). *)
let rec add_text t s =
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
      Found (a, fun t -> match t with None -> rest | Some t -> Tree.Text t :: rest)
  | Tree.Hint (_, attrs) :: rest when List.assoc_opt "break" attrs <> Some "yes"
    ->
      skip (List.hd nodes) rest
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
          e.children <- rebuild (if n = 1 then None else Some (String.sub a 0 (n - 1))))

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
           if Hashtbl.length t.dvars = 0 then attrs
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
