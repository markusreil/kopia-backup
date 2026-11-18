#!/usr/bin/env bash
# Build and optionally push both images to Docker Hub.
# Usage: ./build.sh [--push] [--tag <tag>] [--server-image <name>] [--agent-image <name>]
# Default tag is the repo VERSION (independent of the kopia release).
# Image names default to the official Hub repos; tests override them so the
# suite never touches officials.
set -euo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source versions.env

TAG="$(cat VERSION)"
SERVER_IMAGE=""
AGENT_IMAGE=""
PUSH=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true; shift ;;
    --tag) TAG="$2"; shift 2 ;;
    --server-image) SERVER_IMAGE="$2"; shift 2 ;;
    --agent-image) AGENT_IMAGE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done
if [[ -z "${SERVER_IMAGE}" ]]; then SERVER_IMAGE="mreil/kopia-server:${TAG}"; fi
if [[ -z "${AGENT_IMAGE}" ]]; then AGENT_IMAGE="mreil/kopia-agent:${TAG}"; fi

BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
export BUILDKIT_PROGRESS=plain

docker build \
  --build-arg "KOPIA_VERSION=${KOPIA_VERSION}" \
  --build-arg "BUILD_DATE=${BUILD_DATE}" \
  -t "${SERVER_IMAGE}" \
  ./server

docker build \
  --build-arg "KOPIA_VERSION=${KOPIA_VERSION}" \
  --build-arg "DOCKER_GEN_VERSION=${DOCKER_GEN_VERSION}" \
  --build-arg "YQ_VERSION=${YQ_VERSION}" \
  --build-arg "SUPERCRONIC_VERSION=${SUPERCRONIC_VERSION}" \
  --build-arg "SUPERCRONIC_SHA1SUM=${SUPERCRONIC_SHA1SUM}" \
  --build-arg "BUILD_DATE=${BUILD_DATE}" \
  -t "${AGENT_IMAGE}" \
  ./agent

if [[ "${PUSH}" == true ]]; then
  docker push "${SERVER_IMAGE}"
  docker push "${AGENT_IMAGE}"
fi
