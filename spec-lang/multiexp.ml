open Core
open Util

let interface =
  let open Problem.Interface in
  let%bind [group; scalar] =
    let curve_scopes = ["MNT4753"; "MNT6753"] in
    let group_names = [latex "G_1"; latex "G_2"] in
    def ["G"; "Scalar"]
      List.Let_syntax.(
        let%map scope = curve_scopes and group = group_names in
        (Vec.[scope ^. group; Type.prime_field (scope ^. "r")], scope))
  in
  let%bind n = !Batch_parameter "n" (Literal UInt64) in
  let%bind _g =
    !Batch_parameter "g"
      (Literal (Array {element= Name group; length= Some (Name n)}))
  in
  let%bind _s =
    ( ! ) Input "s"
      (Literal (Array {element= Name scalar; length= Some (Name n)}))
      ~note:
        (Html.markdown
           {m|Elements of `s` will be represented in **standard** form as a little-endian array of 12 64-bit unsigned limbs. This
form is more likely to be useful than Montgomery representation for this problem.|m})
  in
  let%bind _y = !Output "y" (Name group) in
  let description =
    Markdown.of_string
      {md|The output should be the multiexponentiation with the scalars `s`
on the bases `g`. In other words, the group element
`s[0] * g[0] + s[1] * g[1] + ... + s[n - 1] * g[n - 1]`.


In pseduocode, something like
```javascript

var g = [g0, g1, .., gn];

var multiexp = (s) => {
  var res = G_identity;
  for (var i = 0; i < s.length; ++i) {
    var sg = G_scale(s[i], g[i]);
    res = G_add(res, sg);
  }
  return res;
}
```

|md}
  in
  return description

let problem : Problem.t =
  { interface
  ; quick_details=
      { description=
          Markdown.of_string
            "Compute the multi-exponentiation of an array of (scalar, \
             curve-point) pairs for the 4 relevant groups."
      ; prize= Prize.stage1 0 }
  ; preamble= [] |> Fn.const
  ; title= "Multi-exponentiation"
  ; reference_implementation_url= ""
  ; postamble= Fn.const [] }
