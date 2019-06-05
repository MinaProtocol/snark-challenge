#!/bin/bash
dune build crypto_lib/crypto_lib.bc.js && tsc verifier.ts
cp _build/default/crypto_lib/crypto_lib.bc.js dist/crypto_lib.js
mv verifier.js dist/
