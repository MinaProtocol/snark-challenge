# Groth16Prove

<div class="table-of-contents">
<ul>
<li>
<a href="#quick-details">1: Quick details</a>
</li>
<li>
<a href="#problem-specification">2: Problem specification</a>
</li>
<li>
<a href="#parameters">2.1: Parameters</a>
</li>
<li>
<a href="#input">2.2: Input</a>
</li>
<li>
<a href="#output">2.3: Output</a>
</li>
<li>
<a href="#expected-behavior">2.4: Expected behavior</a>
</li>
<li>
<a href="#submission-guidelines">3: Submission guidelines</a>
</li>
<li>
<a href="#reference-implementation">4: Reference implementation</a>
</li>
<li>
<a href="#further-discussion-and-background">5: Further discussion and background</a>
</li>
<li>
<a href="#starter-code">5.1: Starter code</a>
</li>
</ul>
</div>

## Quick details

- **Problem:** The full Groth16 prover.
- **Prize:**
    - **Fastest at end of competition:** $20,000
    - **First submission to increase speed by 16x:** $12,000
    - **First submission to increase speed by 8x:** $10,000
    - **First submission to increase speed by 4x:** $8,000
    - **First submission to increase speed by 2x:** $5,000

This is the full Groth16 prover, or a slightly simplified version of it. It is the main
event of the SNARK Challenge.
It requires performing 7 [FFTs](/snark-challenge/problem-06-curve-operation.html), 4 [multiexponentiations](/snark-challenge/problem-05-multi-exponentiation.html) in $G_1$ and 1 multiexponentiation in $G_2$. How
exactly is described below.
The majority of the time is spent the multiexponentiations, so optimization efforts should be focussed there initially.

## Problem specification

The following problem is defined for any choice of (<a name="Rg==">F</a>, <a name="JEdfMSQ=">$G_1$</a>, <a name="JEdfMiQ=">$G_2$</a>)
in

