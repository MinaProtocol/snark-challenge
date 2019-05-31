/* The goal of this challenge is to implement the verifier for the Bowe--Gabizon
 * SNARK in Javascript.
 *
 * This challenge is set up so that if you like, you can replace only some parts
 * of the verifier and still have a working submission.
 * 
 * Here is a "call graph" of dependencies for `boweGabizonVerifier`,
 * the full verification function:
 *
 * - boweGabizonVerifier
 *   - hashToGroup
 *     - pedersenHash
 *     - groupMap
 *   - boweGabizonVerifierCore
 *
 * So, `boweGabizonVerifier` calls into `hashToGroup` and `boweGabizonVerifierCore`.
 * `hashToGroup` in turn calls into `pedersenHash` and `groupMap`.
 *
 * You can implement as many of these functions as you like. If you implement
 * a function, any implementations of "children functions" will be ignored and
 * that function will be used. 
 *
 * So for example if you want to replace everything, you can
 * implement `boweGabizonVerifier`. 
 *
 * If you only want to replace the pedersen hash, you can just implement
 * `pedersenHash` and the rest of the functions will be filled in with default
 * implementations.
 */

/* This file is a typescript description of the interfaces required for all the
 * functions listed above. It also acts as a specification for said functions.
 */
// An array of length 24.
type Fq = Uint32Array

type Fr = Fq;

type Fq3 = {
  a : Fq,
  b : Fq,
  c : Fq,
};

type Fq6 = {
  a : Fq3,
  b : Fq3,
};

type AffinePoint<F> = {
  x : F,
  y : F,
};

type AffineG1 = AffinePoint<Fq>;
type AffineG2 = AffinePoint<Fq3>;

type Proof = {
  a          : AffineG1,
  b          : AffineG2,
  c          : AffineG1,
  deltaPrime : AffineG2,
  z          : AffineG1,
};

type ExtendedProof = {
  a          : AffineG1,
  b          : AffineG2,
  c          : AffineG1,
  deltaPrime : AffineG2,
  z          : AffineG1,
  yS         : AffineG1,
};

type VerificationKey = {
  alphaBeta : Fq6,
  delta : AffineG2,
  query : Array<AffineG1>,
};

/* This is the full verifier function. If you implement this, no other
 * implementations will be used and this function will be called directly.
 */
function boweGabizonVerifier(
  vk : VerificationKey,
  input : Fr,
  proof : Proof
) : boolean {
  const eProof : ExtendedProof = {
    a: proof.a,
    b: proof.b,
    c: proof.c,
    deltaPrime: proof.deltaPrime,
    z : proof.z,
    yS: hashToGroup(proof.a, proof.b, proof.c, proof.deltaPrime)
  };

  return verifierCore(vk, input, eProof);
};

/* This should implement the "group map". 
 * Bowe-Hopwood Pedersen hash function for the MNT6753
 * G1 curve. Please see verifier.ts for more details.
 */
function groupMap (x : Fq) : AffineG1 {
  throw 'not implemented'
};

/* This should implement the Bowe-Hopwood Pedersen hash function for the MNT6753
 * G1 curve. Please see verifier.ts for more details.
 */
function pedersenHash (ts : Array<[boolean, boolean, boolean]>) : Fq {
  throw 'not implemented'
};

/* This function essentially converts its inputs into bits, feeds that into
 * pedersenHash, then into blake2s, then into groupMap.
 * Please see verifier.ts for more details.
 */
function hashToGroup (
  a : AffineG1,
  b : AffineG2,
  c : AffineG1,
  deltaPrime : AffineG2) : AffineG1 {
  throw 'not implemented'
}

/* This function should check
  e(proof.a, proof.b)
  === proof.alphaBeta
      * e(G1.add(vk.query[0], G1.scale(input, vk.query[1])), G2.one)
      * e(proof.c, proof.deltaPrime)

  and

  e(proof.yS, deltaPrime) === e(proof.z, vk.delta)

  where e is the bilinear pairing on MNT6753 and where * is multiplication in
  Fq6.
*/
function verifierCore (
  vk : VerificationKey,
  input : Fr,
  proof : ExtendedProof) : boolean {
  throw 'not implemented'
};
