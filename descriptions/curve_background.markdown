## Elliptic curves

An elliptic curve $E$ over a field $\F_q$ is the set of points $(x, y) \in F_q \times \F_q$ satisfying the equation
\[
y^2 = x^3 + ax + b
\]
for some $a, b \in \F_q$. One reason elliptic curves are interesting is that there is a commutative [group operation]()
that can be defined on them. This makes it possible to use them in cryptographic applications that
need an abelian group with hard discrete log.

## The elliptic curves Tick and Tock

Coda is powered by two elliptic curves, MNT4-753 and MNT6-753 (or Tick and Tock suggestively).

Tick is an [MNT curve]() of [embedding degree]() 4 defined over the field $\F_q$ with order $r$, where
\[
\begin{align*}
  q &= 41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888253786114353726529584385201591605722013126468931404347949840543007986327743462853720628051692141265303114721689601 \\
  r &= 41898490967918953402344214791240637128170709919953949071783502921025352812571106773058893763790338921418070971888458477323173057491593855069696241854796396165721416325350064441470418137846398469611935719059908164220784476160001
\end{align*}
\]
Tock is an [MNT curve]() of [embedding degree]() 6 defined over the field $\F_r$ with order $q$.
Tick and Tock have their order and field size swapped, which is what it means to form a
[cycle of elliptic curves](). This structure enables efficient [recursive composition](),
which is what enables Coda to have a constant-sized blockchain.

The defining equation for Tick is 
\[
\begin{align*}
  y^2 &= x^3 + A_4 x + B_4 \\
  A_4 &= 2 \\
  B_4 &= 
28798803903456388891410036793299405764940372360099938340752576406393880372126970068421383312482853541572780087363938442377933706865252053507077543420534380486492786626556269083255657125025963825610840222568694137138741554679540
\end{align*}
\]

The defining equation for Tock is 
\[
\begin{align*}
  y^2 &= x^3 + A_6 x + B_6 \\
  A_6 &= 11 \\
  B_6 &= 11625908999541321152027340224010374716841167701783584648338908235410859267060079819722747939267925389062611062156601938166010098747920378738927832658133625454260115409075816187555055859490253375704728027944315501122723426879114
\end{align*}
\]

## Extension fields

Given a prime $p$ and a natural number $k$, it is a fact that there is a unique (up to isomorphism) field of order $F_{p^k}$.
But this field is only unique up to isomorphism. In practice, if we want to do compute with $\F_{p^k}$, we must
pick a concrete representative or *model*. 

Let's start with the case $k = 2$. Fix $D \in \F_p$ which is not a square. I.e., for which there is no
$a \in \F_p$ with $a^2 = D$.

A handy model of $\F_{p^2}$ is $\F_p[\alpha] / (\alpha^2 - D)$. That is, polynomials over $\F_p$ in a single variable
$\alpha$ subject to the equation $\alpha^2 = D$. Put another way, this is the field we get by adding an
"imaginary" square root of $D$ called $\alpha$. 

Every element of this field is of the form $a + b \alpha$ where $a, b \in \F_p$.
The reason is that any higher powers of $\alpha$ may be squished down by replacing $\alpha^2$ with
$D$. There are indeed $p^2$ sums of the form $a + b \alpha$ so this field has the right order.

Addition and multiplication in this field follow from how addition and multiplication work
for polynomials:
\[
\begin{align*}
  (a + b\alpha) + (c + d \alpha) &= (a + c) + (b + d) \alpha \\
  (a + b \alpha)(c + d \alpha)
  &= ac + ad\alpha + bc\alpha + bd\alpha^2 \\
  &= ac + (ad + bc) \alpha + bd D \\
  &= (ac + bdD) + (ad + bc) \alpha \\
\end{align*}
\]

Higher extension fields work similarly. To call out another special case, if we want to
form a model for $\F_{p^3}$, we can find an element $D \in \F_p$ for which $D$ is not a cube.
Then the field $\F_p[\alpha] / (\alpha^3 - D)$ will have as its elements the sums of the form
$a + b \alpha + b \alpha^2$, again with higher powers getting squashed down with the equation
$\alpha^3 = D$. Addition and multiplication work similarly to the case of $\F_{p^2}$, although
there are some clever tricks to make them more efficient.

## Twist curves

Tick and Tock also have [twist curves](https://en.wikipedia.org/wiki/Twists_of_curves).
A twist of a curve $E$ defined over $\F_p$ is a curve $\twist{E}$ defined over $F_{p^\ell}$ for some $\ell$
which are isomorphic over $\algebraicClosure{\F_p}$.

The twist of Tick is defined over $\F_{q^2} = \F_q[\alpha] / (\alpha^2 - 13)$ and has the equation
\[
\begin{align*}
  y^2 &= x^3 \twist{A}_4 x + \twist{B}_4 \\
  \twist{A}_4 &= 13 A_4 + 0 \alpha \\
  \twist{B}_4 &= 0 + 13 B_4 \alpha
\end{align*}
\]

The twist of Tock is defined over $\F_{r^3} = \F_r[\beta] / (\beta^3 - 11)$ and has the equation
\[
\begin{align*}
  y^2 &= x^3 \twist{A}_6 x + \twist{B}_6 \\
  \twist{A}_6 &= 0 + 0 \beta + A_6 \beta^2 \\
  \twist{B}_6 &= 11 B_6 + 0 \beta + 0 \beta^2
\end{align*}
\]

## Ok. So what does the SNARK prover do and how can we make it fast?

The SNARK "prover" (the algorithm that produces SNARKs, compressing the blockchain) performs
operations involving arithmetic over $\F_q, \F_r$ and the [group operation]() in the groups
Tick and Tock.

Let us focus on the algorithm for proving with Tick. The algorithm for proving with Tock is
analogous but with $q$/$r$ and Tick/Tock swapped.

The "heavy" parts of the algorithm.
The algorithm
consists of several basic parts:

1. [Fast fourier transforms (FFTs)]() over $\F_r$.
2. [Multi exponentiation] in Tick.
3. [Multi exponentiation] in the twist of Tick.


### Optimizing field arithmetic
All of these algorithms rely on arithmetic in either $\F_r$ or $\F_q$. So any speedup
to addition and multiplication would yield an essentially proportional speedup to
the SNARK prover as a whole. Multiplication especially is important as it is considerably
more expensive than addition.

Using vectorized instructions is likely to help a lot here. We have heard that Sean Bowe's
Rust implementation of the curve BLS12-381 is faster than the existing C++ implementations
of Tick and Tock because the Rust compiler is better at emitting vectorized instructions.
This may be a promising avenue for optimization.

Here are several good approaches to improving the speed of these three algorithms.

That being said, there are certainly many optimization ideas beyond these.

