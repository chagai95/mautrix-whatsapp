# Chagai's mautrix-whatsapp fork — what differs from upstream

Branch **`chagai/main`** = an upstream release tag + a few small, focused commits.
Everything Chagai-specific lives in **new files** (`chagai/`, `docs/chagai/`) so a
new upstream tag merges without conflicts. Upstream `go.mod`, `Dockerfile` and
`build.sh` are untouched.

| | |
|---|---|
| Base | upstream tag **v0.2605.0** (= what runs on chagai.website since 2026-07) |
| Image | `dock.mau.dev/mautrix/whatsapp:v0.2605.0-chagai` — built locally with `chagai/build-image.sh`, never pushed |
| Remotes | `upstream` = github.com/mautrix/whatsapp · `origin` = github.com/chagai95/mautrix-whatsapp (once the repo + deploy key exist) |

## Commits on top of upstream

1. **backport upstream 446bd22** (connector) — the phone-number ghost and the LID
   ghost of the same person are kept in sync by copying the already-uploaded
   avatar, instead of fetching it a second time with the other JID (which could
   come back "unauthorized" or older, and uploaded every picture twice).
2. **mautrix-go patch, applied at image build time**
   (`chagai/patches/mautrix-go/0001-…patch`, = upstream mautrix-go 52b3b51,
   rebased onto v0.28.0) — when a contact removes or hides their WhatsApp
   picture, the DM room's own picture is now cleared too (before, the portal
   kept a stale copy forever: `Remove: ghost.AvatarID == ""` never matched the
   `"remove"` / `"unauthorized"` ids), and a failed ghost upload no longer
   blanks the room picture.

Both are already in upstream **v26.09+** (whatsapp v0.2609.0 / mautrix-go
v0.31.0). This fork exists only to get them without taking v26.08's
"direct chats switch to LID ghosts" change, which renames every DM partner
ghost and needs its own migration project.

## How to rebase onto a new upstream tag

```sh
git fetch upstream --tags
git checkout chagai/main
git rebase --onto vX.Y.Z v0.2605.0     # drop commits upstream already contains
# patches/mautrix-go: delete any patch whose fix is in the new mautrix-go
chagai/build-image.sh                  # -> dock.mau.dev/mautrix/whatsapp:vX.Y.Z-chagai
```

## Deploy (Chagai's call — live bridge)

Image built + `docker run --rm <image> --version` verified. Switching = the two
commented lines in the Ansible `vars.yml` (search "Chagai fork of
mautrix-whatsapp"), `--check --diff` with the bridge's role tag only (never the
`start` tag), then ONE `systemctl restart matrix-mautrix-whatsapp.service`.
Rollback = comment the lines again + one restart onto `v0.2605.0`.
