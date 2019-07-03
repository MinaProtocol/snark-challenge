# Welcome to the SNARK Challenge! 

## Table of Contents

- [Introduction](#introduction)
	+ [Motivation](#motivation)
	+ [Community and help](#community-and-help)
	+ [Who should participate](#who-should-participate)
- [SNARK Prover](https://coinlist.co/build/coda/pages/prover)
	+ [Motivation](https://coinlist.co/build/coda/pages/prover#motivation)
	+ [Starter Code](https://coinlist.co/build/coda/pages/prover#starter-code)
	+ [Tutorials](https://coinlist.co/build/coda/pages/prover#tutorials)
- [SNARK Verifier](https://coinlist.co/build/coda/pages/verifier)
- [Elliptic Curve Search](https://coinlist.co/build/coda/pages/theory)

## Motivation

Welcome to the SNARK Challenge! By participating, you’ll be improving an exciting new cryptography primitive while earning up to $100k in prizes along the way.

First, some background on zk-SNARKs. zk-SNARKs allow a *verifier* to trustlessly delegate computation to a *prover*. Here’s how it works: First, the prover can take any program, run it on their computer, and create a certificate verifying that the program was run correctly and the results are valid. Amazingly, the prover does not have to reveal all of the inputs (privacy) and the certificate is always really tiny---just a few kilobytes (succinctness---independent of program size!). The certificate can be read and checked by anyone in milliseconds, meaning that one party can do a huge, privacy-protecting computation and anyone from the public can quickly validate the results.

This has awesome implications for verifiable computing, cryptocurrency, and privacy. But, while the cryptography is proven out, the implementations still have room for significant efficiency improvements.

That’s why we’re running the SNARK challenge. By participating, you’ll have the chance to develop a blazing fast prover, write a Javascript verifier, and improve the core cryptographic primitives, while learning about zk-SNARKs and and how they work along the way.

If you prefer a video intro, check out the video below:

<iframe width="560" height="315" src="https://www.youtube.com/embed/81uR9W5PZ5M" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Community and help

We're here to help. If you run into issues, have clarifying questions on the documentations, get stuck, or want to discuss ideas, ask on our [**Discord chat**](https://discord.gg/DUhaJ42) or send an email to brad@o1labs.org.

## [SNARK Prover](https://coinlist.co/build/coda/pages/prover)

- $70,000 + [Satoshi's Treasure Keys](https://satoshistreasure.xyz/16)
- $500 for completing tutorial

In [this challenge](https://coinlist.co/build/coda/pages/prover) we’re offering $70,000 + 3 [Satoshi's Treasure Keys](https://satoshistreasure.xyz/16) in prizes for participants who parallelize the snark prover. The SNARK proving algorithm is heavily susceptible to parallelization, but until now, no one has built a GPU implementation.

**If you have a background in GPUs** or want to learn more about them, this challenge is the one to tackle. Background in cryptography not required, you’ll learn all you need to along the way.


## [SNARK Verifier](https://coinlist.co/build/coda/pages/verifier)

- $10,000

[This challenge](https://coinlist.co/build/coda/pages/verifier) offers $10,000 for the fastest JavaScript SNARK verifier. SNARKs have the potential to offer privacy and trust preserving technologies to the world - implementing an in-browser implementation will help make these possibilities available to a wide audience.

**If you know JavaScript** you’re well equipped to go after this challenge.

## [Elliptic Curve Search](https://coinlist.co/build/coda/pages/theory)

- $20,000

The elliptic curves underlying SNARK constructions may be improved, which could dramatically improve the efficiency and capabilities of the prover. In this challenge we invite participants to find a set of curves which will be fast for both recursive and non-recursive problems. That way, everyone can standardize around the same curves making tooling and problems more universally collaborative.

**Folks with a background in cryptography** should be ready to go after [this challenge](https://coinlist.co/build/coda/pages/theory). See the documentation for the curves we suggest searching for and how best to search for them.
