# The SNARK Challenge

Welcome to the SNARK challenge! The SNARK challenge is a
global competition to advance the state-of-the-art in performance
for SNARK proving. Participants will be part of an effort that aims
to have a massive impact on user-protecting cryptographic technology,
while also competing for $100,000 in prizes.

The SNARK challenge is divided
up into two stages. In <a href="#stage-1">Stage 1</a>, you'll have a chance to get your feet wet and
learn about the algorithms underlying the SNARK prover.
Think of this stage as a paid training for the ultimate challenge
of writing a super-fast SNARK prover. There are $5,000 in prizes in
this stage.

<a href="#stage-2">Stage 2</a> is the main stage of the competition.
There is a grand total of $95,000 in prizes, including $55,000 for speeding up the
[Groth16 prover](/snark-challenge/problem-07-groth16prove.html) and $20,000 for developing better cryptographic
primitives. Here you'll apply GPU programming and techniques for
speeding up elliptic-curve and finite-field arithmetic to try
to build the fastest possible [Groth16 prover](/snark-challenge/problem-07-groth16prove.html).
  
## Table of Contents

<div class="table-of-contents">
<ul>
<li>
<a href="#stage-1">1: Stage 1</a>
</li>
<li>
<a href="#the-stage-1-challenges">1.1: The Stage 1 challenges</a>
</li>
<li>
<a href="#stage-2">2: Stage 2</a>
</li>
<li>
<a href="#implementation-challenges">2.1: Implementation challenges</a>
</li>
<li>
<a href="#theory-challenges">2.2: Theory challenges</a>
</li>
</ul>
</div>

## Stage 1

In this stage, you'll implement the sub-algorithms you need to
implement the full SNARK prover and you'll get paid to do so.
The first 25 participants who complete the four challenges in this stage
will receive $200 and a *SNARK Challenge* swag-bag.
They'll also be very well positioned to apply their solutions to
create submissions for $55,000 of the $75,000 in prizes up for grabs in Stage 2 of the challenge.

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
In total, the first stage has 4 challenges. After implementing these algorithms you'll
be well on your way to having a complete GPU implementation of the SNARK prover.

### The Stage 1 challenges

1. [Finite field arithmetic](/snark-challenge/problem-01-field-arithmetic.html)
2. [Quadratic extension arithmetic](/snark-challenge/problem-02-quadratic-extension-arithmetic.html)
3. [Cubic extension arithmetic](/snark-challenge/problem-03-cubic-extension-arithmetic.html)
4. [Elliptic curve operations](/snark-challenge/problem-04-curve-operations.html)

You'll want to start with the first challenge, [finite field arithmetic](/snark-challenge/problem-01-field-arithmetic.html),
and work your way sequentially through the others. If you want to get a sense for how all these
algorithms come together to build the whole SNARK prover, check out [this page](/snark-challenge/intro.html).

## Stage 2

Stage 2 is the main stage of the challenge with a total of $95,000 in prizes.
The challenges break into two categories: implementation and theory. Let's
start with implementation.

### Implementation challenges

These challenges all build on the algorithms in Stage 1. Stage 2 officially starts on
June 3, but we will add information regarding these challenges as they are 
finalized in case you want to get a head start.

The challenges are:

1. [Writing the fastest Groth16 SNARK prover](/snark-challenge/problem-07-groth16prove.html) on a machine with these [specs](https://github.com/CodaProtocol/snark-challenge/blob/master/descriptions/testing_platform.markdown).
    * The prizes here total $55,000
    
2. Writing the fastest in-browser implementation of the Groth16 SNARK verifier.
    * Acceptable submissions will compile to WebAssembly or JavaScript
    * The fastest entry will win $10,000!

3. Fastest Groth16 SNARK prover for CPU.

4. The code golf prize: shortest Groth16 prover.

5. Most creative Groth16 prover.

5. Most elegant Groth16 prover.

### Theory challenges

A description of the theory challenges will be coming soon!