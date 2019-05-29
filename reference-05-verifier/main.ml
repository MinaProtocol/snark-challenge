open Core_kernel
open Snarkette
open Fold_lib
open Mnt6753

module H = Bowe_gabizon_hash.Make(struct
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
        ~a:G1.Coefficients.a
        ~b:G1.Coefficients.b

    let pedersen= Pedersen.pedersen
  end)

module V = Bowe_gabizon.Make(struct
    include Mnt6753
    module Fqe = Mnt6753.Fq3
    module Fq_target = Mnt6753.Fq6

    let hash = H.hash
  end)

let fake_vk =
  { V.Verification_key.g_alpha_h_beta = Fq6.one
  ; h_delta = G2.one
  ; query = [| G1.one; G1.one |]
  }

let fake_proof =
  {V.Proof.a = G1.one
  ; b = G2.one
  ; c = G1.(negate one)
  ; delta_prime = G2.one
  ; z = G1.one
  }

let input = N.of_int 1

let () = printf !"%{sexp:unit Or_error.t}\n%!"
    (V.verify (V.Verification_key.Processed.create fake_vk) [input] fake_proof)
