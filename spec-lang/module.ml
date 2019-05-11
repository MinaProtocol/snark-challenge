open Core
open Or_name

let warning fmt = ksprintf (fun s -> eprintf "Warning: %s\n%!" s) fmt

module Html = Html_concise

module Declaration = struct
  type t = {name: string; value: [`Value of Value.t * Type.t | `Type of Type.t]}
end

type t = {declarations: Declaration.t list; name: string}

module Page = struct
  module Entry = struct
    type t =
      | Value_declaration of {name: string; type_: Type.t; value: Value.t}
      | Type_declaration of
          { name: string
          ; type_: Type.t
          ; representation: Representation.t option }
  end

  type t = {title: string; entries: Entry.t list}

  let render {title; entries} =
    let open Html in
    let entry (e : Entry.t) =
      match e with
      | Value_declaration {name; type_; value} ->
          div [class_ "entry value"]
            [ Name.render (Name.local name)
            ; text ":"
            ; Type.render type_
            ; text "="
            ; Value.render value ]
      | Type_declaration {name; type_; representation} ->
          div [class_ "entry type"]
            ( [Name.render (Name.local name); text "="; Type.render type_]
            @ Option.(
                to_list
                  (map representation ~f:(fun r ->
                       div [class_ "representation"]
                         [ h2 [] [text "Binary representation"]
                         ; Representation.render r ] ))) )
    in
    div [class_ "module"]
      [h1 [] [text title]; div [class_ "entries"] (List.map entries ~f:entry)]
end

let to_page env {declarations; name= title} =
  let entry {Declaration.name; value} =
    match value with
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

let module_ name ~declarations = {name; declarations}

let mnt4753 : t =
  let var x = Name (Name.local x) in
  let fq = Type.Field.prime (var "q") in
  module_ "MNT4753"
    ~declarations:
      [ let_ ("r" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001"
      ; let_ ("q" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601"
      ; let_ ("a" ^: Type.field fq) = Value.integer "2"
      ; let_ ("b" ^: Type.field fq)
        = Value.integer
            "28798803903456388891410036793299405764940372360099938340752576406393880372126970068421383312482853541572780087363938442377933706865252053507077543420534380486492786626556269083255657125025963825610840222568694137138741554679540"
      ; let_type "G_1" = Type.curve fq ~a:(var "a") ~b:(var "b") ]

let mnt6753 : t =
  let var x = Name (Name.local x) in
  let fq = Type.Field.prime (var "q") in
  module_ "MNT6753"
    ~declarations:
      [ let_ ("r" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601"
      ; let_ ("q" ^: Type.integer)
        = Value.integer
            "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001"
      ; let_ ("a" ^: Type.field fq) = Value.integer "11"
      ; let_ ("b" ^: Type.field fq)
        = Value.integer
            "11625908999541321152027340224010374716841167701783584648338908235410859267060079819722747939267925389062611062156601938166010098747920378738927832658133625454260115409075816187555055859490253375704728027944315501122723426879114"
      ; let_type "G_1" = Type.curve fq ~a:(var "a") ~b:(var "b") ]

let update_env (env : Env.t) {name= module_name; declarations} =
  List.fold declarations ~init:env ~f:(fun env {name; value} ->
      match value with
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
