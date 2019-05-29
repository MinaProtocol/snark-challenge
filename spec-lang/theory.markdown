In order to efficiently compose SNARKs together, one wants a collection of
elliptic curves with certain properties. The goal of this challenge is to discover
and construct elliptic curves with these properties.

Let's understand in more detail what these properties are.

## Three facts about SNARKs

First, the basics.

If $E$ is an [elliptic curve](https://en.wikipedia.org/wiki/Elliptic_curve) defined over the field $\mathbb{F}_q$ with a prime order $r$
subgroup, we say $E$ is pairing-friendly if $r$ divides $q^k - 1$ for some $k \leq 50$. 
The *embedding degree of $E$* is defined to be the smallest such $k$.

**Fact 1:** A pairing-friendly
elliptic curve with an order $r$ subgroup yields a SNARK construction for proving things
about computations that use $\mathbb{F}_r$ arithmetic.

If you don't know what pairing-friendly curves are, please click on the above links
for some background.

Now, if we want to compose proofs together, we'll need a SNARK for the computation of
*verifying* those proofs. For this, it's useful to know the following fact about
what kind of computation the SNARK verifier performs.

**Fact 2:** An elliptic-curve defined over $\mathbb{F}_q$ yields a SNARK construction 
whose verification algorithm is efficiently expressed using $\mathbb{F}_r$ arithmetic.
This is because the Groth16 verifier just checks a few pairing equations.

Combining these two facts yields the following fact.

**Fact 3:** If you want to compose two (or more) SNARKs produced using a construction based
on an elliptic curve $E_1$ defined over a field $\mathbb{F}_q$, you need an
elliptic curve $E_2$ with a subgroup of order $q$.

That is, to check $E_1$'s verifier, by fact 2 you need a SNARK which can check $\mathbb{F}_q$
arithmetic, which by fact 1 means you need a curve with an order $\mathbb{q}$ subgroup.

This naturally leads to the definition of a *pairing-friendly graph of elliptic curves*,
which classifies arrangements of elliptic curves which enable composition of pairing-based
SNARKs.

## Pairing-friendly graphs of curves

**Definition:**
A *paring-friendly graph of elliptic curves* is a directed graph $G = (V, A)$ along
with some data associated to every vertex. Namely, for each vertex $v \in V$ we
have an elliptic curve $E_v$ such that

- $E_v$ is defined over a field of order $q_v$ with $q_v$ a prime.
- $E_v$ has a subgroup of order $r_v$ with $r_v$ a prime.
- $E_v$ is pairing friendly.
- If $(u, v)$ is an arc in $A$, then $q_u = r_v$.

Note that to each vertex $v$ we can also associate a SNARK construction (say Groth16)
for verifying $\mathbb{F}_{r_v}$ arithmetic computations
obtained using the elliptic curve associated to that vertex combined with fact 1.

This definition tells us that we can compose proofs whenever there's an edge.

Or put another way, if $(u, v)$ is an edge, the SNARK construction associated to $v$
can talk about proofs produced by the SNARK construction associated to $u$.

Or put another way, an edge $(u, v)$ allows us to *re-cast* an
$\mathbb{F}_{r_u}$ computation as an $\mathbb{F}_{r_v}$ computation.

TODO: Picture here
Graph:

- $E_1 / \mathbb{F}_5 \colon y^2 = x^3 + 4x + 2$ : order 3
- $E_2 / \mathbb{F}_3 \colon y^2 = x^3 + 2x^2 + 1$ : order 5
- $E_3 / \mathbb{F}_5 \colon y^2 = x^3 + 2x$ : order 2

## Pairing-friendly cycles and recursive composition

When you check Coda's blockchain, you are checking a proof, that
is checking a proof, that is checking a proof, ... and on and on until reaching the genesis
block. It's important therefore that it be possible to compose proofs arbitrarily many
times. 

For this, we'd need a pairing-friendly graph that contains an arbitrarily long path of curves. There
are two ways of achieving this: 

1. Find a graph of curves which is extremely big, bigger than the number of times we want
to compose proofs.
2. Find a graph of curves which contains a cycle, that way we can make arbitrarily long paths
by just going around the cycle as many times as we need.

Pairing-friendly elliptic curves are pretty rare, so I doubt option 1 is going to fly.
Option 2 however is in fact realistic and Coda is built on the pairing-friendly cycle
consisting of the curves [MNT4-753](https://coinlist.co/build/coda/pages/MNT4753)
and [MNT6-753](https://coinlist.co/build/coda/pages/MNT6753).

## Beyond cycles
So, if we want to do unbounded composition, we need a graph with a cycle. What's not
clear though is why you would want anything but a cycle. That is, what is the use of
the vertices in the graph that do not lie on the cycle?

The problem stems from the fact that we actually only know of one way to construct
cycles of elliptic curves (namely, via MNT4/MNT6 cycles) and the curves in these cycles
have bad parameters from an efficiency perspective: the curves have relatively low embedding
degree (4 and 6) which means we must take the size of base field to be quite large (on the order
of 768 bits) in order to achieve roughly 128 [bits of security](https://en.wikipedia.org/wiki/Security_level).

In Coda, this inefficiency affects not only the SNARK prover but leaks into the rest of the application
as well. The reason is that our SNARK needs to certify all cryptographic computations in
Coda (signatures, hashes, etc.) and so those primitives need to be efficiently described
using $\mathbb{F}_r$ arithmetic (where $r$ is the order of one of the curves in our cycle).
But $r$ is large (about 753 bits in our case) which means outside of the SNARK, our cryptographic
operations are a lot slower than they could be.

Moreover, [this paper](https://arxiv.org/pdf/1803.02067.pdf) of Chiesa, Chua, and Weidner rules
out a few potential strategies for constructing other cycles of elliptic curves. So, if we
cannot find new cycles (though you may very well be able to, we just don't know how yet) we
need another technique for reducing the impact of the large field size in known cycles.

This is where the other vertices in a pairing-friendly graph of curves come into play.
Suppose our graph has a vertex $v$ from which we can reach a cycle. Suppose moreover
that $r_v$ and/or $q_v$ were relatively small compared to the parameters of the curves on
the cycle. Say, $r$ could be on the order of $2^{256}$.
Then we'd be in a good position: we could perform the bulk of the computation in
our proofs in $\mathbb{F}_r$ using the SNARK construction associated to $v$, and
then just use the big curves in the cycle for composition and combining proofs.
That is, just use the cycle for the relatively small computation of checking other
verifiers.

## Lollipops

Note that the construction described in the preceding paragraph doesn't use the whole graph
but just a subgraph consisting of a path terminating in a cycle. 

Let's give such a graph a name.

**Definition:** A *lollipop of pairing-friendly curves* is a graph of pairing-friendly curves which
consists of a path terminating in a cycle. We'll call the path the "stick" of the lollipop.
Note that a *cycle* of curves is a special case of a lollipop where the stick has length 0.

## One more restriction on the curves
There is one more constraint we should place on the curves in any graph we consider if
we want to get efficient SNARK constructions. Namely, for every vertex $v$ in a given graph,
we would like $r_v - 1$ to have a large *smooth part*.

The *smooth part* of a number is the largest divisor of that number which is
*[smooth](https://en.wikipedia.org/wiki/Smooth_number)*. Smooth means all the
prime factors of that number are small. This smallness can be quantified:
for example, a 7-smooth number is a number whose prime factors are all at most
7. Likewise, we can talk about the 7-smooth part of a number, which is the
largest divisor of that number which is 7-smooth

**Definition:** Let's define a $(k, n)$-smooth pairing-friendly graph of curves to be a pairing friendly
graph of curves such that for every vertex $v$ in the graph, the $k$-smooth part of
$r_v - 1$ is at least $n$.

For concreteness, a reasonable value of $k$ is at most 13, and a reasonable value for
$n$ is at least 100,000.  Smaller $k$ and larger $n$ would be better.

The reason one imposes this restriction is that if $r_v$ has a large smooth part, one can
more efficiently perform an FFT over the field $\mathbb{F}_{r_v}$ which is part of the
SNARK prover.

## Problem specification
The goal of this challenge is to construct a $(k, n)$-smooth lollipop of pairing-friendly curves as described
above such that every curve in the lollipop has at least 120 bits of security. The quality
of a lollipop will be defined using a combination of the following criteria:

- The length of the stick. (Shorter is better.)
- The length of the cycle. (Shorter is better.)
- The sizes of $r_v$ and $q_v$ where $v$ is the vertex at the base of the stick. (Smaller is better.)
- The size of $k$. (Smaller is better).
- The size of $n$. (Larger is better).

These parameters affect the efficiency of the overall construction in a specific but
difficult to specify way, so we will take them all into account when judging submissions.

## The current best
The best currently-known lollipop of curves is an MNT4/6 cycle with the following quality metrics:

- The length of the stick is 0. (This is the best possible.)
- The length of the cycle is 2. (This is the best possible.)
- $r_v$ and $q_v$ are both on the order of $2^{753}$ for both vertices $v$.
  (These parameters are poor. $2^{256}$ would be the absolute best one could achieve
  while maintaining $128$ bits of security.)
- $k = 5$
- $n$ is $819,200$. (For the other curve in the cycle the $5$-smooth part is 
  $819,200^2 = 671,088,640,000$, which is very good.)

Here are the parameters of the 
[MNT4 curve](https://coinlist.co/build/coda/pages/MNT4753)
and the
[MNT6 curve](https://coinlist.co/build/coda/pages/MNT6753).

## Submission format
Your submission should consist of the following (the more items included the better):

- The equations and parameters of a lollipop of curves.
- A mathematical description of the process by which the curves were obtained.
- Any code used to produce the parameters of the curves in the lollipop.

## Resources

- A [Rust program](https://github.com/imeckler/curve-search) for sampling MNT4/6 cycles.
- An [excellent set of slides](https://www.cosic.esat.kuleuven.be/ecc2013/files/pierrick_gaudry_2.pdf)
  describing pairing-friendly curves. Slide 14 in particular is a "cheat sheet" for constructing
  such curves.
- A [great paper](https://eprint.iacr.org/2006/372.pdf) giving a more in depth discussion of most of the known constructions of pairing friendly curves.
- A [paper](https://arxiv.org/pdf/1803.02067.pdf) ruling out certain avenues to constructing pairing-friendly lollipops.
- A [Github thread](https://github.com/zcash/zcash/issues/3425) about constructing pairing-friendly lollipops.

<!--
-----

Then we'd be 

If our graph had a vertex $v$ such that $r_v$ or $q_v$ were relatively sm

TODO: Picture here

a graph that contai

It seems then, s
You might think, then, that cycles are all we need (since 
Unfortunately, these are 

A pairing-friendly cycle is a pairing friendly graph which, as a graph, is a directed cycle.
Pairing-friendly cycles are important for enabling unbounded proof composition, which is
what makes it possible to certify an arbitrary length computation with one proof, as in
Coda's succinct blockchain. 

Say the vertices in this are $v_1, \dots, v_n$

The goal of the theory challenge is to construct a pairing-friendly directed-graph of
elliptic curves with good parameters. There's a lot to unpack here, so let's walk through
this together. The ultimate goal that dthisubuC

The point of such a gadget is that it describes an arrangement of elliptic
curves which make efficient composition of SNARKs possible. This relies on the following
two facts:

with order $r_v$, defined over a field of order $p_v$ 
equipped with 

for every vertex $v \in V$ we have an associated elliptic-curve 

with 

the following prope -->
