open Util

let t =
  Html.markdown
    {md|# Implementation suggestions

This page has suggestions for how to implement the best Groth16 SNARK
prover ([described here](%s)) to take home up to $75,000 in prizes.

## Parallelism
Both the FFT and the multiexponentiations are massively parallelizable.
The multiexponentiation in particular is an instance of a reduction: combining
an array of values together using a binary operation. Check out [this CUDA code](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction)
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
|md}
