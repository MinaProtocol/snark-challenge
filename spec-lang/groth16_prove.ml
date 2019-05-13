open Core
open Util

type definitional_params = {field: Name.t; g1: Name.t; g2: Name.t}

let definitional_params =
  let open Problem.Interface in
  let%map [field; g1; g2] =
    let curve_scopes = ["MNT4753"; "MNT6753"] in
    def
      ["F"; latex "G_1"; latex "G_2"]
      (List.map curve_scopes ~f:(fun scope ->
           Vec.
             [ Type.prime_field (scope ^. "r")
             ; scope ^. latex "G_1"
             ; scope ^. latex "G_2" ] ))
  in
  {field; g1; g2}

type batch_params =
  { num_constraints: Name.t
  ; num_vars: Name.t
  ; ca: Name.t
  ; cb: Name.t
  ; cc: Name.t
  ; at: Name.t
  ; bt1: Name.t
  ; bt2: Name.t
  ; lt: Name.t
  ; ht: Name.t
  ; alpha_g1: Name.t
  ; beta_g1: Name.t
  ; beta_g2: Name.t
  ; delta_g1: Name.t
  ; delta_g2: Name.t }

(* For simplicity we hardcode num_inputs = 1. *)
let batch_params {field; g1; g2} =
  let open Problem.Interface in
  let%bind num_constraints = !Batch_parameter "n" (Literal UInt64)
  and max_degree = !Batch_parameter "N" (Literal UInt64)
  and num_vars = !Batch_parameter "m" (Literal UInt64) in
  let group_elt name group = !Batch_parameter name (Name group) in
  let group_array name group len =
    !Batch_parameter name
      (Literal (Array {element= Name group; length= Some len}))
  in
  let evaluation_array name =
    !Batch_parameter name
      (Literal
         (Array
            { element= Name field
            ; length=
                Some
                  (Literal (Add (Name max_degree, Literal (Value Bigint.one))))
            }))
  in
  let num_vars_plus_one =
    Literal (Integer.Add (Name num_vars, Literal (Value Bigint.one)))
  in
  let num_vars_minus_one =
    Literal (Integer.Sub (Name num_vars, Literal (Value Bigint.one)))
  in
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
  and ht = group_array "Ht" g1 (Name max_degree)
  (* TODO: Possibly minus one? *)
  and alpha_g1 = group_elt (latex "\\alpha") g1
  and beta_g1 = group_elt (latex "\\beta_1") g1
  and beta_g2 = group_elt (latex "\\beta_2") g2
  and delta_g1 = group_elt (latex "\\delta_1") g1
  and delta_g2 = group_elt (latex "\\delta_2") g2 in
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
  ; ca
  ; cb
  ; cc
  ; at
  ; bt1
  ; bt2
  ; ht
  ; lt
  ; alpha_g1
  ; beta_g1
  ; beta_g2
  ; delta_g1
  ; delta_g2 }

let delatex s =
  let ( >>= ) = Option.( >>= ) in
  match
    String.chop_prefix ~prefix:"\\(" s >>= String.chop_suffix ~suffix:"\\)"
  with
  | Some s ->
      s
  | None ->
      s

let interface =
  let open Problem.Interface in
  let%bind ({field; g1; g2} as params) = definitional_params in
  let field_input name = !Input name (Name field) in
  let%bind batch_params = batch_params params in
  let%bind _w =
    (* w[0] = 1 *)
    let num_vars_plus_one =
      Literal
        (Integer.Add (Name batch_params.num_vars, Literal (Value Bigint.one)))
    in
    !Input "w"
      (Literal (Array {element= Name field; length= Some num_vars_plus_one}))
  and r = field_input "r" in
  let%bind selected_degree = !Output "d" (Literal UInt64) in
  let%bind _proof =
    !Output "proof"
      (Literal (Record [("A", Name g1); ("B", Name g2); ("C", Name g1)]))
  in
  let latex s = sprintf "$%s$" s in
  let description =
    let n = Fn.compose delatex Name.to_string in
    let { num_vars
        ; alpha_g1= _
        ; at
        ; delta_g1= _
        ; beta_g2= _
        ; bt2
        ; delta_g2= _
        ; lt
        ; bt1
        ; beta_g1= _
        ; num_constraints
        ; ht
        ; ca
        ; cb
        ; cc } =
      batch_params
    in
    let a_def =
      sprintf {md|\sum_{i=0}^{%s} w[i] \times %s[i]|md} (n num_vars) (n at)
      |> latex |> latex
    in
    print_endline a_def ;
    let b_def_no_latex ~bt =
      sprintf {md|\sum_{i=0}^{%s} w[i] \times %s[i]|md} (n num_vars) (n bt)
    in
    let b1_def = b_def_no_latex ~bt:bt1 in
    let b2_def = b_def_no_latex ~bt:bt2 |> latex |> latex in
    let c_def =
      sprintf
        (*           {md| \left( \sum_{i=0}^{%s - 2} w[2 + i] %s[i]\right)  + \left(\sum_{i=0}^{%s - 1} H[i] %s[i] \right) + %s A+ %s B1- (%s %s) %s|md} *)
        {md|\sum_{i=2}^{%s} w[i] \times %s[i - 2] + \sum_{i=0}^{%s - 1} H[i] \times %s[i] + %s %s|md}
        (n num_vars) (n lt) (n selected_degree) (n ht) (n r) b1_def
      |> latex |> latex
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
      (n g1) (n g2) (n field) a_def b2_def c_def (n selected_degree) (n ca)
      (n cb) (n cc) (n num_constraints)
  in
  return description

let problem : Problem.t =
  { title= "Groth16Prove"
  ; quick_details=
      {description= Html.text "The full Groth16 prover."; prize= Prize.stage1 0}
  ; preamble= (fun _ -> Html.text "TODO")
  ; interface
  ; reference_implementation_url= ""
  ; postamble= Fn.const (Html.text "TODO") }
