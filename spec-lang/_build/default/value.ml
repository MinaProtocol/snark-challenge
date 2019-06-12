open Core
open Or_name

type literal = Integer of Integer.literal | Tuple of t list

and t = literal Or_name.t

let integer s = Literal (Integer (Integer.Value (Bigint.of_string s)))

let rec render = function
  | Name s ->
      Name.render s
  | Literal (Integer x) ->
      Integer.render (Literal x)
  | Literal (Tuple ts) ->
      let open Html_concise in
      span []
        ( [text "("]
        @ List.intersperse (List.map ts ~f:render) ~sep:(text ", ")
        @ [text ")"] )
