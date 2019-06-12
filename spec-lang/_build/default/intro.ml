open Core
open Util

let url = sprintf "%s/intro.html" base_url

let page (pages : Pages.t) =
  ksprintf Markdown.of_string
    {md|The Groth16 SNARK prover is not such a complicated algorithm, but
it does involve several steps, each of which builds on the next.
The prover must be implemented for two settings of parameters:
the parameters associated with the curve [MNT4-753](%s) and those
associated with the curve [MNT6-753](%s).

Once a collection of parameters $(r, q, e, G_1, G_2)$ is fixed, the
sub-problems making up the SNARK prover are

1.
    a. Addition and multiplication mod $q$.
    b. Addition and multiplication mod $r$.
    
    It is possible for
    the "modulus" (here either $q$ or $r$) to be a parameter in one's
    code, so typically 1a and 1b will share an implementation.
2. Arithmetic in the extension field $\mathbb{F}_{q^e}$. This is pretty
   straightforward to implement once step 1a is complete, though the
   implementation will differ between MNT4 and MNT6.
3.
    a. The group operation in $G_1$. This is easy to implement after completing 1a.
    b. The group operation in $G_2$. This is easy to implement after completing 2
      and typically can share an implementation with the $G_1$ group operation if
      working in a language with generics or templates.
      The only difference between the two being which field operations (i.e.,
      multiplication and addition) are used: those of $\mathbb{F}_q$ for $G_1$
      and those of $\mathbb{F}_{q^e}$ for $G_2$.
4.
    a. Multi-exponentiation in $G_1$.
      There are many techniques for computing this efficiently, but they all essentially
      rely on the group operation from 3a.
    b. Multi-exponentiation in $G_2$. Again, this is similar to 4a and could share
      an implementation which was generic over the group operation.
5. The fast-fourier-transform (FFT) over the field $\mathbb{F}_r$. This only
   depends on 1b. 

Finally, the Groth16 SNARK prover itself simply performs 4 multi-exponentiations
in $G_1$, 1 multi-exponentiation in $G_2$, and a few FFTs, combining the results
together in a [simple way].

The dependencies between all these algorithms are illustrated in this
image:
<div>
  <img src='%s/static/ladder.png'>
</div>
The colored boxes illustrate when one can use a generic implementation to implement
both algorithms. Thus, there are 5 essentially different parts of the
prover implementation.
|md}
    pages.mnt4 pages.mnt6 base_url
