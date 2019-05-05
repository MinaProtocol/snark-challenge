open Core
open Stationary

module Html = struct
  include Html
  let div = node "div"
  let p s = node "p" [] [ text s ]
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
end

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
end

module Or_name = struct
  type 'a t =
    | Literal of 'a
    | Name of Name.t
end
open Or_name

module Integer = struct
  type t = Bigint.t Or_name.t

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

  let render = function
    | Name n -> Name.render n
    | Literal n ->
      if Bigint.(n < of_int 1000000)
      then Html.text (Bigint.to_string n)
      else Html.text (hex_string n)
end

module Value = struct
  type literal =
    | Integer of Bigint.t

  type t = literal Or_name.t

  let integer s = Literal (Integer (Bigint.of_string s))
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

  type literal =
    | UInt64
    | Field of Field.t
    | Integer
    | Curve of { field : Field.t; a : Integer.t; b : Integer.t }
    | Array of { element : t; length : Integer.t option }
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
      | Array { element; length } ->
        let element = render element in
        match length with
        | None -> span [] [ element; text "[]" ]
        | Some length ->
          span [] [ element; text "["; Integer.render length; text "]" ]
end

module Env = struct
  module Single = struct
    type 'a t = 'a Or_name.t Name.Map.t

    let rec find_exn t name =
      match Map.find_exn t name with
      | Literal x -> x
      | Name n -> find_exn t n
  end

  type t =
    { types : Type.literal Single.t
    ; values : Value.literal Single.t
    }

  let find_type_exn t name = Single.find_exn t.types name

  let find_value_exn t name = Single.find_exn t.values name

  let find_bigint_exn t name =
    match find_value_exn t name with
    | Integer n -> n

  let rec find_field_exn t name =
    match Single.find_exn t.types name with
    | Field (Literal f) -> f
    | Field (Name n) -> find_field_exn t n
    | _ -> failwithf !"Name %{Name} does not refer to a field" name ()

  module Deref = struct
    let named env ~f = function
      | Literal l -> l
      | Name x -> f env x

    let type_ = named ~f:find_type_exn
    let bigint = named ~f:find_bigint_exn
  end
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

  let rec of_field (env : Env.t) (f : Type.Field.t) =
    let f =
      match f with
      | Name n -> Env.find_field_exn env n
      | Literal f -> f
    in
    match f with
    | Prime { order } -> 
      let order = Env.Deref.bigint env order in
      let length = Bigint.of_int (size_in_limbs order) in
      Array { element= limb; length = Literal length }
    | Extension { base; degree; non_residue=_ } ->
      let base = of_field env base in
      Array { element= base; length=Literal (Bigint.of_int degree) }

  let rec of_type (env : Env.t) (t : Type.t) =
    let open Or_error.Let_syntax in
    match Env.Deref.type_ env t with
    | UInt64 -> Ok UInt64
    | Integer -> Or_error.error_string "Integer does not have a conrete representation"
    | Field f -> Ok (of_field env f)
    | Curve { field; a=_; b=_ } ->
      let field = of_field env field in
      Ok (Record [ "x", field; "y", field ])
    | Array { element; length } ->
      let%map element = of_type env element in
      match length with
      | None ->
        Sequence ( UInt64, "n", Array { element; length= Name(Name.local "n") } )
      | Some length ->
        Array { element; length }

  let rec render = 
    let open Html in
    function
    | Array {element; length} ->
      let element = render element in
      span [] [ element; text "["; Integer.render length; text "]" ]
    | _ -> failwith "TODO"
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
            representation : Representation.t }
    end

    type t = 
      { title : string
      ; entries : Entry.t list }
  end

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
      type 'n spec =
        { definitional_parameters :  (string, 'n) Vec.t * ( Type.t, 'n) Vec.t list
        ; batch_parameters : (string * Type.t) list
        ; input : (string * Type.t) list
        ; output :(string * Type.t) list
        }
      [@@deriving fields]

      let field = function
        | Parameter_kind.Batch_parameter -> Fields_of_spec.batch_parameters
        | Input -> Fields_of_spec.input
        | Output -> Fields_of_spec.output

      type t = T:'n spec -> t

      let update s pk ~f = 
        let field = field pk in
        Field.fset field s (f (Field.get field s))

      let create ~name:_ m = 
        cata
          (map m ~f:(fun () -> 
              T { definitional_parameters = ([], []); batch_parameters=[]; input=[]; output=[] }))
          ~f:(function
              | Declare (pk, s, t, k) ->
                let T spec =  k (Name.local s) in
                T (update spec pk ~f:(fun xs -> (s, t) :: xs))
              | Choose_definitional_parameter (choices, names, k) ->
                let T spec = k (Vec.map names ~f:(fun s -> Name.local s)) in 
                T { spec with definitional_parameters = (names, choices) })

      let render (T { definitional_parameters; batch_parameters; input; output }) =
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
           @ [ batch_parameters; input; output ])
    end
  end

  type t =
    { title                        : string
    ; description                  : Html.t
    ; interface                    : unit Interface.t
    ; reference_implementation_url : string
    }

  let render { title; description; interface; reference_implementation_url } =
    let open Html in
    div []
      [ h1 [] [ text title ]
      ; Interface.Spec.(render (create ~name:title interface))
      ; description
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
      let group_names = [ "\\(G_1\\)"; "\\(G_2\\)" ] in
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
    return ()

  let problem : Problem.t =
    { interface
    ; title = "Multi-exponentiation"
    ; description = 
        Html.markdown
{md|The output should be the multiexponentiation with the scalars `s`
on the bases `g`. In other words, the group element
`s[0] * g[0] + s[1] * g[1] + ... + s[n - 1] * g[n - 1]`.|md}
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
    ; node "body" [] cs ]

let () =
  let open Async in
  Command.async  ~summary:"" (Command.Param.return (fun () ->
      let%map s = 
        Html.to_string
          (wrap [ Problem.render Multiexp.problem ])
      in
      print_endline "<!DOCTYPE html>";
      print_endline s
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
