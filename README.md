# snark-challenge
Coda + Dekrypt: The SNARK Challenge - Reference Material

This repo contains CPU reference code and runner tools for the Coda + Dekrypt SNARK Challenge.

It compiles under Ubuntu 18.04 with some stock libraries added. The code is meant to be used as a reference point for doing accelerated implementations. Any accelerated implementations should generate identical output for given random inputs as the reference code.

To test compiling and running on your machine, you can use a prebuilt docker image:

```
docker run -it codaprotocol/snark-challenge:latest
```
