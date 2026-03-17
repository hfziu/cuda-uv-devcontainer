#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

IMAGE_NAME="${IMAGE_NAME:-cuda-uv-devcontainer}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.cuda}"
CUDA_VERSIONS_STR="${CUDA_VERSIONS:-13.2.0-cudnn-devel-ubuntu24.04 12.9.1-cudnn-devel-ubuntu24.04}"
UV_PYTHONS="${UV_PYTHONS:-3.10 3.11 3.12 3.13}"
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY_OWNER="${REPOSITORY_OWNER:-${GITHUB_REPOSITORY_OWNER:-}}"
ACTION="${ACTION:-build-and-push}"
PUSH_LATEST="${PUSH_LATEST:-true}"
CUDA_LATEST_TAG="${CUDA_LATEST_TAG:-}"

IFS=' ' read -r -a CUDA_VERSIONS <<< "${CUDA_VERSIONS_STR}"

if [[ "${#CUDA_VERSIONS[@]}" -eq 0 ]]; then
  log_error "No CUDA versions configured."
  exit 1
fi

build_images() {
  for cuda_tag in "${CUDA_VERSIONS[@]}"; do
    image_tag="${IMAGE_NAME}:${cuda_tag}"
    log_info "Building ${image_tag}"
    docker build \
      --progress=plain \
      -t "${image_tag}" \
      --build-arg BASE_TAG="${cuda_tag}" \
      --build-arg UV_PYTHONS="${UV_PYTHONS}" \
      -f "${DOCKERFILE}" \
      .
    log_ok "Built ${image_tag}"
  done
}

push_images() {
  require_repository_owner

  for cuda_tag in "${CUDA_VERSIONS[@]}"; do
    image_tag="${IMAGE_NAME}:${cuda_tag}"
    remote_tag="${REGISTRY}/${REPOSITORY_OWNER}/${IMAGE_NAME}:${cuda_tag}"
    docker tag "${image_tag}" "${remote_tag}"
    docker push "${remote_tag}"
    log_ok "Pushed ${remote_tag}"
  done

  if [[ "${PUSH_LATEST}" == "true" ]]; then
    latest_source_tag="${CUDA_LATEST_TAG:-${CUDA_VERSIONS[0]}}"
    source_image="${IMAGE_NAME}:${latest_source_tag}"
    latest_image="${REGISTRY}/${REPOSITORY_OWNER}/${IMAGE_NAME}:latest"
    docker tag "${source_image}" "${latest_image}"
    docker push "${latest_image}"
    log_ok "Pushed ${latest_image} from ${source_image}"
  fi
}

case "${ACTION}" in
  build)
    build_images
    ;;
  push)
    push_images
    ;;
  build-and-push)
    build_images
    push_images
    ;;
  *)
    log_error "Unsupported ACTION='${ACTION}'. Use: build, push, or build-and-push."
    exit 1
    ;;
esac

show_local_image_sizes "${IMAGE_NAME}"
