open Core
open Stationary

module Representation = struct
  type t =
    | Bignum of { num_limbs : int }
end

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
end

module Or_name = struct
  type 'a t =
    | Literal of 'a
    | Name of Name.t
end
open Or_name

module Integer = struct
  type t = Bigint.t Or_name.t
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

  let rec find_field_exn t name =
    match Single.find_exn t.types name with
    | Field (Literal f) -> f
    | Field (Name n) -> find_field_exn t n
    | _ -> failwithf !"Name %{Name} does not refer to a field" name ()
end

module Representation = struct
  type t =
    | Array of { element : t ; length : Integer.t }
    | Sequence of t * string * t
    | Record of (string * t) list
    | UInt64

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
    | Prime { order } -> size_in_limbs order


  let rec of_type (env : Env.t) (t : Type.t) =
    let ty =
      match t with
      | Name name -> Env.find_exn env name
      | Literal ty -> ty
    in
    match ty with
    | UInt64 -> Ok UInt64
    | Integer -> Or_error.error_string "Integer does not have a conrete representation"
    | Curve { field; a; b } ->
      
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
            * ((Type.t, 'n) Vec.t -> 'a) -> 'a t

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
  end

  type t =
    { title                        : string
    ; description                  : Html.t
    ; interface                    : unit Interface.t
    ; reference_implementation_url : string
    }
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
      let group_names = [ "G_1"; "G_2" ] in
      def [ "G"; "Scalar" ] List.Let_syntax.(
          let%map scope = curve_scopes
          and group = group_names in
          Vec.[ scope ^. group
          ; Type.prime_field (scope ^. "r")
          ])
    in
    let%bind n = ! Batch_parameter "n" (Literal UInt64) in
    let%bind _g = ! Batch_parameter "g" (Literal (Array {element=group; length=Some(Name n) })) in
    let%bind _s = ! Input "s" (Literal (Array { element=scalar; length=Some (Name n)})) in
    let%bind _y = ! Output "y" group in
    return ()
end

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

module Problem = struct
  type t =
    { parameters : Type.t
    }
end
