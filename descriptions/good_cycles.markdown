# Basics 
Given a pairing-friendly elliptic curve $E$ defined over a field $\F_\q$ with $|E| = r$,
one obtains a SNARK-construction for certifying $\F_r$ arithmetic computations.
The prover for this SNARK performs an FFT over $\F_r$ elements (which involves
doing $\F_r$ arithmetic) and multiexponentiations in $E$, which involves doing
$\F_q$ arithmetic.

Thus, one way of speeding up a SNARK construction is to use an elliptic curve where
$q$ and $r$ are smaller, so that $\F_q$ and $\F_r$ arithmetic can be faster.
However, for security, $q$ and $r$ must both be somewhat large. How large they must
be depends on the *embedding degree* of the curve.

# Embedding degree 
The embedding degree of a curve $E$ of order $r$ defined over $\F_q$ is defined to
be the minimal $k$ such that $r \divides q^k - 1$. The reason for this is that if
we have such a $k$, then we obtain a pairing on $E$ taking values in (the group of
units of) $\F_{q^k}$.

If $k$ is too big, this pairing will be useless as it will be infeasible to
compute with (or even store in memory) elements of $F_{q^k}$.

If $k$ is small-ish (say less than 50) then it is feasible to compute with
elements of $\F_{q^k}$, and we call the curve *pairing-friendly*.

However, there is a downside to having a small embedding degree. Namely, because
we have a pairing $e$ taking values in $\F_{q^k}$, if I want to compute the discrete
log of $h = g^x$ with respect to $g$, I can instead compute $H = e(g^x, g) = e(g, g)^x$ and
then compute the discrete log of $H$ with respect to $e(g, g)$ in $\F_{q^k}$. So,
if we want the discrete log in $E$ to be hard (and we do for our SNARK to be secure)
the discrete log in $\F_{q^k}$ must also be hard. For this to be the case, $q^k$
must be large. If we fix the desired security level, there is a tradeoff between $q$ and $k$. If $k$ is small, then $q$ must
be large, and if $k$ is large, then $q$ can be smaller.

# How embedding degree and field size affect performance

The field size $q$ has much more of an influence on the performance of the SNARK prover than the
embedding $k$. In fact, $k$ has no direct influence whatsoever on the prover and only impacts the
verifier. Thus, it's desirable to make $k$ as large as the verifier can stand (any $k \leq 20$ say is 
reasonable) so that we can make $q$ as small as possible and thus speed up our
prover as much as possible.

# Cycles of elliptic-curves and proof composition

In order to perform recursive proof composition, we need a cycle of pairing-friendly elliptic curves. 

A cycle of curves is a pair of elliptic curves $(E_0, E_1)$ with $E_i$ defined over $\F_{q_i}$ and
$|E_i| = q_{1 - i}$. In other words, the order of each curve is the size of the other's base
field. 

The reason this lets us efficiently perform proof composition is as follows:

$E_0$ gives us a SNARK construction for arithmetic in a field of order $|E_0| = q_1$, i.e., $\F_{q_1}$.
The verifier for $E_0$ involves some invocations of $E_0$'s pairing, which involves doing
arithmetic over $E_0$'s base field $\F_{q_0}$.

$E_1$ gives us a SNARK construction for arithmetic in a field of order $|E_1| = q_0$, i.e., $\F_{q_0}$.
The verifier for $E_1$ involves some invocations of $E_0$'s pairing, which involves doing
arithmetic over $E_1$'s base field $\F_{q_1}$.

Thus, the SNARK from $E_0$ can certify $E_1$'s verifier, and the SNARK from $E_1$ can
certify $E_0$'s verifier. This makes it possible for $E_1$ to essentially certify
its own verifier, which makes recursive composition possible.

# Problem 0: Constructing pairing-friendly elliptic curves

If we have a desired embedding-degree $k$ and $(q, r, n)$ such that
$r \divides n$ and $r \divides q^k - 1$, then we can plausibly hope to find
an elliptic curve $E$ of order $n$ over the field $\F_q$.

However, to go from the field size $q$ and the curve order $n$ to the
actual equation $y^3 = x^3 + Ax + B$ defining the curve, we need to
use the complex-multiplication (CM) algorithm. Letting $t = q + 1 - n$,
in order for the CM algorithm to operate efficiently, it is necessary that
$4q - t^2$ has a small square-free part. In other words, we must have
$4q - t^2 = D V^2$ for integers $D, V$ with $|D|$ being small. Concretely,
we must have $D \leq 10^{16}$ for state-of-the-art implementations of the CM
algorithm.

To sum things up, the problem of constructing a pairing friendly curve
boils down to finding $k, q, r, n$ such that

