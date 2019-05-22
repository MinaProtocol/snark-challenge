// This is a typescript implementation of MNT4753 G1
// multiexponentiation. I have chosen algorithms that
// I think should provide good performance. But of course
// it is javascript and so will not be parallel or very
// performant itself.
//
// Think of it as a blueprint for a fast CUDA or OpenCL
// implementation. There are many decisions that have to
// be made about memory representation, tuning look-up
// tables, but I think from an algorithmic point-of-view
// the algorithm implemented here would be a good starting
// point.

// All of the arithmetic we'll be dealing with happens
// mod a large prime q.
// I.e., whenever you do + or *, you do %q at the end.
const q : bigint = BigInt("0x01C4C62D92C41110229022EEE2CDADB7F997505B8FAFED5EB7E8F96C97D87307FDB925E8A0ED8D99D124D9A15AF79DB117E776F218059DB80F0DA5CB537E38685ACCE9767254A4638810719AC425F0E39D54522CDD119F5E9063DE245E8001");

// A "field element" is just a bigint in the interval [0, q - 1].
type FieldElement = bigint;

// There are different representations for points, some
// support more efficient operations than others.
// Jacobian and Affine are two such representations.
type JacobianPoint = {
  x : FieldElement,
  y : FieldElement,
  z : FieldElement
}

type AffinePoint = {
  x : FieldElement,
  y : FieldElement,
}

// It is easy to convert from Affine to Jacobian
function affineToJacobian(P : AffinePoint) : JacobianPoint {
  return { x: P.x, y:P.y, z:BigInt(1) };
}

// Multiplication mod q. In practice one would probably want to
// use Montgomery representation. Used in the cuda-fixnum library
// already.
function Mul(x : FieldElement, y : FieldElement) : FieldElement {
  return (x * y) % q;
}

// NB; Squaring can be made 1.5-2x faster than multiplication so it is
// worth special casing.
function Square(x : FieldElement) : FieldElement {
  return Mul(x, x);
}

function Add(x : FieldElement, y : FieldElement) {
  let s = x + y;
  if (s >= q) {
    return s - q;
  } else {
    return s;
  }
}

function Sub(x : FieldElement, y : FieldElement) {
  if (y <= x) {
    return x - y;
  } else {
    let s = y - x;
    return q - s;
  }
}

function timesTwo(x : FieldElement) : FieldElement {
  return Add(x, x);
}

function timesFour(x : FieldElement) : FieldElement {
  let x2 = x + x;
  return (x2 + x2) % q;
}

const aCoeff : FieldElement = BigInt(2);

function timesA(x : FieldElement) {
  return Mul(x, aCoeff);
}

function timesEight(x : FieldElement) {
  let x2 = x + x;
  let x4 = x2 + x2;
  return (x4 + x4) % q;
}

function timesThree(x : FieldElement) {
  let x2 = x + x;
  return (x2 + x) % q;
}

function pointAdd(P : JacobianPoint, Q : JacobianPoint) : JacobianPoint {
  let X1 = P.x, Y1 = P.y, Z1 = P.z;
  let X2 = Q.x, Y2 = Q.y, Z2 = Q.z;

  let Z1Z1 = Square(Z1);
  let Z2Z2 = Square(Z2);
  let U1 = Mul(X1, Z2Z2);
  let U2 = Mul(X2, Z1Z1);
  let S1 = Mul(Mul(Y1, Z2), Z2Z2);
  let S2 = Mul(Mul(Y2, Z1), Z1Z1);
  let H = Sub(U2, U1);
  let I = Square(timesTwo(H));
  let J = Mul(H, I);
  let r = timesTwo(Sub(S2, S1));
  let V = Mul(U1, I);
  let X3 = Sub(Sub(Square(r), J), timesTwo(V));

  return {
    x : X3,
    y : Sub(Mul(r, Sub(V, X3)), timesTwo(Mul(S1, J))),
    z :  Mul(Sub(Sub(Square(Add(Z1, Z2)), Z1Z1), Z2Z2), H)
  };
}

