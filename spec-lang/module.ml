open Core
open Util

let warning fmt = ksprintf (fun s -> eprintf "Warning: %s\n%!" s) fmt

module Html = Html_concise

module Declaration = struct
  type t =
    { name: string
    ; value:
        [ `Value of Value.t * Type.t
        | `Type of Type.t
        | `Field of Type.Field.literal
        | `Html of Html.t ] }
end

type t = {declarations: Declaration.t list; name: string}

module Page = struct
  module Entry = struct
    type t =
      | Html of Html.t
      | Value_declaration of {name: string; type_: Type.t; value: Value.t}
      | Field_declaration of
          { field: Type.Field.literal
          ; representation: Representation.t option }
      | Type_declaration of
          { name: string
          ; type_: Type.t
          ; representation: Representation.t option }
  end

  type t = {title: string; entries: Entry.t list}

  let render_representation = function
    | None ->
        []
    | Some r ->
        let open Html in
        [ hr []
        ; div [class_ "representation"]
            [h3 [] [text "Binary representation"]; Representation.render r] ]

  let render {title; entries} =
    let open Html in
    let entry (e : Entry.t) =
      match e with
      | Html h ->
          h
      | Value_declaration {name; type_; value} ->
          div [class_ "entry value"]
            [ Name.render_declaration name
            ; text ":"
            ; Type.render type_
            ; text "="
            ; Value.render value ]
      | Field_declaration {field; representation} -> (
        match field with
        | Extension {base= Literal (Prime {order= Name p}); degree; non_residue}
          ->
            let elt =
              let sqrt =
                if degree = 2 then {h|\sqrt|h}
                else sprintf {h|\sqrt[%d]|h} degree
              in
              List.init degree ~f:(fun i ->
                  if i = 0 then "a_0"
                  else if i = 1 then sprintf {h|a_1 %s{\alpha}|h} sqrt
                  else sprintf {h|a_%d %s{\alpha}^{%d}|h} i sqrt i )
              |> String.concat ~sep:" + "
            in
            let tup =
              List.init degree ~f:(fun i -> sprintf "a_%d" i)
              |> String.concat ~sep:", "
            in
            div [class_ "entry field"]
              ( [ span []
                    [ Type.Field.render (Literal field)
                    ; text " is constructed as "
                    ; ksprintf text
                        {latex|\(\mathbb{F}_%s[x] / (x^{%s} = \alpha)\)|latex}
                        (Name.to_string p) (Int.to_string degree)
                    ; text {h| where \(\alpha\) is |h}
                    ; Value.render non_residue
                    ; text ". " ]
                ; ksprintf text
                    {h|Concretely, each element has the form \(%s\) and is represented as the tuple \((%s)\).|h}
                    elt tup ]
              @ render_representation representation )
        | Prime {order} ->
            div [class_ "entry field"]
              ( [ Type.Field.render (Literal field)
                ; text "is the field of integers mod "
                ; Integer.render order ]
              @ render_representation representation )
        | _ ->
            failwith "TODO" )
      | Type_declaration {name; type_; representation} ->
          div [class_ "entry type"]
            ( [Name.render_declaration name; text "="; Type.render type_]
            @ render_representation representation )
    in
    div [class_ "module"]
      [h1 [] [text title]; div [class_ "entries"] (List.map entries ~f:entry)]
end

let to_page env {declarations; name= title} =
  let entry {Declaration.name; value} =
    match value with
    | `Html h ->
        Page.Entry.Html h
    | `Field f ->
        let representation =
          match
            Representation.of_type ~scope:title env (Type.field (Literal f))
          with
          | Error e ->
              warning !"%{sexp:Error.t}" e ;
              None
          | Ok r ->
              Some r
        in
        Page.Entry.Field_declaration {field= f; representation}
    | `Value (v, t) ->
        Page.Entry.Value_declaration {name; type_= t; value= v}
    | `Type t ->
        let representation =
          match Representation.of_type ~scope:title env t with
          | Error e ->
              warning !"%{sexp:Error.t}" e ;
              None
          | Ok r ->
              Some r
        in
        Type_declaration {name; type_= t; representation}
  in
  {Page.title; entries= List.map declarations ~f:entry}

let ( ^: ) x y = (x, y)

let ( = ) f x = f x

let let_ (name, ty) rhs = {Declaration.name; value= `Value (rhs, ty)}

let let_type name ty = {Declaration.name; value= `Type ty}

let let_field f = {Declaration.name= ""; value= `Field f}

let let_html h = {Declaration.name= ""; value= `Html h}

let module_ name ~declarations = {name; declarations}

let twist_coeff x = ksprintf latex "\\tilde{%s}" x

