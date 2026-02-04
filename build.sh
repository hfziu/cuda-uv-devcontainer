#!/usr/bin/env bash
set -euo pipefail

# Set default value for UV_PYTHON if not provided
UV_PYTHON="${UV_PYTHON:-3.13}"

# Define image name and read CUDA versions from environment or use defaults
IMAGE_NAME="cuda-uv-devcontainer"
CUDA_VERSIONS_STR="${CUDA_VERSIONS:-13.1.1-cudnn-devel-ubuntu24.04 12.9.1-cudnn-devel-ubuntu24.04}"
IFS=' ' read -ra CUDA_VERSIONS <<< "$CUDA_VERSIONS_STR"

log_info() { echo "[INFO] $1"; }
log_success() { echo "[OK] $1"; }
log_error() { echo "[ERROR] $1"; }

# DEBUG: show CUDA versions source
if [ -z "${CUDA_VERSIONS_ENV+x}" ]; then
    log_info "Using default CUDA versions: ${CUDA_VERSIONS_STR}"
else
    log_info "Using environment CUDA_VERSIONS: ${CUDA_VERSIONS_STR}"
fi

# Build images for each CUDA version
for CUDA_VERSION in "${CUDA_VERSIONS[@]}"; do
    IMAGE_TAG="${IMAGE_NAME}:${CUDA_VERSION}"
    
    log_info "Building image: $IMAGE_TAG"
    docker build \
        --progress=plain \
        -t "$IMAGE_TAG" \
        --build-arg BASE_TAG="${CUDA_VERSION}" \
        --build-arg UV_PYTHON="${UV_PYTHON}" \
        -f Dockerfile \
        . || { log_error "Image build failed for $IMAGE_TAG"; exit 1; }
    log_success "Image built: $IMAGE_TAG"
done

# Display image sizes
log_info "Image sizes:"
docker images --filter "reference=${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

log_success "Build completed successfully!"