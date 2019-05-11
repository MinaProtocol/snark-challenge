open Core
open Util

type curve =
  | MNT4
  | MNT6

let p curve_scope =
  let s = (match curve_scope with
    | MNT4 -> "MNT4"
    | MNT6 -> "MNT6") ^ "753"
  in
  Name.in_scope s "q" |> Name.to_markdown

let preamble =
  ksprintf Html.markdown
    {md|Once we have multiplication mod $q$ in hand, we can 
begin implementing the group operations needed.

    The basic operations needed for the SNARK prover algorithm are
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
(p MNT4)
(p MNT6)

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let%bind [ group ] =
    def [ latex "G" ] List.Let_syntax.(
        let%map c =["MNT4753"; "MNT6753"]
        and g = [ latex "G_1"; latex "G_2" ] in
        Vec.[Name (Name.in_scope c g)])
  in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr =
    Literal (Type.Array { element=Name group; length=Some (Name n) })
  in
  let%map x =
    !Input "x" arr
  and y =
    !Input "y" arr
  and output  =
    !Output "z"  arr
  in
  ksprintf Html.markdown {md|The output should be `%s[i] = %s[i] + %s[i]`
where `+` is the group operation for the curve %s as described above.|md}
    (Name.to_markdown output)
    (Name.to_markdown x)
    (Name.to_markdown y)
    (Name.to_markdown group)

let problem : Problem.t =
  { title = "Curve operation"
  ; preamble
  ; interface
  ; reference_implementation_url = ""
  }
