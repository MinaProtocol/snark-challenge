### Groth16 prover
This directory contains a reference CPU implementation of  the
Groth16 prover
using [libsnark](README-libsnark.md).


#### Build
``` bash
./build.sh
```

#### Generate parameters
``` bash
./generate_parameters
```

#### Generate Inputs
``` bash
./generate_inputs
```

### Run
``` bash
./main compute parameters inputs outputs
```

### Check results
``` bash
sha256sum outputs
```
