#!/bin/bash
mkdir build
pushd build
  cmake ..
  make -j12 main generate_inputs
popd
mv build/libff/main .
mv build/libff/generate_inputs .
