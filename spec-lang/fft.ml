open Core
open Util

type curve =
  | MNT4
  | MNT6

let q curve_scope =
  let s = (match curve_scope with
    | MNT4 -> "MNT4"
    | MNT6 -> "MNT6") ^ "753"
  in
  Name.in_scope s "q" |> Name.to_markdown

let preamble =
  ksprintf Html.markdown
    {md||md}

let interface : Html.t Problem.Interface.t =
  let open Html in
  let open Problem.Interface in
  let open Let_syntax in
  let%bind [ r; _s; _smega ] =
    def [ latex "r"; latex "s"; latex "\\omega" ] (
      List.map ["MNT4753"; "MNT6753"] ~f:(fun c ->
          Vec.[ Name (Name.in_scope c "r")
              ; Name (Name.in_scope c "s")
              ; Name (Name.in_scope c (latex "\\omega"))
              ])
    )
  in
  let%bind n =
    (!) Batch_parameter "n" (Literal UInt64)
      ~note:(text "Guaranteed to be a power of 2.")
  in
  let field = Type.field (Type.Field.prime (Name r)) in
  let arr =
    Literal (Type.Array { element=field; length=Some (Name n) })
  in
  let%map x =
    !Input "x" arr
  and output  =
    !Output "y"  arr
  in
  ksprintf Html.markdown {md|The output should be
%s[i] = \sum_{j=0}^{n-1} %s[i] \omega^{ij (2^s / n)}|md}
    (Name.to_string output)
    (Name.to_string x)


let problem : Problem.t =
  { title = "Curve operation"
  ; preamble
  ; interface
  ; reference_implementation_url = ""
  }

