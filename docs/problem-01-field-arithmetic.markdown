# Field arithmetic

<div class="table-of-contents">
<ul>
<li>
<a href="#quick-details">1: Quick details</a>
</li>
<li>
<a href="#problem-specification">2: Problem specification</a>
</li>
<li>
<a href="#input">2.1: Input</a>
</li>
<li>
<a href="#output">2.2: Output</a>
</li>
<li>
<a href="#expected-behavior">2.3: Expected behavior</a>
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
<a href="#montgomery-representation">5.1: Montgomery representation</a>
</li>
<li>
<a href="#starter-code">5.2: Starter code</a>
</li>
<li>
<a href="#other-resources">5.3: Other resources</a>
</li>
</ul>
</div>

## Quick details

- **Problem:** Use a GPU to multiply together an array of elements of a prime-order field.
- **Prize:**
    - **First 25 submissions:** $50
    - **All submissions:** Swag bag including SNARK challenge T-shirt.

## Problem specification



### Input

- n : <span>uint64</span>
- x : <span>Array(<span>&#x1D53D;<sub><a href="/snark-challenge/MNT4753.html#cQ==">MNT4753.q</a></sub></span>, <a href="#bg==">n</a>)</span>
    <p>The elements of <code>x</code> are represented using the Montgomery representation as described below.</p>
- y : <span>Array(<span>&#x1D53D;<sub><a href="/snark-challenge/MNT6753.html#cQ==">MNT6753.q</a></sub></span>, <a href="#bg==">n</a>)</span>
    <p>The elements of <code>y</code> are represented using the Montgomery representation as described below.</p>

### Output

- out_x : <span>&#x1D53D;<sub><a href="/snark-challenge/MNT4753.html#cQ==">MNT4753.q</a></sub></span>
- out_y : <span>&#x1D53D;<sub><a href="/snark-challenge/MNT6753.html#cQ==">MNT6753.q</a></sub></span>

### Expected behavior

Your implementation should use one or both of the benchmark machine's GPUs to solve this problem. The machine's specifications can be found [here]().
    
The output `out_x` should be `x[0] * x[1] * ... * x[n - 1]`
where `*` is multiplication in the field <span>&#x1D53D;<sub><a href="/snark-challenge/MNT4753.html#cQ==">MNT4753.q</a></sub></span>.

The output `out_y` should be `y[0] * y[1] * ... * y[n - 1]`
where `*` is multiplication in the field <span>&#x1D53D;<sub><a href="/snark-challenge/MNT6753.html#cQ==">MNT6753.q</a></sub></span>.


## Submission guidelines

Your submission will be run and evaluated as follows.


0. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

3. Your binary will be invoked with

    ```bash
        ./main compute PATH_TO_INPUTS PATH_TO_OUTPUTS
    ```

    and its runtime will be recorded. The file `PATH_TO_INPUTS` will contain
    a sequence of inputs, each of which is of the form specified in the
    ["Input"](#input) section. 

    It should create a file called "outputs" at the path `PATH_TO_OUTPUTS`
    which contains a sequence of outputs, each of which is of the form
    specified in the ["Output"](#output) section.

    
    

## Reference implementation

The output of your submitted program will be checked against 
the reference implementation at this repo [here](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-01-field-arithmetic).
The "main" file is [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-01-field-arithmetic/libff/main.cpp).
The core algorithm is implemented [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-01-field-arithmetic/libff/algebra/fields/fp.tcc#L161).


## Further discussion and background

The basic operations needed for the SNARK prover algorithm are
multiplication and addition of integers.

Usually when programming we're used to working with 32-bit or 64-bit
integers and addition and multiplication mod $2^{32}$ or $2^{64}$) respectively.

For the SNARK prover though, the integers involved are a lot bigger.
For our purposes, the integers are 753 bits and are represented using
arrays of native integers. For example, we could represent them using
an array of 12 64-bit integers (since $12 \cdot 64 = 768 > 753$) or
an array of 24 32-bit integers (since $24 \cdot 32 = 768 > 753$).
And instead of computing mod $2^{753}$, we'll compute mod $q$ where
$q$ is either [MNT4753.q](/snark-challenge/MNT4753.html#cQ==) or [MNT6753.q](/snark-challenge/MNT6753.html#cQ==).

Each element of such an array is called a "limb". For example, we would say
that we can represent a $2^{768}$ bit integer using 12 64-bit limbs.

We call the set of numbers $0, \dots, q - 1$ by the name $\mathbb{F}_q$.
This set forms a field, which means we can add, multiply, and divide numbers in
the set. Addition and multiplication happen mod q. It might seem weird that we can
divide, but it turns out for any $a, b$ in $\mathbb{F}_q$, there is a number $c$ 
in $\mathbb{F}_q$ such that $(c b) \mod q = a$.
In this case we say $a / b = c$ so that $(a / b) b \mod q = c b \mod q = a$
as you'd expect.

### Montgomery representation

Montgomery representation is an alternative way of representing elements of $\mathbb{F}_q$ so that
multiplication mod $q$ can be computed more efficiently.

Let $q$ be one of [MNT4753.q](/snark-challenge/MNT4753.html#cQ==) or [MNT6753.q](/snark-challenge/MNT6753.html#cQ==) and let $R = 2^{768}$.
The Montgomery representation of the nubmer $x$ is $(x R) \mod q$. So for example,
when $q$ is [MNT4753.q](/snark-challenge/MNT4753.html#cQ==), the number 5 is represented as $(5 \cdot 2^{768}) \mod q$ which
happens to be
```
15141386232259939182423724568694911114488003694957216858820448966622494022908702997737632032507442391226452946698823665470952711443326537357991482811741996884665155234620507693793230633117754640516203527639390490866666926222409
```
This number then is represented as a little-endian length 12 array of 64-bit integers.

In summary, we represent the number `x` as an array `a` with
```python
a.map((ai, i) => (2**i) * ai).sum() == (x * R) % q
```

Let us see how multplication works in this setting. We'll
use pseudocode with `%` for $\mathrm{mod}$.

Given the Montgomery representation
`X = (x * R) % q` of `x` and
`Y = (y * R) % q` of `y`,
we want to compute the
Montgomery representation of `(x * y) % q`,
which is `(x * y * R) % q`.

We have
```javascript
X * Y
== ((x * R) % q) * ((y * R) % q)
== (x * y * R * R) % q
```
So, if we had a function `div_R` for letting
us divide by `R` mod `q`, we would be able to compute
the Montgomery representation of `x * y` from `X`
and `Y` as `div_R(X * Y)`.

To recap, to implement multiplication mod $q$, we need to implement two functions:

1. Big integer multiplication, which takes two `k` limb integers and returns the `2 * k`-limb integer which
    is their product.
2. `div_R`, which takes a `2 * k`-limb integer `Z` and returns the `k`-limb integer equal to
    `(Z * r) % q`, where `r` is the inverse of `R`. That is, the number with `(R * r) % q = 1`.

We will then have
```
div_R(X * Y)
== div_R((x * y * R * R) % q)
== (x * y * R * R * r) % q
== (x * y * R * 1) % q
== (x * y * R) % q
```
which is the Montgomery representation of the product of the inputs, exactly as we wanted.

### Starter code

- This [library](https://github.com/data61/cuda-fixnum) implements prime-order field arithmetic in CUDA.
Unfortunately, it's not currently compiling against CUDA 10.1 which is what is used on our benchmark machine, but
it should be a great place to start, either in getting it to compile against CUDA 10.1 or just as an example
implementation.
- This [repo](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction) has some starter code
   for a CUDA implementation of a parallel reduction for summing up an array of 32-bit integers.

### Other resources

- Algorithms for big-integer multiplication and `div_R` (often called Montgomery reduction)
are given [here](http://cacr.uwaterloo.ca/hac/about/chap14.pdf), where our $q$ is called $m$.
- A C++ implementation of Montgomery reduction can be found [here](https://github.com/scipr-lab/libff/blob/master/libff/algebra/fields/fp.tcc#L161).
- [These slides](https://cryptojedi.org/peter/data/pairing-20131122.pdf) may have useful insights for squeezing out extra performance.
- This problem is sometimes called big integer multiplication, multi-precision multiplication,
  or more specifically "modular multiplication". You can find lots of great resources by
  searching for these terms along with "GPU".