open Core
open Stationary

module Html = Html_concise

let base_url = ""

module Name = struct
  module Qualification = struct
    type t =
      | In_module of string
      | In_current_scope
    [@@deriving compare, sexp]
  end

  module T = struct
    type t = { qualification : Qualification.t; ident : string }
    [@@deriving compare, sexp]
  end
  include T
  include Comparable.Make(T)

  let local ident = { qualification = In_current_scope; ident }

  let in_scope scope x = { qualification = In_module scope; ident = x }

  let to_string { qualification; ident } =
    match qualification with
    | In_module s -> sprintf "%s.%s" s ident
    | In_current_scope -> ident

  let module_url m = sprintf "%s/%s.html" base_url m

  let id ident = Base64.encode_string ident

  let url { qualification; ident } =
    match qualification with
    | In_module s -> sprintf "%s#%s" (module_url s) (id ident)
    | In_current_scope -> sprintf "#%s" (id ident)

  let render_declaration name =
    let open Html in
    span [ Attribute.create "id" (id name) ] [ text name ]

  let render name = 
    Html.a [ Html.href (url name) ] [ Html.text (to_string name) ]

  module Qualified = struct
    module T = struct
      type t = { in_module : string; ident : string }
      [@@deriving sexp, compare]
    end
    include T
    include Comparable.Make(T)

    let create ~in_module ident = { in_module; ident }

    let to_string { in_module ; ident } = to_string { qualification=In_module in_module; ident }
  end

end

module Or_name = struct
  type 'a t =
    | Literal of 'a
    | Name of Name.t

  let map t ~f =
    match t with
    | Literal x -> Literal (f x)
    | Name n -> Name n

  let out t ~on_name ~on_literal =
    match t with
    | Name n -> on_name n
    | Literal x -> on_literal x
end
open Or_name

module Integer = struct
  type literal =
    | Value of Bigint.t
    | Add of t * t
    | Sub of t * t
  and t = literal Or_name.t

  let of_int n = Literal (Value (Bigint.of_int n))

  let hex_char = function
    | 0 -> '0'
    | 1 -> '1'
    | 2 -> '2'
    | 3 -> '3'
    | 4 -> '4'
    | 5 -> '5'
    | 6 -> '6'
    | 7 -> '7'
    | 8 -> '8'
    | 9 -> '9'
    | 10 -> 'A'
    | 11 -> 'B'
    | 12 -> 'C'
    | 13 -> 'D'
    | 14 -> 'E'
    | 15 -> 'F'
    | _ -> failwith "hex_char"

  let hex_string n =
    (* One hex character = 4 bits *)
    let byte_to_hex b =
      [ hex_char (b lsr 4) ; hex_char (b % 16) ]
    in
    let bytes_msb =
      let rec go acc x =
        let open Bigint in
        if x = zero
        then acc
        else go (to_int_exn (x % of_int 256) :: acc) (shift_right x 8)
      in
      go [] n
    in
    "0x" ^ (String.of_char_list (List.concat_map bytes_msb ~f:byte_to_hex))

  let rec render : t -> Html.t = function
    | Name n -> Name.render n
    | Literal Value n ->
      if Bigint.(n < of_int 1000000)
      then Html.text (Bigint.to_string n)
      else Html.text (hex_string n)
    | Literal Sub (t1, t2) ->
      let open Html in
      span []
        [ render t1
        ; text "-"
        ; render t2
        ]
    | Literal Add (t1, t2) ->
      let open Html in
      span []
        [ render t1
        ; text "+"
        ; render t2
        ]
end

module Value = struct
  type literal = Integer.literal
  type t = Integer.t

  let integer s = Literal (Integer.Value (Bigint.of_string s))

  let render = Integer.render
end

