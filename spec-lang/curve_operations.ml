open Core
open Util

type curve = MNT4 | MNT6

let p curve_scope =
  let s = (match curve_scope with MNT4 -> "MNT4" | MNT6 -> "MNT6") ^ "753" in
  Name.in_scope s "q" |> Name.to_markdown

let preamble (pages : Pages.t) =
  ksprintf Html.markdown
    {md|In this challenge you'll use the field arithmetic built up 
in [this](%s), [this](%s) and [this challenge](%s)
to implement the group operation for several elliptic curves.

## Background
Fix a field $\mathbb{F}$. For example, one of the fields described
on the parameter pages for [MNT4-753](%s) and [MNT6-753](%s).
Then fix numbers $a, b$ in $\mathbb{F}$. The set of points $(x, y)$ such that
$y^2 = x^3 + a x + b$ is called an elliptic curve over the field $\mathbb{F}$.

Elliptic curves are the essential tool powering SNARKs. They're useful because
we can define a kind of "addition" of points on a given curve. This is also
called the "group operation" for the curve.
Let's define this "addition" as follows using pseudocode, where `+, *, /` are
all taking place in the field $\mathbb{F}$.

```javascript

var curve_add = (p, q) => {
  var s = (p.y - q.y) / (p.x - q.x);
  var x = s*s - p.x - q.x;
  return {
    x: x,
    y: s*(p.x - x) - p.y
  };
};
```
Note that this definition doesn't work in the case that `p.x = q.x`. This case
splits into the case `p.y = q.y` (in which case its called "doubling" and
there is a separate formula) and the case `p.y = -q.y` in which case a special
"identity" value should be returned.

For efficiency, one uses a different, more complicated
formula for adding curve points. This will be discussed in
the techniques section below.
|md}
    pages.field_arithmetic pages.quadratic_extension pages.cubic_extension
    pages.mnt4 pages.mnt6

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  let%bind [group] =
    def [latex "G"]
      List.Let_syntax.(
        let%map c = ["MNT4753"; "MNT6753"]
        and g = [latex "G_1"; latex "G_2"] in
        Vec.[Name (Name.in_scope c g)])
  in
  let%bind n = !Input "n" (Literal UInt64) in
  let arr =
    Literal (Type.Array {element= Name group; length= Some (Name n)})
  in
  let%map _x = !Input "x" arr and _output = !Output "y" (Name group) in
  ksprintf Html.markdown
    {md|The output should be `x[0] + x[1] + ... + x[n - 1]`
where `+` is the group operation for the curve $G$ as described above.|md}

let postamble (_pages : Pages.t) =
  ksprintf Html.markdown
    {h|#Techniques
## Coordinate systems

Points in the form $(x, y)$ as above are said to be
represented using *affine coordinates*
and the above definition is *affine* curve addition.

There are more efficient ways of adding
curve points which use different coordinate systems.
The most efficient of these is called
*Jacobian coordinates*. Formulas for addition and doubling in Jacobian
coordinates can be found [here](https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#doubling-dbl-2007-bl)
and a Rust implementation [here](https://github.com/CodaProtocol/pairing/blob/mnt46-753/src/mnt4_753/ec.rs#L374).

There is a further technique called "mixed addition" which allows one to add
a point in Jacobian coordinates to a point in affine coordinates even more efficiently than adding
two points in Jacobian coordinates. This technique can yield large efficiency
gains but makes taking advantage of parallelism more complicated.

## Parallelism

This problem is an instance of a *reduction* and is inherently
parallel.
|h}

let problem : Problem.t =
  { title= "Curve operations"
  ; quick_details=
      { description=
          Html.text
            "Add together an array of elements of each of the four relevant \
             elliptic curves."
      ; prize= {dollars= 1000} }
  ; preamble
  ; interface
  ; reference_implementation_url= ""
  ; postamble }
