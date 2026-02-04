#!/usr/bin/env bash
set -euo pipefail

# Set default value for UV_PYTHON if not provided
UV_PYTHON="${UV_PYTHON:-3.13}"

# Define image name
IMAGE_TAG="cuda-uv-devcontainer:latest"

log_info() { echo "[INFO] $1"; }
log_success() { echo "[OK] $1"; }
log_error() { echo "[ERROR] $1"; }

# Build base image
log_info "Building base image: $IMAGE_TAG"
docker build \
    --progress=plain \
    -t "$IMAGE_TAG" \
    --build-arg UV_PYTHON="${UV_PYTHON}" \
    -f Dockerfile \
    . || { log_error "Base image build failed"; exit 1; }
log_success "Base image built: $IMAGE_TAG"

# Display image sizes
log_info "Image sizes:"
docker images --filter "reference=$IMAGE_TAG" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

log_success "Build completed successfully!"