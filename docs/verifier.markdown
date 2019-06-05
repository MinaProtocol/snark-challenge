# Fastest JavaScript/WebAssembly verifier
<div class="table-of-contents">
<ul>
<li>
<a href="#quick-details">1: Quick details</a>
</li>
<li>
<a href="#submission-format">2: Submission format</a>
</li>
<li>
<a href="#starter-code">3: Starter code</a>
</li>
</ul>
</div>

## Quick details

- **Problem:** Implement the Bowe--Gabizon verifier for [MNT6-753](/snark-challenge/MNT6753.html) to run in the browser using JavaScript and/or WebAssembly.
- **Prize:**
    - **Fastest at end of competition when run on Firefox:** $10,000

The [Bowe--Gabizon SNARK](https://eprint.iacr.org/2018/187.pdf) is
a variation on the Groth16 SNARK. This challenge involves implementing the
verifier algorithm for the Bowe--Gabizon SNARK using
JavaScript or WebAssembly so
that it can be run in a browser.

We'll use Typescript to give a specification of the functions your JavaScript program should implement.

The Bowe--Gabizon verifier consists of several functions. You can, if you choose, implement only these algorithms and default implementations will be provided for the rest.

We'll call the top-level verifier algorithm `boweGabizonVerifier`.
Here is a "call graph" of functions used by `boweGabizonVerifier`:

- `boweGabizonVerifier`
  - `hashToGroup`
    - `pedersenHash`
    - `groupMap`
  - `boweGabizonVerifierCore`


So, `boweGabizonVerifier` calls into `hashToGroup` and `boweGabizonVerifierCore`.
`hashToGroup` in turn calls into `pedersenHash` and `groupMap`.

You can implement as many of these functions as you like. If you implement
a function, any implementations of "children functions" will be ignored and
that function will be used. 

For example, if you want to replace everything, you can
implement `boweGabizonVerifier`. 

If you only want to replace the Pedersen hash, you can just implement
`pedersenHash` and the rest of the functions will be filled in with default
implementations.


## Submission format

Your submission be a file called `main.js` containing implementations of
any of the following 5 functions:
```typescript

function boweGabizonVerifier(
  vk : VerificationKey,
  input : Fr,
  proof : Proof) : boolean {
  ...
};

function groupMap (x : Fq) : AffineG1 {
  ...
};

function pedersenHash (ts : Array<[boolean, boolean, boolean]>) : Fq {
  ...
};

function hashToGroup (
  a : AffineG1,
  b : AffineG2,
  c : AffineG1,
  deltaPrime : AffineG2) : AffineG1 {
  ...
}

function verifierCore (
  vk : VerificationKey,
  input : Fr,
  proof : ExtendedProof) : boolean {
  ...
};
```
where the types are defined as follows, with `Fq` representing an element
of [MNT4-753.$\mathbb{F}_q$](https://coinlist.co/build/coda/pages/MNT6753#cQ==).
Please see 

- [this page](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-05-verifier/spec.ts)
  for specifications of the behavior of `boweGabizonVerifier` and `verifierCore`.
- [this page](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-05-verifier/verifier.ts)
  for specifications of the behavior of `pedersenHash`, `groupMap`, and `hashToGroup`.

```typescript

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
```


## Starter code

- You can find a complete OCaml implementation (which compiles to JavaScript with js_of_ocaml) [here](https://github.com/CodaProtocol/snark-challenge/tree/master/reference-05-verifier).
- This TypeScript/JavaScript [spec](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-05-verifier/spec.ts) is a great place to get started.
- You can find TypeScript/JavaScript implementations of `pedersenHash`, `groupMap`, and `hashToGroup`.
  [here](https://github.com/CodaProtocol/snark-challenge/blob/master/reference-05-verifier/verifier.ts), with
  the implementation of finite-field arithmetic stubbed out.