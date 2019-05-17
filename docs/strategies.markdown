# Implementation strategies
<div class="table-of-contents">
<ul>
<li>
<a href="#splitting-computation-between-the-cpu-and-gpu">1: Splitting computation between the CPU and GPU</a>
</li>
<li>
<a href="#parallelism">2: Parallelism</a>
</li>
<li>
<a href="#parallelism-on-the-cpu">2.1: Parallelism on the CPU</a>
</li>
<li>
<a href="#parallelism-on-the-gpu">2.2: Parallelism on the GPU</a>
</li>
<li>
<a href="#field-arithmetic">3: Field arithmetic</a>
</li>
<li>
<a href="#optimizing-curve-arithmetic">4: Optimizing curve arithmetic</a>
</li>
<li>
<a href="#representation-of-points">4.1: Representation of points</a>
</li>
<li>
<a href="#exponentiation-algorithms">4.2: Exponentiation algorithms</a>
</li>
</ul>
</div>

This page has suggestions for how to implement the best Groth16 SNARK
prover ([described here](/snark-challenge/problem-07-groth16prove.html)) to take home up to $75,000 in prizes.

## Splitting computation between the CPU and GPU

The Groth16 prover consists of 4 $G_1$ multiexponentiations, 1 $G_2$ multiexponentiation,
and 7 FFTs, as described [here](/snark-challenge/problem-07-groth16prove.html).

1 of the $G_1$ multiexponentiations cannot be computed until all of the FFTs.
The other 3 $G_1$ multiexponentiations and the $G_2$ multiexponentiation however
don't have any dependencies between each other or on any other computation.

So, some of them can be computed on the CPU while at the same time others are computed on the GPU.
For example, you could first the FFTs first on the CPU, while simultaneously performing 2 of
the $G_1$ multi-exponentiations on the GPU. After those completed, you could then compute the
final $G_1$ multi-exponentiation on the CPU and the $G_2$ multi-exponentiation on the GPU.

## Parallelism

Both the FFT and the multiexponentiations are massively parallelizable.
        The multiexponentiation in particular is an instance of a reduction: combining
        an array of values together using a binary operation.

### Parallelism on the CPU

[libsnark](https://github.com/scipr-lab/libsnark)'s "sub-libraries"
[libff](https://github.com/scipr-lab/libff/) and
[libfqfft](https://github.com/scipr-lab/libfqfft) implement parallelized
multiexponentiation (code [here](https://github.com/scipr-lab/libff/blob/master/libff/algebra/scalar_multiplication/multiexp.tcc#L402)) and
FFT (code [here](https://github.com/scipr-lab/libfqfft/blob/master/libfqfft/evaluation_domain/domains/basic_radix2_domain_aux.tcc#L81))
respectively.

### Parallelism on the GPU

Check out [this CUDA code](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction)
which implements a parallel reduction in CUDA to sum up an array of 32-bit ints.

## Field arithmetic

There is an excellent CUDA implementation of modular-multiplication using Montgomery representation
[here](https://github.com/data61/cuda-fixnum). Using that library to implement the field extension 
multiplication and curve-additions
and then building a parallel reduction for curve-addition is likely an excellent path to
creating a winning implementation of multi-exponentiation.

## Optimizing curve arithmetic

### Representation of points

There are many ways of representing curve points which yield efficiency improvements.
Probably the best is [Jacobian coordinates]() which allow for doubling points with
$4$ multiplications and adding points with 12 multiplications.

If some of the points
are statically known, as in the case of an exponentiation, they can be represented in
affine coordinates and one can take advantage of "mixed-addition". Mixed-addition allows you
to add a point in affine cordinates to a point in Jacobian coordinates to obtain a point in
Jacobian coordinates at a cost of 8 multiplications.

There are likely many other optimizations

### Exponentiation algorithms

There are many techniques for speeding up exponentiation and multi-exponentiation.