// This is much more efficient than pointAdd(P, P)
function pointDouble(P : JacobianPoint) : JacobianPoint {
  let X1 = P.x, Y1 = P.y, Z1 = P.z;
  let XX = Square(X1);
  let YY = Square(Y1);
  let YYYY = Square(YY);
  let ZZ = Square(Z1);
  let S = timesTwo(Sub(Sub(Square(Add(X1,YY)), XX), YYYY));
  let M = Add(timesThree(XX), timesA(Square(ZZ)));
  let T = Sub(Square(M), timesTwo(S));
  let X3 = T;
  let Y3 = Sub(Mul(M, Sub(S, T)), timesEight(YYYY));
  let Z3 = Sub(Sub(Square(Add(Y1,Z1)), YY), ZZ);
  return { x:X3, y:Y3, z:Z3 };
}

// Since Affine points are just Jacobian points with z=1,
// we can special case a lot of the operations above to
// get a more efficient "mixed add" function.
function mixedAdd(P : JacobianPoint, Q : AffinePoint) : JacobianPoint {
  // Many of these can be done in place to save memory
  let X1 = P.x, Y1 = P.y, Z1 = P.z;
  let X2 = Q.x, Y2 = Q.y;
  let Z1Z1 = Square(Z1);
  let U2 = Mul(X2, Z1Z1);
  let S2 = Mul(Mul(Y2, Z1), Z1Z1);
  let H = Sub(U2, X1);
  let HH = Square(H);
  let I = timesFour(HH);
  let J = Mul(H, I);
  let r = timesTwo(Sub(S2, Y1));
  let V = Mul(X1, I);
  let X3 = Sub(Sub(Square(r), J), timesTwo(V));
  let Y3 = Sub(Mul(r, Sub(V, X3)), timesTwo(Mul(Y1, J)));
  let Z3 = Sub(Sub(Square(Add(Z1, H)), Z1Z1), HH);
  return { x : X3, y : Y3, z : Z3 };
}

type Scalar = bigint;

const identity : JacobianPoint = { x : BigInt(0), y : BigInt(0), z : BigInt(1) };

function getBit(s : Scalar, i) : boolean {
  return ((s >> BigInt(i)) & BigInt(1)) == BigInt(1);
}

// Actually, since q is only 753 bits long, all numbers only involve 753 bits,
// but in practice you will use 768 bits to store bigints (since its the smallest
// multiple of 32 (or 64) bigger than 753, and bigint arithmetic is implemented in
// terms of 32- or 64-bit arithmetic.
const numBits = 753;

// Performs at most `numBits` many doublings and `mixedAdd`s
// scale(s, P) = P + ... + P
// s many times.
function scale(s : Scalar, P : AffinePoint) : JacobianPoint {
  let result = identity;
  for (let i = numBits - 1; i >= 0; --i) {
    result = pointDouble(result);
    if (getBit(s, i)) {
      result = mixedAdd(result, P);
    }
  }

  return result;
}
// To see the logic of this algorithm imagine we are computing
// scale(0b1010110110, P).
// We start with result = 0 * P.
// In the first iteration, we will first have
//  result == 2*0*P = 0*P
// after the doubling, and then
//  result == 0b1 * P
// after the conditional.
//
// In the second iteration, we will first have
//  result == 0b10 * P
// after the doubling, and then still
//  result == 0b10 * P
// after the conditional.
//
// In the third iteration, we will first have
//  result == 0b100 * P
// after the doubling, and then
//  result == 0b101 * P
// after the conditional.
//
// So on each iteration, we are "shifting" the multiple of P to the left and
// "or-ing" in the next bit of the binary representation of s into the multiple
// of P.