module Type = struct
  module Field = struct
    type literal =
      | Prime of { order : Integer.t }
      | Extension of { base : t; degree : int ; non_residue : Value.t }
    and t = literal Or_name.t

    let prime order = Literal (Prime { order })

    let render = function
      | Name name -> Name.render name
      | Literal f ->
        let open Html in
        match f with
        | Prime { order } ->
          span []
            [ text "&#x1D53D;"; sub [ Integer.render order ] ]
        | Extension _ -> failwith "TODO Extension field"
  end

  module Polynomial = struct
    type literal = { degree : int Or_name.t; field : Field.t }

    type t = literal
  end

  type literal =
    | UInt64
    | Polynomial of Polynomial.t
    | Field of Field.t
    | Integer
    | Curve of { field : Field.t; a : Integer.t; b : Integer.t }
    | Array of { element : t; length : Integer.t option }
    | Linear_combination of { field : Field.t }
    | Record of (string * t) list
  and t = literal Or_name.t

  let integer = Literal Integer

  let field x = Literal (Field x)

  let curve field ~a ~b = Literal (Curve { field; a; b })

  let prime_field p = field (Field.prime p)

  let rec render = 
    let open Html in
    function
    | Name name -> a [ href (Name.url name) ] [ text (Name.to_string name) ]
    | Literal ty ->
      match ty with
      | UInt64 -> span [] [ text "uint64" ]
      | Field f -> Field.render f
      | Integer -> span [] [ text "Integer" ]
      | Linear_combination { field } ->
        let f = Field.render field in
        span []
          [ text "LinearCombination("; f; text ")"]
      | Curve { field; a; b } ->
        let field = Field.render field in
        span [] 
          [ text "{ (x, y) &isin; "; field; text "&#x2a2f;"; field
          ; text "&#xFF5C;"
          ; text "y"; sup [ text "2" ]; text "="
          ; text "x"; sup [ text"3" ]; text " + "
          ; Integer.render a; text "x"; text " + "
          ; Integer.render b
          ; text "}"
          ]
      | Record ts ->
        span []
          ( [text "{"]
            @ 
            List.intersperse ~sep:( text "," )
              (List.map ts ~f:(fun (name, t) ->
                  span [] [ text name; text ":"; render t ]))
            @ [ text "}"]
          )

      | Polynomial { degree; field } ->
        let field = Field.render field in
        span []
          [ text "Polynomial(degree="
          ; (match degree with
             | Name n -> Name.render n
             | Literal n -> text (Int.to_string n))
          ; text ","
          ; field
          ; text ")"
          ]
      | Array { element; length } ->
        let element = render element in
        match length with
        | None -> span [] [ element; text "[]" ]
        | Some length ->
          span [] [ element; text "["; Integer.render length; text "]" ]
end

module Env = struct
  let rec search f t name =
    match f t name with
    | Literal x -> x
    | Name n ->
      let in_module =
        match n.Name.qualification with
        | In_current_scope -> name.Name.Qualified.in_module
        | In_module s -> s
      in
      search f t { in_module; ident = n.ident }

  module Single = struct
    type 'a t = 'a Or_name.t Name.Qualified.Map.t

    let find_exn (t : _ t) name =
      search Map.find_exn t name

    let find_exn t name =
      try find_exn t name
      with _ -> raise (Not_found_s (Name.Qualified.sexp_of_t name))

    let empty = Name.Qualified.Map.empty
  end

  type t =
    { types : Type.literal Single.t
    ; values : Value.literal Single.t
    }

  let find_type_exn t name =
    Single.find_exn t.types name

  let find_value_exn t name = Single.find_exn t.values name

  let find_field_exn t name =
    search (fun t n ->
        match Single.find_exn t n with
        | Type.Field (Name n) -> Name n
        | Type.Field (Literal f) -> 
          Literal f
        | _ -> failwithf !"Name %{Name.Qualified} does not refer to a field" name ())
      t.types 
      name

  module Deref = struct
    let named ~scope env ~f = function
      | Literal l -> l
      | Name { qualification; ident } -> 
        let in_module = 
          match qualification with
          | In_current_scope -> scope
          | In_module s -> s
        in
        f env {Name.Qualified. in_module ; ident }

    let type_ ~scope = named ~scope ~f:find_type_exn

    let field ~scope = named ~scope ~f:find_field_exn

    let rec bigint : scope:string -> t -> Integer.t -> Bigint.t =
      fun ~scope t0 x0 ->
      match named ~scope t0 x0 ~f:find_value_exn with
      | Value n -> n
      | Add (x1, x2) ->
        Bigint.(bigint ~scope t0 x1 + bigint ~scope t0 x2)
      | Sub (x1, x2) ->
        Bigint.(bigint ~scope t0 x1 - bigint ~scope t0 x2)
  end

  let empty = { types = Single.empty; values = Single.empty }
end

