#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

IMAGE_NAME="${IMAGE_NAME:-cuda-uv-devcontainer}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.cuda-ros}"
CUDA_ROS_BASE_TAG="${CUDA_ROS_BASE_TAG:-12.9.1-cudnn-devel-ubuntu24.04}"
CUDA_ROS_TAG="${CUDA_ROS_TAG:-cuda-ros}"
UV_PYTHONS="${UV_PYTHONS:-3.10 3.11 3.12 3.13}"
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY_OWNER="${REPOSITORY_OWNER:-${GITHUB_REPOSITORY_OWNER:-}}"
ACTION="${ACTION:-build-and-push}"

local_image="${IMAGE_NAME}:${CUDA_ROS_TAG}"

build_image() {
  log_info "Building ${local_image}"
  docker build \
    --progress=plain \
    --build-arg BASE_TAG="${CUDA_ROS_BASE_TAG}" \
    --build-arg UV_PYTHONS="${UV_PYTHONS}" \
    -t "${local_image}" \
    -f "${DOCKERFILE}" \
    .
  log_ok "Built ${local_image}"
}

push_image() {
  require_repository_owner
  remote_image="${REGISTRY}/${REPOSITORY_OWNER}/${IMAGE_NAME}:${CUDA_ROS_TAG}"
  docker tag "${local_image}" "${remote_image}"
  docker push "${remote_image}"
  log_ok "Pushed ${remote_image}"
}

case "${ACTION}" in
  build)
    build_image
    ;;
  push)
    push_image
    ;;
  build-and-push)
    build_image
    push_image
    ;;
  *)
    log_error "Unsupported ACTION='${ACTION}'. Use: build, push, or build-and-push."
    exit 1
    ;;
esac

show_local_image_sizes "${IMAGE_NAME}"