// There are two big optimizations we can do to this algorithm.
// 1. Share the cost of the "shifting"/doubling across many scalings
// when doing a multiexponentiation (or "multiscaling").
// 2. Use a lookup table to "or in" many bits of s at once. This is especially
//  useful in the context of SNARKs since the points we are scaling are
//  actually fixed.

// Should be an array of the form [ P, P^2, P^3, ... ]
type AffineLookupTable = Array<AffinePoint>
const windowSize = 3;
const numWindows = numBits / windowSize;

function getBitN(s, i) { return getBit(s, i) ? 1 : 0; }

function scaleLookup(s : Scalar, Ptable : AffineLookupTable) {
  let result = identity;

  for (let i = 0; i < numWindows; ++i) {
    // We shift "windowSize" many bits over
    for (let j = 0; j < windowSize; ++j) {
      result = pointDouble(result);
    }

    let windowEnd = (numBits - 1) - windowSize*i;
    // This should be implemented more efficiently in practice.
    // We also special case to windowSize = 3 for simplicity.
    let windowBits =
        4 * getBitN(s, windowEnd)
      + 2 * getBitN(s, windowEnd-1)
      +     getBitN(s, windowEnd-2);

    if (windowBits !== 0) {
      result = mixedAdd(result, Ptable[windowBits - 1]);
    }
  }
}


// Performs at most `numBits` many doublings and `n * numBits` many `mixedAdd`s.
// So we save on the doublings by sharing them across all the inputs since we
// would have to perform `n * numBits` doublings if done naively.
function multiScaleBatched(ps : Array<[Scalar, AffinePoint]>) : JacobianPoint {
  // Share the doublings across all scalars.
  const n = ps.length;
  let result = identity;
  for (let i = numBits - 1; i >= 0; --i) {
    result = pointDouble(result);

    for (let j = 0; j < n; ++j) {
      let [ s, P ] = ps[j];

      if (getBit(s, i)) {
        result = mixedAdd(result, P);
      }
    }
  }

  return result;
}

// We can combine the batching optimization with lookup tables as well.
// If the input has length `n`, this performs
//
// - `numBits` many doublings
// - `n * (numBits/windowSize)` many mixed-adds.
//
// Naively, this would require
//
// - `n * numBits` many doublings
// - `n * numBits` many mixed-adds.
//
// So if our batch-size is large, the cost of the doublings is a neglible
// part of the entire computation.
//
// The windowSize lets us scale the cost of the remainder of the computation,
// at the cost of using additional memory. Finding the right trade-off
// when using a GPU is an interesting problem.
function multiScaleLookupBatched(
  ps : Array<[ Scalar, AffineLookupTable ]>) : JacobianPoint {
  let result = identity;

  for (let i = 0; i < numWindows; ++i) {
    // We shift "windowSize" many bits over
    for (let j = 0; j < windowSize; ++j) {
      result = pointDouble(result);
    }

    let windowEnd = (numBits - 1) - windowSize*i;
    for (let j = 0; j < ps.length; ++j) {
      let [ s, Ptable ] = ps[j];

      let windowBits =
          4 * getBitN(s, windowEnd)
        + 2 * getBitN(s, windowEnd-1)
        +     getBitN(s, windowEnd-2);

      if (windowBits !== 0) {
        result = mixedAdd(result, Ptable[windowBits - 1]);
      }
    }
  }

  return result;
}

// This should be made parallel for a GPU implementation.
function mapReduce<A, B>(mapper : ((A) => B), reduce, xs : Array<A>) {
  let ys = [];

  for (var i = 0; i < xs.length; ++i) {
    ys.push(mapper(xs[i]));
  }

  let res = ys[0];

  for (var i = 1; i < ys.length; ++i) {
    res = reduce(res, ys[i]);
  }

  return res;
}

