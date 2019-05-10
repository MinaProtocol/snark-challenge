### Prerequisite Tools/Libraries: (ubuntu method)
```
sudo apt-get install cmake \
                     pkg-config \
                     libboost-dev \
                     libboost-program-options-dev \
		     libomp-dev \
                     libprocps-dev \
                     libssl-dev \
                     libgmp-dev
```

### Binaries:

`./build.sh` will compile and build two executables `gen_input` and `main`:

- `gen_input` generates a random input file (~100MB) called `input` in the working directory.

- `main` reads from the `input` file in the working directory and write its
  result to a file called `output` in the working directory.

### Data Format:
All integers in all files are little endian.

The input and output format is as follows:
- The first 8 bytes are an unsigned integer `n`.

- The rest of the file consists of `n` field elements. Each field element is
  represented as 96 bytes `b_0, .., b_95` and corresponds to the field element
  $256^0 b_0 + 256^1 b_1 + ... + 256^95 b_95$.
