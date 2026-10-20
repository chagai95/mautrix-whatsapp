# Chagai's build of mautrix-whatsapp = upstream Dockerfile + optional patches
# from chagai/patches (see chagai/patches/README.md). Upstream files stay
# untouched, so merging a new upstream tag never conflicts with this file.
# Keep the base images in sync with upstream's Dockerfile (upstream-check.sh warns).
#
#   chagai/build-image.sh            -> dock.mau.dev/mautrix/whatsapp:<tag>-chagai
FROM golang:1-alpine3.24 AS builder

RUN apk add --no-cache git ca-certificates build-base su-exec olm-dev patch

COPY . /build
WORKDIR /build
RUN set -eux; \
    for p in chagai/patches/whatsapp/*.patch; do [ -e "$p" ] || continue; patch -p1 --forward < "$p"; done; \
    if ls chagai/patches/mautrix-go/*.patch >/dev/null 2>&1; then \
      MGO_VER="$(go list -m -f '{{.Version}}' maunium.net/go/mautrix)"; \
      go mod download maunium.net/go/mautrix@"$MGO_VER"; \
      SRC="$(go list -m -f '{{.Dir}}' maunium.net/go/mautrix)"; \
      mkdir -p /build/.chagai-deps && cp -r "$SRC" /build/.chagai-deps/mautrix-go && chmod -R u+w /build/.chagai-deps; \
      for p in chagai/patches/mautrix-go/*.patch; do patch -d /build/.chagai-deps/mautrix-go -p1 --forward < "$p"; done; \
      go mod edit -replace maunium.net/go/mautrix=./.chagai-deps/mautrix-go; \
    fi; \
    ./build.sh; \
    ./mautrix-whatsapp --version

FROM alpine:3.24

ENV UID=1337 \
    GID=1337

RUN apk add --no-cache ffmpeg su-exec ca-certificates olm bash jq curl yq-go lottieconverter

COPY --from=builder /build/mautrix-whatsapp /usr/bin/mautrix-whatsapp
COPY --from=builder /build/docker-run.sh /docker-run.sh
VOLUME /data

CMD ["/docker-run.sh"]