function multiexponentiation(
  ps : Array<AffineLookupTable>, // This part is computed once and fixed
  scalars : Array<Scalar> // This part will vary
) : JacobianPoint {

  const n = scalars.length;
  const batchSize = 32;
  const numBatches = n / batchSize;
  // We assume n is a multiple of batchSize

  let batches : Array< Array<[Scalar, AffineLookupTable]> > = [];

  // Split up the inputs into batches
  for (let i = 0; i < numBatches; ++i) {
    let batch = [];
    for (let j = 0; j < batchSize; ++j) {
      const k = i*batchSize + j;
      batch.push([ scalars[k], ps[k] ]);
    }
    batches.push(batch);
  }

  return mapReduce(multiScaleLookupBatched, pointAdd, batches);
}

// Potential improvements:
// - w-ary NAF
// - use Montgomery representation
// - perform doubling in-place
// - perform adding in-place

// G2 multi-exponentiation

// An element of the "extension field' F_{q^2}. It consists of
// two bigints
type EFieldElement = {
  a : FieldElement,
  b : FieldElement
};

// We'll need this special cased multiplication function
const nonResidue = BigInt(13);
function timesNonReside(x : FieldElement) : FieldElement {
  const x4 = timesFour(x);
  const x8 = x4 + x4;
  return (x8 + x4 + x) % q;
}

function EMul(x : EFieldElement, y : EFieldElement) : EFieldElement {
  let A = Mul(x.a, y.a);
  let B = Mul(x.b, y.b);
  return {
    a : Add(A, timesNonReside(B)),
    b : Sub(Sub(Mul(Add(x.a, x.b), Add(y.a, y.b)), A), B)
  };
}

// Here squaring is special cased.
function ESquare(x : EFieldElement) : EFieldElement {
  let a = x.a, b = x.b;
  let ab = Mul(a, b);

  return {
    a: Sub(Sub(Mul(Add(a, b), Add(a, timesNonReside(b))), ab), timesNonReside(ab)),
    b: timesTwo(ab)
  };
}

function EAdd(x : EFieldElement, y : EFieldElement) : EFieldElement {
  return {
    a: Add(x.a, y.a),
    b: Add(x.b, y.b)
  };
}

function ESub(x : EFieldElement, y : EFieldElement) : EFieldElement {
  return {
    a: Sub(x.a, y.a),
    b: Sub(x.b, y.b)
  };
}

function EtimesTwo(x : EFieldElement) : EFieldElement {
  return EAdd(x, x);
}

function EtimesFour(x : EFieldElement) : EFieldElement {
  let x2 = EAdd(x, x);
  return EAdd(x2, x2);
}

const EaCoeff : EFieldElement = {
  a: Mul(aCoeff, nonResidue),
  b: BigInt(0)
};

// This could be special cased for efficiency.
function EtimesA(x : EFieldElement) {
  return EMul(x, EaCoeff);
}

// All these could be made more efficient by doing the %q at the end in
// the "a" and "b" fields of the record.
function EtimesEight(x : EFieldElement) {
  let x2 = EAdd(x, x);
  let x4 = EAdd(x2, x2);
  return EAdd(x4, x4);
}

function EtimesThree(x : EFieldElement) {
  let x2 = EAdd(x, x);
  return EAdd(x2, x);
}

// These are "G2" Points
type G2JacobianPoint = {
  x : EFieldElement,
  y : EFieldElement,
  z : EFieldElement
}

type G2AffinePoint = {
  x : EFieldElement,
  y : EFieldElement,
}

// Everything that follows is the same as the "G1" versions of these functions
// with Add, Mul, etc replaced with EAdd, EMul, etc

