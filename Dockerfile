FROM ubuntu:18.04

RUN apt-get update && apt install -y \
    build-essential \
    cmake \
    libboost-all-dev \
    libgmp3-dev \
    libomp-dev \
    libprocps-dev \
    libssl-dev \
    pkg-config \
    linux-tools-generic \
    linux-tools-4.15.0-48-generic

RUN mkdir /app
ADD . /app

WORKDIR /app/test-runner

ENTRYPOINT /app/test-runner/run_reference.sh