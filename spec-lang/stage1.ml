open Core
open Util

let page (pages : Pages.t) =
  ksprintf Html.markdown
    {md|Welcome to stage 1 of the SNARK challenge!
Think of this stage as a paid training for the ultimate challenge
of writing a super-fast SNARK prover.
Want to learn cutting edge cryptography, GPU programming and get
paid to do it? Then you're in the right place.

In this stage, you'll implement the sub-algorithms you need to
implement the full SNARK prover and you'll get paid to do so.

#TODO: explain payout structure

Let's dive into it and give a quick overview of the SNARK prover so
we have an idea of where we're going. The SNARK prover itself
consists of two sub-algorithms: 

1. Multi-exponentiation on an elliptic curve.
2. Fast fourier transform (FFT) over a finite field.

The cool thing about both of these algorithms is that they're massively
parallel and ideally suited to implementation on GPU, which we expect to
help take the top prize in the challenge.

But before we get there, those 2 algorithms themselves have sub-algorithms
which you'll need to implement first. All in all, there are N challenges:

## The stage 1 challenges
1. [Finite field arithmetic](%s)
2. [Quadratic extension arithmetic](%s)
3. [Cubic extension arithmetic](%s)
4. [Elliptic curve operations](%s)
5. [Multi-exponentiation](%s)
6. [Fast fourier transform](%s)

You'll want to get started with the first challenge, [finite field arithmetic](%s)
and work your way through the others. If you want to get a sense for how all these
algorithms come together to build the whole prover, check out [this page](%s).
|md}
    pages.field_arithmetic pages.quadratic_extension pages.cubic_extension
    pages.curve_operations pages.multi_exponentiation pages.fft
    pages.field_arithmetic pages.intro