let mnt4753 : t =
  let var x = Name (Name.local x) in
  let fq_field = Type.Field.Prime {order= var "q"} in
  let fq = Literal fq_field in
  let e = 2 in
  let non_residue = Integer.Value (Bigint.of_int 13) in
  let fqe =
    Type.Field.Extension
      {base= fq; degree= e; non_residue= Literal (Value.Integer non_residue)}
  in
  module_ "MNT4753"
    ~declarations:
      [ let_html
          (Html.markdown
             {md|This page describes the constants, fields, and groups associated with the MNT4-753 curve.|md})
      ; let_ ("r" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001"
      ; let_ ("q" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601"
        (*
      ; let_ ("R" ^: Type.integer)
        = Literal (Integer.Pow (Value.integer "2", Value.integer "768"))
*)
      ; let_ ("e" ^: Type.integer) = Value.integer (Int.to_string e)
      ; let_field fq_field
      ; let_field fqe
      ; let_ ("a" ^: Type.field fq) = Value.integer "2"
      ; let_ ("b" ^: Type.field fq)
        = Value.integer
            "28798803903456388891410036793299405764940372360099938340752576406393880372126970068421383312482853541572780087363938442377933706865252053507077543420534380486492786626556269083255657125025963825610840222568694137138741554679540"
      ; let_type (latex "G_1") = Type.curve fq ~a:(var "a") ~b:(var "b")
      ; let_
          (twist_coeff "a" ^: Type.field (Literal fqe))
          (Literal
             (Value.Tuple
                [ Literal (Integer (Mul (Literal non_residue, var "a")))
                ; Literal (Integer (Value Bigint.zero)) ]))
      ; let_
          (twist_coeff "b" ^: Type.field (Literal fqe))
          (Literal
             (Value.Tuple
                [ Literal (Integer (Value Bigint.zero))
                ; Literal (Integer (Mul (Literal non_residue, var "b"))) ]))
      ; let_type (latex "G_2")
        = Type.curve (Literal fqe)
            ~a:(var (twist_coeff "a"))
            ~b:(var (twist_coeff "b")) ]

let mnt6753 : t =
  let var x = Name (Name.local x) in
  let fq_field = Type.Field.Prime {order= var "q"} in
  let fq = Literal fq_field in
  let e = 3 in
  let non_residue = Integer.Value (Bigint.of_int 11) in
  let fqe =
    Type.Field.Extension
      {base= fq; degree= e; non_residue= Literal (Integer non_residue)}
  in
  module_ "MNT6753"
    ~declarations:
      [ let_html
          (Html.markdown
             {md|This page describes the constants, fields, and groups associated with the MNT6-753 curve.|md})
      ; let_ ("r" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601"
      ; let_ ("q" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001"
      ; let_ ("e" ^: Type.integer) = Value.integer (Int.to_string e)
      ; let_field fq_field
      ; let_field fqe
      ; let_ ("a" ^: Type.field fq) = Value.integer "11"
      ; let_ ("b" ^: Type.field fq)
        = Value.integer
            "11625908999541321152027340224010374716841167701783584648338908235410859267060079819722747939267925389062611062156601938166010098747920378738927832658133625454260115409075816187555055859490253375704728027944315501122723426879114"
      ; let_type (latex "G_1") = Type.curve fq ~a:(var "a") ~b:(var "b")
      ; let_
          (twist_coeff "a" ^: Type.field (Literal fqe))
          (Literal
             (Value.Tuple
                [ Literal (Integer (Value Bigint.zero))
                ; Literal (Integer (Value Bigint.zero))
                ; var "a" ]))
      ; let_
          (twist_coeff "b" ^: Type.field (Literal fqe))
          (Literal
             (Value.Tuple
                [ Literal (Integer (Mul (Literal non_residue, var "b")))
                ; Literal (Integer (Value Bigint.zero))
                ; Literal (Integer (Value Bigint.zero)) ]))
      ; let_type (latex "G_2")
        = Type.curve (Literal fqe)
            ~a:(var (twist_coeff "a"))
            ~b:(var (twist_coeff "b")) ]

let update_env (env : Env.t) {name= module_name; declarations} =
  List.fold declarations ~init:env ~f:(fun env {name; value} ->
      match value with
      | `Html _ | `Field _ ->
          env
      | `Value (v, _t) ->
          { env with
            values=
              Map.add_exn env.values
                ~key:(Name.Qualified.create ~in_module:module_name name)
                ~data:v }
      | `Type t ->
          { env with
            types=
              Map.add_exn env.types
                ~key:(Name.Qualified.create ~in_module:module_name name)
                ~data:t } )
