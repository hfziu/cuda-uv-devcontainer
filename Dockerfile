# syntax=docker/dockerfile:1
ARG BASE_IMAGE=nvidia/cuda
ARG BASE_TAG=13.1.1-cudnn-devel-ubuntu24.04
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

# Metadata
LABEL org.opencontainers.image.title="CUDA UV DevContainer"
LABEL org.opencontainers.image.description="Image based on nvidia/cuda, added uv and some essential dev tools"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies with BuildKit cache mount for faster builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    clang-format \
    clangd \
    cmake \
    curl \
    fish \
    gdb \
    git \
    ninja-build \
    pkg-config \
    sudo \
    tree \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy uv from official image (using specific version for reproducibility)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
RUN chmod +x /usr/local/bin/uv

# Set up uv environment variables
ENV UV_LINK_MODE=copy
ENV UV_TORCH_BACKEND=auto

# Python versions to preinstall with uv
ARG UV_PYTHONS="3.11 3.12 3.13"
ARG UV_DEFAULT_PYTHON=3.13

# Install multiple Python versions
RUN --mount=type=cache,target=/root/.cache/uv \
    uv python install ${UV_PYTHONS}

# Create symbolic links for each installed Python version and set defaults
RUN for version in ${UV_PYTHONS}; do \
      ln -sf "$(uv python find ${version})" "/usr/local/bin/python${version}"; \
    done && \
    ln -sf /usr/local/bin/python${UV_DEFAULT_PYTHON} /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python${UV_DEFAULT_PYTHON} /usr/local/bin/python && \
    python --version

# Set default shell to fish
ENV SHELL=/usr/bin/fish

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python --version || exit 1

# Default command
CMD ["/usr/bin/fish"]
