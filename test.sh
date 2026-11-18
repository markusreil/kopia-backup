#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ROOT="$(pwd)"
SERVER_ROOT="$(realpath ../docker-backup)"

export SERVER_IMAGE="kopia-server-under-test:local"
export AGENT_IMAGE="kopia-agent-under-test:local"

./build.sh --server-image "${SERVER_IMAGE}" --agent-image "${AGENT_IMAGE}"
robot -d test/out \
  --variable "ROOT:${ROOT}" \
  --variable "SERVER_ROOT:${SERVER_ROOT}" \
  test/image.robot test/kopia.robot