module Representation = struct
  type t =
    | Array of { element : t ; length : Integer.t }
    | Sequence of t * string * t
    | Record of (string * t) list
    | UInt64

  let limb = UInt64
  let size_in_limbs n =
    let limb_size = 64 in
    let rec go i =
      if Bigint.( (of_int 1 lsl Int.(limb_size * i)) > n)
      then i
      else go (i + 1)
    in
    go 1

  let rec of_field ~scope (env : Env.t) (f : Type.Field.t) =
    match Env.Deref.field ~scope env f with
    | Prime { order } -> 
      let order = Env.Deref.bigint ~scope env order in
      let length = Bigint.of_int (size_in_limbs order) in
      Array { element= limb; length = Literal (Value length) }
    | Extension { base; degree; non_residue=_ } ->
      let base = of_field ~scope env base in
      Array { element= base
            ; length= Literal (Value (Bigint.of_int degree)) }

  let rec of_type ~scope (env : Env.t) (t : Type.t) =
    let open Or_error.Let_syntax in
    match Env.Deref.type_ ~scope env t with
    | UInt64 -> Ok UInt64
    | Integer -> Or_error.error_string "Integer does not have a conrete representation"
    | Field f -> Ok (of_field ~scope env f)
    | Curve { field; a=_; b=_ } ->
      let field = of_field ~scope env field in
      Ok (Record [ "x", field; "y", field ])
    | Record ts ->
      let%map rs =
        (List.map ts ~f:(fun (name, t) ->
            let%map r = of_type ~scope env t in (name, r)) |> Or_error.all)
      in
      Record rs
    | Polynomial { degree; field } ->
      of_type ~scope env 
        (Literal (Array 
                    { element=
                        Literal (Field field)
                    ; length=Some (Or_name.map ~f:(fun d -> Integer.Value (Bigint.of_int d)) degree)}))
    | Linear_combination { field } ->
      let field = of_field ~scope env field in
      let element =
        Record [ ("coefficient", field); ("variable", UInt64) ]
      in
      Ok (
      Sequence
        (UInt64
        , "num_terms"
        , Array { element; length=Name (Name.local "num_terms") }))

    | Array { element; length } ->
      let%map element = of_type ~scope env element in
      begin match length with
      | None ->
        Sequence ( UInt64, "n", Array { element; length= Name(Name.local "n") } )
      | Some length ->
        Array { element; length }
      end

  let rec render = 
    let open Html in
    function
    | UInt64 -> text "uint64"
    | Record ts ->
      ul []
        (List.map ts ~f:(fun (name, t) ->
            li [] [ text name; text ":"; render t ]))
    | Array {element; length} ->
      let element = render element in
      span [] [ element; text "["; Integer.render length; text "]" ]
    | Sequence (t1, name1, t2) ->
      let t1 = render t1 in
      let t2 = render t2 in
      div [ class_ "representation-sequence" ]
        [ div [ class_ "representation-sequence-item" ]
            [ span [] [text name1; text ":"; t1]
            ]
        ; div [ class_ "representation-sequence-item" ]
            [ t2
            ]
        ]
end

module Groth16 = struct
  (*
     Parameters:
     A QAP with

     query density like 
      At=184187/239993, Bt=175307/239993
  *)
end

(*
Want a page like 

MNT
p : Integer = ...
q : Integer = ...

a : Field q = ..
b : Field q = ..

G1 : Type = Curve { field: Field q; a = a; b = b }
   representation:
   struct {
    x : [Field q](Link to synthesized page for this field which explains the representation)
    y : Field q
   }

G2 : Type = ..
*)

let warning fmt =
  ksprintf (fun s ->
      eprintf "Warning: %s\n%!" s)
    fmt

