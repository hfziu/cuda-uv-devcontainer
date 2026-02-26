# CUDA UV Devcontainer

Personalized development containers based on `nvidia/cuda` and `nvcr.io/nvidia/pytorch`, designed for use as [devcontainers](https://containers.dev/) (e.g., with IDEs like [VS Code](https://code.visualstudio.com/docs/devcontainers/containers)). These images come with extensive development tools and libraries preinstalled and are not optimized for size. They may not be suitable for production use, especially on low-resource machines.

## Included Tools

In addition to the libraries and tools included in the base NVIDIA images, the following tools have been preinstalled based solely on personal preferences:

- Clang tooling: `clang`, `clangd`, `clang-format`, `clang-tidy`
- Debugger: `gdb`
- Shell and utilities: `fish`, `tree`

- `uv` (`uv` is already available in the `nvcr.io/nvidia/pytorch` base image)

## Tags

- `cuda-uv-devcontainer:<base-tag>` - based on `nvidia/cuda`, where `<base-tag>` is a valid tag from [`nvidia/cuda`](https://hub.docker.com/r/nvidia/cuda)
  - currently only `13.1.1-cudnn-devel-ubuntu24.04` and `12.9.1-cudnn-devel-ubuntu24.04` are supported
- `cuda-uv-devcontainer:nv-pytorch-<base-tag>` - based on `nvcr.io/nvidia/pytorch`, where `<base-tag>` is a valid tag from [`nvcr.io/nvidia/pytorch`](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch)
  - currently only `26.01-py3` is supported (the default system-wide Python version is 3.12. I also installed Python 3.11 - 3.13 with `uv` so you can create virtual environments with those versions if needed)
