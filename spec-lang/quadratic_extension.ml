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

The simplest kind of field extension and the one we'll implement here is
called a quadratic extension. The idea is the following. First we'll start
with our prime order field $\mathbb{F}_q$ where $q$ is %s. Then, we'll
pick a number in $\mathbb{F}_q$ which does not have a square root in
$\mathbb{F}_q$. In our case, we'll use $13$.

Now we can define the field we call $\mathbb{F}_q[x] / (x^2 = 13)$. This is the field
obtained by adding an "imaginary" square root $x$ for $13$ to $\mathbb{F}_q$. It's a lot like how
the complex numbers are constructed from the real numbers by adding an "imaginary" square root
$i$ for $-1$ to $\mathbb{R}$.

Like the complex numbers, the elements of $\mathbb{F}_q[x] / (x^2 = 13)$ are sums
of the form $a_0 + a_1 x$ where $a_0$ and $a_1$ are elements of $\mathbb{F}_q$. This is a
field extension of $\mathbb{F}_q$ since $\mathbb{F}_q$ is contained in this field as
the elements with $a_1 = 0$. For short, we call this field $\mathbb{F}_{q^2}$ since it
has $q^2$ elements.

## The problem

In code, you can think of an element of $\mathbb{F}_{q^2}$ as a pair `(a0, a1)` where
each of $a_0, a_1$ is an element of $\mathbb{F}_q$ or a struct `{ a0 : Fq, a1 : Fq }`.

This problem will have you implement addition and multiplication for $\mathbb{F}_{q^2}$.
Addition and multiplication are defined how you might expect:

$$
\begin{aligned}
(a_0 + a_1 x) + (b_0 + b_1 x)
&= (a_0 + b_0 ) + (a_1 + b_1 )x \\
(a_0 + a_1 x) (b_0 + b_1  x)
&= a_0 b_0 + a_1 b_0 x + a_0 b_1  x + a_1 b_1  x^2 \\
&= a_0 b_0 + a_1 b_0 x + a_0 b_1  x + 13 a_1 b_1  \\
&= (a_0 b_0 + 13 a_1 b_1 ) + (a_1 b_0  + a_0 b_1 ) x
\end{aligned}
$$

In pseduo-code, this would be
```javascript

var alpha = fq(13);

var fq2_add = (a, b) => {
  return {
    a: fq_add(a.a0, b.a0),
    b: fq_add(a.a0, b.a0)
  };
};

var fq2_mul = (a, b) => {
  var a0_b0 = fq_mul(a.a0, b.a0);
  var a1_b1 = fq_mul(a.a1, b.a1);
  var a1_b0 = fq_mul(a.a1, b.a0);
  var a0_b1 = fq_mul(a.a0, b.a1);
  return {
    a0: fq_add(a0_b0, fq_mul(a1_b1, alpha)),
    a1: fq_add(a1_b0, a0_b1)
  };
};
```
|md}
    pages.field_arithmetic (q MNT4)

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let fq = Type.Field.Prime {order= Name (Name.in_scope "MNT4753" "q")} in
  let fqe =
    Type.Field.Extension
      { base= Literal fq
      ; degree= 2
      ; non_residue= Literal (Integer (Value (Bigint.of_int 13))) }
  in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr =
    Literal
      (Type.Array {element= Type.field (Literal fqe); length= Some (Name n)})
  in
  let%map _x = !Input "x" arr
  and _output = !Output "y" (Type.field (Literal fqe)) in
  ksprintf Html.markdown
    {md|%s

The output should be `x[0] * x[1] * ... * x[n - 1]`
where `*` is multiplication in the field %s as described above.
|md}
    Gpu_message.t
    ( (fun () -> Type.Field.render (Literal fqe) |> Html.to_string)
    |> Async.Thread_safe.block_on_async_exn )

let postamble _ =
  Html.markdown
    {md|## Efficiency tricks

The pseduocode above does 4 $\mathbb{F}_q$ multiplications, 1 multiplication
by $13$ (which can be made much cheaper than a general multiplication if it is
special-cased), and 2 additions.

If you want to get the most efficiency, it's good to reduce the number of
multiplications, as they are much more costly than additions. There is a trick
to do so, described in [section 3 of this paper](https://pdfs.semanticscholar.org/3e01/de88d7428076b2547b60072088507d881bf1.pdf)
but let's go through it here. The net result of the trick is that we'll get down
to 3 multiplications, 1 multiplication by $13$, and 5 additions/subtractions. So we need to
do more additions and subtractions, but we do one less multiplication, which is a big win.

In pseudo-code, the trick is
```javascript

var fq2_mul = (a, b) => {
  var a0_b0 = fq_mul(a.a0, b.a0);
  var a1_b1 = fq_mul(a.a1, b.a1);

  var a0_plus_a1 = fq_add(a.a0, a.a1);
  var b0_plus_b1 = fq_add(b.a0, b.a1);

  var c = fq_mul(a0_plus_a1, b0_plus_b1);

  return {
    a0: fq_add(a0_b0, fq_mul(a1_b1, alpha)),
    a1: fq_sub(fq_sub(c, a0_b0), a1_b1)
  };
};
```
|md}

let problem : Problem.t =
  { title= "Quadratic extension arithmetic"
  ; quick_details=
      { description=
          Html.text
            "Multiply together an array of elements of a quadratic extension \
             field."
      ; prize= Prize.stage1 25 }
  ; preamble
  ; interface
  ; reference_implementation_url= ""
  ; postamble }