module Module = struct
  module Declaration = struct
    type t =
      { name : string
      ; value : [`Value of (Value.t * Type.t) | `Type of Type.t]
      }
  end

  type t = 
    { declarations : Declaration.t list
    ; name : string }

  module Page = struct
    module Entry = struct
      type t =
        | Value_declaration of { name : string; type_ : Type.t; value: Value.t }
        | Type_declaration of {
            name : string;
            type_ : Type.t;
            representation : Representation.t option }
    end

    type t = 
      { title : string
      ; entries : Entry.t list }

    let render { title; entries } =
      let open Html in
      let entry (e : Entry.t) =
        match e with
        | Value_declaration {name; type_; value} ->
          div [ class_ "entry value" ]
            [ Name.render (Name.local name)
            ; text ":"
            ; Type.render type_
            ; text "="
            ; Value.render value
            ]
        | Type_declaration { name; type_; representation } ->
          div [ class_ "entry type" ]
            ([ Name.render (Name.local name)
            ; text "="
            ; Type.render type_
           ] @
             Option.(to_list (map representation ~f:(fun r ->
               div [ class_ "representation" ]
                [ h2 [] [ text "Binary representation" ]
                ; Representation.render r
                ])))
            )
      in
      div [ class_ "module" ]
        [ h1 [] [ text title ]
        ; div [ class_ "entries" ]
            (List.map entries ~f:entry)
        ]
  end

  let to_page env { declarations; name=title } =
    let entry { Declaration.name ;value } =
      match value with
      | `Value (v, t) ->
        Page.Entry.Value_declaration { name; type_ = t; value = v}
      | `Type t ->
        let representation =
          match Representation.of_type ~scope:title env t with
          | Error e ->
            warning !"%{sexp:Error.t}" e;
            None
          | Ok r -> Some r
        in
        Type_declaration 
          { name
          ; type_=t
          ; representation }
    in
    { Page.title
    ; entries = List.map declarations ~f:entry
    }

  let (^:) x y = (x, y)

  let (=) f x = f x

  let let_ (name, ty) rhs = { Declaration.name; value = `Value (rhs, ty) }

  let let_type name ty = { Declaration.name; value = `Type ty }

  let module_ name ~declarations = { name ; declarations }

  let mnt4753 : t = 
    let var x = Name (Name.local x) in
    let fq = Type.Field.prime (var "q") in
    module_ "MNT4753" ~declarations:[
      let_ ("r" ^: Type.integer) = Value.integer "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001" ;
      let_ ("q" ^: Type.integer) = Value.integer "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601" ;
      let_ ("a" ^: Type.field fq) = Value.integer "2";
      let_ ("b" ^: Type.field fq) = Value.integer "28798803903456388891410036793299405764940372360099938340752576406393880372126970068421383312482853541572780087363938442377933706865252053507077543420534380486492786626556269083255657125025963825610840222568694137138741554679540";
      let_type "G_1" = Type.curve fq ~a:(var "a") ~b:(var "b");
    ]

  let mnt6753 : t = 
    let var x = Name (Name.local x) in
    let fq = Type.Field.prime (var "q") in
    module_ "MNT6753" ~declarations:[
      let_ ("r" ^: Type.integer) = Value.integer "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601" ;
      let_ ("q" ^: Type.integer) = Value.integer "41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001" ;
      let_ ("a" ^: Type.field fq) = Value.integer "11";
      let_ ("b" ^: Type.field fq) = Value.integer "11625908999541321152027340224010374716841167701783584648338908235410859267060079819722747939267925389062611062156601938166010098747920378738927832658133625454260115409075816187555055859490253375704728027944315501122723426879114";
      let_type "G_1" = Type.curve fq ~a:(var "a") ~b:(var "b");
    ]

  let update_env (env : Env.t) { name=module_name; declarations } =
    List.fold declarations ~init:env ~f:(fun env {name; value} ->
        match value with
        | `Value (v, _t) ->
          { env with values =  Map.add_exn env.values ~key:(Name.Qualified.create ~in_module:module_name name) ~data:v }
        | `Type t ->
          { env with types =  Map.add_exn env.types ~key:(Name.Qualified.create ~in_module:module_name name) ~data:t })
end

module Definitional_parameters = struct
  type t
end

