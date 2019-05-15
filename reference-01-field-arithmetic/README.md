### Field Arithmetic

This directory contains a reference CPU implementation of 
[Field Arithmetic](https://codaprotocol.github.io/snark-challenge/problem-01-Field%20arithmetic.html) 
using [libff](README-libff.md).


#### Build
``` bash
./build.sh
```

#### Generate Inputs
``` bash
./generate_inputs
```

### Run
``` bash
./main compute inputs outputs
```

### Check results
``` bash
sha256sum outputs
```