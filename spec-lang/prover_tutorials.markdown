# Prover Tutorials

- [Introduction](#introduction)
- [Formatting and Submission](#formatting-and-submission)
- [Starter Code: Field Arithmetic](#field-arithmetic)
	+ [Detailed Spec](https://coinlist.co/build/coda/pages/problem-01-field-arithmetic)
- [Stage 1: Quadratic Extension Arithmetic: $150](#quadratic-extension-arithmetic)
	+ [Detailed Spec](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic)
- [Stage 2: Cubic Extension Arithmetic: $150](#cubic-extension-arithmetic)
	+ [Detailed Spec](https://coinlist.co/build/coda/pages/problem-03-cubic-extension-arithmetic)
- [Stage 3: Curve Operations: $200](#curve-operations)
	+ [Detailed Spec](https://coinlist.co/build/coda/pages/problem-04-curve-operations)
- [Next steps](#next-steps)

## Introduction

In these tutorials, we will guide you through implementing elliptic curves, the basic building blocks for a SNARK prover on GPU.

By the end you’ll be well positioned to start swapping components of the reference CPU prover for GPU components and make your first speedups.

This tutorial breaks this down into individual steps, guiding you from some GPU starter code to an on-GPU elliptic curve implementation. So, even if you haven’t encountered elliptic curves before it will be straightforward to get started with a solution.

Our starter code uses CUDA, and you can use as a base for the first stage of the tutorial. If you know CUDA or another GPU programming language well you should feel free to start on your own too.

We intend for each of these stages to take at most a few hours, given some background in GPU computing. Feel free to contact us (brad@o1labs.org) or jump on our [discord channel](https://discord.gg/DUhaJ42) if you have any questions!

## Tutorial Stages

- [Starter Code: Field Arithmetic](#field-arithmetic)
- [Stage 1: Quadratic Extension Arithmetic](#quadratic-extension-arithmetic): $150
- [Stage 2: Cubic Extension Arithmetic](#cubic-extension-arithmetic): $150
- [Stage 3: Curve Operations](#curve-operations): $200

By the end of the tutorial stages, you’ll understand:

- How elliptic curve operations are implemented
- How to make your first improvements to the SNARK prover

## Formatting and Submission

For each tutorial, there is a reference CPU solution your GPU program will be checked against.

For each, there will be some inputs, an operation you need to perform on them, and some outputs.

Your program can interpret inputs and format outputs in either standard numeric form, or it can interpret inputs / outputs in “montgomery” form. However, your program must perform the operation using montgomery arithmetic, as it is far more efficient than standard arithmetic. (the starter code already uses montgomery arithmetic, checkout the Wikipedia article [here](https://en.wikipedia.org/wiki/Montgomery_modular_multiplication) to learn more about it).

Your submissions will be run and evaluated as follows.

1. The submission runner will generate a random sequence of inputs, saved to a file inputs
2. Your binary will be compiled with ```./build.sh```. This step should produce a binary ```./main```
3. Your binary will be invoked with ```./main compute inputs outputs```
4. See each problem’s reference implementation for the expected inputs / outputs format

### Field Arithmetic

- [Starter code on github](https://github.com/CodaProtocol/cuda-fixnum/)
- [Reference code on github](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-01-field-arithmetic)
- [Detailed Field Arithmetic Spec](https://coinlist.co/build/coda/pages/problem-01-field-arithmetic)

The tutorial starter code implements Field Arithmetic, interpreting inputs and outputs in standard numeric form and performing operations using montgomery arithmetic on the GPU.

Check out [this file](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-01-field-arithmetic/libff/main.cpp) in the reference code for the exact I/O format and to see where the operations are being performed.

#### What is Field Arithmetic?

[Field arithmetic](https://jeremykun.com/2014/03/13/programming-with-finite-fields/) takes non-negative numbers, and adds the concept of a "modulus." When you do an operation in field arithmetic, you mod the result by the modulus to get your result.

For example, if the modulus is "17," then:

```
10 + 10 = 20 mod 17 = 3
7*4 = 28 mod 17 = 11
84 = 84 mod 17 = 16
```

Division also takes on a slightly different meaning. An element times its inverse is still 1 (½ x 2 = 1). However, the inverse is itself an element on the field instead of a fraction. For example, for 2, 2^(-1) x 2 = 1, but 2^(-1) = 9. You can verify that 9 x 2 = 18 = 18 mod 17 = 1. Every element besides zero in the field has another element as its inverse. (for 17, [1,1], [2,9], [3,6], etc)

For our problem, our modulus is very large (753 bits!). The starter code represents uses bignums to accommodate this.

We also require doing arithmetic in montgomery form. The starter code already does this, but if you’re curious to learn more checkout the Wikipedia article [here](https://en.wikipedia.org/wiki/Montgomery_modular_multiplication).

### Quadratic Extension Arithmetic

- [Reference code on github](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-02-quadratic-extension/libff/main.cpp)
- Prize: $150 for the first 10 submissions
- [Detailed Quadratic Extension Spec](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic)

In this tutorial you will implement "Quadratic Extension" Arithmetic.

Check out [this file](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-02-quadratic-extension/libff/main.cpp) in the reference code for the exact I/O format and to see where the operations are being performed.

#### Quadratic Extension Multiplication

Instead of multiplying field elements, we’ll now be multiplying elements in a “quadratic extension field”. This is similar to complex numbers, but for fields. Instead of having just a single field as above, we’ll now have 2 fields.

To multiply two elements in a “quadratic extension field”, you do the following arithmetic, where “fq_mul” is field multiplication, “fq_add” is field addition (see starter code), and “fq” is the field representation of a numeral. To learn more, checkout in-depth documentation [here](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic#definitions-and-review).

To multiply two elements in a "quadratic extension field", you do the following arithmetic, where ```fq_mul``` is field multiplication, ```fq_add``` is field addition (see starter code), and ```fq``` is the field representation of a numeral. To learn more, checkout in depth documentation [here](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic#definitions-and-review).

```
var fq2_mul = (a, b) => {
  var a0_b0 = fq_mul(a.a0, b.a0);
  var a1_b1 = fq_mul(a.a1, b.a1);
  var a1_b0 = fq_mul(a.a1, b.a0);
  var a0_b1 = fq_mul(a.a0, b.a1);
  return {
    a0: fq_add(a0_b0, fq_mul(a1_b1, alpha)),
    a1: fq_add(a1_b0, a0_b1)
  };
};
var alpha = fq(13);

var fq2_add = (a, b) => {
  return {
    a: fq_add(a.a0, b.a0),
    b: fq_add(a.a0, b.a0)
  };
};
```

### Cubic Extension Arithmetic

- [Reference code on github](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-03-cubic-extension)
- Prize: $150 for first 10 submissions
- [Detailed Cubic Extension Spec](https://coinlist.co/build/coda/pages/problem-04-curve-operations)

In this tutorial you will implement “Cubic Extension” Arithmetic. After this, you’ll be ready to implement operations on elliptic curves!

Checkout [this file](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-03-cubic-extension/libff/main.cpp) in the reference code for the exact I/O format and to see where the operations are being performed.

#### Cubic Extension Multiplication

Similar to previous problem, except now instead of 2 fields, there are 3 fields! In depth documentation [here](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic#definitions-and-review), see pseudo code as follows:

```
var alpha = fq(11);

var fq3_add = (a, b) => {
  return {
    a0: fq_add(a.a0, b.a0),
    a1: fq_add(a.a1, b.a1),
    a2: fq_add(a.a2, b.a2)
  };
};

var fq3_mul = (a, b) => {
  var a0_b0 = fq_mul(a.a0, b.a0);
  var a0_b1 = fq_mul(a.a0, b.a1);
  var a0_b2 = fq_mul(a.a0, b.a2);

  var a1_b0 = fq_mul(a.a1, b.a0);
  var a1_b1 = fq_mul(a.a1, b.a1);
  var a1_b2 = fq_mul(a.a1, b.a2);

  var a2_b0 = fq_mul(a.a2, b.a0);
  var a2_b1 = fq_mul(a.a2, b.a1);
  var a2_b2 = fq_mul(a.a2, b.a2);

  return {
    a0: fq_add(a0_b0, fq_mul(alpha, fq_add(a1_b2, a2_b1))),
    a1: fq_add(a0_b1, fq_add(a1_b0, fq_mul(alpha, a2_b2))),
    a2: fq_add(a0_b2, fq_add(a1_b1, a2_b0))
  };
};
```

### Curve Operations

- [Reference code on github](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-04-curve-operations)
- Prize: $200 for first 10 submissions

We’re ready to implement elliptic curves! After this, you’ll be ready to apply these primitives to a faster snark prover.

Check out [this file](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-04-curve-operations/libff/main.cpp) in the reference code for the exact I/O format and to see where the operations are being performed.

#### MNT4 and MNT6

A single snark proving / verifying system is a pair of elliptic curves. We’ll call these (G1, G2). Because we are optimizing the snark prover for 2 snark proving / verifying systems (MNT4 and MNT6), we have 4 total curves:

1. MNT4 G1
2. MNT4 G2
3. MNT6 G1
4. MNT6 G2

We’ll use the following shorthand for the elements from the previous tutorial stages:

- Fields: `Fq`
- Quadratic Extension Fields: `Fq2`
- Cubic Extension Fields: `Fq3`

Each curve is specified by a pair of two of these elements, specifically:

- MNT4 G1: (Fq, Fq)
- MNT4 G2: (Fq2, Fq2)
- MNT6 G1: (Fq, Fq)
- MNT6 G2: (Fq3, Fq3)

#### Curve Addition

Operations are defined on elements of the same type, so if you’re adding two curves from MNT4 G1, you’ll use field operations. If you’re adding elements from MNT6 G2, you’ll use cubic extension operations.

Say our two curves we’re adding are p, and q. Where p.x and p.y refer to the first and second elements of the curve.

In the usual case, you do:

```
var curve_add = (p, q) => {
  var s = (p.y - q.y) / (p.x - q.x);
  var x = s*s - p.x - q.x;
  return {
    x: x,
    y: s*(p.x - x) - p.y
  };
};
```

However, if p == q then you do a different algorithm called “doubling”. 

```
var curve_double = (p, q) => {
  var s = (p.x*p.x+p.x*p.x+p.x*p.x + coeff_a) / (p.y + p.y);
  var x = s*s - p.x - q.x;
  return {
    x: x,
    y: s*(p.x - x) - p.y
  };
};
```

Curves have some additional parameters unique to each curve. `coeff_a` is one of these parameters. See [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-04-curve-operations/libff/algebra/curves/mnt753/mnt4753/mnt4753_init.cpp#L119) for where `coeff_a` is defined for MNT4_G1 (which happens to be just "2" for this curve). See sibling files in the reference repo for the `coeff_a` of the other 3 curves.

See an optimized add function [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-04-curve-operations/libff/algebra/curves/mnt753/mnt4753/mnt4753_g1.cpp#L220) for addition in MNT4 G1.

Read more about elliptic curve operations on Wikipedia [here](https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_addition).

## Next steps

After you’ve finished the tutorial, you’ll have an on-GPU implementation of curve operations and you’ll be ready to start swapping components of the reference CPU prover for GPU components.

The first thing to do is to swap out is the prover’s multi-exponentiations (see prover reference [here](https://coinlist.co/build/coda/pages/problem-05-multi-exponentiation)).

The multi-exponentiations can be seen as a giant map-reduce, as explained [here](https://youtu.be/81uR9W5PZ5M?t=772). Move the “map” off CPU to take advantage of the parallelism offered by a GPU!

After that, some more hints on what to try:

- Put the [reduce](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction) portion of the multi-exponentiations on GPU as well
- Use an on-GPU FFT (see for example [cuFFT](https://developer.nvidia.com/cufft)) for the FFT portion of the prover
- Optimize the curve operations further (see “jacobian coordinates” and “mixed addition” - ask us for hints as well we have many ideas on cool hacks for further efficiency gains)

For more information on the prover architecture, we suggest looking at the following

- [**Prover video**](https://youtu.be/81uR9W5PZ5M). This video discusses the construction of the prover in detail (recommended).
- [**Prover spec page**](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges). This walks you through the architecture of the prover.