module Problem = struct
  module Parameter_kind = struct
    type t =
      | Batch_parameter
      | Input
      | Output
  end

  module Interface = struct
    module F = struct
      type 'a t =
        | Declare of Parameter_kind.t * string * Type.t * (Name.t -> 'a)
        | Choose_definitional_parameter
          : 
            (Type.t, 'n) Vec.t list
            * (string, 'n) Vec.t
            * ((Name.t, 'n) Vec.t -> 'a) -> 'a t

      let map t ~f = 
        match t with
        | Choose_definitional_parameter (xs, names, k) ->
          Choose_definitional_parameter (xs, names, fun x -> f (k x))
        | (Declare (p, s, t, k)) ->
          Declare (p, s, t, fun n -> f (k n))
    end
    include Free_monad.Make(F)

    let (!) p s t = Free (Declare (p, s, t, return))

    let def names ts = Free (Choose_definitional_parameter (ts, names, return))

    module Spec = struct
      type ('a, 'n) spec =
        { definitional_parameters :  (string, 'n) Vec.t * ( Type.t, 'n) Vec.t list
        ; batch_parameters : (string * Type.t) list
        ; input : (string * Type.t) list
        ; output :(string * Type.t) list
        ; description :'a
        }
      [@@deriving fields]

      let field = function
        | Parameter_kind.Batch_parameter -> Fields_of_spec.batch_parameters
        | Input -> Fields_of_spec.input
        | Output -> Fields_of_spec.output

      type 'a t = T:('a, 'n) spec -> 'a t

      let update s pk ~f = 
        let field = field pk in
        Field.fset field s (f (Field.get field s))

      let create ~name:_ m = 
        cata
          (map m ~f:(fun description -> 
               T { description; definitional_parameters = ([], []); batch_parameters=[]; input=[]; output=[] }))
          ~f:(function
              | Declare (pk, s, t, k) ->
                let T spec =  k (Name.local s) in
                T (update spec pk ~f:(fun xs -> (s, t) :: xs))
              | Choose_definitional_parameter (choices, names, k) ->
                let T spec = k (Vec.map names ~f:(fun s -> Name.local s)) in 
                T { spec with definitional_parameters = (names, choices) })

      let render (T { description; definitional_parameters; batch_parameters; input; output }) =
        let open Html in
        let definitional_preamble =
          let (names, choices) = definitional_parameters in
          match choices with
          | [] -> []
          | _ ->
            [ span []
                ( text "The following problem is defined for any choice of ("
                  :: 
                  List.intersperse ~sep:(text ",")
                  (List.map (Vec.to_list names) ~f:(fun name ->
                        (Name.render_declaration name)))
                  @
                  [ text ") in" ] )
            ; ul []
              (List.map choices ~f:(fun choice ->
                    li []
                      (List.intersperse
                        (List.map (Vec.to_list choice) ~f:Type.render)
                        ~sep:(text ", ")
                      )
                  ) 
              )
            ; p "You can click on the types of any of the parameters, inputs, or outputs to\
                see how they will be represented in the files given to your program."
            ]
        in
        let params ?desc ~title xs =
          div 
            [ class_ "parameters" ]
            ([ h2 [] [ text title ] ]
             @ Option.to_list desc @
            [ ul [ class_ "value-list"]
                (List.map xs ~f:(fun (ident, ty) ->
                 li []
                    [ div []
                        [ span [ class_ "identifier" ] [ text ident ]
                        ; text ":"
                        ; span [ class_ "type" ] [ Type.render ty ]
                        ]
                    ; div [ class_ "representation" ]
                        [ 
                        ]
                    ]))
            ] )
        in
        let batch_parameters =
          params ~title:"Parameters"
            ~desc:(p
                "The parameters will be generated once and your submission will be allowed to \
                preprocess them in any way you like before being invoked on multiple inputs." )
            batch_parameters
        in
        let input = params ~title:"Input" input in 
        let output = params ~title:"Output" output in 
        div [ class_ "problem" ] 
          (definitional_preamble
           @ [ batch_parameters; input; output; description ])
    end
  end

  type t =
    { title                        : string
    ; interface                    : Html.t Interface.t
    ; reference_implementation_url : string
    }

  let render { title; interface; reference_implementation_url } =
    let open Html in
    div []
      [ h1 [] [ text title ]
      ; Interface.Spec.(render (create ~name:title interface))
      ; div []
          [ h2 [] [ text "Submission guidelines" ];
markdown {md|
Your submission will be run and evaluated as follows.

0. The submission-runner will randomly generate the parameters and save them to a file `PATH_TO_PARAMETERS`
1. Your binary `main` will be run with 

    ```bash
    ./main preprocess PATH_TO_PARAMETERS
    ```
    where `PATH_TO_PARAMETERS` will be replaced by the acutal path.

    Your binary can at this point, if you like, do some preprocessing of the parameters and
    save any state it would like to a file `./preprocessed`.

2. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

3. Your binary will be invoked with

    ```bash
    ./main compute PATH_TO_INPUTS
    ```

    and its runtime will be recorded. It can, if it likes, read
    the file "./preprocessed" in order to help it solve the problem.|md}
          ]
      ; hr []
      ; a [ href reference_implementation_url]
          [ text "Reference implementation" ]
      ]
end

let (^.) scope name = Name (Name.in_scope scope name)

module QAP_witness_map = struct
  (* Parameters:
     n : UInt64
     m : UInt64

     A : Poly(n, Fr)[m+1]
     B : Poly(n, Fr)[m+1]
     C : Poly(n, Fr)[m+1]

     Input:
     w : Fr[m]

     Output
     H : Poly(n, Fr)

  such that
    H(z) = (A(z)*B(z)-C(z))/Z(z)
  where
    A(z) := A_0(z) + \sum_{k=1}^{m} w_k A_k(z) + d1 * Z(z)
    B(z) := B_0(z) + \sum_{k=1}^{m} w_k B_k(z) + d2 * Z(z)
    C(z) := C_0(z) + \sum_{k=1}^{m} w_k C_k(z) + d3 * Z(z)
    Z(z) := "vanishing polynomial of set S"
 *)

  let interface =
    let open Problem.Interface in
    let%bind [ field ] =
      let curve_scopes =
        [ "MNT4753"; "MNT6753" ]
      in
      def [ "F" ] (List.map curve_scopes ~f:(fun scope -> 
          Vec.[ Type.prime_field (scope ^. "r") ]))
    in
    let%bind n = !Batch_parameter "n" (Literal UInt64) in
    let%bind m = !Batch_parameter "m" (Literal UInt64) in
    let polynomial =Literal (Type.Polynomial { degree=Name n; field = Name field}) in
    let polynomial_array x = 
      !Batch_parameter x
        (Literal 
           (Array { element=polynomial
                  ; length=Some (Literal (Integer.Add (Name m, Literal (Value Bigint.one)))) })
        )
    in
    let%bind _a = polynomial_array "A"
    and _b = polynomial_array "B"
    and _c = polynomial_array "C"
    in
    let%bind _w =
      !Input "w" 
        (Literal (Array { element=Name field; length = Some (Name m) }))
    in
    let%bind _h =
      !Output "h" polynomial
    in
    return ()
end

let latex s = sprintf "\\(%s\\)" s

module Groth16_QAP_prove = struct
  type definitional_params =
    { field : Name.t
    ; g1 : Name.t
    ; g2 : Name.t
    }

  let definitional_params =
    let open Problem.Interface in
    let%map [ field; g1; g2 ] =
      let curve_scopes =
        [ "MNT4753"; "MNT6753" ]
      in
      def [ "F"; latex "G_1"; latex "G_2"  ] 
        (List.map curve_scopes ~f:(fun scope -> 
             Vec.
               [ Type.prime_field (scope ^. "r") 
               ; scope ^. (latex "G_1")
               ; scope ^. (latex "G_2")
               ]))
    in
    {field; g1; g2}

  type batch_params =
    { num_constraints : Name.t
    ; num_vars : Name.t
    ; ca : Name.t
    ; cb : Name.t
    ; cc : Name.t
    ; at : Name.t
    ; bt1 : Name.t
    ; bt2 : Name.t
    ; lt : Name.t
    ; ht : Name.t
    ; alpha_g1 : Name.t
    ; beta_g1 : Name.t
    ; beta_g2 : Name.t
    ; delta_g1 : Name.t
    ; delta_g2 : Name.t
    }

  (* For simplicity we hardcode num_inputs = 1. *)
  let batch_params {field;g1;g2} =
    let open Problem.Interface in
    let%bind num_constraints = !Batch_parameter "n" (Literal UInt64)
    and max_degree = !Batch_parameter "N" (Literal UInt64)
    and num_vars = !Batch_parameter "m" (Literal UInt64)
    in
    let group_elt name group = !Batch_parameter name (Name group) in
    let group_array name group len =
      !Batch_parameter name
        (Literal
           (Array { element=Name group
                  ; length=Some len })
        )
    in
    let evaluation_array name =
      !Batch_parameter name
        (Literal
           (Array { element = Name field
                  ; length = Some (Literal (Add (Name max_degree, Literal (Value Bigint.one)))) }))
    in
    let num_vars_plus_one = Literal (Integer.Add (Name num_vars, Literal (Value Bigint.one))) in
    let num_vars_minus_one = Literal (Integer.Sub (Name num_vars, Literal (Value Bigint.one))) in
    let%map ca = evaluation_array "ca"
    and cb = evaluation_array "cb"
    and cc = evaluation_array "cc"
    and at = group_array "At" g1 num_vars_plus_one
    (* At[i] = u_i(x) = A_i(t) *)
    and bt1 = group_array "Bt1" g1 num_vars_plus_one
    and bt2 = group_array "Bt2" g2 num_vars_plus_one
    and lt = group_array "Lt" g1 num_vars_minus_one
    (* Lt[i] 
       = (beta u_i(t) + alpha v_i(t) + w_i(t)) / delta
       = (beta At[i] + alpha Bt[i] + Ct[i]) / delta
    *)
    and ht = group_array "Ht" g1 (Name max_degree) (* TODO: Possibly minus one? *)
    and alpha_g1 = group_elt (latex "\\alpha") g1
    and beta_g1 =group_elt (latex "\\beta_1") g1
    and beta_g2 =group_elt (latex "\\beta_2") g2
    and delta_g1 = group_elt (latex "\\delta_1") g1
    and delta_g2 = group_elt (latex "\\delta_2") g2
    in
    (* Note: Here is a dictionary between the names in libsnark and the names in Groth16.

       Z(t)   <-> t(x)
       A_i(t) <-> u_i(x) 
       B_i(t) <-> v_i(x) 
       C_i(t) <-> w_i(x)  *)
    (* Ht[i]
       = (Z(t) / delta) t^i
    *)
    (*
       param At.
       input r.
       input w.

       proof element a =

       alpha_g1 + \sum_{i=0}^m w[i] * At[x] + r delta

       ----
       OR
       ----
       param A.
       param T.
       input r.
       input w.

       At[i] == eval(A[i], t) == \sum_{j=1}^n A[i][j] * T[j]

       proof element a =

       alpha_g1 + \sum_{i=0}^m w[i] * At[i] + r delta
       ==
       alpha_g1 + \sum_{i=0}^m w[i] * ( \sum_{j=1}^n A[i][j] * T[j] ) + r delta

    *)
    { num_vars
    ; num_constraints
    ; ca; cb; cc
    ; at; bt1; bt2; ht; lt
    ; alpha_g1; beta_g1; beta_g2; delta_g1; delta_g2
    }

  let delatex s =
    let (>>=) = Option.(>>=) in
    match 
      String.chop_prefix ~prefix:"\\(" s
      >>= String.chop_suffix ~suffix:"\\)"
    with
    | Some s -> s
    | None -> s

  let interface =
    let open Problem.Interface in
    let%bind {field; g1; g2} as params = definitional_params in
    let field_input name = !Input name (Name field) in
    let%bind batch_params = batch_params params in
    let%bind _w =
      (* w[0] = 1 *)
      let num_vars_plus_one = Literal (Integer.Add (Name batch_params.num_vars, Literal (Value Bigint.one))) in
      !Input "w" 
        (Literal (Array { element=Name field; length = Some num_vars_plus_one }))
    and r = field_input "r" in
    let%bind selected_degree =
      !Output "d" (Literal UInt64)
    in
    let%bind _proof =
      !Output "proof"
        (Literal (Record
                 [ "A", Name g1
                 ; "B", Name g2
                 ; "C", Name g1
                ]))
    in
    let latex s = sprintf "$%s$" s in
    let description =
      let n = Fn.compose delatex Name.to_string in
      let { num_vars; alpha_g1=_; at; delta_g1=_
          ; beta_g2=_; bt2; delta_g2=_
          ; lt
          ; bt1; beta_g1=_
          ; num_constraints
          ; ht
          ; ca; cb; cc
          } = batch_params
      in
      let a_def =
        sprintf
          {md|\sum_{i=0}^{%s} w[i] \times %s[i]|md}
          (n num_vars)
          (n at)
        |> latex
        |> latex
      in
      print_endline a_def;
      let b_def_no_latex ~bt =
        sprintf
          {md|\sum_{i=0}^{%s} w[i] \times %s[i]|md}
          (n num_vars)
          (n bt)
      in
      let b1_def = b_def_no_latex ~bt:bt1 in
      let b2_def = b_def_no_latex ~bt:bt2 |> latex |> latex in
      let c_def =
        sprintf
(*           {md| \left( \sum_{i=0}^{%s - 2} w[2 + i] %s[i]\right)  + \left(\sum_{i=0}^{%s - 1} H[i] %s[i] \right) + %s A+ %s B1- (%s %s) %s|md} *)
          {md|\sum_{i=2}^{%s} w[i] \times %s[i - 2] + \sum_{i=0}^{%s - 1} H[i] \times %s[i] + %s %s|md}

          (n num_vars)
          (n lt)
          (n selected_degree)
          (n ht)
          (n r)
          b1_def
        |> latex
        |> latex
      in
      ksprintf Html.markdown
        {md|This problem is a version of the [Groth16 SNARK prover](https://eprint.iacr.org/2016/260.pdf), simplified to the difficult core of the problem.

If $P, Q$ are points on an elliptic curve (either $%s$ or $%s$) and $s : %s$, then
$P + Q$ denotes the sum of the points as described [here](https://en.wikipedia.org/wiki/Elliptic_curve#The_group_law)
and $s \times P$ denotes the scalar-multiplication of $P$ by $s$ as described [here](https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Basics).

The output should be as follows.

- A = %s
- B = %s
- C = %s

where

- H is an array of the coefficients of the polynomial
  $h(x) = \frac{a(x) b(x) - c(x)}{z(x)}$
  where $a, b, c$ are the degree %s
  polynomials specified by

$$
\begin{aligned}
  a(\omega_i) &= %s[i] \\
  b(\omega_i) &= %s[i] \\
  c(\omega_i) &= %s[i] \\
\end{aligned}
$$

  for $0 \leq i < %s + 1$.
|md}
        (n g1)
        (n g2)
        (n field)
a_def
b2_def
c_def
(n selected_degree)
(n ca)
(n cb)
(n cc)
(n num_constraints)
    in
    return description

  let problem : Problem.t =
    { title = "Groth16Prove"
    ; interface
    ; reference_implementation_url = ""
    }
end

module Multiexp = struct
  module Definitional_parameters = struct
    type t = unit
  end

  let interface =
    let open Problem.Interface in
    let%bind [group;scalar] =
      let curve_scopes =
        [ "MNT4753"; "MNT6753" ]
      in
      let group_names = [ latex "G_1"; latex "G_2" ] in
      def [ "G"; "Scalar" ] List.Let_syntax.(
          let%map scope = curve_scopes
          and group = group_names in
          Vec.[ scope ^. group
          ; Type.prime_field (scope ^. "r")
          ])
    in
    let%bind n = ! Batch_parameter "n" (Literal UInt64) in
    let%bind _g = ! Batch_parameter "g" (Literal (Array {element=Name group; length=Some(Name n) })) in
    let%bind _s = ! Input "s" (Literal (Array { element=Name scalar; length=Some (Name n)})) in
    let%bind _y = ! Output "y" (Name group) in
    let description =
        Html.markdown
{md|The output should be the multiexponentiation with the scalars `s`
on the bases `g`. In other words, the group element
`s[0] * g[0] + s[1] * g[1] + ... + s[n - 1] * g[n - 1]`.|md}
    in
    return description

  let problem : Problem.t =
    { interface
    ; title = "Multi-exponentiation"
    ; reference_implementation_url =""
    }
end

let wrap cs =
  let open Html in
  node "html" []
    [ node "head" []
        [ literal {h|<meta charset="UTF-8">|h}
        ; literal {h|<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.10.1/dist/katex.min.css" integrity="sha384-dbVIfZGuN1Yq7/1Ocstc1lUEm+AT+/rCkibIcC/OmWo5f0EA48Vf8CytHzGrSwbQ" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.10.1/dist/katex.min.js" integrity="sha384-2BKqo+exmr9su6dir+qCw08N2ZKRucY4PrGQPPWU1A7FtlCGjmEGFqXCv5nyM5Ij" crossorigin="anonymous"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.10.1/dist/contrib/auto-render.min.js" integrity="sha384-kWPLUVMOks5AQFrykwIup5lo0m3iMkkHrD0uJ4H5cjeGihAutqP0yW0J6dpFiVkI" crossorigin="anonymous"
    onload="renderMathInElement(document.body);"></script>|h}
        ]
    ; Html.literal
        {html|<script>
          document.addEventListener("DOMContentLoaded", function() {
            var blocks = document.querySelectorAll(".math.display");
            for (var i = 0; i < blocks.length; i++) {
              var b = blocks[i];
              katex.render(b.innerText, b, {displayMode:true});
            }
            blocks = document.querySelectorAll(".math.inline");
            for (var i = 0; i < blocks.length; i++) {
              var b = blocks[i];
              katex.render(b.innerText, b, {displayMode:false});
            }
          });
        </script>|html}
    ; node "body" [] cs ]

let site =
  let open Stationary in
  let modules = 
    [ Module.mnt4753
    ; Module.mnt6753
    ]
  in
  let env =
    List.fold modules ~init:Env.empty ~f:Module.update_env
  in
  let problems =
    [ Multiexp.problem
    ; Groth16_QAP_prove.problem
    ]
  in
  Site.create (
    List.map modules ~f:(fun m ->
        File_system.file
          (File.of_html ~name:(Filename.basename (Name.module_url m.name))
             (wrap [ Module.(Page.render (to_page env m)) ])
          )
      )
    @
    List.map problems  ~f:(fun p ->
        File_system.file
          (File.of_html ~name:(sprintf "problem-%s.html" p.title)
            (wrap [ Problem.render p ])))
  )

let () =
  let open Async in
  Command.async  ~summary:"" (Command.Param.return (fun () ->
      Site.build ~dst:"_site" site
(*
      let%map s = 
        Html.to_string
          (wrap [ Problem.render Multiexp.problem ])
      in
      print_endline "<!DOCTYPE html>";
      print_endline s
*)
    ))
  |> Command.run

(* Description:
   For a group G \in { MNT6753.G1, MNT6753.G2, MNT4753.G1, MNT4753.G2 }, implement
   fixed-based multiexponentiation over G.

   Parameters: 
    - n : UInt32
    - g : Array(G) of length n

   Input:
   - s : Array(Integer) of length n

   Output :
   - y : G

    The output should be the multiexponentiation with the scalars `s`
    on the bases `g`. In other words, the group element
    `s[0] * g[0] + s[1] * g[1] + ... + s[n - 1] * g[n - 1]`.

   # Expected interface for your submission.

   Parameters will be generated randomly and saved to a file `PATH_TO_PARAMETERS`

   Your binary `main` will be run with 
   ```bash
   ./main preprocess PATH_TO_PARAMETERS
   ```
   where `PATH_TO_PARAMETERS` will be replaced by the acutal path.

   Your binary can at this point, if you like, do some preprocessing of the parameters and
   save any state it would like to a file `./preprocessed`.

   Our program will then be run to generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

   Your binary will then be invoked with
   ```bash
   ./main compute PATH_TO_INPUTS
   ```
   where `PATH_TO_INPUTS` will be replaced by the actual path. It can, if it likes, read
   the file "./preprocessed" in order to help it solve the problem.
*)

module FFT = struct
  type t = unit
end

(* Spec pages
   Problem pages *)

module Spec_page = struct
end

module Constant = struct
  type t =
    { name : string
    ; value : Value.t
    }
end
