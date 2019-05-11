open Core
open Util

type curve =
  | MNT4
  | MNT6

let param name curve_scope =
  let s = (match curve_scope with
    | MNT4 -> "MNT4"
    | MNT6 -> "MNT6") ^ "753"
  in
  Name.in_scope s name|> Name.to_markdown

let q = param "q"
let r = param "r"

let preamble =
  ksprintf Html.markdown
{md|The basic operations needed for the SNARK prover algorithm are
multiplication and addition of integers.
Usually, when programming we're used to working with 32-bit or 64-bit
integers and addition and multiplication (mod $2^{32}$ or $2^{64}$).

// In fact, once you've implemented these operations, the rest of the prover is 

For the SNARK prover though, the integers involved are a lot bigger.
For our purposes, the integers are 753 bits and are represented using
arrays of native integers. For example, we could represent them using
an array of 12 64-bit integers (since $12 \cdot 64 = 768 > 753$) or
an array of 24 32-bit integers (since $24 \cdot 32 = 768 > 753$).
And instead of computing mod $2^{753}$, we'll compute mod $q$ where
$q$ is either %s or %s.

Note that %s = %s and %s = %s.

For 32 or 64-bit integers, addition and multiplication are primitive operations.
For larger integers (and computing mod $q$) however, we need to implement
these arithmetic operations ourselves.

This challenge will have you implement addition and multiplication mod $q$.

There are a few techniques for implementing 

https://alicebob.cryptoland.net/understanding-the-montgomery-reduction-algorithm/

Addition $\mod 
This means addition isn't a primitive operation 

The integers in question are no

These two operations |md}
(q MNT4)
(q MNT6)
(q MNT4) (r MNT6)
(q MNT6) (r MNT4)
;;

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let%bind [ q ] =
    def [ "q" ] (
      List.map ["MNT4753"; "MNT6753"] ~f:(fun c ->
          Vec.[ Name (Name.in_scope c "q")
              ])
    )
  in
  let field = Type.field (Type.Field.prime (Name q) ) in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr =
    Literal (Type.Array { element=field; length=Some (Name n) })
  in
  let%map x =
    !Input "x" arr
  and y =
    !Input "y" arr
  and output  =
    !Output "z"  arr
  in
  ksprintf Html.markdown {md|The output should be `%s[i] = %s[i] * %s[i]`
where `*` is multiplication in the field %s as described above.|md}
    (Name.to_markdown output)
    (Name.to_markdown x)
    (Name.to_markdown y)
    (Name.to_markdown q)

let problem : Problem.t =
  { title = "Field arithmetic"
  ; preamble
  ; interface
  ; reference_implementation_url = ""
  }
