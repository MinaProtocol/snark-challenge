### Quadratic Extension
This directory contains a reference CPU implementation of 
[Quadratic Extension](https://codaprotocol.github.io/snark-challenge/problem-02-Quadratic%20extension%20arithmetic.html) 
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