open Or_name

type literal = Integer.literal

type t = Integer.t

let integer s = Literal (Integer.Value (Bigint.of_string s))

let render = Integer.render
