# Chagai's build of mautrix-whatsapp: upstream Dockerfile + the patches in
# chagai/patches applied to Go module dependencies at build time.
# Upstream files (go.mod, Dockerfile, build.sh) stay untouched, so merging a
# new upstream tag never conflicts with this file.
#
#   chagai/build-image.sh            -> dock.mau.dev/mautrix/whatsapp:<tag>-chagai
FROM golang:1-alpine3.23 AS builder

RUN apk add --no-cache git ca-certificates build-base su-exec olm-dev patch

COPY . /build
WORKDIR /build
# Patch maunium.net/go/mautrix (mautrix-go) at the exact version go.mod pins:
# copy it out of the module cache, apply chagai/patches/mautrix-go/*.patch and
# point the build at the copy with a build-time-only `replace`.
RUN set -eux; \
    MGO_VER="$(go list -m -f '{{.Version}}' maunium.net/go/mautrix)"; \
    go mod download maunium.net/go/mautrix@"$MGO_VER"; \
    SRC="$(go list -m -f '{{.Dir}}' maunium.net/go/mautrix)"; \
    mkdir -p /build/.chagai-deps && cp -r "$SRC" /build/.chagai-deps/mautrix-go && chmod -R u+w /build/.chagai-deps; \
    for p in chagai/patches/mautrix-go/*.patch; do patch -d /build/.chagai-deps/mautrix-go -p1 --forward < "$p"; done; \
    go mod edit -replace maunium.net/go/mautrix=./.chagai-deps/mautrix-go; \
    ./build.sh; \
    ./mautrix-whatsapp --version

FROM alpine:3.23

ENV UID=1337 \
    GID=1337

RUN apk add --no-cache ffmpeg su-exec ca-certificates olm bash jq curl yq-go lottieconverter

COPY --from=builder /build/mautrix-whatsapp /usr/bin/mautrix-whatsapp
COPY --from=builder /build/docker-run.sh /docker-run.sh
VOLUME /data

CMD ["/docker-run.sh"]
