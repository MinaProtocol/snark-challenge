open Core
open Or_name
module Html = Html_concise

type t =
  | Array of {element: t; length: Integer.t}
  | Sequence of t * string * t
  | Record of (string * t) list
  | UInt64

let limb = UInt64

let size_in_limbs n =
  let limb_size = 64 in
  let rec go i =
    if Bigint.((of_int 1 lsl Int.(limb_size * i)) > n) then i else go (i + 1)
  in
  go 1

let rec of_field ~scope (env : Env.t) (f : Type.Field.t) =
  match Env.Deref.field ~scope env f with
  | Prime {order} ->
      let order = Env.Deref.bigint ~scope env order in
      let length = Bigint.of_int (size_in_limbs order) in
      Array {element= limb; length= Literal (Value length)}
  | Extension {base; degree; non_residue= _} ->
      let base = of_field ~scope env base in
      Array {element= base; length= Literal (Value (Bigint.of_int degree))}

let rec of_type ~scope (env : Env.t) (t : Type.t) =
  let open Or_error.Let_syntax in
  match Env.Deref.type_ ~scope env t with
  | UInt64 ->
      Ok UInt64
  | Integer ->
      Or_error.error_string "Integer does not have a conrete representation"
  | Field f ->
      Ok (of_field ~scope env f)
  | Curve {field; a= _; b= _} ->
      let field = of_field ~scope env field in
      Ok (Record [("x", field); ("y", field)])
  | Record ts ->
      let%map rs =
        List.map ts ~f:(fun (name, t) ->
            let%map r = of_type ~scope env t in
            (name, r) )
        |> Or_error.all
      in
      Record rs
  | Polynomial {degree; field} ->
      of_type ~scope env
        (Literal
           (Array
              { element= Literal (Field field)
              ; length=
                  Some
                    (Or_name.map
                       ~f:(fun d -> Integer.Value (Bigint.of_int d))
                       degree) }))
  | Linear_combination {field} ->
      let field = of_field ~scope env field in
      let element = Record [("coefficient", field); ("variable", UInt64)] in
      Ok
        (Sequence
           ( UInt64
           , "num_terms"
           , Array {element; length= Name (Name.local "num_terms")} ))
  | Array {element; length} -> (
      let%map element = of_type ~scope env element in
      match length with
      | None ->
          Sequence (UInt64, "n", Array {element; length= Name (Name.local "n")})
      | Some length ->
          Array {element; length} )

let rec render =
  let open Html in
  function
  | UInt64 ->
      text "uint64"
  | Record ts ->
      ul []
        (List.map ts ~f:(fun (name, t) -> li [] [text name; text ":"; render t]))
  | Array {element; length} ->
      let element = render element in
      span [] [element; text "["; Integer.render length; text "]"]
  | Sequence (t1, name1, t2) ->
      let t1 = render t1 in
      let t2 = render t2 in
      div
        [class_ "representation-sequence"]
        [ div
            [class_ "representation-sequence-item"]
            [span [] [text name1; text ":"; t1]]
        ; div [class_ "representation-sequence-item"] [t2] ]
