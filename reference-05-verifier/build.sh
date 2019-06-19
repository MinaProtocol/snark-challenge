#!/bin/bash

set -x

# Use js_of_ocaml to generate crypto_lib javascript
dune build crypto_lib/crypto_lib.bc.js

# Use typescript compiler to generate javascript
tsc verifier.ts

# put tools in dist dir
cp _build/default/crypto_lib/crypto_lib.bc.js dist/crypto_lib.js
mv verifier.js dist/
