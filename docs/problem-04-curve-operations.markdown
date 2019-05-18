# Curve operations

<div class="table-of-contents">
<ul>
<li>
<a href="#quick-details">1: Quick details</a>
</li>
<li>
<a href="#definition-of-curve-addition">2: Definition of curve addition</a>
</li>
<li>
<a href="#problem-specification">3: Problem specification</a>
</li>
<li>
<a href="#input">3.1: Input</a>
</li>
<li>
<a href="#output">3.2: Output</a>
</li>
<li>
<a href="#expected-behavior">3.3: Expected behavior</a>
</li>
<li>
<a href="#submission-guidelines">4: Submission guidelines</a>
</li>
<li>
<a href="#reference-implementation">5: Reference implementation</a>
</li>
<li>
<a href="#further-discussion-and-background">6: Further discussion and background</a>
</li>
<li>
<a href="#starter-code">6.1: Starter code</a>
</li>
<li>
<a href="#techniques">6.2: Techniques</a>
</li>
<li>
<a href="#coordinate-systems">6.2.1: Coordinate systems</a>
</li>
<li>
<a href="#parallelism">6.3: Parallelism</a>
</li>
</ul>
</div>

## Quick details

- **Problem:** Add together an array of elements of each of the four relevant elliptic curves.
- **Prize:**
    - **First 25 submissions:** $100
    - **All submissions:** Swag bag including SNARK challenge T-shirt.

In this challenge you'll use the field arithmetic built up 
in [this](/snark-challenge/problem-01-field-arithmetic.html), [this](/snark-challenge/problem-02-quadratic-extension-arithmetic.html) and [this challenge](/snark-challenge/problem-03-cubic-extension-arithmetic.html)
to implement the group operation for several elliptic curves.

## Definition of curve addition


Fix a field $\mathbb{F}$. For example, one of the fields described
on the parameter pages for [MNT4-753](/snark-challenge/MNT4753.html) and [MNT6-753](/snark-challenge/MNT6753.html).
Then fix numbers $a, b$ in $\mathbb{F}$. The set of points $(x, y)$ such that
$y^2 = x^3 + a x + b$ is called an elliptic curve over the field $\mathbb{F}$.

Elliptic curves are the essential tool powering SNARKs. They're useful because
we can define a kind of "addition" of points on a given curve. This is also
called the "group operation" for the curve.
Let's define this "addition" as follows using pseudocode, where `+, *, /` are
all taking place in the field $\mathbb{F}$.

```javascript

var curve_add = (p, q) => {
  var s = (p.y - q.y) / (p.x - q.x);
  var x = s*s - p.x - q.x;
  return {
    x: x,
    y: s*(p.x - x) - p.y
  };
};
```
Note that this definition doesn't work in the case that `p.x = q.x`. This case
splits into the case `p.y = q.y` (in which case its called "doubling" and
there is a separate formula) and the case `p.y = -q.y` in which case a special
"identity" value should be returned.

For efficiency, one uses a different, more complicated
formula for adding curve points. This will be discussed in
the techniques section below.

## Problem specification



### Input

- n : <span>uint64</span>
- g4_1 : <span>Array(<a href="/snark-challenge/MNT4753.html#XChHXzFcKQ==">MNT4753.\(G_1\)</a>, <a href="#bg==">n</a>)</span>
- g4_2 : <span>Array(<a href="/snark-challenge/MNT4753.html#XChHXzJcKQ==">MNT4753.\(G_2\)</a>, <a href="#bg==">n</a>)</span>
- g6_1 : <span>Array(<a href="/snark-challenge/MNT6753.html#XChHXzFcKQ==">MNT6753.\(G_1\)</a>, <a href="#bg==">n</a>)</span>
- g6_2 : <span>Array(<a href="/snark-challenge/MNT6753.html#XChHXzJcKQ==">MNT6753.\(G_2\)</a>, <a href="#bg==">n</a>)</span>

### Output

- h4_1 : <a href="/snark-challenge/MNT4753.html#XChHXzFcKQ==">MNT4753.\(G_1\)</a>
- h4_2 : <a href="/snark-challenge/MNT4753.html#XChHXzJcKQ==">MNT4753.\(G_2\)</a>
- h6_1 : <a href="/snark-challenge/MNT6753.html#XChHXzFcKQ==">MNT6753.\(G_1\)</a>
- h6_2 : <a href="/snark-challenge/MNT6753.html#XChHXzJcKQ==">MNT6753.\(G_2\)</a>

### Expected behavior

Your implementation should use one or both of the benchmark machine's GPUs to solve this problem. The machine's specifications can be found [here]().

`h4_1` should be `g4_1[0] + g4_1[1] + ... + g4_1[n - 1]` where `+` is the group operation for the curve [MNT4753.$G_1$](/snark-challenge/MNT4753.html#JEdfMSQ=).

`h4_2` should be `g4_2[0] + g4_2[1] + ... + g4_2[n - 1]` where `+` is the group operation for the curve [MNT4753.$G_2$](/snark-challenge/MNT4753.html#JEdfMiQ=).

`h6_1` should be `g6_1[0] + g6_1[1] + ... + g6_1[n - 1]` where `+` is the group operation for the curve [MNT6753.$G_1$](/snark-challenge/MNT6753.html#JEdfMSQ=).

`h6_2` should be `g6_2[0] + g6_2[1] + ... + g6_2[n - 1]` where `+` is the group operation for the curve [MNT6753.$G_2$](/snark-challenge/MNT6753.html#JEdfMiQ=).

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
the reference implementation at this repo [here](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-04-curve-operations).
The "main" file is [here](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-04-curve-operations/libff/main.cpp).
The core algorithm is implemented [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-04-curve-operations/libff/algebra/curves/mnt753/mnt4753/mnt4753_g1.cpp#L135).


## Further discussion and background

### Starter code

- This [library](https://github.com/data61/cuda-fixnum) implements prime-order field arithmetic in CUDA.
Unfortunately, it's not currently compiling against CUDA 10.1 which is what is used on our benchmark machine, but
it should be a great place to start, either in getting it to compile against CUDA 10.1 or just as an example
implementation.
- This [repo](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction) has some starter code
   for a CUDA implementation of a parallel reduction for summing up an array of 32-bit integers.

Please see [this page](/snark-challenge/strategies.html) for a more full list of implementation techniques.

### Techniques

#### Coordinate systems

Points in the form $(x, y)$ as above are said to be
represented using *affine coordinates*
and the above definition is *affine* curve addition.

There are more efficient ways of adding
curve points which use different coordinate systems.
The most efficient of these is called
*Jacobian coordinates*. Formulas for addition and doubling in Jacobian
coordinates can be found [here](https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#doubling-dbl-2007-bl)
and a Rust implementation [here](https://github.com/CodaProtocol/pairing/blob/mnt46-753/src/mnt4_753/ec.rs#L374).

There is a further technique called "mixed addition" which allows one to add
a point in Jacobian coordinates to a point in affine coordinates even more efficiently than adding
two points in Jacobian coordinates. This technique can yield large efficiency
gains but makes taking advantage of parallelism more complicated.

### Parallelism

This problem is an instance of a *reduction* and is inherently parallel.