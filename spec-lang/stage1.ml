open Core
open Util

let _page (pages : Pages.t) =
  let open Sectioned_page in
  [ sec ~title:"Stage 1"
      [ {md|Want to learn cutting edge cryptography, GPU programming and get
paid to do it? Then you're in the right place.

In this stage, you'll implement the sub-algorithms you need to
implement the full SNARK prover and you'll get paid to do so.
The first 25 participants who complete the four challenges in this stage
will receive $200 and a *SNARK Challenge* swag-bag.
They'll also be very well positioned to apply their solutions to
create submissions for $55,000 of the $75,000 in prizes up for grabs in the second stage.

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
be well on your way to having a complete GPU implementation of the SNARK prover itself.|md}
        |> Markdown.of_string |> leaf
      ; sec ~title:"The stage 1 challenges"
          [ ksprintf
              (Fn.compose leaf Markdown.of_string)
              {md|The stage 1 challenges are

1. [Finite field arithmetic](%s). Reward of $50.
2. [Quadratic extension arithmetic](%s). Reward of $25.
3. [Cubic extension arithmetic](%s). Reward of $25.
4. [Elliptic curve operations](%s). Reward of $100.

You'll want to get started with the first challenge, [finite field arithmetic](%s),
and work your way through the others. If you want to get a sense for how all these
algorithms come together to build the whole prover, check out [this page](%s).|md}
              pages.field_arithmetic pages.quadratic_extension
              pages.cubic_extension pages.curve_operations
              pages.field_arithmetic pages.intro ] ]
  ; sec ~title:"Stage 2"
      [ {md|Stage 2 is the main stage of the challenge with a total of $95,000 in prizes.
The challenges break into two categories: implementation and theory. Let's
start with implementation.|md}
        |> Markdown.of_string |> leaf
      ; sec ~title:"Implementation challenges"
          [ ksprintf
              (Fn.compose leaf Markdown.of_string)
              {md|These challenges all build on the challenges of stage 1. Stage 2 officially starts on
June 3, but we will add information regarding these challenges as they are 
finalized in case you want to get a head start.

The challenges are

1. [Writing the fastest Groth16 SNARK prover](%s) on a machine with these [specs](https://github.com/CodaProtocol/snark-challenge/blob/master/descriptions/testing_platform.markdown)
    The prizes here total $55,000.
    
2. Writing the fastest in-browser implementation of the Groth16 SNARK verifier.
    Acceptable submissions would compile to WebAssembly or JavaScript.
    The fastest entry will receive $10,000.

3. Fastest Groth16 SNARK prover for CPU.

4. The code golf prize: Shortest Groth16 prover.

5. Most creative Groth16 prover.

5. Most elegant Groth16 prover.|md}
              pages.groth16 ]
      ; sec ~title:"The theory challenge"
          [ ksprintf
              (Fn.compose leaf Markdown.of_string)
              {md|The theory challenge asks participants to
find a collection of elliptic curves which enable extremely efficient recursive
composition. The prize is $20,000 for the best construction. You can find a problem
description, along with more background and resources [here](%s).
|md}
              pages.theory ] ] ]

let page (pages : Pages.t) =
  let main =
    let open Challenge in
    let programmer_challenges : Challenge.t list =
      [ challenge "SNARK prover challenges (performance, mobile, creative)"
          ~url:pages.groth16 ~short:"prover" ~dollars:65_000
          [ (*
          challenge "Fastest prover (GPU and CPU)" ~short:"gpu-cpu" ~dollars:55_000 [];
          challenge "Fastest prover (CPU only)" ~short:"cpu" ~dollars:0 [];
          challenge "Fastest prover (mobile)" ~short:"mobile" ~dollars:0 [];
          challenge "Most elegant prover code" ~short:"elegant" ~dollars:0 [];
*) ]
      ; challenge "SNARK verifier challenge" ~short:"verifier" ~dollars:10_000
          [] ]
    in
    let stage1_challenges : Challenge.t list =
      [challenge "Tutorial challenges" ~short:"tutorial" ~dollars:200 []]
      (*
      List.map ~f:(Tuple2.uncurry problem)
      [ Field_arithmetic.problem, 1
      ; Quadratic_extension.problem, 2
      ; Cubic_extension.problem, 3
      ; Curve_operations.problem, 4
      ]
*)
    in
    let theory_challenges : Challenge.t list =
      [ challenge "Construct an optimal graph of pairing-friendly curves"
          ~short:"theory" ~dollars:20_000 [] ]
    in
    let challenges c = unlines (List.map c ~f:Challenge.render) in
    ksprintf Markdown.of_string
      {md|## For programmers and cryptographers
%s
%s

## For cryptographers
%s
|md}
      (challenges programmer_challenges)
      (challenges stage1_challenges)
      (challenges theory_challenges)
  in
  let intro =
    ksprintf Markdown.of_string
      {md|Welcome to the SNARK challenge! The SNARK challenge is a
global competition to advance the state-of-the-art in performance
for SNARK proving. Participants will be part of an effort that aims
to have a massive impact on user-protecting cryptographic technology,
and compete for $100,000 in prizes.

There are two categories of challenges: those for programmers who want
to implement high-performance cryptography, and those for cryptographers
who want to advance the state-of-the-art in efficiency of the underlying
elliptic-curves powering SNARK constructions. Click through to the individual challenge
pages for more details.

<!--
The SNARK challenge is divided
up into two stages. In the first stage, you'll get your feet wet and
learn about the algorithms underlying the SNARK prover.
Think of this stage as a paid training for the ultimate challenge
of writing a super-fast SNARK prover. There are $5,000 in prizes in
this stage.

The second stage is the main stage of the competition.
There are $95,000 in prizes including $55,000 for speeding up the
[Groth16 prover](%s) and $20,000 for developing better cryptographic
primitives. Here you'll apply GPU programming and techniques for
speeding up elliptic-curve and finite-field arithmetic to try
to build the fastest possible [Groth16 prover](%s).-->|md}
      pages.groth16 pages.groth16
  in
  ksprintf Markdown.of_string !{md|%{Markdown}

%{Markdown}|md} intro main

(*
  ksprintf Markdown.of_string
    {md|Welcome to the SNARK challenge! The SNARK challenge is divided
up into two stages. In the first stage, you'll get your feet wet and
learn about the algorithms underlying the SNARK prover.
Think of this stage as a paid training for the ultimate challenge
of writing a super-fast SNARK prover. There are $5,000 in prizes in
this stage.

The second stage is the main stage of the competition.
There are $95,000 in prizes including $55,000 for speeding up the
[Groth16 prover](%s) and $20,000 for developing better cryptographic
primitives. Here you'll apply GPU programming and techniques for
speeding up elliptic-curve and finite-field arithmetic to try
to build the fastest possible [Groth16 prover](%s).

## Stage 1

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
    pages.groth16 pages.groth16
    pages.field_arithmetic pages.quadratic_extension pages.cubic_extension
    pages.curve_operations pages.field_arithmetic pages.intro
*)