function G2pointAdd(P : G2JacobianPoint, Q : G2JacobianPoint) : G2JacobianPoint {
  let X1 = P.x, Y1 = P.y, Z1 = P.z;
  let X2 = Q.x, Y2 = Q.y, Z2 = Q.z;

  let Z1Z1 = ESquare(Z1);
  let Z2Z2 = ESquare(Z2);
  let U1 = EMul(X1, Z2Z2);
  let U2 = EMul(X2, Z1Z1);
  let S1 = EMul(EMul(Y1, Z2), Z2Z2);
  let S2 = EMul(EMul(Y2, Z1), Z1Z1);
  let H = ESub(U2, U1);
  let I = ESquare(EtimesTwo(H));
  let J = EMul(H, I);
  let r = EtimesTwo(ESub(S2,S1));
  let V = EMul(U1, I);
  let X3 = ESub(ESub(ESquare(r), J), EtimesTwo(V));

  return {
    x : X3,
    y : ESub(EMul(r, ESub(V, X3)), EtimesTwo(EMul(S1, J))),
    z :  EMul(ESub(ESub(ESquare(EAdd(Z1, Z2)), Z1Z1), Z2Z2), H)
  };
}

function G2pointDouble(P : G2JacobianPoint) : G2JacobianPoint {
  let X1 = P.x, Y1 = P.y, Z1 = P.z;
  let XX = ESquare(X1);
  let YY = ESquare(Y1);
  let YYYY = ESquare(YY);
  let ZZ = ESquare(Z1);
  let S = EtimesTwo(ESub(ESub(ESquare(EAdd(X1, YY)), XX), YYYY));
  let M = EAdd(EtimesThree(XX), EtimesA(ESquare(ZZ)));
  let T = ESub(ESquare(M), EtimesTwo(S));
  let X3 = T;
  let Y3 = ESub(EMul(M, ESub(S, T)), EtimesEight(YYYY));
  let Z3 = ESub(ESub(ESquare(EAdd(Y1,Z1)), YY), ZZ);
  return { x:X3, y:Y3, z:Z3 };
}

function G2mixedAdd(P : G2JacobianPoint, Q : G2AffinePoint) : G2JacobianPoint {
  // Many of these can be done in place to save memory
  let X1 = P.x, Y1 = P.y, Z1 = P.z;
  let X2 = Q.x, Y2 = Q.y;
  let Z1Z1 = ESquare(Z1);
  let U2 = EMul(X2, Z1Z1);
  let S2 = EMul(EMul(Y2, Z1), Z1Z1);
  let H = ESub(U2, X1);
  let HH = ESquare(H);
  let I = EtimesFour(HH);
  let J = EMul(H, I);
  let r = EtimesTwo(ESub(S2, Y1));
  let V = EMul(X1, I);
  let X3 = ESub(ESub(ESquare(r), J), EtimesTwo(V));
  let Y3 = ESub(EMul(r, ESub(V, X3)), EtimesTwo(EMul(Y1, J)));
  let Z3 = ESub(ESub(ESquare(EAdd(Z1, H)), Z1Z1), HH);
  return { x : X3, y : Y3, z : Z3 };
}

const Ezero : EFieldElement = { a : BigInt(0), b: BigInt(0) };
const Eone : EFieldElement = { a : BigInt(1), b: BigInt(0) };
const G2identity : G2JacobianPoint = { x : Ezero, y : Ezero, z : Eone };

type G2AffineLookupTable = Array<G2AffinePoint>
function G2multiScaleLookupBatched(
  ps : Array<[ Scalar, G2AffineLookupTable ]>) : G2JacobianPoint {
  let result = G2identity;

  for (let i = 0; i < numWindows; ++i) {
    // We shift "windowSize" many bits over
    for (let j = 0; j < windowSize; ++j) {
      result = G2pointDouble(result);
    }

    let windowEnd = (numBits - 1) - windowSize*i;
    for (let j = 0; j < ps.length; ++j) {
      let [ s, Ptable ] = ps[j];

      let windowBits =
          4 * getBitN(s, windowEnd)
        + 2 * getBitN(s, windowEnd-1)
        +     getBitN(s, windowEnd-2);

      if (windowBits !== 0) {
        result = G2mixedAdd(result, Ptable[windowBits - 1]);
      }
    }
  }

  return result;
}

