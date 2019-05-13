open Core
open Util

type curve = MNT4 | MNT6

let param name curve_scope =
  let s = (match curve_scope with MNT4 -> "MNT4" | MNT6 -> "MNT6") ^ "753" in
  Name.in_scope s name |> Name.to_markdown

let q = param "q"

let r = param "r"

let preamble _pages =
  ksprintf Html.markdown
    {md|## Background
The basic operations needed for the SNARK prover algorithm are
multiplication and addition of integers.

Usually when programming we're used to working with 32-bit or 64-bit
integers and addition and multiplication mod $2^{32}$ or $2^{64}$) respectively.

For the SNARK prover though, the integers involved are a lot bigger.
For our purposes, the integers are 753 bits and are represented using
arrays of native integers. For example, we could represent them using
an array of 12 64-bit integers (since $12 \cdot 64 = 768 > 753$) or
an array of 24 32-bit integers (since $24 \cdot 32 = 768 > 753$).
And instead of computing mod $2^{753}$, we'll compute mod $q$ where
$q$ is either %s or %s.

Each element of such an array is called a "limb". For example, we would say
that we can represent a $2^{768}$ bit integer using 12 64-bit limbs.

We call the set of numbers $0, \dots, q - 1$ by the name $\mathbb{F}_q$.
This set forms a field, which means we can add, multiply, and divide numbers in
the set. Addition and multiplication happen mod q. It might seem weird that we can
divide, but it turns out for any $a, b$ in $\mathbb{F}_q$, there is a number $c$ 
in $\mathbb{F}_q$ such that $(c b) \mod q = a$.
In this case we say $a / b = c$ so that $(a / b) b \mod q = c b \mod q = a$
as you'd expect.

### Montgomery representation
Montgomery representation is an alternative way of representing elements of $\mathbb{F}_q$ so that
multiplication mod $q$ can be computed more efficiently.

So let $q$ be a prime and let $R = 2^{768}$.
The Montgomery representation of the nubmer $x$ is $(x R) \mod q$. So for example,
when $q$ is %s, the number 5 is represented as $(5 \cdot 2^{768}) \mod q$ which
happens to be
```
15141386232259939182423724568694911114488003694957216858820448966622494022908702997737632032507442391226452946698823665470952711443326537357991482811741996884665155234620507693793230633117754640516203527639390490866666926222409
```
This number then is represented as a TODO-ENDIANNESS length 12 array of 64-bit integers.

Let us see how multplication works in this setting. We'll
use pseudocode with `%%` for $\mod$.

Given the Montgomery representation
`X = (x * R) %% q` of `x` and
`Y = (y * R) %% q` of `y`,
we want to compute the
Montgomery representation of `(x * y) %% q`,
which is `(x * y * R) %% q`.

We have
```javascript
X * Y
== ((x * R) %% q) * ((y * R) %% q)
== (x * y * R * R) %% q
```
So, if we had a function `div_R` for letting
us divide by `R` mod `q`, we would be able to compute
the Montgomery representation of `x * y` from `X`
and `Y` as `div_R(X * Y)`.

To recap, to implement multiplication mod $q$, we need to implement two functions:

1. Big integer multiplication, which takes two `k` limb integers and returns the `2 * k`-limb integer which
    is their product.
2. `div_R`, which takes a `2 * k`-limb integer `Z` and returns the `k`-limb integer equal to
    `(Z * r) %% q`, where `r` is the inverse of `R`. That is, the number with `(R * r) %% q = 1`.

We will then have
```
div_R(X * Y)
== div_R((x * y * R * R) %% q)
== (x * y * R * R * r) %% q
== (x * y * R * 1) %% q
== (x * y * R) %% q
```
which is the Montgomery representation of the product of the inputs, exactly as we wanted.

Algorithms for big-integer multiplication and `div_R` (often called Montgomery reduction)
are given [here](http://cacr.uwaterloo.ca/hac/about/chap14.pdf), where our $q$ is called $m$.

### Note
Note that %s = %s and %s = %s, so there are only two fields we need to implement
arithmetic for across the whole SNARK challenge.|md}
    (q MNT4) (q MNT6) (q MNT4) (q MNT4) (r MNT6) (q MNT6) (r MNT4)

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let%bind [q] =
    def ["q"]
      (List.map ["MNT4753"; "MNT6753"] ~f:(fun c ->
           Vec.[Name (Name.in_scope c "q")] ))
  in
  let field = Type.field (Type.Field.prime (Name q)) in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr = Literal (Type.Array {element= field; length= Some (Name n)}) in
  let%map x = !Input "x" arr and output = !Output "y" field in
  ksprintf Html.markdown
    {md|The output %s should be `%s[0] * %s[1] * ... * %s[n - 1]`
where `*` is multiplication in the field %s as described above.|md}
    (Name.to_markdown output) (Name.to_markdown x) (Name.to_markdown x)
    (Name.to_markdown x) (Name.to_markdown q)

let problem : Problem.t =
  { title= "Field arithmetic"
  ; preamble
  ; interface
  ; reference_implementation_url= ""
  ; postamble= Fn.const (Html.text "TODO") }
