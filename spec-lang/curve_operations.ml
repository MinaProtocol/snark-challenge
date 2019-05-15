open Core
open Util

type curve = MNT4 | MNT6

let curve_scope c = (match c with MNT4 -> "MNT4" | MNT6 -> "MNT6") ^ "753"

let p c = Name.in_scope (curve_scope c) "q" |> Name.to_markdown

let preamble (pages : Pages.t) =
  let open Sectioned_page in
  let md fmt = ksprintf (fun s -> leaf [Html.markdown s]) fmt in
  [ md
      {md|In this challenge you'll use the field arithmetic built up 
in [this](%s), [this](%s) and [this challenge](%s)
to implement the group operation for several elliptic curves.|md}
      pages.field_arithmetic pages.quadratic_extension pages.cubic_extension
  ; sec ~title:"Definition of curve addition"
      [ md
          {md|
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
the techniques section below.|md}
          pages.mnt4 pages.mnt6 ] ]

(*

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
*)

type two = One | Two

let int_of_two = function One -> 1 | Two -> 2

let embedding_degree = function MNT4 -> 4 | MNT6 -> 6

let group' f curve i =
  let i = int_of_two i in
  Name.in_scope (curve_scope curve) (ksprintf f "G_%d" i)

let group = group' latex

let group_md = group' (sprintf "$%s$")

let interface : Html.t Problem.Interface.t =
  let open Problem.Interface in
  let open Let_syntax in
  (*
  let%bind [group] =
    def [latex "G"]
      List.Let_syntax.(
        let%map c = ["MNT4753"; "MNT6753"]
        and g = [latex "G_1"; latex "G_2"] in
        Vec.[Name (Name.in_scope c g)])
  in
*)
  let%bind n = !Input "n" (Literal UInt64) in
  let input (c, i) =
    let arr =
      Literal (Type.Array {element= Name (group c i); length= Some (Name n)})
    in
    !Input (sprintf "g%d_%d" (embedding_degree c) (int_of_two i)) arr
  in
  let output (c, i) =
    !Output
      (sprintf "h%d_%d" (embedding_degree c) (int_of_two i))
      (Name (group c i))
  in
  let params = [(MNT4, One); (MNT4, Two); (MNT6, One); (MNT6, Two)] in
  let%map _input = all (List.map ~f:input params)
  and _output = all (List.map ~f:output params) in
  let desc (g, i) =
    let k = embedding_degree g in
    let j = int_of_two i in
    sprintf
      "`h%d_%d` should be `g%d_%d[0] + g%d_%d[1] + ... + g%d_%d[n - 1]` where \
       `+` is the group operation for the curve %s."
      k j k j k j k j
      (group_md g i |> Name.to_markdown)
  in
  sprintf "%s\n\n%s" Gpu_message.t
    (String.concat ~sep:"\n\n" (List.map ~f:desc params))
  |> Html.markdown

let postamble (pages : Pages.t) =
  let open Sectioned_page in
  let md fmt = ksprintf (fun s -> leaf [Html.markdown s]) fmt in
  [ md
      {md|Please see [this page](%s) for a more full list of implementation techniques.|md}
      pages.implementation_strategies
  ; sec ~title:"Techniques"
      [ sec ~title:"Coordinate systems"
          [ md
              {md|Points in the form $(x, y)$ as above are said to be
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
gains but makes taking advantage of parallelism more complicated.|md}
          ] ]
  ; sec ~title:"Parallelism"
      [ md
          {md|This problem is an instance of a *reduction* and is inherently parallel.|md}
      ] ]

(*
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

*)
let problem : Problem.t =
  { title= "Curve operations"
  ; quick_details=
      { description=
          Html.text
            "Add together an array of elements of each of the four relevant \
             elliptic curves."
      ; prize= Prize.stage1 100 }
  ; preamble
  ; interface
  ; reference_implementation_url=
      "https://github.com/CodaProtocol/snark-challenge/tree/master/reference-04-curve-operations"
  ; postamble }
