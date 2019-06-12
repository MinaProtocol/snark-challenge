open Core
open Util

let page (pages : Pages.t) =
  let open Challenge in
  ksprintf Markdown.of_string
    {md|Want to learn cutting edge cryptography, GPU programming and get
paid to do it? Then you're in the right place.

In the tutorial challenges, you'll implement the sub-algorithms you need to
implement the full SNARK prover and you'll get paid to do so.
The first 10 participants who complete the four challenges in this stage
will receive $500 and a *SNARK Challenge* swag-bag.
They'll also be very well positioned to apply their solutions to
create submissions for $70,000 of the $105,000 in prizes up for grabs in the other challenges.

The challenges in this stage are

%s


## Broader context
Let's give a quick overview of the SNARK prover so
we have an idea of where these challenges lead. The SNARK prover itself
consists of two sub-algorithms: 

1. Multi-exponentiation on an elliptic curve.
2. Fast fourier transform (FFT) over a finite field.

The cool thing about both of these algorithms is that they're massively
parallel and ideally suited to implementation on GPU, which we expect to
help take the top prize in the challenge. The multi-exponentiation in
particular is just a big [reduction](https://developer.download.nvidia.com/assets/cuda/files/reduction.pdf),
although the reduction function requires some work to describe.

These 2 algorithms themselves have sub-algorithms which you'll need to implement first.
In total, this stage has 4 challenges. After implementing these challenges you'll
be well on your way to having a complete GPU implementation of the SNARK prover itself.

Click through to each of the challenge pages for starter code and more details.|md}
    (unlines
       (List.map
          ~f:(fun (p, url) -> render (problem p ~url))
          [ (Field_arithmetic.problem, pages.field_arithmetic)
          ; (Quadratic_extension.problem, pages.quadratic_extension)
          ; (Cubic_extension.problem, pages.cubic_extension)
          ; (Curve_operations.problem, pages.curve_operations) ]))
