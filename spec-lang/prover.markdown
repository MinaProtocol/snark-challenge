# SNARK Prover

## Table of Contents
- [Motivation](#motivation)
- [Community and help](#community-and-help)
- [Starter code](#starter-code)
- [Tutorials](#tutorials)
	+ [Field Arithmetic](https://coinlist.co/build/coda/pages/problem-01-field-arithmetinc)
	+ [Quadratic Extension Arithmetic](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic): $150
	+ [Cubic Extension Arithmetic](https://coinlist.co/build/coda/pages/problem-03-cubic-extension-arithmetic): $150
	+ [Curve Operations](https://coinlist.co/build/coda/pages/problem-04-curve-operations): $200
- [Architecture reference](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges)

## Introduction

On this page, you’ll learn how to get started on the SNARK prover contest. Here’s what you can expect: 

1. [Motivation](#motivation). We’ll give you some motivation and background (e.g. what a SNARK?). 
2. [Starter code](#starter-code). Then, we’ll show you how to set up an environment to complete the challenge and walk you through the submission workflow.
3. [Tutorials](#tutorials). Finally, we’ll guide you through several targeted tutorials that will walk you through the steps for your first improvement.

## Motivation

In this challenge you’ll parallelizing the snark prover for GPU, vastly speeding up the time to create a snark proof.

We're offering $70k in cash to speed up the zk-SNARK prover. That's broken down as follows:

- $7k to the first team that gets a 2x speedup
- $8k to the first team that gets a 4x speedup
- $10k to the first team that gets an 8x speedup
- $15k to the first team that gets a 16x speedup
- $30k to the fastest prover at the end of the contest

And finally, we're giving $500 to the first ten teams that finish a tutorial that prepares you to make a GPU-enhanced submission.

### What is a SNARK prover?

At a high level, zk-SNARK systems look like this:

1. A *prover* performs a computation, yielding the result of that computation and a certificate (the **zk-SNARK**), that the computation was performed correctly.
2. A *verifier* can perform a quick computation that verifies the certificate is valid and the computation's results are accurate. This process doesn't expose the inputs of the computation to the verifier.

While the verifier can be performed extremely quickly and efficiently, modern provers can still be dramatically improved.

### Why is parallelization useful?

The majority of the computation time constructing a SNARK prover is spent on two steps: performing 7 [FFTs](https://en.wikipedia.org/wiki/Fast_Fourier_transform) and 4 [multiexponentiations](https://coinlist.co/build/coda/pages/problem-05-multi-exponentiation). 

It's not important to worry about the details of these computations for now, but it's important to know that they're both [perfectly parallelizeable](https://en.wikipedia.org/wiki/Embarrassingly_parallel), and therefore implementing them on GPUs (or other hardware that can exploit the parallelism) could yield a massive speedup.  

## Community and help

We're here to help. If you run into issues, have clarifying questions on the documentations, get stuck, or want to discuss ideas, ask on our [**Discord chat**](https://discord.gg/DUhaJ42) or send an email to brad@o1labs.org.

## Starter Code

To start, we'll show you how to go through the submission workflow for the problem of speeding up the SNARK prover. At a high level, it consists of these steps:

1. (Optional) Set up GPU machine.

2. Fork the git repo with reference code.

3. Compile and test.

4. Submit.

### (Optional) Set up GPU machine

We expect many participants to use GPUs to try and speed up the SNARK prover, so we've set up a preconfigured AWS AMI that should help you get started.

Full instructions are [here](https://coinlist.co/build/coda/pages/cloud-setup).

### Fork the git repo with reference code.

Go [here](https://github.com/CodaProtocol/snark-challenge-prover-reference) to fork the reference repo. Once you've
forked it, run:

```bash
git clone https://github.com/YOUR_USER_NAME/snark-challenge-prover-reference.git
```
to clone it.

If you're on the AMI, then you're already done, as we've preinstalled the dependencies.

If not, install the dependencies as follows (it may differ slightly for other distros).

- On Mac:

We aren't supporting OSX for this challenge. Consider grabbing a cloud GPU machine, we've provided instructions above.

* On Ubuntu 18.04 LTS:

```bash
$ sudo apt-get install build-essential cmake git libgmp3-dev libprocps-dev python-markdown libboost-all-dev libssl-dev
```

* On Ubuntu 16.04 LTS:

```bash
$ sudo apt-get install build-essential cmake git libgmp3-dev libprocps4-dev python-markdown libboost-all-dev libssl-dev
```

* On Ubuntu 14.04 LTS:

```bash
$ sudo apt-get install build-essential cmake git libgmp3-dev libprocps3-dev python-markdown libboost-all-dev libssl-dev
```

* On Fedora 21 through 23:

```bash
$ sudo yum install gcc-c++ cmake make git gmp-devel procps-ng-devel python2-markdown
```

* On Fedora 20:

```bash
$ sudo yum install gcc-c++ cmake make git gmp-devel procps-ng-devel python-markdown
```

### Compile and test

Once that's done, build with

```bash
$ ./build.sh
```

This will create three binaries. We won't go through them in detail right now but the [problem page](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges) has more info.

To test the prover, run the following command:

```bash
$ ./generate_parameters fast; time ./main MNT4753 compute MNT4753-parameters MNT4753-input outputs
```

This will save your program's output to the file `outputs`.

Now let's make a change to the implementation and re-compile.
In `libsnark/main.cpp`, find the line 

```c++
const multi_exp_method method = multi_exp_method_BDLO12;
```

It should be line 24. Comment it out and uncomment the next line

```c++
const multi_exp_method method = multi_exp_method_bos_coster;
```

Recompile and run with

```bash
$ ./build.sh && time ./main MNT4753 compute MNT4753-parameters MNT4753-input outputs-new
```

The program should now be significantly faster!
Check that the new outputs and the old outputs agree by checking
`shasum outputs outputs-new`.

Note that there is no need to rerun  `./generate_parameters` every time you make a change.

Commit and push your change.
```bash
$ git commit -am 'try to speed things up' && git push
```

### Submit

Go to [this page](https://coinlist.co/build/coda/projects/new) to create a submission.

- Pick a team name and a description like "quick start".
- Paste in your github repo URL from step 1.
- Select NVIDIA for the architecture (it's not actually important in this case since the reference code doesn't use the GPU).
- Select `nvidia/cuda:10.1-devel` for the docker image.
- Select "Groth16 optimzation" for the problem.
- Click submit.

## Tutorials

To help you get ready for your first GPU-based submission, we've created a series of tutorials that walk you through to your first big improvement.

The first 10 participants who complete the four challenges in this stage will receive $500 and a SNARK Challenge swag-bag. You'll also be very well positioned to apply their solutions to create submissions for the $70,000 prizes for speeding up the prover.

We've released [starter code](https://github.com/CodaProtocol/cuda-fixnum) that performs arithmetic on large numbers (see [field arithmetic](https://coinlist.co/build/coda/pages/problem-01-field-arithmetic)) to get you started. Next, we suggest do you the following to build up to implementing multi-exponentiation on the GPU.

1. **[Quadratic Extension Arithmetic](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic) tutorial: $150**. Working from the starter code should make this relatively straightforward. 
2. **[Cubic Extension Arithmetic tutorial](https://coinlist.co/build/coda/pages/problem-03-cubic-extension-arithmetic): $200**. This builds on the quadratic extension arithmetic module.
3. **[Curve Operations tutorial](https://coinlist.co/build/coda/pages/problem-04-curve-operations): $200**. This builds upon both of the above tutorials

Once you've finished curve operations, here’s what we recommend working on next to implement multi-exponentiation.

- Try improving the multi-exponentiations with on-GPU versions using the curve operations from the tutorial. Each multi-exponentiation can be seen as a [map-reduce](https://youtu.be/81uR9W5PZ5M?t=772), as explained here. Start by implementing the "map" part on GPU, leaving the "reduce" part on CPU.
- Do the multi-exponentiations entirely on-GPU using an on-GPU [reduce](https://github.com/NVIDIA/cuda-samples/tree/master/Samples/reduction).
- Use an on-GPU FFT (see for example [cuFFT](https://developer.nvidia.com/cufft)), adapted to finite fields. You can find a C++ implementation of a finite-field FFT [here](https://github.com/CodaProtocol/snark-challenge-prover-reference/blob/master/depends/libfqfft/libfqfft/evaluation_domain/domains/basic_radix2_domain_aux.tcc#L46).

For more information on the prover architecture, we suggest looking at the following

- [**Prover video**](https://youtu.be/81uR9W5PZ5M). This video discusses the construction of the prover in detail (recommended).
- [**Prover spec page**](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges). This walks you through the architecture of the prover.

### Further resources

We've also provided some additional resources that should be helpful. Remember, if you run into any roadblocks, please feel free to ask questions in our [Discord chat](https://discord.gg/DUhaJ42).

- A C++ reference we recommend is the [C++ Super-FAQ](https://isocpp.org/faq)
- For CUDA questions, we recommend consulting the [CUDA C Programming guide](https://docs.nvidia.com/cuda/pdf/CUDA_C_Programming_Guide.pdf) ([web version](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)). The [NVIDIA developer site](https://docs.nvidia.com/cuda/) is also an excellent resource, and there's a [free Udacity course](https://developer.nvidia.com/udacity-cs344-intro-parallel-programming) as well.