#!/bin/bash
dune build crypto_lib.bc.js && tsc verifier.ts
cp _build/default/crypto_lib.bc.js crypto_lib.js
