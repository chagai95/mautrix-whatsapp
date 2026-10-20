# Patches applied on top of upstream at image build time

Empty on purpose: as of upstream **v0.2610.0** every fix Chagai needed is upstream,
so the live bridge runs the **official upstream image** and nothing here is built.

When a fix is needed that upstream doesn't have yet:

* `whatsapp/NNNN-*.patch`   — applied to this repo (`patch -p1`) inside the build
* `mautrix-go/NNNN-*.patch` — applied to the exact mautrix-go version `go.mod` pins,
  via a build-only `replace` (go.mod stays untouched → upstream merges never conflict)

Then `chagai/build-image.sh` → `dock.mau.dev/mautrix/whatsapp:<tag>-chagai`.
Drop each patch as soon as upstream ships the fix (`chagai/upstream-check.sh` reports new tags).
