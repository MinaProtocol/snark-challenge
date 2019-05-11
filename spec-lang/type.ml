open Core
open Or_name
module Html = Html_concise

module Field = struct
  type literal =
    | Prime of {order: Integer.t}
    | Extension of {base: t; degree: int; non_residue: Value.t}

  and t = literal Or_name.t

  let prime order = Literal (Prime {order})

  let render = function
    | Name name ->
        Name.render name
    | Literal f -> (
        let open Html in
        match f with
        | Prime {order} ->
            span [] [text "&#x1D53D;"; sub [Integer.render order]]
        | Extension _ ->
            failwith "TODO Extension field" )
end

module Polynomial = struct
  type literal = {degree: int Or_name.t; field: Field.t}

  type t = literal
end

type literal =
  | UInt64
  | Polynomial of Polynomial.t
  | Field of Field.t
  | Integer
  | Curve of {field: Field.t; a: Integer.t; b: Integer.t}
  | Array of {element: t; length: Integer.t option}
  | Linear_combination of {field: Field.t}
  | Record of (string * t) list

and t = literal Or_name.t

let integer = Literal Integer

let field x = Literal (Field x)

let curve field ~a ~b = Literal (Curve {field; a; b})

let prime_field p = field (Field.prime p)

let rec render =
  let open Html in
  function
  | Name name ->
      a [href (Name.url name)] [text (Name.to_string name)]
  | Literal ty -> (
    match ty with
    | UInt64 ->
        span [] [text "uint64"]
    | Field f ->
        Field.render f
    | Integer ->
        span [] [text "Integer"]
    | Linear_combination {field} ->
        let f = Field.render field in
        span [] [text "LinearCombination("; f; text ")"]
    | Curve {field; a; b} ->
        let field = Field.render field in
        span []
          [ text "{ (x, y) &isin; "
          ; field
          ; text "&#x2a2f;"
          ; field
          ; text "&#xFF5C;"
          ; text "y"
          ; sup [text "2"]
          ; text "="
          ; text "x"
          ; sup [text "3"]
          ; text " + "
          ; Integer.render a
          ; text "x"
          ; text " + "
          ; Integer.render b
          ; text "}" ]
    | Record ts ->
        span []
          ( [text "{"]
          @ List.intersperse ~sep:(text ",")
              (List.map ts ~f:(fun (name, t) ->
                   span [] [text name; text ":"; render t] ))
          @ [text "}"] )
    | Polynomial {degree; field} ->
        let field = Field.render field in
        span []
          [ text "Polynomial(degree="
          ; ( match degree with
            | Name n ->
                Name.render n
            | Literal n ->
                text (Int.to_string n) )
          ; text ","
          ; field
          ; text ")" ]
    | Array {element; length} -> (
        let element = render element in
        match length with
        | None ->
            span [] [element; text "[]"]
        | Some length ->
            span [] [element; text "["; Integer.render length; text "]"] ) )
