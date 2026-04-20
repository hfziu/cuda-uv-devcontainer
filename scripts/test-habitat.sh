#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${1:-/tmp/habitat-data}"

if [[ -n "${IMAGE:-}" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=utils.sh
  source "${SCRIPT_DIR}/utils.sh"

  log_info "Running Habitat smoke test in ${IMAGE}"
  docker run --rm -i "${IMAGE}" test-habitat "${DATA_DIR}"
  log_ok "Habitat smoke test passed in ${IMAGE}"
  exit 0
fi

export DISPLAY=
export MAGNUM_LOG="${MAGNUM_LOG:-quiet}"
export HABITAT_SIM_LOG="${HABITAT_SIM_LOG:-quiet}"
RUN_RENDER_SMOKE="${RUN_RENDER_SMOKE:-auto}"

python - <<'PY'
from habitat.version import VERSION as HABITAT_LAB_VERSION
import habitat.gym  # noqa: F401
from habitat_sim import (
    AgentConfiguration,
    Configuration,
    Simulator,
    SimulatorConfiguration,
    __version__ as HABITAT_SIM_VERSION,
)

print(f"Habitat-Lab {HABITAT_LAB_VERSION}")
print(f"Habitat-Sim {HABITAT_SIM_VERSION}")

backend_cfg = SimulatorConfiguration()
backend_cfg.scene_id = "NONE"
backend_cfg.enable_physics = False

agent_cfg = AgentConfiguration()
agent_cfg.sensor_specifications = []

sim = Simulator(Configuration(backend_cfg, [agent_cfg]))
print("Habitat-Sim minimal simulator startup OK")
sim.close()
PY

should_run_render_smoke=false
case "${RUN_RENDER_SMOKE}" in
  true)
    should_run_render_smoke=true
    ;;
  false)
    should_run_render_smoke=false
    ;;
  auto)
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
      should_run_render_smoke=true
    fi
    ;;
  *)
    echo "Unsupported RUN_RENDER_SMOKE='${RUN_RENDER_SMOKE}'. Use: auto, true, or false." >&2
    exit 1
    ;;
esac

if [[ "${should_run_render_smoke}" != "true" ]]; then
  echo "Skipping render smoke test because no GPU runtime was detected."
  exit 0
fi

python -m habitat_sim.utils.datasets_download \
  --uids habitat_test_scenes \
  --data-path "${DATA_DIR}"

python /opt/habitat-src/habitat-sim/examples/example.py \
  --scene "${DATA_DIR}/scene_datasets/habitat-test-scenes/skokloster-castle.glb" \
  --width 64 \
  --height 64 \
  --max_frames 5 \
  --silent \
  --enable_physics
