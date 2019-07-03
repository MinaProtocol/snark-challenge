open Snarkette
open Core_kernel
open Js_of_ocaml
open Fold_lib
module Fq = Mnt6753.Fq
module N = Mnt6753.N

class type ['a] simple_field_object =
  object
    method one : 'a Js.readonly_prop

    method equal : 'a -> 'a -> bool Js.t Js.meth

    method add : 'a -> 'a -> 'a Js.meth

    method sub : 'a -> 'a -> 'a Js.meth

    method mul : 'a -> 'a -> 'a Js.meth

    method div : 'a -> 'a -> 'a Js.meth

    method negate : 'a -> 'a Js.meth
  end

class type ['a] field_object =
  object
    inherit ['a] simple_field_object

    method square : 'a -> 'a Js.meth

    method sqrt : 'a -> 'a Js.meth

    method isSquare : 'a -> bool Js.t Js.meth

    method isZero : 'a -> bool Js.t Js.meth

    method ofString : Js.js_string Js.t -> 'a Js.meth

    method toString : 'a -> Js.js_string Js.t Js.meth

    method ofInt : int -> 'a Js.meth

    method toBits : 'a -> bool Js.t Js.js_array Js.t Js.meth

    method ofBits : bool Js.t Js.js_array Js.t -> 'a Js.meth

    method toLimbs : 'a -> Typed_array.uint32Array Js.t Js.meth
  end

module type Field_intf = Snarkette.Fields.Fp_intf with type nat := N.t

let make_field_object (type t) (module M : Field_intf with type t = t) :
    t field_object Js.t =
  let of_bigint : N.t -> M.t = Obj.magic in
  object%js
    val one = M.one

    method equal x y = Js.bool M.(equal x y)

    method add x y = M.(x + y)

    method sub x y = M.(x - y)

    method mul x y = M.(x * y)

    method div x y = M.(x / y)

    method negate x = M.negate x

    method square x = M.square x

    method sqrt x = M.sqrt x

    method isSquare x = Js.bool (M.is_square x)

    method isZero x = Js.bool (M.equal M.zero x)

    method ofString s = M.of_string (Js.to_string s)

    method toString x = Js.string (M.to_string x)

    method ofInt n = M.of_int n

    method toBits x =
      let n = M.to_bigint x in
      let arr = new%js Js.array_empty in
      for i = 0 to M.length_in_bits - 1 do
        arr##push (Js.bool (N.test_bit n i)) |> ignore
      done ;
      arr

    method toLimbs x =
      let n = M.to_bigint x in
      let limb_size = 32 in
      let size_in_limbs = 24 in
      let limb i =
        let offset = i * limb_size in
        let rec go acc j =
          if i < 0 then acc
          else
            let acc = acc lsl 1 in
            let acc = if N.test_bit n (offset + j) then acc lor 1 else acc in
            go acc (j - 1)
        in
        go 0 (limb_size - 1)
      in
      let arr = new%js Typed_array.uint32Array size_in_limbs in
      for i = 0 to size_in_limbs - 1 do
        let float_of_int : int -> float = Obj.magic in
        Typed_array.set arr i (float_of_int (limb i))
      done ;
      arr

    method ofBits (bs : bool Js.t Js.js_array Js.t) : t =
      let one = N.of_int 1 in
      let opt_def_get : 'a Js.Optdef.t -> 'a = Obj.magic in
      let rec go acc i =
        if i < 0 then of_bigint acc
        else
          let acc = N.shift_left acc 1 in
          let acc =
            if Js.to_bool (opt_def_get (Js.array_get bs i)) then
              N.log_or acc one
            else acc
          in
          go acc (i - 1)
      in
      go (N.of_int 0) (M.length_in_bits - 1)
  end

module Fr =
  Snarkette.Fields.Make_fp
    (N)
    (struct
      let order = Snarkette.Mnt4753.Fq.order
    end)

let group_map_params =
  Group_map.Params.create
    (module Mnt6753.Fq)
    ~a:Mnt6753.G1.Coefficients.a ~b:Mnt6753.G1.Coefficients.b

module H = Bowe_gabizon_hash.Make (struct
  module Field = struct
    include Snarkette.Mnt6753.Fq

    let to_bits = Fn.compose Fold.to_list fold_bits

    let of_bits x = Option.value_exn (of_bits x)
  end

  module Fqe = struct
    include Mnt6753.Fq3

    let parts = to_base_elements
  end

  module G1 = Mnt6753.G1
  module G2 = Mnt6753.G2

  module Bigint = struct
    include Mnt6753.N

    let of_field = Fq.to_bigint
  end

  let params = group_map_params

  let pedersen = Pedersen.pedersen
end)

module V = Bowe_gabizon.Make (struct
  include Mnt6753
  module Fqe = Mnt6753.Fq3
  module Fq_target = Mnt6753.Fq6

  let hash = H.hash
end)

let test_case () =
  let open Mnt6753 in
  let scalar () = N.of_int (Random.int Int.max_value) in
  let g scale = scale (scalar ()) in
  let g1 () = g G1.(scale one) in
  let g2 () = g G2.(scale one) in
  let a = g1 () in
  let b = g2 () in
  let c = g1 () in
  let delta_scalar = scalar () in
  let delta_g2 = G2.(scale one) delta_scalar in
  let d = scalar () in
  let delta_prime = G2.(scale delta_g2) d in
  let y_s = H.hash ?message:None ~a ~b ~c ~delta_prime in
  let z = G1.scale y_s d in
  let query = Array.init 2 ~f:(fun _ -> g1 ()) in
  let input =
    let zero = Char.to_int '0' in
    N.of_string
      (String.init 225 ~f:(fun _ -> Char.of_int_exn (zero + Random.int 10)))
  in
  let alpha_beta =
    let open Pairing in
    let ml p q =
      miller_loop (G1_precomputation.create p) (G2_precomputation.create q)
    in
    (* e(A, B) - (e((q0 + I*q1), 1) + e(C, delta_prime)) = ab
    *)
    let open Fq6 in
    final_exponentiation
      ( ml a b
      / (ml G1.(query.(0) + scale query.(1) input) G2.one * ml c delta_prime)
      )
  in
  ( {V.Verification_key.alpha_beta; delta= delta_g2; query}
  , input
  , {V.Proof.a; b; c; delta_prime; z} )

type 'a affine_point = < x: 'a Js.readonly_prop ; y: 'a Js.readonly_prop > Js.t

type 'a jacobian_point =
  < x: 'a Js.readonly_prop ; y: 'a Js.readonly_prop ; z: 'a Js.readonly_prop >
  Js.t

let conv_g1 (p : Mnt6753.G1.t) : Fq.t affine_point =
  let x, y = Mnt6753.G1.to_affine_coordinates p in
  object%js
    val x = x

    val y = y
  end

let unconv_g1 (p : Fq.t affine_point) = (p##.x, p##.y)

type fq3 =
  < a: Fq.t Js.readonly_prop
  ; b: Fq.t Js.readonly_prop
  ; c: Fq.t Js.readonly_prop >
  Js.t

let conv_fq3 ((a, b, c) : Mnt6753.Fq3.t) : fq3 =
  object%js
    val a = a

    val b = b

    val c = c
  end

let unconv_fq3 (x : fq3) : Mnt6753.Fq3.t = (x##.a, x##.b, x##.c)

let conv_g2 (p : Mnt6753.G2.t) : fq3 affine_point =
  let x, y = Mnt6753.G2.to_affine_coordinates p in
  object%js
    val x = conv_fq3 x

    val y = conv_fq3 y
  end

type fq6 = < a: fq3 Js.readonly_prop ; b: fq3 Js.readonly_prop > Js.t

let conv_fq6 ((a, b) : Mnt6753.Fq6.t) : fq6 =
  object%js
    val a = conv_fq3 a

    val b = conv_fq3 b
  end

let unconv_fq6 (x : fq6) : Mnt6753.Fq6.t = (unconv_fq3 x##.a, unconv_fq3 x##.b)

class type ['a] group_object =
  object
    method add :
      'a jacobian_point -> 'a jacobian_point -> 'a jacobian_point Js.meth

    method double : 'a jacobian_point -> 'a jacobian_point Js.meth

    method mixedAdd :
      'a jacobian_point -> 'a affine_point -> 'a jacobian_point Js.meth

    method ofAffine : 'a affine_point -> 'a jacobian_point Js.meth

    method toAffine : 'a jacobian_point -> 'a affine_point Js.meth
  end

class type pairing_object =
  let open Mnt6753.Pairing in
  object
    method g1Precompute : Fq.t jacobian_point -> G1_precomputation.t Js.meth

    method g2Precompute : fq3 jacobian_point -> G2_precomputation.t Js.meth

    method millerLoop :
      G1_precomputation.t -> G2_precomputation.t -> fq6 Js.meth

    method finalExponentiation : fq6 -> fq6 Js.meth
  end

let pairing_object : pairing_object Js.t =
  let open Mnt6753 in
  let open Pairing in
  object%js
    method g1Precompute (p : Fq.t jacobian_point) =
      let x, y, z = (p##.x, p##.y, p##.z) in
      (* x == x0 z^2
       y == y0 z^3 *)
      let z2 = Fq.square z in
      let z3 = Fq.(z2 * z) in
      G1_precomputation.create
        (G1.of_affine_coordinates (Fq.(x / z2), Fq.(y / z3)))

    method g2Precompute (p : fq3 jacobian_point) =
      let x, y, z = (unconv_fq3 p##.x, unconv_fq3 p##.y, unconv_fq3 p##.z) in
      (* x == x0 z^2
       y == y0 z^3 *)
      let z2 = Fq3.square z in
      let z3 = Fq3.(z2 * z) in
      G2_precomputation.create
        (G2.of_affine_coordinates (Fq3.(x / z2), Fq3.(y / z3)))

    method finalExponentiation (x : fq6) =
      conv_fq6 (final_exponentiation (unconv_fq6 x))

    method millerLoop p q = conv_fq6 (miller_loop p q)
  end

let fq6_object : fq6 simple_field_object Js.t =
  let open Mnt6753.Fq6 in
  let fn f x = conv_fq6 (f (unconv_fq6 x)) in
  let op f x y = conv_fq6 (f (unconv_fq6 x) (unconv_fq6 y)) in
  object%js
    val one = conv_fq6 one

    method equal x y = Js.bool (equal (unconv_fq6 x) (unconv_fq6 y))

    method add x y = op ( + ) x y

    method sub x y = op ( - ) x y

    method mul x y = op ( * ) x y

    method div x y = op ( / ) x y

    method negate x = fn negate x
  end

type verification_key =
  < alphaBeta: fq6 Js.readonly_prop
  ; delta: fq3 affine_point Js.readonly_prop
  ; query: Fq.t affine_point Js.js_array Js.t Js.readonly_prop >
  Js.t

type proof =
  < a: Fq.t affine_point Js.readonly_prop
  ; b: fq3 affine_point Js.readonly_prop
  ; c: Fq.t affine_point Js.readonly_prop
  ; deltaPrime: fq3 affine_point Js.readonly_prop
  ; z: Fq.t affine_point Js.readonly_prop >
  Js.t

let test_case () =
  let vk, input, proof = test_case () in
  let input : Fr.t = Obj.magic input in
  let vk : verification_key =
    object%js
      val alphaBeta = conv_fq6 vk.alpha_beta

      val delta = conv_g2 vk.delta

      val query = Js.array (Array.map vk.query ~f:conv_g1)
    end
  in
  let proof : proof =
    let {V.Proof.a; b; c; delta_prime; z} = proof in
    object%js
      val a = conv_g1 a

      val c = conv_g1 c

      val z = conv_g1 z

      val b = conv_g2 b

      val deltaPrime = conv_g2 delta_prime
    end
  in
  object%js
    val verificationKey = vk

    val input = input

    val proof = proof
  end

let () =
  let blake2s =
    Js.wrap_callback (fun (bits : bool Js.t Js.js_array Js.t) ->
        ( Js.to_array bits |> Array.map ~f:Js.to_bool |> Blake2.bits_to_string
          |> Blake2.digest_string |> Blake2.to_raw_string
          |> Blake2.string_to_bits |> Array.map ~f:Js.bool |> Js.array
          : bool Js.t Js.js_array Js.t ) )
  in
  Js.Unsafe.global ##. MNT6Pairing := pairing_object ;
  Js.Unsafe.global ##. MNT6Fq := make_field_object (module Fq) ;
  Js.Unsafe.global ##. MNT6Fr := make_field_object (module Fr) ;
  Js.Unsafe.global ##. MNT6Fq6 := fq6_object ;
  Js.Unsafe.global##.generateTestCase := Js.wrap_callback test_case ;
  Js.Unsafe.global##.blake2s := blake2s

module type T = sig
  type t [@@deriving compare, sexp]
end

let test_eq (type t) (module M : T with type t = t) (a : t) (b : t) : unit =
  match Or_error.try_with (fun () -> [%test_eq: M.t] a b) with
  | Ok () ->
      print_endline "Looked good"
  | Error e ->
      print_endline (Error.to_string_hum e)

module Affine = struct
  type t = Fq.t * Fq.t [@@deriving compare, sexp]
end

let test_pedersen () =
  let module G1 = Mnt6753.G1 in
  let random_bits () =
    Array.init 1 ~f:(fun _ ->
        let b = Random.bool in
        (b (), b (), b ()) )
  in
  let pedersen_hash =
    let pedersen (ts : bool Js.t Js.js_array Js.t Js.js_array Js.t) : Fq.t =
      Js.Unsafe.global##pedersenHash ts
    in
    fun bits ->
      Array.map bits ~f:(fun (a, b, c) ->
          let arr = new%js Js.array_empty in
          let f x = arr##push (Js.bool x) |> ignore in
          f a ; f b ; f c ; arr )
      |> Js.array |> pedersen
  in
  let bits = random_bits () in
  let expected = Pedersen.pedersen (Fold.of_array bits) in
  let actual = pedersen_hash bits in
  let on_curve x =
    Fq.(is_square ((x * x * x) + (G1.Coefficients.a * x) + G1.Coefficients.b))
  in
  assert (on_curve expected) ;
  assert (on_curve actual) ;
  test_eq (module Mnt6753.Fq) expected actual

let test_group_map () =
  let group_map (a : Fq.t) : Fq.t affine_point =
    Js.Unsafe.global##groupMap a
  in
  let random_fq () =
    Fq.of_bits (List.init (Fq.length_in_bits - 1) ~f:(fun _ -> Random.bool ()))
    |> Option.value_exn
  in
  let x = random_fq () in
  test_eq
    (module Affine)
    (Group_map.to_group (module Mnt6753.Fq) ~params:group_map_params x)
    (group_map x |> unconv_g1)

let test_hash_to_group () =
  let hash_to_group (a : Fq.t affine_point) (b : fq3 affine_point)
      (c : Fq.t affine_point) (delta_prime : fq3 affine_point) :
      Fq.t affine_point =
    Js.Unsafe.global##hashToGroup a b c delta_prime
  in
  let random_g1 () =
    Mnt6753.G1.(scale one) (N.of_int (Random.int Int.max_value_30_bits))
  in
  let random_g2 () =
    Mnt6753.G2.(scale one) (N.of_int (Random.int Int.max_value_30_bits))
  in
  let conv_g2 (p : Mnt6753.G2.t) : fq3 affine_point =
    let x, y = Mnt6753.G2.to_affine_coordinates p in
    object%js
      val x = conv_fq3 x

      val y = conv_fq3 y
    end
  in
  let a = random_g1 ()
  and b = random_g2 ()
  and c = random_g1 ()
  and delta_prime = random_g2 () in
  let expected =
    H.hash ~a ~b ~c ~delta_prime ?message:None
    |> Mnt6753.G1.to_affine_coordinates
  in
  let actual =
    hash_to_group (conv_g1 a) (conv_g2 b) (conv_g1 c) (conv_g2 delta_prime)
    |> unconv_g1
  in
  test_eq (module Affine) expected actual

let test_addition () =
  let module G1 = Mnt6753.G1 in
  let g1 : Fq.t group_object Js.t = Js.Unsafe.global ##. G1 in
  let p = Pedersen.pedersen_points.(0) in
  let q = Pedersen.pedersen_points.(1) in
  let actual =
    unconv_g1
      (g1##toAffine
         (g1##add (g1##ofAffine (conv_g1 p)) (g1##ofAffine (conv_g1 q))))
  in
  let expected = G1.(to_affine_coordinates (p + q)) in
  test_eq (module Affine) expected actual

let test_double () =
  let module G1 = Mnt6753.G1 in
  let g1 : Fq.t group_object Js.t = Js.Unsafe.global ##. G1 in
  let p = Pedersen.pedersen_points.(0) in
  let actual =
    unconv_g1 (g1##toAffine (g1##double (g1##ofAffine (conv_g1 p))))
  in
  let expected = G1.(to_affine_coordinates (p + p)) in
  assert (G1.is_well_formed (G1.of_affine_coordinates expected)) ;
  assert (G1.is_well_formed (G1.of_affine_coordinates actual)) ;
  test_eq (module Affine) expected actual

let test_multiscale n =
  let n = Js.Optdef.case n (fun () -> 1) Fn.id in
  let module G1 = Mnt6753.G1 in
  let g1 : Fq.t group_object Js.t = Js.Unsafe.global ##. G1 in
  let multiscale xs =
    let ps =
      Array.of_list_map xs ~f:(fun (s, g) ->
          let arr = new%js Js.array_empty in
          arr##push (Js.Unsafe.inject s) |> ignore ;
          arr##push (Js.Unsafe.inject (conv_g1 g)) |> ignore ;
          arr )
      |> Js.array
    in
    unconv_g1 (g1##toAffine (Js.Unsafe.global##multiscale ps))
  in
  let xs = [(N.of_int 13, G1.one)] in
  let expected = Pedersen.multiscale xs |> G1.to_affine_coordinates in
  let actual = multiscale xs in
  assert (G1.is_well_formed (G1.of_affine_coordinates expected)) ;
  assert (G1.is_well_formed (G1.of_affine_coordinates actual)) ;
  ignore n ;
  test_eq (module Affine) expected actual

let () =
  Js.Unsafe.global##.testHashToGroup := Js.wrap_callback test_hash_to_group ;
  Js.Unsafe.global##.testGroupMap := Js.wrap_callback test_group_map ;
  Js.Unsafe.global##.testPedersen := Js.wrap_callback test_pedersen ;
  Js.Unsafe.global##.testAddition := Js.wrap_callback test_addition ;
  Js.Unsafe.global##.testDouble := Js.wrap_callback test_double ;
  Js.Unsafe.global##.testMultiscale := Js.wrap_callback test_multiscale
