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

let preamble _pages =
  ksprintf Html.markdown
{md|Now that we've implemented arithmetic in a prime-order field
in the [previous challenge](), we can implement field extension
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
of the form $a + b x$ where $a$ and $b$ are elements of $\mathbb{F}_q$. This is a
field extension of $\mathbb{F}_q$ since $\mathbb{F}_q$ is contained in this field as
the elements with $b = 0$. For short, we call this field $\mathbb{F}_{q^2}$ since it
has $q^2$ elements.

## The problem

In code, you can think of an element of $\mathbb{F}_{q^2}$ as a pair $(a, b)$ where
each of $a, b$ is an element of $\mathbb{F}_q$ or a struct `{ a : Fq, b : Fq }`.

This problem will have you implement addition and multiplication for $\mathbb{F}_{q^2}$.
Addition and multiplication are defined how you might expect:

$$
\begin{aligned}
(a + b x) + (c + d x)
&= (a + c) + (b + d)x \\
(a + b x) (c + d x)
&= ac + bc x + ad x + bd x^2 \\
&= ac + bc x + ad x + 13 bd \\
&= (ac + 13 bd) + (bc + ad) x
\end{aligned}
$$

In pseduo-code, this would be
```javascript

var alpha = fq(13);

var fq2_add = (e1, e2) => {
  return {
    a: fq_add(e1.a, e2.a),
    b: fq_add(e1.b, e2.b)
  };
};

var fq2_mul = (e1, e2) => {
  var a1_a2 = fq_mul(e1.a, e2.a);
  var b1_b2 = fq_mul(e1.b, e2.b);
  var b1_a2 = fq_mul(e1.b, e2.a);
  var a1_b2 = fq_mul(e1.a, e2.b);
  return {
    a: fq_add(a1_a2, fq_mul(b1_b2, alpha)),
    b: fq_add(b1_a2, a1_b2)
  };
};
```

So it's pretty easy to define given we have arithmetic for $\mathbb{F}_q$.
You can see this is a field extension
|md}
(q MNT4)
;;

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let fq = Type.Field.Prime { order = (Name (Name.in_scope "MNT4753" "q") ) } in
  let fqe = Type.Field.Extension { base=Literal fq; degree=2; non_residue=Literal (Value (Bigint.of_int 13)) } in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr =
    Literal (Type.Array { element=Type.field (Literal fqe); length=Some (Name n) })
  in
  let%map _x =
    !Input "x" arr
  and _y =
    !Input "y" arr
  and _output  =
    !Output "z"  arr
  in
  ksprintf Html.markdown {md|The output should be `z[i] = x[i] * y[i]`
where `*` is multiplication in the field %s as described above.
|md}
    ((fun () -> Type.Field.render (Literal fqe)
     |> Html.to_string ) |> Async.Thread_safe.block_on_async_exn)
;;

let postamble _ =
  Html.markdown {md|## Efficiency tricks

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

var fq2_mul = (e1, e2) => {
  var a1_a2 = fq_mul(e1.a, e2.a);
  var b1_b2 = fq_mul(e1.b, e2.b);

  var a1_plus_b1 = fq_add(e1.a, e1.b);
  var a2_plus_b2 = fq_add(e2.a, e2.b);

  var c = fq_mul(a1_plus_b1, a2_plus_b2);

  return {
    a: fq_add(a1_a2, fq_mul(b1_b2, alpha)),
    b: fq_sub(fq_sub(c, a1_a2), b1_b2)
  };
};
```
|md}

let problem : Problem.t =
  { title = "Field extension arithmetic"
  ; preamble
  ; interface
  ; reference_implementation_url = ""
  ; postamble
  }

