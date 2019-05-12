open Core
open Util

type curve = MNT4 | MNT6

let param name curve_scope =
  let s = (match curve_scope with MNT4 -> "MNT4" | MNT6 -> "MNT6") ^ "753" in
  Name.in_scope s name |> Name.to_markdown

let q = param "q"

let r = param "r"

let preamble (pages : Pages.t) =
  ksprintf Html.markdown
    {md|Now that we've implemented arithmetic in a prime-order field
in a [previous challenge](%s), we can implement field extension
arithmetic, which we'll need for multi-exponentiation.

## Definitions and review
Let's review what exactly a field extension is. The actual operations
needed are actually pretty simple, so if you just want to get started coding,
you can safely skip this section.

A field extension of a field $\mathbb{F}$ is another field $\mathbb{F}'$
which contains $\mathbb{F}$. To use a familiar example, $\mathbb{R}$,
the field of real numbers is a field extension of the field $\mathbb{Q}$
of rational numbers.

In the SNARK challenge and in cryptography in general, we work with finite
fields, and the extension fields we'll consider will be finite fields as
well.

In this problem, you'll implement a kind of extension called a cubic extension.
The idea is the following. First we'll start
with our prime order field $\mathbb{F}_q$ where $q$ is %s. Then, we'll
pick a number in $\mathbb{F}_q$ which does not have a cube root in
$\mathbb{F}_q$. In our case, we'll use $11$.
If you already completed [the quadratic extension](%s), this problem is
very similar.

Now we can define the field we call $\mathbb{F}_q[x] / (x^3 = 11)$. This is the field
obtained by adding an "imaginary" cube root $x$ for $11$ to $\mathbb{F}_q$. It's a lot like how
the complex numbers are constructed from the real numbers by adding an "imaginary" square root
$i$ for $-1$ to $\mathbb{R}$.

Similar to the complex numbers, the elements of $\mathbb{F}_q[x] / (x^3 = 11)$ are sums
of the form $a_0 + a_1 x + a_2 x^2$ where $a_0, a_1, a_2$ are elements of $\mathbb{F}_q$. This is a
field extension of $\mathbb{F}_q$ since $\mathbb{F}_q$ is contained in this field as
the elements with $a_1 = a_2 = 0$. For short, we call this field $\mathbb{F}_{q^3}$ since it
has $q^3$ elements.

## The problem

In code, you can think of an element of $\mathbb{F}_{q^3}$ as a tuple
`(a0, a1, a2)` where
each of `a0`, `a1`, `a2` is an element of $\mathbb{F}_q$ or a
struct `{ a0 : Fq, a1 : Fq, a2 : Fq }`.

This problem will have you implement multiplication for $\mathbb{F}_{q^2}$.
Addition and multiplication are defined how you might expect:

$$
\begin{aligned}
(a_0 + a_1 x + a_2 x^2) +  (b_0 + b_1 x + b_2 x^2)
&= (a_0 + b_0) + (a_1 + b_1) x + (a_2 + b_2) x^2 \\
(a_0 + a_1 x + a_2 x^2) (b_0 + b_1 x + b_2 x^2)
&= a_0 b_0 + a_0 b_1 x + a_0 b_2 x^2
+ a_1 b_0 x + a_1 b_1 x^2 + a_1 b_2 x^3
+ a_2 b_0 x^2 + a_2 b_1 x^3 + a_2 b_2 x^4 \\
&= a_0 b_0 + a_0 b_1 x + a_0 b_2 x^2
+ a_1 b_0 x + a_1 b_1 x^2 + 11 a_1 b_2 
+ a_2 b_0 x^2 + 11 a_2 b_1 + 11 a_2 b_2 x \\
&= (a_0 b_0 + 11 a_1 b_2 + 11 a_2 b_1)
+ (a_0 b_1 + a_1 b_0 + 11 a_2 b_2) x
+ (a_0 b_2 + a_1 b_1 + a_2 b_0) x^2 \\
\end{aligned}
$$

In pseduo-code, this would be
```javascript

var alpha = fq(11);

var fq3_add = (a, b) => {
  return {
    a0: fq_add(a.a0, b.a0),
    a1: fq_add(a.a1, b.a1),
    a2: fq_add(a.a2, b.a2)
  };
};

var fq3_mul = (a, b) => {
  var a0_b0 = fq_mul(a.a0, b.a0);
  var a0_b1 = fq_mul(a.a0, b.a1);
  var a0_b2 = fq_mul(a.a0, b.a2);

  var a1_b0 = fq_mul(a.a1, b.a0);
  var a1_b1 = fq_mul(a.a1, b.a1);
  var a1_b2 = fq_mul(a.a1, b.a2);

  var a2_b0 = fq_mul(a.a2, b.a0);
  var a2_b1 = fq_mul(a.a2, b.a1);
  var a2_b2 = fq_mul(a.a2, b.a2);

  return {
    a0: fq_add(a0_b0, fq_mul(alpha, fq_add(a1_b2, a2_b1))),
    a1: fq_add(a0_b1, fq_add(a1_b0, fq_mul(alpha, a2_b2))),
    a2: fq_add(a0_b2, fq_add(a1_b1, a2_b0))
  };
};
```
|md}
    pages.field_arithmetic (q MNT6) pages.quadratic_extension

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let fq = Type.Field.Prime {order= Name (Name.in_scope "MNT4753" "q")} in
  let fqe =
    Type.Field.Extension
      { base= Literal fq
      ; degree= 2
      ; non_residue= Literal (Value (Bigint.of_int 13)) }
  in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr =
    Literal
      (Type.Array {element= Type.field (Literal fqe); length= Some (Name n)})
  in
  let%map _x = !Input "x" arr
  and _y = !Input "y" arr
  and _output = !Output "z" arr in
  ksprintf Html.markdown
    {md|The output should be `z[i] = x[i] * y[i]`
where `*` is multiplication in the field %s as described above.
|md}
    ( (fun () -> Type.Field.render (Literal fqe) |> Html.to_string)
    |> Async.Thread_safe.block_on_async_exn )

let postamble _ =
  Html.markdown
    {md|## Efficiency tricks

The pseduocode above does 9 $\mathbb{F}_q$ multiplications, 2 multiplications
by $11$ (which can be made much cheaper than a general multiplication if it is
special-cased), and 6 additions.

If you want to get the most efficiency, it's good to reduce the number of
multiplications, as they are much more costly than additions.
There a two methods to do so, called the Karatsuba and Toom-Cook methods,
, described in [section 4 of this paper](https://pdfs.semanticscholar.org/3e01/de88d7428076b2547b60072088507d881bf1.pdf).
They require 6 and 5 multiplications respectively.
The Toom-Cook method should be faster, but it's slightly more complicated to implement.
|md}

let problem : Problem.t =
  { title= "Cubic extension arithmetic"
  ; preamble
  ; interface
  ; reference_implementation_url= ""
  ; postamble }
