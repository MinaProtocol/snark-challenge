open Core
open Util

type definitional_params = {field: Name.t; g1: Name.t; g2: Name.t}

let definitional_params =
  let open Problem.Interface in
  let latex = md_latex in
  let%map [field; g1; g2] =
    let curve_scopes = ["MNT4753"; "MNT6753"] in
    def
      ["F"; latex "G_1"; latex "G_2"]
      (List.map curve_scopes ~f:(fun scope ->
           ( Vec.
               [ Type.prime_field (scope ^. "r")
               ; scope ^. latex "G_1"
               ; scope ^. latex "G_2" ]
           , scope ) ))
  in
  {field; g1; g2}

type batch_params =
  { max_degree: Name.t
  ; num_vars: Name.t
  ; ca: Name.t
  ; cb: Name.t
  ; cc: Name.t
  ; at: Name.t
  ; bt1: Name.t
  ; bt2: Name.t
  ; lt: Name.t
  ; ht: Name.t }

(* For simplicity we hardcode num_inputs = 1. *)
let batch_params {field; g1; g2} =
  let open Problem.Interface in
  let%bind max_degree =
    ( ! ) Batch_parameter "d" (Literal UInt64)
      ~note:
        (Html.markdown
           "$d + 1$ is guaranteed to be a power of $2$ in the MNT4753 case \
            and of the form $2^x 5^y$ in the MNT6753 case.")
  and num_vars = !Batch_parameter "m" (Literal UInt64) in
  let _group_elt name group = !Batch_parameter name (Name group) in
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
                (* The last entry here I think will always be zero. Test that. *)
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
  and at = group_array "A" g1 num_vars_plus_one
  (* At[i] = u_i(x) = A_i(t) *)
  and bt1 = group_array "B1" g1 num_vars_plus_one
  and bt2 = group_array "B2" g2 num_vars_plus_one
  and lt = group_array "L" g1 num_vars_minus_one
  (* Lt[i] 
       = (beta u_i(t) + alpha v_i(t) + w_i(t)) / delta
       = (beta At[i] + alpha Bt[i] + Ct[i]) / delta
    *)
  and ht = group_array "T" g1 (Name max_degree) in
  (* TODO: Possibly minus one? *)
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
  {num_vars; max_degree; ca; cb; cc; at; bt1; bt2; ht; lt}

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
  and r =
    field_input "r"
    (*
  and d1 = field_input "d1"
  and d2 = field_input "d2"
  and d3 = field_input "d3" *)
  in
  let%bind _proof =
    !Output "proof"
      (Literal (Record [("A", Name g1); ("B", Name g2); ("C", Name g1)]))
  in
  let latex s = sprintf "$%s$" s in
  let description =
    let n = Fn.compose delatex Name.to_string in
    let {num_vars; at; bt2; lt; bt1; max_degree; ht; ca; cb; cc} =
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
        (n num_vars) (n lt) (n max_degree) (n ht) (n r) b1_def
      |> latex |> latex
    in
    ksprintf Markdown.of_string
      {md|This problem is a version of the [Groth16 SNARK prover](https://eprint.iacr.org/2016/260.pdf), simplified to the difficult core of the problem.

If $P, Q$ are points on an elliptic curve (either $G_1$ or $G_2$) and $s : %s$, then
$P + Q$ denotes the sum of the points as described [here](https://en.wikipedia.org/wiki/Elliptic_curve#The_group_law)
and $s \times P$ denotes the scalar-multiplication of $P$ by $s$ as described [here](https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Basics).

The output should be as follows.

- A = %s
- B = %s
- C = %s

where

- Let $\omega = \sigma^{(r - 1) / (d + 1)}$. This guarantees that
  we have $\omega^{d + 1} = 1$. Look at the MNT4753 or MNT6753 parameter
  pages to find the value of $\sigma$ in each case.

    H is an array of the coefficients of the polynomial
    $h(x) = \frac{a(x) b(x) - c(x)}{z(x)}$
    where $a, b, c$ are the degree %s
    polynomials specified by

$$
\begin{aligned}
  a(\omega^i) &= %s[i] \\
  b(\omega^i) &= %s[i] \\
  c(\omega^i) &= %s[i] \\
\end{aligned}
$$

  for $0 \leq i < %s + 1$ and where $z$ is the polynomial
$$
\begin{aligned}
  z(x)
  &= (x - 1)(x - \omega^1) \dots (x - \omega^{%s}) \\
  &= x^{%s} - 1
\end{aligned}
$$

One would want to obtain the coefficients of $h$ by computing its evaluations
on $\omega^0, \dots, \omega^{%s}$ as `(%s[i] * %s[i] - %s[i]) / z(ω_i)` for each `i`.
This won't work however as $z(\omega^i) = 0$ for each $i$. Alternatively, one can do the following.

1. Perform 3 inverse FFTs to compute the coefficients of $a, b$ and $c$.
2. Use the coefficients of these polynomials to compute the evaluations of of $a, b, c$
    on the "shifted set" $\{ \sigma , \sigma \omega^1, \sigma \omega^2, \dots, \sigma \omega^{%s}\}$.

    Let's say `ea` is an array with `ea[i]` being the i<sup>th</sup> coefficient of the polynomial
    `a`. Then we can evaluate `a` on the set $\{ \sigma , \sigma \omega^1, \sigma \omega^2, \dots, \sigma \omega^{%s}\}$
    by computing `sa = ea.map((ai, i) => sigma**i * ai)` and then performing an FFT on `sa`.
    Analogously for the polynomials $b$ and $c$ to obtain evaluation arrays `eb` and `ec`.

    In all this step requires 3 FFTs.
3. Note that $z(\sigma \omega^i) = \sigma^{%s} \omega^{%s} - 1 = \sigma^{%s} - 1$.
    So, having computed `sa, sb, sc`, you can compute the evaluations of 
    $h(x) = \frac{a(x) b(x) - c(x)}{z(x)}$  on the
    shifted set as `sh[i] = (sa[i] * sb[i] - sc[i]) / (sigma**%s - 1)`.

4. Finally, we can now obtain the coefficients `H` of $h$ by performing an inverse FFT on `sh` 
    to obtain `shifted_H` and
    then computing `H[i] = shifted_H[i] / sigma`.

All in all, we have to do 3 FFTs and 4 inverse FFTs to compute the array `H`,
perform 4 multiexponentiations in %s and 1 multiexponentiation in %s.

.|md}
      (n field) a_def b2_def c_def (n max_degree) (n ca) (n cb) (n cc)
      (n max_degree) (n max_degree) (n max_degree) (n max_degree)
      (n max_degree) (n max_degree) (n max_degree) (n max_degree)
      (n max_degree) (n max_degree) (n max_degree) (n max_degree)
      (n max_degree) (n g1) (n g2)
  in
  return description

let preamble (pages : Pages.t) =
  ksprintf Markdown.of_string
    {md|This is the full Groth16 prover, or a slightly simplified version of it. It is the main
event of the SNARK Challenge.
It requires performing 7 [FFTs](%s), 4 [multiexponentiations](%s) in $G_1$ and 1 multiexponentiation in $G_2$. How
exactly is described below.
The majority of the time is spent the multiexponentiations, so optimization efforts should be focussed there initially.|md}
    pages.fft pages.multi_exponentiation
  |> Sectioned_page.leaf |> List.return

let postamble _ =
  let open Sectioned_page in
  [ sec ~title:"Starter code"
      [ md
          {md|- This [repo](https://github.com/CodaProtocol/snark-challenge-cuda-starter) has some CUDA starter code,
   just to illustrate how to build it on the benchmark machine.
- This [library](https://github.com/data61/cuda-fixnum) implements prime-order field arithmetic in CUDA.
Unfortunately, it's not currently working correctly with CUDA 10.1 which is what is used on our benchmark machine, but
it should be a great place to start, either in getting it to compile against CUDA 10.1 or just as an example
implementation.
|md}
      ] ]

let problem : Problem.t =
  { title= "Groth16Prove"
  ; quick_details=
      { description= Markdown.of_string "The full Groth16 prover."
      ; prize=
          [ (Best_performance_at_end, Dollars 20_000)
          ; (First_to (Improve_speed_by 16), Dollars 12_000)
          ; (First_to (Improve_speed_by 8), Dollars 10_000)
          ; (First_to (Improve_speed_by 4), Dollars 8_000)
          ; (First_to (Improve_speed_by 2), Dollars 5_000) ] }
  ; preamble
  ; interface
  ; reference_implementation=
      { repo=
          "https://github.com/CodaProtocol/snark-challenge/tree/master/reference-07-groth16-prover"
      ; main=
          "https://github.com/CodaProtocol/snark-challenge/tree/master/reference-07-groth16-prover/libsnark/main.cpp"
      ; core=
          "https://github.com/CodaProtocol/snark-challenge/blob/master/reference-07-groth16-prover/libsnark/main.cpp#L199"
      }
  ; postamble }
