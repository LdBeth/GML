(* The nodes the engine writes in the canonical tree ([Be_xml]: the
   namespace urn:x-gml:canonical, serialized gml:NAME).

   Each node is declared once, as a value of [t]: the hints and elements
   of the control words in [Hints] (whose table says which words put
   them out), the others where they are put out, with [declare].  The
   description of them that the stylesheets and gml.tex share
   (xslt/gml-shared.xml and share/tex/gml-shared.tex, made by gmlshare
   from lib/shared.ml) is built from these declarations, not copied by
   hand. *)

(* Whether a control word breaks (LR Table 13, p.441; [Hints]); for a
   hint, the values of its break= attribute.  [Varies]: it depends on the
   operands or on the word that puts the hint out. *)
type brk = Yes | No | Varies | Not_a_hint
type tier = Block | Inline

type property = { prop : string; tier : tier; initial : string }
(** A property of the formatting state that a backend scopes (xslt/scope.xsl):
    its name, its tier (a block scope contains inline ones, never the reverse)
    and its value before any hint sets it. *)

(* An event acts where it stands; a state hint sets the properties
   [sets] until changed.  [conditional]: only some hints of the name are
   state (an .in/.ir for a distance, temporary="yes", is not; a .hy is
   only with mode=): the condition is the backend's. *)
type cls = Event | State of { sets : property list; conditional : bool }

type kind =
  | Root  (** the document element *)
  | Element  (** an element holding text of another flow, or a heading *)
  | Scope  (** the text of counted input lines ([Doc.scope]) *)
  | Hint of cls  (** an empty formatting hint *)
  | Raw  (** backend passthrough *)

type t = { name : string; kind : kind }

let qname n = "gml:" ^ n.name
let event name = { name; kind = Hint Event }

let state ?(conditional = false) name sets =
  { name; kind = Hint (State { sets; conditional }) }

let element name = { name; kind = Element }

(* The nodes no row of the [Hints] table puts out: [brk] the break a
   hint carries, [from] what puts it out. *)
type declared = { node : t; brk : brk; from : string }

let declared = ref []

let declare ?(brk = Not_a_hint) ~from node =
  declared := { node; brk; from } :: !declared;
  node
