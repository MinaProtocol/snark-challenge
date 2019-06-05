open Core_kernel
open Snarkette
open Fold_lib
open Tuple_lib
open Mnt6753
open Js_of_ocaml

type fn = Function of {name: string; dependencies: fn list}

let verifier =
  let fn name dependencies = Function {name; dependencies} in
  fn "boweGabizonVerifier"
    [ fn "hashToGroup" [fn "pedersenHash" []; fn "groupMap" []]
    ; fn "boweGabizonVerifierCore" [] ]

type preprocessed_verification_key = < > Js.t

type js_fq = Typed_array.uint32Array Js.t

type js_fr = js_fq

type 'a affine_point = < x: 'a Js.readonly_prop ; y: 'a Js.readonly_prop > Js.t

type js_fq3 =
  < a: js_fq Js.readonly_prop
  ; b: js_fq Js.readonly_prop
  ; c: js_fq Js.readonly_prop >
  Js.t

type js_fq6 = < a: js_fq3 Js.readonly_prop ; b: js_fq3 Js.readonly_prop > Js.t

type js_g1 = js_fq affine_point

type js_g2 = js_fq3 affine_point

type js_proof =
  < a: js_g1 Js.readonly_prop
  ; b: js_g2 Js.readonly_prop
  ; c: js_g1 Js.readonly_prop
  ; deltaPrime: js_g2 Js.readonly_prop
  ; z: js_g1 Js.readonly_prop
  ; yS: js_g1 Js.readonly_prop >
  Js.t

type js_verification_key =
  < alphaBeta: js_fq6 Js.readonly_prop
  ; delta: js_g2 Js.readonly_prop
  ; query: js_g1 Js.js_array Js.t Js.readonly_prop >
  Js.t

let submission_runtime = ref Time.Span.zero

let time f =
  let start = Time.now () in
  let x = f () in
  let stop = Time.now () in
  (Time.diff stop start, x)

let user_code f =
  let runtime, x = time f in
  submission_runtime := Time.Span.( + ) !submission_runtime runtime ;
  x

let limb_size = 32

let num_limbs = 24

let () = assert (num_limbs * limb_size = 768)

let () =
  let zero : js_fq =
    let r = new%js Typed_array.uint32Array num_limbs in
    for i = 0 to num_limbs - 1 do
      Typed_array.set r i 0.
    done ;
    r
  in
  Js.Unsafe.global##.pedersenHash
  := Js.wrap_callback (fun (_ : _) -> (zero : js_fq)) ;
  Js.Unsafe.global##.verifierCore
  := Js.wrap_callback (fun (_vk : _) _input _proof -> (Js._true : bool Js.t))

