# SNARK Prover

## Table of Contents
- [Motivation](#motivation)
- [Starter Code](#starter-code)
- [Tutorials](#tutorials)
	+ [Field Arithmetic](#field-arithmetic)
	+ [Quadratic Extension Arithmetic](#quadratic-extension-arithmetic): $150
	+ [Cubic Extension Arithmetic](#cubic-extension-arithmetic): $150
	+ [Curve Operations](#curve-operations): $200

## Motivation

### What is a SNARK prover?

At a high level, zk-SNARK systems look like this:

1. A setup ceremony is held to generate some parameters.
2. A *prover* performs a computation, yielding the result of that computation and a certificate (the **zk-SNARK**), that the computation was performed correctly.
3. A *verifier* can perform a quick computation that verifies the certificate is valid and the computation's results are accurate. This process doesn't expose the inputs of the computation to the verifier.

While the third step can be performed extremely quickly and efficiently, the second step remains relatively slow.

### Why is parallelization useful?

The majority of the computation time constructing a SNARK prover is spent on two steps: performing 7 [FFTs](https://en.wikipedia.org/wiki/Fast_Fourier_transform) and 4 [multiexponentiations](https://coinlist.co/build/coda/pages/problem-05-multi-exponentiation). 

It's not important to worry about the details of these computations for now, but it's important to know that they're both [perfectly parallelizeable](https://en.wikipedia.org/wiki/Embarrassingly_parallel), and therefore implementing them on GPUs (or other hardware that can exploit the parallelism) could yield a massive speedup.  

### Prize structure

We're offering $70k in cash to speed up the zk-SNARK prover. That's broken down as follows:

- $7k to the first team that gets a 2x speedup
- $8k to the first team that gets a 4x speedup
- $10k to the first team that gets an 8x speedup
- $15k to the first team that gets a 16x speedup
- $30k to the fastest prover at the end of the contest

And finally, we're giving $500 to the first ten teams that finish a tutorial that walks you through the main components of the SNARK prover.

## Starter Code

To start, we'll show you how to go through the submission workflow for the problem of speeding up the SNARK prover. At a high level, it consists of these steps:

0. (Optional) Set up GPU machine.

1. Fork the git repo with reference code.

2. Compile and test.

3. Submit.

### (Optional) Set up GPU machine

We expect many participants to use GPUs to try and speed up the SNARK prover, so we've set up a preconfigured AWS AMI that should help you get started!

1. Go to console.aws.amazon.com

2. Login or create account

3. Choose US West (Oregon) as your region

<img src="static/oregon.png">

4. Type EC2 in the "Find Services" searchbar

<img src="static/ec2.png">

5. Click launch instance

<img src="static/launch.png">

6. Type "snark" in the search bar for AMIs

<img src="static/snark.png">

7. In "Community AMIs," select the coda-snark-challenge-base-* image

<img src="static/ami.png">

8. You should choose a GPU instance -- we recommend choosing a p2.xlarge

<img src="static/p2x.png">

9. Click "review and launch"

You may encounter an error where you aren't allowed to launch an p2.xlarge instance. We've found that requests [here](http://aws.amazon.com/contact-us/ec2-request) are quickly granted.

10. Click launch

<img src="static/launchv2.png">

11. Go to EC2

12. Right click on instance and select "Connect"

<img src="static/connect.png">

13. Follow the instructions to get connected

### Fork the git repo with reference code.

Go [here](https://github.com/CodaProtocol/snark-challenge-prover-reference) to fork the reference repo. Once you've
forked it, run:

```bash
git clone https://github.com/YOUR_USER_NAME/snark-challenge-prover-reference.git
```
to clone it.

If you're using the AMI image as above, you'll need to switch to the `cuda-10.0` branch.

```bash
git checkout cuda-10.0
```

Now, install the dependencies as follows (it may be differ slightly for
other distros). Note, we've preinstalled the dependencies on the AMI:

- On Mac:

We aren't supporting OSX for this challenge. Consider grabbing a cloud GPU machine, instructions above.

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
$ ./generate_parameters fast; time ./main MNT4753 compute CPU MNT4753-parameters MNT4753-input outputs
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
$ ./build.sh && time ./main MNT4753 compute CPU MNT4753-parameters MNT4753-input outputs-new
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
- Click submit!

## Tutorials

In the tutorial challenges, you’ll implement the sub-algorithms you need to implement the full SNARK prover and you’ll get paid to do so. The first 10 participants who complete the four challenges in this stage will receive $500 and a SNARK Challenge swag-bag. You'll also be very well positioned to apply their solutions to create submissions for the $70,000 prizes for speeding up the prover.

The challenges in this stage are: 

1. [Field arithmetic](https://coinlist.co/build/coda/pages/problem-01-field-arithmetic): This challenge has ended, but please read the page for more info as the [solution](https://github.com/codaprotocol/cuda-fixnum) has been released and will be useful in the other challenges.
2. [Quadratic extension arithmetic](https://coinlist.co/build/coda/pages/problem-02-quadratic-extension-arithmetic): $150 in prizes for each of the first 10 participants
3. [Cubic extension arithmetic](https://coinlist.co/build/coda/pages/problem-03-cubic-extension-arithmetic): $150 in prizes for each of the first 10 participants
4. [Curve operations](https://coinlist.co/build/coda/pages/problem-04-curve-operations): $200 in prizes for each of the first 10 participants

### Further resources

We've also provided some additional resources that should be helpful. Remember, if you run into any roadblocks, please feel free to ask questions in our [Discord chat](https://discord.gg/DUhaJ42)!

- [**Prover spec page**](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges). Start here if you're familiar with elliptic curve cryptography. We've included CUDA code for finite-field arithmetic and many other optimization ideas for you to try out.
- [**Prover video**](https://youtu.be/81uR9W5PZ5M). This video discusses the construction of the prover in detail.
- A C++ reference we recommend is the [C++ Super-FAQ](https://isocpp.org/faq)
- For CUDA questions, we recommed consulting the [CUDA C Programming guide](https://docs.nvidia.com/cuda/pdf/CUDA_C_Programming_Guide.pdf) ([web version](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)). The [NVIDIA developer site](https://docs.nvidia.com/cuda/) is also an excellent resource, and there's a [free Udacity course](https://developer.nvidia.com/udacity-cs344-intro-parallel-programming) as well.