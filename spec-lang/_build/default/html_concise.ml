open Core
open Stationary
include Html

let div = node "div"

let p s = node "p" [] [text s]

let ul = node "ul"

let li = node "li"

let a = node "a"

let span = node "span"

let href = Attribute.href

let class_ = Attribute.class_

let sub = node "sub" []

let sup = node "sup" []

let h1 = node "h1"

let h2 = node "h2"

let h3 = node "h3"

let to_string t = Async.Thread_safe.block_on_async_exn (fun () -> to_string t)

let deindent s =
  String.split_lines s |> List.map ~f:String.strip |> String.concat ~sep:"\n"

let to_string = Fn.compose deindent to_string