let pedersenHash (ts : bool Js.t Js.js_array Js.t Js.js_array Js.t) : js_fq =
  user_code (fun () -> Js.Unsafe.global##pedersenHash ts)

let verifierCore (vk : js_verification_key) (input : js_fr) (proof : js_proof)
    : bool Js.t =
  user_code (fun () -> Js.Unsafe.global##verifierCore vk input proof)

module H = Bowe_gabizon_hash.Make (struct
  module Field = struct
    include Mnt6753.Fq

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

  let params =
    Group_map.Params.create
      (module Mnt6753.Fq)
      ~a:G1.Coefficients.a ~b:G1.Coefficients.b

  let uint32_array_foldi (t : Typed_array.uint32Array Js.t) ~(init : 'acc)
      ~(f : int -> 'acc -> int -> 'acc) : 'acc =
    let n = t##.length in
    let rec go acc i =
      if i = n then acc
      else
        let x : int = Obj.magic (Typed_array.unsafe_get t i) in
        go (f i acc x) (i + 1)
    in
    go init 0

  let pedersen (ts : bool Triple.t Fold.t) : Fq.t =
    let res = new%js Js.array_empty in
    ts.fold ~init:() ~f:(fun () (b0, b1, b2) ->
        let t = new%js Js.array_empty in
        t##push (Js.bool b0) |> ignore ;
        t##push (Js.bool b1) |> ignore ;
        t##push (Js.bool b2) |> ignore ;
        res##push t |> ignore ) ;
    let x = pedersenHash res in
    let fold_f i acc (x : int) =
      N.(log_or acc (shift_left (of_int x) Int.(32 * i)))
    in
    let fq_of_nat : N.t -> Fq.t = Obj.magic in
    fq_of_nat (uint32_array_foldi x ~init:(N.of_int 0) ~f:fold_f)
end)

module V = Bowe_gabizon.Make (struct
  include Mnt6753
  module Fqe = Mnt6753.Fq3
  module Fq_target = Mnt6753.Fq6

  let hash = H.hash
end)

let verify =
  let conv_fq : Fq.t -> js_fq =
   fun x ->
    let n = Fq.to_bigint x in
    let res = new%js Typed_array.uint32Array num_limbs in
    for i = 0 to num_limbs - 1 do
      let rec loop acc j =
        if j = limb_size then acc
        else
          let acc =
            if N.test_bit n ((i * limb_size) + j) then acc lor (1 lsl j)
            else acc
          in
          loop acc (j + 1)
      in
      let int_to_float : int -> float = Obj.magic in
      Typed_array.set res i (int_to_float (loop 0 0))
    done ;
    res
  in
  let conv_fq3 ((a, b, c) : Fq3.t) : js_fq3 =
    object%js
      val a = conv_fq a

      val b = conv_fq b

      val c = conv_fq c
    end
  in
  let conv_fq6 ((a, b) : Fq6.t) : js_fq6 =
    object%js
      val a = conv_fq3 a

      val b = conv_fq3 b
    end
  in
  let conv_g1 (p : G1.t) : js_g1 =
    let x, y = G1.to_affine_coordinates p in
    object%js
      val x = conv_fq x

      val y = conv_fq y
    end
  in
  let conv_g2 (p : G2.t) : js_g2 =
    let x, y = G2.to_affine_coordinates p in
    object%js
      val x = conv_fq3 x

      val y = conv_fq3 y
    end
  in
  let conv_proof ({a; b; c; delta_prime; z} : V.Proof.t) : js_proof =
    object%js
      val a = conv_g1 a

      val b = conv_g2 b

      val c = conv_g1 c

      val deltaPrime = conv_g2 delta_prime

      val z = conv_g1 z

      val yS = conv_g1 (H.hash ?message:None ~a ~b ~c ~delta_prime)
    end
  in
  fun (proof : V.Proof.t) (vk : V.Verification_key.t) (input : Fq.t) ->
    ( submission_runtime := Time.Span.zero ;
      let full_time, res =
        time (fun () ->
            let query = new%js Js.array_empty in
            query##push (conv_g1 vk.query.(0)) |> ignore ;
            query##push (conv_g1 vk.query.(1)) |> ignore ;
            let vk =
              object%js
                val alphaBeta = conv_fq6 vk.g_alpha_h_beta

                val delta = conv_g2 vk.h_delta

                val query = query
              end
            in
            Js.to_bool (verifierCore vk (conv_fq input) (conv_proof proof)) )
      in
      let overhead = Time.Span.(full_time - !submission_runtime) in
      printf !"overhead = %{Time.Span}\n%!" overhead ;
      res
      : bool )

let fake_vk : V.Verification_key.t =
  {g_alpha_h_beta= Fq6.one; h_delta= G2.one; query= [|G1.one; G1.one|]}

let fails_on_second_check : V.Proof.t =
  let delta_prime = G2.one in
  let a = G1.one in
  let b = G2.one in
  let c = G1.(negate one) in
  let z = G1.one in
  {a; b; c; z; delta_prime}

(*

  e(a, b)
  === alphaBeta
      * e(G1.add(vk.query[0], G1.scale(input, vk.query[1])), G2.one)
      * e(proof.c, proof.deltaPrime)

  e(1, 1)
  === 
  e(vk.query[0] + G1.scale(input, vk.query[1]), 1)
  * e(c, deltaPrime)

*)

let fake_proof : V.Proof.t =
  let delta_prime = G2.one in
  let a = G1.one in
  let b = G2.one in
  let c = G1.(negate one) in
  let z = G1.one in
  {a; b; c; z; delta_prime}

let input = N.of_int 1

let _ = verify fake_proof fake_vk (Obj.magic input)

(*
let () =
  printf
    !"%{sexp:unit Or_error.t}\n%!"
    (V.verify (V.Verification_key.Processed.create fake_vk) [input] fails_on_second_check)
*)
