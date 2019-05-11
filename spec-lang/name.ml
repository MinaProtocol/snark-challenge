open Core
open Stationary
module Html = Html_concise

module Qualification = struct
  type t = In_module of string | In_current_scope [@@deriving compare, sexp]
end

module T = struct
  type t = {qualification: Qualification.t; ident: string}
  [@@deriving compare, sexp]
end

include T
include Comparable.Make (T)

let local ident = {qualification= In_current_scope; ident}

let in_scope scope x = {qualification= In_module scope; ident= x}

let to_string {qualification; ident} =
  match qualification with
  | In_module s ->
      sprintf "%s.%s" s ident
  | In_current_scope ->
      ident

let base_url = ""

let module_url m = sprintf "%s/%s.html" base_url m

let id ident = Base64.encode_string ident

let url {qualification; ident} =
  match qualification with
  | In_module s ->
      sprintf "%s#%s" (module_url s) (id ident)
  | In_current_scope ->
      sprintf "#%s" (id ident)

let render_declaration name =
  let open Html in
  span [Attribute.create "id" (id name)] [text name]

let render name = Html.a [Html.href (url name)] [Html.text (to_string name)]

let to_markdown name = sprintf "[%s](%s)" (to_string name) (url name)

module Qualified = struct
  module T = struct
    type t = {in_module: string; ident: string} [@@deriving sexp, compare]
  end

  include T
  include Comparable.Make (T)

  let create ~in_module ident = {in_module; ident}

  let to_string {in_module; ident} =
    to_string {qualification= In_module in_module; ident}
end
