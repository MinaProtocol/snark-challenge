#!/bin/bash
mkdir build
pushd build
  cmake -DMULTICORE=ON ..
  make -j12 main generate_inputs generate_parameters
popd
mv build/libsnark/main .
mv build/libsnark/generate_inputs .
mv build/libsnark/generate_parameters .
