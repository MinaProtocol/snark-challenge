open Core
open Util

type t = {dollars: int}

let render {dollars} =
  ksprintf Html.text "$%s" (Int.to_string_hum ~delimiter:',' dollars)
