type 'a t = Literal of 'a | Name of Name.t

let map t ~f = match t with Literal x -> Literal (f x) | Name n -> Name n

let out t ~on_name ~on_literal =
  match t with Name n -> on_name n | Literal x -> on_literal x
