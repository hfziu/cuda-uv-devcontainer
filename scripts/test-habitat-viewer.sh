#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

IMAGE="${IMAGE:-cuda-uv-devcontainer:cuda-habitat}"
DATA_DIR="${DATA_DIR:-/tmp/habitat-data}"
SCENE="${SCENE:-${DATA_DIR}/scene_datasets/habitat-test-scenes/skokloster-castle.glb}"
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-720}"
DOCKER_GPU_ARGS="${DOCKER_GPU_ARGS:---gpus all}"
DOCKER_EXTRA_ARGS="${DOCKER_EXTRA_ARGS:-}"
XAUTHORITY_PATH="${XAUTHORITY:-$HOME/.Xauthority}"
DATASET_DOWNLOAD_MODE="${DATASET_DOWNLOAD_MODE:---no-replace}"

if [[ -z "${DISPLAY:-}" ]]; then
  log_error "DISPLAY is not set. Start an X11/Xwayland session or SSH with X11 forwarding."
  exit 1
fi

if [[ ! -f "${XAUTHORITY_PATH}" ]]; then
  log_error "XAUTHORITY file not found at ${XAUTHORITY_PATH}."
  exit 1
fi

docker_args=(--rm -it --network host)

if [[ -n "${DOCKER_GPU_ARGS}" ]]; then
  read -r -a gpu_args <<< "${DOCKER_GPU_ARGS}"
  docker_args+=("${gpu_args[@]}")
fi

if [[ -n "${DOCKER_EXTRA_ARGS}" ]]; then
  read -r -a extra_args <<< "${DOCKER_EXTRA_ARGS}"
  docker_args+=("${extra_args[@]}")
fi

docker_args+=(
  -e "DISPLAY=${DISPLAY}"
  -e "XAUTHORITY=${XAUTHORITY_PATH}"
  -v "${XAUTHORITY_PATH}:${XAUTHORITY_PATH}:ro"
  -v "${DATA_DIR}:${DATA_DIR}"
)

if [[ -d /tmp/.X11-unix ]]; then
  docker_args+=(-v /tmp/.X11-unix:/tmp/.X11-unix)
fi

viewer_args=("$@")
if [[ "${#viewer_args[@]}" -eq 0 ]]; then
  viewer_args=(
    --scene "${SCENE}"
    --width "${WIDTH}"
    --height "${HEIGHT}"
  )
fi

log_info "Launching Habitat viewer in ${IMAGE}"
log_info "DISPLAY=${DISPLAY}"
log_info "DATA_DIR=${DATA_DIR}"

docker run "${docker_args[@]}" "${IMAGE}" bash -lc "
  python -m habitat_sim.utils.datasets_download --uids habitat_test_scenes --data-path '${DATA_DIR}' ${DATASET_DOWNLOAD_MODE} &&
  python /opt/habitat-src/habitat-sim/examples/viewer.py $(printf '%q ' "${viewer_args[@]}")
"
