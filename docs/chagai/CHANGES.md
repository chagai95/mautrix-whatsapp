# Chagai's mautrix-whatsapp fork — what differs from upstream

Branch **`chagai/main`** = the latest upstream release tag + ONE commit that only
adds new files (`chagai/`, `docs/chagai/`). No upstream file is modified, so a new
upstream tag is taken with a plain `git rebase --onto <new tag>` — never a conflict.

| | |
|---|---|
| Base | upstream tag **v0.2610.0** (v26.10, 2026-10-16) |
| Code patches | **none** — `chagai/patches/` is empty (see its README) |
| Image | upstream's official **`dock.mau.dev/mautrix/whatsapp:v0.2610.0`** (no patch → no own build needed). `chagai/build-image.sh` → `…:<tag>-chagai` exists for when a patch is needed. |
| Remotes | `upstream` = github.com/mautrix/whatsapp · `origin` = github.com/chagai95/mautrix-whatsapp |
| Old fork | tag `chagai/v26.05-backports` = v0.2605.0 + backports of whatsapp 446bd22 and mautrix-go 52b3b51 (superseded: both are in v26.10) |

## Why there are no patches any more

The two avatar fixes Chagai needed (2026-10-20, card *cinny-whatsapp-avatars*):

1. whatsapp **446bd22** "lidmigrate: resync missing avatars and reuse info for alt
   ghost sync" (2026-09-08, in v26.09) — phone-number ghost and LID ghost of the same
   person get the same picture (no second fetch with the other JID).
2. mautrix-go **52b3b51** "bridgev2/portal: don't update avatar from ghost if
   uploading failed" (2026-09-08, mautrix-go v0.31.0; v26.10 pins v0.32.0) — DM room
   picture is cleared when the contact removes/hides theirs.

Both are upstream, so the fork carries nothing.

## Taking a new upstream release

```sh
chagai/upstream-check.sh               # exit 10 + changelog when a newer tag exists
git fetch upstream --tags
git rebase --onto vX.Y.Z <old tag> chagai/main
# drop any chagai/patches/* whose fix upstream now contains
# read CHANGELOG for DB/config/ID migrations, then check docs/chagai/FEATURES.md
```

Deploy = pin the image in the Ansible `vars.yml` (both copies), render with the
bridge's role tag only (**never `start`**), `pg_dump` the bridge DB, ONE
`systemctl restart matrix-mautrix-whatsapp.service`, verify FEATURES.md checks.
