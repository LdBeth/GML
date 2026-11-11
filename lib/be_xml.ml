(* Canonical XML serializer. *)

let ns_uri = "urn:x-gml:canonical"
let raw_node = Node.declare ~from:".xr" { Node.name = "raw"; kind = Node.Raw }
let raw_name = Node.qname raw_node

(* Escape for both character data and (double-quoted) attribute values.
   Control characters that XML 1.0 cannot represent become U+FFFD. *)
let escape ~attr b s =
  String.iter
    (fun c ->
      match c with
      | '&' -> Buffer.add_string b "&amp;"
      | '<' -> Buffer.add_string b "&lt;"
      | '>' -> Buffer.add_string b "&gt;"
      | '"' -> Buffer.add_string b "&quot;"
      | '\n' when attr -> Buffer.add_string b "&#10;"
      | '\t' when attr -> Buffer.add_string b "&#9;"
      | '\r' -> Buffer.add_string b "&#13;"
      | '\n' | '\t' -> Buffer.add_char b c
      | c when Char.code c < 0x20 -> Buffer.add_string b "\xEF\xBF\xBD"
      | c -> Buffer.add_char b c)
    s

let add_attrs b attrs =
  List.iter
    (fun (k, v) ->
      Buffer.add_char b ' ';
      Buffer.add_string b k;
      Buffer.add_string b "=\"";
      escape ~attr:true b v;
      Buffer.add_char b '"')
    attrs

let rec add_node b = function
  | Tree.Text s -> escape ~attr:false b s
  | Tree.Hint (name, attrs) ->
      Buffer.add_string b "<gml:";
      Buffer.add_string b name;
      add_attrs b attrs;
      Buffer.add_string b "/>"
  | Tree.Raw (backend, content) ->
      Buffer.add_char b '<';
      Buffer.add_string b raw_name;
      add_attrs b [ ("backend", backend) ];
      Buffer.add_char b '>';
      escape ~attr:false b content;
      Buffer.add_string b "</";
      Buffer.add_string b raw_name;
      Buffer.add_char b '>'
  | Tree.Element (name, attrs, children) -> add_element b name attrs children

and add_element b name attrs children =
  Buffer.add_char b '<';
  Buffer.add_string b name;
  add_attrs b attrs;
  if children = [] then Buffer.add_string b "/>"
  else begin
    Buffer.add_char b '>';
    List.iter (add_node b) children;
    Buffer.add_string b "</";
    Buffer.add_string b name;
    Buffer.add_char b '>'
  end

(** Serialize a whole document. The root element gets the [gml] namespace
    declaration (unless it already carries one). *)
let document root =
  let b = Buffer.create 4096 in
  Buffer.add_string b "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
  (match root with
  | Tree.Element (name, attrs, children) ->
      let attrs =
        if List.mem_assoc "xmlns:gml" attrs then attrs
        else ("xmlns:gml", ns_uri) :: attrs
      in
      add_element b name attrs children
  | n -> add_node b n);
  Buffer.add_char b '\n';
  Buffer.contents b

(** Serialize a data file kept in the source tree, so that it diffs well: one
    element per line, indented by its depth (an element holding text is one
    line), after the XML declaration and the comment [comment]; no namespace is
    added (the root declares its own). *)
let data_file ?comment root =
  let b = Buffer.create 4096 in
  Buffer.add_string b "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
  Option.iter (fun c -> Printf.bprintf b "<!-- %s -->\n" c) comment;
  let rec line depth node =
    Buffer.add_string b (String.make depth ' ');
    (match node with
    | Tree.Element (name, attrs, (_ :: _ as children))
      when List.for_all
             (function Tree.Element _ -> true | _ -> false)
             children ->
        Buffer.add_char b '<';
        Buffer.add_string b name;
        add_attrs b attrs;
        Buffer.add_string b ">\n";
        List.iter (line (depth + 1)) children;
        Buffer.add_string b (String.make depth ' ');
        Buffer.add_string b "</";
        Buffer.add_string b name;
        Buffer.add_char b '>'
    | n -> add_node b n);
    Buffer.add_char b '\n'
  in
  line 0 root;
  Buffer.contents b
