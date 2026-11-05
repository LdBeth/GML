(* The canonical document tree.  Attribute lists keep their given order;
   the serializer is deterministic. *)

type attrs = (string * string) list

type node =
  | Element of string * attrs * node list
  | Text of string
  | Hint of string * attrs      (** formatting hint, serialized as gml:NAME *)
  | Raw of string * string      (** backend, content (passthrough) *)
