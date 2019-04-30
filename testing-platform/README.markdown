### Background

This document is meant to capture general details on the testing platform used for snark-challenge performance measurements.

### Host Hardware
- **CPU:** Intel Core i9-9900K (3.6GHz 8C/16T)
- **Motherboard:** Asus ROG Strix Z390-E Gaming
- **RAM:** Corsair 2 x 16GB
- **Storage:** Samsung 1TB 860 EVO SATA III
- **GPU1:** EVGA RTX 2080 Ti XC Gaming 11GB GDDR6 (NVIDIA)
- **GPU2:** Sapphire Radeon Nitro+ RX Vega 64 8GB DDR5 (AMD R9 Fury X)
- **PSU:** Corsair RM1000X 1000W

### Host Software:
- **OS:** Ubuntu 18.04.02 LTS
- **NVIDIA Dev:** CudaDrivers 418.40.04-1 (10.1)
- **AMD Dev:** TBD
- **Containers:** Docker CE 5:18.09.5~3-0~ubuntu-bionic + nvidia-docker2 container runtime

### Container Resources:
- [NVIDIA CUDA DEV 10.1-devel](https://hub.docker.com/r/nvidia/cuda)
- [AMD ROCm DEV (WIP)](https://hub.docker.com/r/rocm/dev-ubuntu-18.04)
- [Vulkan (WIP)](https://hub.docker.com/r/pmathia0/gcc-cmake-vulkan)

### Other Resources:
- [General GPU Benchmark (compiles for cuda AND ocl)](https://github.com/ekondis/mixbench)


### Notes:

#### Confirming access to NVIDIA card via cuda-devel docker
``` bash
docker run -ti --rm \
    --runtime=nvidia \
    nvidia/cuda:10.1-devel \
    nvidia-smi

+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.56       Driver Version: 418.56       CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce RTX 208...  Off  | 00000000:01:00.0  On |                  N/A |
| 69%   75C    P2   250W / 260W |   3632MiB / 10989MiB |    100%      Default |
+-------------------------------+----------------------+----------------------+
```