- $k \leq 20$ or so.
- $q$ is a prime.
- $r$ is a prime.
- $r \divides n$.
- $r \divides q^k - 1$ and does not divide $q^{k'} - 1$ for $k' < k$.
- $4q - t^2 = DV^2$ for some $D, V \in \Z$ with $|D| < 10^{16}$, where $t = q + 1 - n$.
  The number $D$ (the squarefree part of $4q - t^2$) is called the discriminant.

# Methods for finding the parameters of pairing-friendly curves

Now that we know what we need to find to construct pairing-friendly curves,
we can begin to think about how to actually find such $(k, q, r, n)$.
There are only a few known methods for doing so, as described in the 
excellent paper [A Taxonomy of Pairing-Friendly Elliptic Curves](https://eprint.iacr.org/2006/372.pdf):
- The "families" method.
- The Cocks--Pinch method.
- The DEM method.
- Super-singular curves.

We will describe the first two in more detail.

## Method 1: Families of elliptic curves

The first method is the "families" method. The idea is as follows.
Fix a desired embedding degree $k$.
Instead of finding integers $(q, r, n)$ as above we find *polynomials*
$(q(x), r(x), n(x))$ with rational coefficients such that
- $q(x)$ is an irreducible polynomial. (Note that this is analogous to being a prime number.)
- $r(x)$ is an irreducible polynomial.
- $r(x) \divides n(x)$ *as a polynomial*.
- $r(x) \divides q(x)^k - 1$ and does not divide $q(x)^{k'} - 1$ for $k' < k$.

We will return to the condition on the discriminant in a moment.
The idea is that we will then somehow sample a random $x_0$ and check that
$q(x_0)$ and $r(x_0)$ are both prime which (ignoring the discriminant condition)
would give us a pairing-friendly curve of embedding degree $k$, order $n(x_0)$
defined over $\F_{q(x_0)}$.

So, letting $t(x) = q(x) + 1 - n(x)$,
how can we make sure we pick $x_0$ such that $t(x_0)$
has a small squarefree part? There are two methods. The first is to pick
the polynomials $q(x), n(x)$ such that
$4q(x) - t(x)^2 = D V(x)^2$ for some fixed $D \leq 10^{16}$ and some polynomial
$V(x)$. This will by construction guarantee that the discriminant is $D$,
which is small and then we can just sample $x_0$ randomly and check
that $q(x_0)$ and $r(x_0)$ are both prime.
This is for example how the BLS families work. 

The second method is to iterate over all (suitable) $D \leq 10^{16}$,
and for each $D$ find all solutions $(x, y)$ to the equation $4 q(x) - t(x)^2 = D y^2$.
Then, having solved that equation, take each solution $(x_0, y_0)$ and
check if $q(x_0), r(x_0)$ are both prime. This is for example what we must
do for the MNT families. If $q(x)$ is a quadratic and $t(x)$ is linear then
the equation $4q(x) - t(x)^2 = D y^2$ is an example of what is called a Pell equation,
and all solutions may be efficiently enumerated.

## Method 2: Cocks--Pinch

We will describe the Cocks--Pinch method in terms of its black-box behavior.

- Input: 
  The desired embedding degree $k$, discriminant $D \leq 10^{16}$, and
  a prime $r$ such that $k \divides r - 1$ and $-D$ is a square in $\F_r$.
- Output: $(q, n, y)$ such that $q$ is prime, $r \divides n$,
  $k$ is minimal such that $r \divides q^k - 1$, and $4q - t^2$ has
  squarefree part $D$. 

  Moreover, we'll have $q \approx r^2$.

In short, one fixes the embedding-degree $k$ and the desired order
$r$ of a prime subgroup, and one gets back a field $\F_q$ such that we can find
a curve of embedding-degree $k$ defined over $\F_q$ with an order
$r$ subgroup. This method is thus useful if one wants a curve of a given
order and does not care too much about the field it is defined over.

# Problem 1: Finding cycles with larger embedding degrees

The only known pairing-friendly cycles are from the MNT family of curves.

A *family of elliptic curves* of embedding degree $k$ is a pair of
polynomials $(q(x), r(x))$ such that $r(x)$ divides (as a polynomial)
$q(x)^k - 1$ and does not divide $q(x)^k' - 1$ for $k' < k$.
The idea is that you can then plug random values $x_0$ into these polynomials
to obtain integers $(q(x_0), r(x_0))$ and then try to find curves
of order $r(x_0)$ defined over $F_{q(x_0)}$. Then, such curves will by
design have embedding degree $k$.

Most pairing friendly curves that we know of come from families. The primary
method for constructing curves without using families is the Cocks--Pinch method.

The cycle has %

-----

# Concretely what is a good cycle

First, let's concretely state acceptable combinations of embedding degree and
modulus size for 128 bits of security


# Misc
All SNARK-prover operations involve doing computations in two prime order fields $\F_r$ and $\F_q$.
$\F_q$ is the base field of the pairing-friendly elliptic curve 

One good way to improve the speed of the SNARK prover is to work with a curve defined over a smaller
modulus.
