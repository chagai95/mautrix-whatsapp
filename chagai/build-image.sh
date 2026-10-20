#!/bin/sh
# Build dock.mau.dev/mautrix/whatsapp:<upstream tag>-chagai from chagai/main.
# Local image only — nothing is pushed and the running bridge is not touched.
set -eu
cd "$(dirname "$0")/.."
BASE_TAG="$(git describe --tags --abbrev=0)"          # e.g. v0.2605.0
IMAGE="dock.mau.dev/mautrix/whatsapp:${BASE_TAG}-chagai"
sudo docker build -f chagai/Dockerfile \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  --label "org.opencontainers.image.source=https://github.com/chagai95/mautrix-whatsapp" \
  -t "$IMAGE" .
echo "built $IMAGE"
