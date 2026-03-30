# CUDA UV Devcontainer

Personalized development containers based on `nvidia/cuda` and ROS 2 Jazzy, designed for use as [devcontainers](https://containers.dev/) (e.g., with IDEs like [VS Code](https://code.visualstudio.com/docs/devcontainers/containers)). These images come with extensive development tools and libraries preinstalled and are not optimized for size. They may not be suitable for production use, especially on low-resource machines.

## Included Tools

In addition to the libraries and tools included in the base NVIDIA images, the following tools have been preinstalled based solely on personal preferences:

- Clang tooling: `clang`, `clangd`, `clang-format`, `clang-tidy`
- Debugger: `gdb`
- Shell and utilities: `tree`, `zsh`

- `uv`

May include in the future:

- [ ] `libgl1`

## Tags

- `cuda-uv-devcontainer:<base-tag>` - based on `nvidia/cuda`, where `<base-tag>` is a valid tag from [`nvidia/cuda`](https://hub.docker.com/r/nvidia/cuda)
  - currently only `13.2.0-cudnn-devel-ubuntu24.04` and `12.9.1-cudnn-devel-ubuntu24.04` are supported
- `cuda-uv-devcontainer:cuda-ros` - based on `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04` plus the official ROS 2 Jazzy `ros-base` package set for Ubuntu 24.04

## Local Build

```bash
docker build --progress=plain -f Dockerfile.cuda-ros -t cuda-uv-devcontainer:cuda-ros --build-arg BASE_TAG=12.9.1-cudnn-devel-ubuntu24.04 .
docker build --progress=plain -f Dockerfile.cuda -t cuda-uv-devcontainer:test-cuda .
```

```bash
docker run --rm cuda-uv-devcontainer:cuda-ros zsh -lc 'echo $0 && echo $ROS_DISTRO && ros2 --help >/dev/null && colcon --help >/dev/null && rosdep --help >/dev/null && uv --version && nvcc --version'
docker run --rm cuda-uv-devcontainer:test-cuda zsh -lc 'echo $0 && uv --version && nvcc --version'
docker run --rm cuda-uv-devcontainer:cuda-ros env | grep "^ROS_DISTRO=jazzy$"
bash scripts/test-cuda-ros-rclpy.sh
DOCKER_GPU_ARGS="--gpus all" bash scripts/test-cuda-ros-rclpy.sh
```
