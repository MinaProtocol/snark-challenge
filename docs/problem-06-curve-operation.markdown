# Curve operation

<div class="table-of-contents">
<ul>
<li>
<a href="#quick-details">1: Quick details</a>
</li>
<li>
<a href="#problem-specification">2: Problem specification</a>
</li>
<li>
<a href="#parameters">2.1: Parameters</a>
</li>
<li>
<a href="#input">2.2: Input</a>
</li>
<li>
<a href="#output">2.3: Output</a>
</li>
<li>
<a href="#expected-behavior">2.4: Expected behavior</a>
</li>
<li>
<a href="#submission-guidelines">3: Submission guidelines</a>
</li>
<li>
<a href="#reference-implementation">4: Reference implementation</a>
</li>
</ul>
</div>

## Quick details

- **Problem:** Perform a fast-fourier transform on an array of elements of one of the scalar fields $\mathbb{F}_r$.
- **Prize:**
    - **First 25 submissions:** $0
    - **All submissions:** Swag bag including SNARK challenge T-shirt.

## Problem specification

The following problem is defined for any choice of (<a name="XChyXCk=">\(r\)</a>, <a name="XChzXCk=">\(s\)</a>, <a name="XChcb21lZ2FcKQ==">\(\omega\)</a>)
in

- `MNT4753`: (<a href="/snark-challenge/MNT4753.html#cg==">MNT4753.r</a>, <a href="/snark-challenge/MNT4753.html#cw==">MNT4753.s</a>, <a href="/snark-challenge/MNT4753.html#XChcb21lZ2FcKQ==">MNT4753.\(\omega\)</a>)
- `MNT6753`: (<a href="/snark-challenge/MNT6753.html#cg==">MNT6753.r</a>, <a href="/snark-challenge/MNT6753.html#cw==">MNT6753.s</a>, <a href="/snark-challenge/MNT6753.html#XChcb21lZ2FcKQ==">MNT6753.\(\omega\)</a>)

You can click on the above types to see how they will be
represented in the files given to your program. `uint64`
values are represented in little-endian byte order. Arrays
are represented as sequences of values, with no length
prefix and no separators between elements. Structs are also
represented this way.

### Parameters

The parameters will be generated once and your submission will be allowed to preprocess them in any way you like before being invoked on multiple inputs.

- n : <span>uint64</span>
    Guaranteed to be a power of 2.

### Input

- x : <span>Array(<span>&#x1D53D;<sub><a href="#XChyXCk=">\(r\)</a></sub></span>, <a href="#bg==">n</a>)</span>

### Output

- y : <span>Array(<span>&#x1D53D;<sub><a href="#XChyXCk=">\(r\)</a></sub></span>, <a href="#bg==">n</a>)</span>

### Expected behavior

The output should be
y[i] = \sum_{j=0}^{n-1} x[i] \omega^{ij (2^s / n)}

## Submission guidelines

Your submission will be run and evaluated as follows.


0. The submission-runner will randomly generate the parameters and save them to
    files `PATH_TO_MNT4753_PARAMETERS` and `PATH_TO_MNT6753_PARAMETERS`.
0. Your binary `main` will be run with 

    ```bash
        ./main MNT4753 preprocess PATH_TO_MNT4753_PARAMETERS
./main MNT6753 preprocess PATH_TO_MNT6753_PARAMETERS
    ```
    where `PATH_TO_X_PARAMETERS` will be replaced by the actual path.

    Your binary can at this point, if you like, do some preprocessing of the parameters and
    save any state it would like to files `./MNT4753_preprocessed` and `./MNT6753_preprocessed`.
0. The submission runner will generate a random sequence of inputs, saved to a file
   `PATH_TO_INPUTS`.

1. Your binary will be compiled with `./build.sh`. This step should produce a binary `./main`.

3. Your binary will be invoked with

    ```bash
        ./main MNT4753 compute PATH_TO_MNT4753_PARAMETERS PATH_TO_INPUTS PATH_TO_OUTPUTS
./main MNT6753 compute PATH_TO_MNT6753_PARAMETERS PATH_TO_INPUTS PATH_TO_OUTPUTS
    ```

    and its runtime will be recorded. The file `PATH_TO_INPUTS` will contain
    a sequence of inputs, each of which is of the form specified in the
    ["Input"](#input) section. 

    It should create a file called "outputs" at the path `PATH_TO_OUTPUTS`
    which contains a sequence of outputs, each of which is of the form
    specified in the ["Output"](#output) section.

    It can, if it likes, read the preprocessed files created in step 1
    in order to help it solve the problem.
    

## Reference implementation

The output of your submitted program will be checked against 
the reference implementation at this repo [here]().
The "main" file is [here]().
The core algorithm is implemented [here]().
