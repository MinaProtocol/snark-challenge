#!/bin/bash
mkdir build
pushd build
  cmake -DMULTICORE=ON ..
  make -j12 main generate_inputs
popd
mv build/libff/main .
mv build/libff/generate_inputs .
