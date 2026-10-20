# What Chagai's setup relies on in mautrix-whatsapp — re-check after every upgrade

Live instance: `matrix-mautrix-whatsapp` on chagai.website, multi-user bridge
(~28 WhatsApp logins; Chagai's: @me = +41766524456, @stayinginbern = +41783166727,
@bridge = relay). Config is rendered by matrix-docker-ansible-deploy; overrides live in
`host_vars/matrix.chagai.website/vars.yml` (and the copy in `/matrix/vars.yml`).

| # | Feature | Setting / where | How to verify after an upgrade |
|---|---|---|---|
| 1 | DM rooms carry the contact's **name and picture** | `bridge.private_chat_portal_meta: true` — **must stay true** (false broke all DM names in 2026-07; it is still a plain bool in mautrix-go v0.32) | `grep private_chat_portal_meta` in the rendered config; a fresh DM gets `m.room.name` + `m.room.avatar` |
| 2 | Name format `<contact name> (WA)` | `network.displayname_template: '{{or .FullName .BusinessName .PushName .RedactedPhone "Unknown user"}} (WA)'` | ghost display names end in ` (WA)`; matrix-os `align-contact-names.py` / `name-unnamed-dms.py` assume it |
| 3 | Command prefix `!wa`, admins @me/@stayinginbern/@bridge | `bridge.command_prefix`, `bridge.permissions` | `!wa help` / `!wa list-logins` in the mgmt room answers |
| 4 | **Relay mode** (Telegram↔WhatsApp group bridging via @bridge) | `bridge.relay.enabled: true`, `admin_only: false`, custom `message_formats` (`<b>Name</b>: msg`) | a relayed message shows the bold sender prefix |
| 5 | **Double puppeting** (own messages from the phone appear as @me, read receipts both ways) | per-login double puppet (appservice-style, `double_puppet.secrets` empty → login-time token) | message sent from the phone shows as @me, not as the own-number ghost |
| 6 | Backfill | `backfill.enabled: true`, `max_initial_messages: 50`, `max_catchup_messages: 500`, `unread_hours_threshold: 720`; `history_sync.max_initial_conversations: -1`, `request_full_sync: false`, media `auto_request_media: true` / `immediate` | after a restart, messages missed while down appear |
| 7 | Status broadcast room (low-priority, muted, no sending) | `enable_status_broadcast: true`, `mute_status_broadcast`, `status_broadcast_tag: m.lowpriority`, `disable_status_broadcast_send: true` | status room still exists, tagged low priority |
| 8 | Polls as extensible events, call notices | `extev_polls: true`, `call_start_notices: true` | — |
| 9 | Personal filtering spaces | `bridge.personal_filtering_spaces: true` | each user's WhatsApp space still lists chats |
| 10 | Don't leave WhatsApp chats when leaving a Matrix room | `bridge_matrix_leave: false`; `cleanup_on_logout.enabled: false` | — |
| 11 | No encryption, no direct media, no URL previews, no public media | `encryption.allow: false`, `direct_media.enabled: false`, `url_previews: false` | — |
| 12 | Bot writes never trigger WhatsApp read receipts | matrix-os writes DM room state **as @whatsappbot** (as_token); the bridge ignores its own bot — writing as @me would send implicit read receipts | write a test state event as the bot → no `implicit read receipt` log line |
| 13 | `--version` identifies the build | upstream image: `mautrix-whatsapp v26.10 (built …)`; own build adds `+dev.<commit>` | `docker exec matrix-mautrix-whatsapp mautrix-whatsapp --version` |
| 14 | matrix-os tooling that parses WhatsApp ghost IDs | `@whatsapp_<digits>` (phone) and, since v26.08, `@whatsapp_lid-<digits>` (LID; map via bridge table `whatsmeow_lid_map`) | see wiki [[bridges-status]] 2026-10-20 LID section for the list of scripts |

## Upstream changes that affect these features (keep this list going)

* **v26.08 — DMs switched to LID ghosts.** On first start the bridge re-IDs every DM
  portal `<phone>@s.whatsapp.net` → `<lid>@lid`: same Matrix room, but the phone-number
  ghost leaves and `@whatsapp_lid-<lid>` joins (DM rooms with no Matrix room are
  dropped; a phone DM whose LID twin already has a room is tombstoned into it; DMs
  whose LID isn't known yet migrate on their next message). Breaks anything that
  derives a phone number from the DM partner's MXID → feature 14.
* **v26.09** — one-time copy of avatars from phone ghosts to LID ghosts that have none;
  new options `lazy avatars` (direct media only) and a limit for eager group member sync.
* **v26.10** — block/unblock, contact arrays, partial reply quoting, "delete for me" in DMs.
