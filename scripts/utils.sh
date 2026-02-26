#!/usr/bin/env bash

log_info() { echo "[INFO] $1"; }
log_ok() { echo "[OK] $1"; }
log_error() { echo "[ERROR] $1"; }

require_repository_owner() {
  if [[ -z "${REPOSITORY_OWNER:-}" ]]; then
    log_error "REPOSITORY_OWNER (or GITHUB_REPOSITORY_OWNER) is required."
    exit 1
  fi
}

show_local_image_sizes() {
  local image_name="$1"
  log_info "Local image sizes:"
  docker images --filter "reference=${image_name}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
}
