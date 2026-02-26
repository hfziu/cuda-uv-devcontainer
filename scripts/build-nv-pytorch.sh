#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

IMAGE_NAME="${IMAGE_NAME:-cuda-uv-devcontainer}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.nv-pytorch}"
NV_PYTORCH_IMAGE="${NV_PYTORCH_IMAGE:-nvcr.io/nvidia/pytorch}"
NV_PYTORCH_BASE_TAG="${NV_PYTORCH_BASE_TAG:-26.01-py3}"
NV_PYTORCH_TAG_PREFIX="${NV_PYTORCH_TAG_PREFIX:-nv-pytorch}"
NV_PYTORCH_TAG="${NV_PYTORCH_TAG:-${NV_PYTORCH_TAG_PREFIX}-${NV_PYTORCH_BASE_TAG}}"
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY_OWNER="${REPOSITORY_OWNER:-${GITHUB_REPOSITORY_OWNER:-}}"
ACTION="${ACTION:-build-and-push}"

local_image="${IMAGE_NAME}:${NV_PYTORCH_TAG}"

build_image() {
  log_info "Building ${local_image}"
  docker build \
    --progress=plain \
    --build-arg NV_PYTORCH_IMAGE="${NV_PYTORCH_IMAGE}" \
    --build-arg NV_PYTORCH_BASE_TAG="${NV_PYTORCH_BASE_TAG}" \
    -t "${local_image}" \
    -f "${DOCKERFILE}" \
    .
  log_ok "Built ${local_image}"
}

push_image() {
  require_repository_owner
  remote_image="${REGISTRY}/${REPOSITORY_OWNER}/${IMAGE_NAME}:${NV_PYTORCH_TAG}"
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
