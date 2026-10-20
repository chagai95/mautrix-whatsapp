#!/bin/bash
# Report whether upstream mautrix/whatsapp has a newer release than what runs live.
# Read-only: fetches tags, compares with the running container + the fork base.
# Output: one line "STATUS live=<tag> base=<tag> upstream=<tag> ..." (+ details),
# exit 0 = up to date, 10 = newer upstream tag available, 1 = error.
# Used by the upstream-sync timer (see wiki [[upstream-sync]]); safe to run anytime.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
git fetch -q upstream --tags
LATEST="$(git tag -l 'v0.*' | sort -V | tail -1)"
BASE="$(git describe --tags --abbrev=0 chagai/main 2>/dev/null || echo '?')"
LIVE_IMG="$(sudo -n docker inspect -f '{{.Config.Image}}' matrix-mautrix-whatsapp 2>/dev/null || echo '?')"
LIVE_TAG="${LIVE_IMG##*:}"; LIVE_TAG="${LIVE_TAG%-chagai}"
PATCHES="$( (ls chagai/patches/*/*.patch 2>/dev/null || true) | wc -l)"
# base images of upstream's Dockerfile vs ours
UP_FROM="$(git show "$LATEST":Dockerfile | grep -E '^FROM' | awk '{print $2}' | tr '\n' ' ')"
OUR_FROM="$(grep -E '^FROM' chagai/Dockerfile | awk '{print $2}' | tr '\n' ' ')"
status=0; state="UP-TO-DATE"
if [ "$LIVE_TAG" != "$LATEST" ] || [ "$BASE" != "$LATEST" ]; then state="NEW-UPSTREAM"; status=10; fi
echo "$state live=$LIVE_TAG base=$BASE upstream=$LATEST patches=$PATCHES"
if [ "$status" = 10 ]; then
  echo "--- upstream CHANGELOG since $LIVE_TAG:"
  git show "$LATEST":CHANGELOG.md | awk -v stop="# v$(echo "$LIVE_TAG" | sed -E 's/^v0\.([0-9]{2})([0-9]{2})\..*/\1.\2/')" '$0==stop{exit} {print}'
fi
[ "$UP_FROM" = "$OUR_FROM" ] || echo "WARN chagai/Dockerfile base images ($OUR_FROM) differ from upstream ($UP_FROM)"
exit $status