- `MNT4753`: (<span>&#x1D53D;<sub><a href="/snark-challenge/MNT4753.html#cg==">MNT4753.r</a></sub></span>, <a href="/snark-challenge/MNT4753.html#JEdfMSQ=">MNT4753.$G_1$</a>, <a href="/snark-challenge/MNT4753.html#JEdfMiQ=">MNT4753.$G_2$</a>)
- `MNT6753`: (<span>&#x1D53D;<sub><a href="/snark-challenge/MNT6753.html#cg==">MNT6753.r</a></sub></span>, <a href="/snark-challenge/MNT6753.html#JEdfMSQ=">MNT6753.$G_1$</a>, <a href="/snark-challenge/MNT6753.html#JEdfMiQ=">MNT6753.$G_2$</a>)

You can click on the above types to see how they will be
represented in the files given to your program. `uint64`
values are represented in little-endian byte order. Arrays
are represented as sequences of values, with no length
prefix and no separators between elements. Structs are also
represented this way.

### Parameters

The parameters will be generated once and your submission will be allowed to preprocess them in any way you like before being invoked on multiple inputs.

- d : <span>uint64</span>
    <p><span class="math inline">d + 1</span> is guaranteed to be a power of <span class="math inline">2</span> in the MNT4753 case and of the form <span class="math inline">2^x 5^y</span> in the MNT6753 case.</p>
- m : <span>uint64</span>
- ca : <span>Array(<a href="#Rg==">F</a>, <span><a href="#ZA==">d</a>+1</span>)</span>
- cb : <span>Array(<a href="#Rg==">F</a>, <span><a href="#ZA==">d</a>+1</span>)</span>
- cc : <span>Array(<a href="#Rg==">F</a>, <span><a href="#ZA==">d</a>+1</span>)</span>
- A : <span>Array(<a href="#JEdfMSQ=">$G_1$</a>, <span><a href="#bQ==">m</a>+1</span>)</span>
- B1 : <span>Array(<a href="#JEdfMSQ=">$G_1$</a>, <span><a href="#bQ==">m</a>+1</span>)</span>
- B2 : <span>Array(<a href="#JEdfMiQ=">$G_2$</a>, <span><a href="#bQ==">m</a>+1</span>)</span>
- L : <span>Array(<a href="#JEdfMSQ=">$G_1$</a>, <span><a href="#bQ==">m</a>-1</span>)</span>
- T : <span>Array(<a href="#JEdfMSQ=">$G_1$</a>, <a href="#ZA==">d</a>)</span>

### Input

- w : <span>Array(<a href="#Rg==">F</a>, <span><a href="#bQ==">m</a>+1</span>)</span>
- r : <a href="#Rg==">F</a>

### Output

- proof : <span>{ <span>A : <a href="#JEdfMSQ=">$G_1$</a></span>, <span>B : <a href="#JEdfMiQ=">$G_2$</a></span>, <span>C : <a href="#JEdfMSQ=">$G_1$</a></span> }</span>

### Expected behavior

This problem is a version of the [Groth16 SNARK prover](https://eprint.iacr.org/2016/260.pdf), simplified to the difficult core of the problem.

If $P, Q$ are points on an elliptic curve (either $G_1$ or $G_2$) and $s : F$, then
$P + Q$ denotes the sum of the points as described [here](https://en.wikipedia.org/wiki/Elliptic_curve#The_group_law)
and $s \times P$ denotes the scalar-multiplication of $P$ by $s$ as described [here](https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Basics).

The output should be as follows.

- A = $$\sum_{i=0}^{m} w[i] \times A[i]$$
- B = $$\sum_{i=0}^{m} w[i] \times B2[i]$$
- C = $$\sum_{i=2}^{m} w[i] \times L[i - 2] + \sum_{i=0}^{d - 1} H[i] \times T[i] + r \sum_{i=0}^{m} w[i] \times B1[i]$$

where

- Let $\omega = \sigma^{(r - 1) / (d + 1)}$. This guarantees that
  we have $\omega^{d + 1} = 1$. Look at the MNT4753 or MNT6753 parameter
  pages to find the value of $\sigma$ in each case.

    H is an array of the coefficients of the polynomial
    $h(x) = \frac{a(x) b(x) - c(x)}{z(x)}$
    where $a, b, c$ are the degree d
    polynomials specified by

$$
\begin{aligned}
  a(\omega^i) &= ca[i] \\
  b(\omega^i) &= cb[i] \\
  c(\omega^i) &= cc[i] \\
\end{aligned}
$$

  for $0 \leq i < d + 1$ and where $z$ is the polynomial
$$
\begin{aligned}
  z(x)
  &= (x - 1)(x - \omega^1) \dots (x - \omega^{d}) \\
  &= x^{d} - 1
\end{aligned}
$$

One would want to obtain the coefficients of $h$ by computing its evaluations
on $\omega^0, \dots, \omega^{d}$ as `(d[i] * d[i] - d[i]) / z(ω_i)` for each `i`.
This won't work however as $z(\omega^i) = 0$ for each $i$. Alternatively, one can do the following.

1. Perform 3 inverse FFTs to compute the coefficients of $a, b$ and $c$.
2. Use the coefficients of these polynomials to compute the evaluations of of $a, b, c$
    on the "shifted set" $\{ \sigma , \sigma \omega^1, \sigma \omega^2, \dots, \sigma \omega^{d}\}$.

    Let's say `ea` is an array with `ea[i]` being the i<sup>th</sup> coefficient of the polynomial
    `a`. Then we can evaluate `a` on the set $\{ \sigma , \sigma \omega^1, \sigma \omega^2, \dots, \sigma \omega^{d}\}$
    by computing `sa = ea.map((ai, i) => sigma**i * ai)` and then performing an FFT on `sa`.
    Analogously for the polynomials $b$ and $c$ to obtain evaluation arrays `eb` and `ec`.

    In all this step requires 3 FFTs.
3. Note that $z(\sigma \omega^i) = \sigma^{d} \omega^{d} - 1 = \sigma^{d} - 1$.
    So, having computed `sa, sb, sc`, you can compute the evaluations of 
    $h(x) = \frac{a(x) b(x) - c(x)}{z(x)}$  on the
    shifted set as `sh[i] = (sa[i] * sb[i] - sc[i]) / (sigma**d - 1)`.

4. Finally, we can now obtain the coefficients `H` of $h$ by performing an inverse FFT on `sh` 
    to obtain `shifted_H` and
    then computing `H[i] = shifted_H[i] / sigma`.

All in all, we have to do 3 FFTs and 4 inverse FFTs to compute the array `H`,
perform 4 multiexponentiations in $G_1$ and 1 multiexponentiation in $G_2$.

.

## Submission guidelines

Your submission will be run and evaluated as follows.


0. The submission-runner will randomly generate the parameters and save them to
    files `PATH_TO_MNT4753_PARAMETERS` and `PATH_TO_MNT6753_PARAMETERS`.
0. Your binary `main` will be run with 

    ```bash
        ./main MNT4753 preprocess PATH_TO_MNT4753_PARAMETERS
./main MNT6753 preprocess PATH_TO_MNT6753_PARAMETERS
    ```
    where `PATH_TO_X_PARAMETERS` will be replaced by the actual path.

    Your binary can at this point, if you like, do some preprocessing of the parameters and
    save any state it would like to files `./MNT4753_preprocessed` and `./MNT6753_preprocessed`.
0. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

3. Your binary will be invoked with

    ```bash
        ./main MNT4753 compute PATH_TO_MNT4753_PARAMETERS PATH_TO_INPUTS PATH_TO_OUTPUTS
./main MNT6753 compute PATH_TO_MNT6753_PARAMETERS PATH_TO_INPUTS PATH_TO_OUTPUTS
    ```

    and its runtime will be recorded. The file `PATH_TO_INPUTS` will contain
    a sequence of inputs, each of which is of the form specified in the
    ["Input"](#input) section. 

    It should create a file called "outputs" at the path `PATH_TO_OUTPUTS`
    which contains a sequence of outputs, each of which is of the form
    specified in the ["Output"](#output) section.

    It can, if it likes, read the preprocessed files created in step 1
    in order to help it solve the problem.
    

## Reference implementation

The output of your submitted program will be checked against 
the reference implementation at this repo [here](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-07-groth16-prover).
The "main" file is [here](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-07-groth16-prover/libsnark/main.cpp).
The core algorithm is implemented [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-07-groth16-prover/libsnark/main.cpp#L199).


## Further discussion and background

### Starter code

- This [library](https://github.com/data61/cuda-fixnum) implements prime-order field arithmetic in CUDA.
Unfortunately, it's not currently compiling against CUDA 10.1 which is what is used on our benchmark machine, but
it should be a great place to start, either in getting it to compile against CUDA 10.1 or just as an example
implementation.
- This [repo](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction) has some starter code
   for a CUDA implementation of a parallel reduction for summing up an array of 32-bit integers.