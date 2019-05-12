open Core
open Or_name
module Html = Html_concise

let rec search f t name =
  match f t name with
  | Literal x ->
      x
  | Name n ->
      let in_module =
        match n.Name.qualification with
        | In_current_scope ->
            name.Name.Qualified.in_module
        | In_module s ->
            s
      in
      search f t {in_module; ident= n.ident}

module Single = struct
  type 'a t = 'a Or_name.t Name.Qualified.Map.t

  let find_exn (t : _ t) name = search Map.find_exn t name

  let find_exn t name =
    try find_exn t name
    with _ -> raise (Not_found_s (Name.Qualified.sexp_of_t name))

  let empty = Name.Qualified.Map.empty
end

type t = {types: Type.literal Single.t; values: Value.literal Single.t}

let find_type_exn t name = Single.find_exn t.types name

let find_value_exn t name = Single.find_exn t.values name

let find_field_exn t name =
  search
    (fun t n ->
      match Single.find_exn t n with
      | Type.Field (Name n) ->
          Name n
      | Type.Field (Literal f) ->
          Literal f
      | _ ->
          failwithf !"Name %{Name.Qualified} does not refer to a field" name ()
      )
    t.types name

module Deref = struct
  let named ~scope env ~f = function
    | Literal l ->
        l
    | Name {qualification; ident} ->
        let in_module =
          match qualification with
          | In_current_scope ->
              scope
          | In_module s ->
              s
        in
        f env {Name.Qualified.in_module; ident}

  let type_ ~scope = named ~scope ~f:find_type_exn

  let field ~scope = named ~scope ~f:find_field_exn

  let rec bigint : scope:string -> t -> Integer.t -> Bigint.t =
   fun ~scope t0 x0 ->
    match named ~scope t0 x0 ~f:find_value_exn with
    | Value n ->
        n
    | Add (x1, x2) ->
        Bigint.(bigint ~scope t0 x1 + bigint ~scope t0 x2)
    | Sub (x1, x2) ->
        Bigint.(bigint ~scope t0 x1 - bigint ~scope t0 x2)
    | Pow (x1, x2) ->
        Bigint.(pow (bigint ~scope t0 x1) (bigint ~scope t0 x2))
end

let empty = {types= Single.empty; values= Single.empty}
