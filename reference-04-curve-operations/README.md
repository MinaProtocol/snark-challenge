### Curve Operations
This directory contains a reference CPU implementation of 
[Curve Operations](https://codaprotocol.github.io/snark-challenge/problem-04-Curve%20operations.html) 
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