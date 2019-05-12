open Core
open Or_name
module Html = Html_concise

type literal = Value of Bigint.t | Add of t * t | Sub of t * t | Pow of t * t

and t = literal Or_name.t

let of_int n = Literal (Value (Bigint.of_int n))

let hex_char = function
  | 0 ->
      '0'
  | 1 ->
      '1'
  | 2 ->
      '2'
  | 3 ->
      '3'
  | 4 ->
      '4'
  | 5 ->
      '5'
  | 6 ->
      '6'
  | 7 ->
      '7'
  | 8 ->
      '8'
  | 9 ->
      '9'
  | 10 ->
      'A'
  | 11 ->
      'B'
  | 12 ->
      'C'
  | 13 ->
      'D'
  | 14 ->
      'E'
  | 15 ->
      'F'
  | _ ->
      failwith "hex_char"

let hex_string n =
  (* One hex character = 4 bits *)
  let byte_to_hex b = [hex_char (b lsr 4); hex_char (b % 16)] in
  let bytes_msb =
    let rec go acc x =
      let open Bigint in
      if x = zero then acc
      else go (to_int_exn (x % of_int 256) :: acc) (shift_right x 8)
    in
    go [] n
  in
  "0x" ^ String.of_char_list (List.concat_map bytes_msb ~f:byte_to_hex)

let rec render : t -> Html.t = function
  | Name n ->
      Name.render n
  | Literal (Value n) ->
      if Bigint.(n < of_int 1000000) then Html.text (Bigint.to_string n)
      else Html.text (hex_string n)
  | Literal (Sub (t1, t2)) ->
      let open Html in
      span [] [render t1; text "-"; render t2]
  | Literal (Add (t1, t2)) ->
      let open Html in
      span [] [render t1; text "+"; render t2]
  | Literal (Pow (t1, t2)) ->
      let open Html in
      span [] [render t1; sup [render t2]]
