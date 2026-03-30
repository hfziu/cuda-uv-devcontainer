#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

IMAGE="${IMAGE:-cuda-uv-devcontainer:cuda-ros}"
DOCKER_GPU_ARGS="${DOCKER_GPU_ARGS:-}"

docker_args=(--rm -i)
if [[ -n "${DOCKER_GPU_ARGS}" ]]; then
  # Allow callers to pass optional runtime flags such as "--gpus all".
  read -r -a extra_args <<< "${DOCKER_GPU_ARGS}"
  docker_args+=("${extra_args[@]}")
fi

log_info "Running rclpy smoke test in ${IMAGE}"

docker run "${docker_args[@]}" "${IMAGE}" python3 - <<'PY'
import platform

import rclpy
from rclpy.node import Node
from std_msgs.msg import String

rclpy.init(args=None)
node = Node("rclpy_smoke_test")
received_messages = []


def on_message(msg: String) -> None:
    received_messages.append(msg.data)
    print(f"subscriber received: {msg.data}")


publisher = node.create_publisher(String, "smoke_test_topic", 10)
subscription = node.create_subscription(String, "smoke_test_topic", on_message, 10)

message = String()
message.data = "hello from cuda-ros rclpy smoke test"
publisher.publish(message)

deadline = node.get_clock().now().nanoseconds + 2_000_000_000
while not received_messages and node.get_clock().now().nanoseconds < deadline:
    rclpy.spin_once(node, timeout_sec=0.1)

print(f"python={platform.python_version()}")
print(f"rclpy={getattr(rclpy, '__version__', 'unknown')}")
print(f"rmw={rclpy.get_rmw_implementation_identifier()}")
print(f"node={node.get_name()}")
print(f"namespace={node.get_namespace()}")
print(f"logger={node.get_logger().name}")
print(f"clock_ns={node.get_clock().now().nanoseconds}")
print(f"publisher_topic={publisher.topic_name}")
print(f"subscription_topic={subscription.topic_name}")

if not received_messages:
    raise RuntimeError("timed out waiting for rclpy loopback message")

print(f"loopback_count={len(received_messages)}")
print("rclpy smoke test passed")

node.destroy_node()
rclpy.shutdown()
PY

log_ok "rclpy smoke test passed in ${IMAGE}"
