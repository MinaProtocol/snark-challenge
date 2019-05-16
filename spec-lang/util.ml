open Core

type 'a or_name = 'a Or_name.t = Literal of 'a | Name of Name.t

let latex s = sprintf "\\(%s\\)" s

let md_latex s = sprintf "$%s$" s

let ( ^. ) scope name = Name (Name.in_scope scope name)

module Html = Html_concise

let base_url = Name.base_url
