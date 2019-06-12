# Start here 

Welcome to the SNARK Challenge! By participating, you're joining researchers, engineers, students, and hackers from around the world to try and improve the world's cryptography commons. Along the way, you'll learn about zk-SNARKs, a cutting-edge cryptographic primitive that's being used widely in blockchain and cryptocurrency applications. You'll also implement numerical algorithms on high performance computing platforms.

This page is meant to be your jumping-off point to start the challenge. It's split into three sections:

- [Introduction](#introduction). We describe the challenge at a high level and explain how you can win part of the $100k prize pool.
- [Quick start](#quick-start). This tutorial gets you up and running by showing how to start a project and make a submission.  
- [Further resources and challenges](#further-resources-and-challenges). We've compiled a wealth of resources that might be helpful in improving your submission.

## Introduction

We're offering $105k in cash to improve zk-SNARK cryptography. The main prize is *speeding up the zk-SNARK prover*, for which we're offering a total of $70k. That's broken down as follows:

- $7k to the first team that gets a 2x speedup
- $8k to the first team that gets a 4x speedup
- $10k to the first team that gets an 8x speedup
- $15k to the first team that gets a 16x speedup
- $30k to the fastest prover at the end of the contest

We're also offering prizes for the best SNARK verifier written in JavasCript ($10k) and the best elliptic curve improvements ($20k).

And finally, we're giving $500 to the first ten teams that finish a tutorial that walks you through the main components of the SNARK prover.

## Quick start

To start, we'll show you how to go through the submission workflow for the problem of speeding
up the SNARK prover.
At a high level, it consists of these steps:

0. (Optional) Set up GPU machine.
1. Fork the git repo with reference code.
2. Compile and test.
3. Submit.

### (Optional) Set up GPU machine

We expect many participants to use GPUs to try and speed up the SNARK prover, so we've set up a preconfigured AWS AMI that should help you get started!

1. Go to console.aws.amazon.com
2. Login or create account
3. Choose US West (Oregon) as your region
<img src="oregon.png">
4. Type EC2 in the "Find Services" searchbar
<img src="ec2.png">
5. Click launch instance
<img src="launch.png">
6. Type "snark" in the search bar for AMIs
<img src="snark.png">
7. In "Community AMIs," select the coda-snark-challenge-base-* image
<img src="ami.png">
8. You should choose a GPU instance -- we recommend choosing a p2.xlarge
<img src="p2x.png">
9. Click "review and launch"
10. Click launch
<img src="launchv2.png">
11. Go to EC2
12. Right click on instance and select "Connect"
<img src="connect.png">
13. Follow the instructions to get connected

### Fork the git repo with reference code.

Go [here](https://github.com/CodaProtocol/snark-challenge-prover-reference) to fork the reference repo. Once you've
forked it, run
```bash
git clone https://github.com/YOUR_USER_NAME/snark-challenge-prover-reference.git
```
to clone it.

Now, install the dependencies as follows (it may be differ slightly for
other distros):

- On Mac:

        $  ./macos-setup.sh

Beware, however, we haven't tested OSX well. Consider grabbing a cloud GPU machine, instructions [above](#cloud-setup).

* On Ubuntu 16.04 LTS:

        $ sudo apt-get install build-essential cmake git libgmp3-dev libprocps4-dev python-markdown libboost-all-dev libssl-dev

* On Ubuntu 14.04 LTS:

        $ sudo apt-get install build-essential cmake git libgmp3-dev libprocps3-dev python-markdown libboost-all-dev libssl-dev

* On Fedora 21 through 23:

        $ sudo yum install gcc-c++ cmake make git gmp-devel procps-ng-devel python2-markdown

* On Fedora 20:

        $ sudo yum install gcc-c++ cmake make git gmp-devel procps-ng-devel python-markdown

## Compile and test

Once that's done, build with
```bash
./build.sh
```

This will create three binaries. We won't go through them in detail right now but the [problem page](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges) has more info.

To test the prover, run the following command:
```bash
./generate_parameters fast
time ./main MNT4753 compute MNT4753-parameters MNT4753-input MNT4753-output
```
This will save your program's output to the file `./outputs`.

Now let's make a change to the implementation and re-compile.
In `libsnark/main.cu`, find the line 
```c++
const multi_exp_method method = multi_exp_method_BDLO12;
```
It should be line 24. Comment it out and uncomment the next line
```c++
const multi_exp_method method = multi_exp_method_bos_coster;
```

Recompile and run with
```bash
./build.sh && time ./main MNT4753 compute MNT4753-parameters MNT4753-input MNT4753-output
```

The program should now be significantly faster!
Check that the new outputs and the old outputs agree by checking
`shasum outputs outputs-new`.

Note that there is no need to rerun  `./generate_parameters` every time you make a change.

Commit and push your change.
```bash
git commit -am 'try to speed things up' && git push
```

## Submit

Go to [this page](https://coinlist.co/build/coda/projects/new) to create a submission.

- Pick a team name and a description like "quick start".
- Paste in your github repo URL from step 1.
- Select NVIDIA for the architecture (it's not actually important in this case since the reference code doesn't use the GPU).
- Select `nvidia/cuda:10.1-devel` for the docker image.
- Select "Groth16 optimzation" for the problem.
- Click submit!

## Further resources and challenges

Now that you've gotten your feet wet, you're probably ready to
start figuring out how to speed up the SNARK prover. Depending on 
your background and experience, we've provided a few different 
resources that can help get you started.

### Further resources

- [**Prover tutorial**](https://coinlist.co/build/coda/pages/tutorial). For those who haven't implemented elliptic curve cryptography before we recommend you start with [this tutorial](https://coinlist.co/build/coda/pages/tutorial). As a bonus, if you're one of the first 10 to finish the tutorial, you'll earn a $500 prize!
- [**Prover spec page**](https://coinlist.co/build/coda/pages/problem-07-groth16-prover-challenges). Start here if you're familiar with elliptic curve cryptography. We've included CUDA code for finite-field arithmetic and many other optimization ideas for you to try out.

### Other challenges

In addition to this challenge, we're running two others, which you may be interested in doing depending on your background:

- [**Verifier**](https://coinlist.co/build/coda/pages/verifier). This is a good challenge for those with JavaScript or WebAssembly expertise, with $10,000 in prizes for the fastest implementation.
- [**Curve search**](https://coinlist.co/build/coda/pages/theory). This challenge is aimed at improving the underlying elliptic curves, with $20,000 in prizes for the best curves.

