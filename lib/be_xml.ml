(* Canonical XML serializer. *)

let ns_uri = "urn:x-gml:canonical"

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
      Buffer.add_string b "<gml:raw";
      add_attrs b [ ("backend", backend) ];
      Buffer.add_char b '>';
      escape ~attr:false b content;
      Buffer.add_string b "</gml:raw>"
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
