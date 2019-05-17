open Core

let page (pages : Pages.t) =
  ksprintf Markdown.of_string
    {md|Welcome to the SNARK challenge! The SNARK challenge is divided
up into two stages. In the first stage, you'll get your feet wet and
learn about the algorithms underlying the SNARK prover.
Think of this stage as a paid training for the ultimate challenge
of writing a super-fast SNARK prover. There are $5,000 in prizes in
this stage.

The second stage is the main stage of the competition.


#*SNARK Challenge*: Stage 1

Want to learn cutting edge cryptography, GPU programming and get
paid to do it? Then you're in the right place.

In this stage, you'll implement the sub-algorithms you need to
implement the full SNARK prover and you'll get paid to do so.
The first 25 participants who complete the four challenges in this stage
will receive $200 and a *SNARK Challenge* swag-bag.
They'll also be very well positioned to apply their solutions to
create submissions for the $75,000 in optimization prizes up for grabs in the second stage.

Let's dive into it and give a quick overview of the SNARK prover so
we have an idea of where we're going. The SNARK prover itself
consists of two sub-algorithms: 

1. Multi-exponentiation on an elliptic curve.
2. Fast fourier transform (FFT) over a finite field.

The cool thing about both of these algorithms is that they're massively
parallel and ideally suited to implementation on GPU, which we expect to
help take the top prize in the challenge. The multi-exponentiation in
particular is just a big [reduction](https://developer.download.nvidia.com/assets/cuda/files/reduction.pdf),
although the reduction function requires some work to describe.

These 2 algorithms themselves have sub-algorithms which you'll need to implement first.
In total, the first stage has 4 challenges. After implementing these challenges you'll
be well on your way to having a complete GPU implementation of the SNARK prover itself.

## The stage 1 challenges
1. [Finite field arithmetic](%s). Reward of $50.
2. [Quadratic extension arithmetic](%s). Reward of $25.
3. [Cubic extension arithmetic](%s). Reward of $25.
4. [Elliptic curve operations](%s). Reward of $100.

You'll want to get started with the first challenge, [finite field arithmetic](%s),
and work your way through the others. If you want to get a sense for how all these
algorithms come together to build the whole prover, check out [this page](%s).

## The stage 2 challenges

This is the main stage of the challenge with a total of $95,000 in prizes.
The challenges break into two categories: implementation and theory. Let's
start with implementation.

### Implementation challenges
These challenges all build on the challenges of stage 1. They are

1. Writing the fastest Groth16 SNARK prover on a machine with a fast CPU,
    NVIDIA RTX 2080 and AMD TODO. The prizes here total $55,000.
    
2. Writing the fastest in-browser implementation of the Groth16 SNARK verifier.
    Acceptable submissions would compile to WebAssembly or JavaScript.
    The fastest entry will receive $10,000.

3. Fastest Groth16 SNARK prover for CPU.

4. The code golf prize: Shortest Groth16 prover.
5. Most creative Groth16 prover.
5. Most elegant Groth16 prover.

The prizes are as follows.

1. 
|md}
    pages.field_arithmetic pages.quadratic_extension pages.cubic_extension
    pages.curve_operations pages.field_arithmetic pages.intro

(*
have N elements.
         split into batches of size k.
                                      r = 753
                               window w
(N / k) * ( (r / w)*MIXED*k + r * DOUBLE )

*)
