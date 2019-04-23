#!/bin/bash
pushd libfqfft
mkdir build
cd build
cmake ..
make -j12 fft_benchmark fft_gen_input
popd

mv libfqfft/build/libfqfft/fft_benchmark main
mv libfqfft/build/libfqfft/fft_gen_input gen_input
