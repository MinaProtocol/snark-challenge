### Background

This document is meant to capture general details on the testing platform used for snark-challenge performance measurements.

### Host Hardware
- **CPU:** Intel Core i9-9900K (3.6GHz 8C/16T)
- **Motherboard:** Asus ROG Strix Z390-E Gaming
- **RAM:** Corsair 2 x 16GB
- **Storage:** Samsung 1TB 860 EVO SATA III
- **GPU1:** EVGA RTX 2080 Ti XC Gaming 11GB GDDR6 (NVIDIA)
- **GPU2:** Sapphire Radeon Nitro+ RX Vega 64 8GB DDR5 (AMD R9 Fury X)  (Note: Radeon VII consider too new to use)
- **PSU:** Corsair RM1000X 1000W

### Host Software:
- **OS:** Ubuntu Server 18.04.02 LTS
- **NVIDIA Dev:** CudaDrivers 418.40.04-1 (10.1)
- **AMD Dev:** ROCm 2.0
- **Containers:** Docker CE 5:18.09.5~3-0~ubuntu-bionic + nvidia-docker2 container runtime

### Container Resources:
- [NVIDIA CUDA DEV 10.1-devel](https://hub.docker.com/r/nvidia/cuda)
- [AMD ROCm DEV (WIP)](https://hub.docker.com/r/rocm/dev-ubuntu-18.04)

### Other Resources:
- [General GPU Benchmark (compiles for cuda AND ocl)](https://github.com/ekondis/mixbench)


### Notes:



#### OS Install Notes

```
# Start with stock 18.04.2 LTS Server Edition

##################################################
# AMD Driver Install
tar -xvf amdgpu-pro-19.10-785425-ubuntu-18.04.tar.xz
cd amdgpu-pro-19.10-785425-ubuntu-18.04
./amdgpu-install --headless --opencl=pal
sudo reboot

# Pathing hack for mixbench
sudo ln -s /opt/amdgpu-pro/lib/x86_64-linux-gnu /opt/amdgpu-pro/lib/x86_64

##################################################
# NVIDIA Driver install
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt install nvidia-headless-418 nvidia-utils-418
sudo reboot

# CUDA
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.1.105-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1804_10.1.105-1_amd64.deb

sudo apt-get update
sudo apt-get install cuda-libraries-10-1 cuda-libraries-dev-10-1 cuda-compiler-10-1

# pathing hack for mixbench
sudo ln -s /usr/local/cuda-10.1 /usr/local/cuda


##################################################
# Docker CE
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Test
sudo docker run hello-world

##################################################
# NVIDIA Docker Runtime
# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update

# Install nvidia-docker2 and reload the Docker daemon configuration
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd

# Test
docker run --runtime=nvidia --rm nvidia/cuda:10.1-base nvidia-smi


```

#### Mixbench Makefile paths
```
CUDA_INSTALL_PATH = /usr/local/cuda
OCL_INSTALL_PATH = /opt/amdgpu-pro
```