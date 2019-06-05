open Core_kernel
open Snarkette
open Fold_lib
open Mnt6753

(* With libsnark and the 298 bit curves, the hash took 1.82ms and
   the rest of the verifier took 12.28ms, so it seems to be worth optimizing
   the hash as well. *)

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

  let pedersen = Pedersen.pedersen
end)

module V = Bowe_gabizon.Make (struct
  include Mnt6753
  module Fqe = Mnt6753.Fq3
  module Fq_target = Mnt6753.Fq6

  let hash = H.hash
end)

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
let good_proof : V.Proof.t =
  let d = N.of_int (Random.int (1 lsl 30)) in
  let delta_prime = G2.scale fake_vk.h_delta d in
  let a = G1.one in
  let b = G2.one in
  let c = G1.(negate one) in
  let z = G1.scale (H.hash ~a ~b ~c ~delta_prime ?message:None) d in
  {a; b; c; z; delta_prime}

let input = N.of_int 1

let () =
  printf
    !"%{sexp:unit Or_error.t}\n%!"
    (V.verify
       (V.Verification_key.Processed.create fake_vk)
       [input] fails_on_second_check)
