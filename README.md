# Mnema for Unraid

Community Apps templates for [Mnema Talk](https://mnema.xyz), a small
self-hosted home for one community (text channels, drop-in voice Talks and
screen sharing), for its media store, and for **Mnemo**, its self-hosted AI
helper bot.

| App | Template | Needs | Guide |
|---|---|---|---|
| Mnema Talk | `templates/mnema-talk.xml` | PostgreSQL 18 and SeaweedFS-Mnema, installed first | [install guide](https://github.com/mnema-xyz/talk/blob/main/doc/platform-notes.md#install-on-unraid-via-community-apps) |
| SeaweedFS-Mnema | `templates/seaweedfs-mnema.xml` | nothing | same guide |
| Mnemo | `templates/mnemo.xml` | a Talk server 3.1+, an AI provider key | [install guide](https://github.com/mnema-xyz/talk-mnemo-bot/blob/main/README.md#install-on-unraid) |

## Mnema Talk in three containers

Mnema Talk keeps its data in PostgreSQL and its media in S3 storage. On Unraid
each one is a container of its own, installed from the *Apps* tab in this
order:

1. **postgresql18** from *jj9987's Repository* (the official `postgres:18` image, an existing Community
   Apps template). Set *POSTGRES_USER* to `mnema`, *POSTGRES_DB* to
   `mnema_talk` and a password from `openssl rand -hex 32`.
2. **SeaweedFS-Mnema** (this repository): the official `chrislusf/seaweedfs`
   image as a private S3 store. Pick an access key and a secret key. Only the
   S3 port is published, and it refuses every request without the key.
3. **Mnema-Talk** (this repository): enter the database URL
   `postgres://mnema:PASSWORD@UNRAID-IP:5432/mnema_talk?sslmode=disable`, the
   media storage address `http://UNRAID-IP:8333` with the same two keys, a JWT
   secret and the admin password.

All three run on the default bridge network and reach each other through the
Unraid server's address. Never forward ports 5432, 8333 or 8080 on your router;
only HTTPS (through your reverse proxy) and the voice ports.

## Files

| Path | What |
|---|---|
| `templates/mnema-talk.xml` | Mnema Talk (single container) |
| `templates/seaweedfs-mnema.xml` | SeaweedFS as the Talk media store (single container) |
| `templates/mnemo.xml` | Mnemo (single container) |
| `mnema-talk/compose.yaml`, `mnema-talk/.env.example` | the whole stack for the Compose Manager plugin, an alternative to the three templates |
| `pending/mnema-talk.xml.pending` | a compose package draft, parked until the Community Apps compose package contract is published (not scanned) |
| `ca_profile.xml` | repository profile |
| `icon.png`, `icon-mnemo.png`, `icon-seaweedfs.png` | app icons (256x256); the SeaweedFS icon is the upstream logo (Apache-2.0) |
| `pin-commit.sh` | pins the compose draft to the commit of `mnema-talk/` |

Support: [Talk issues](https://github.com/mnema-xyz/talk/issues) (Talk and
SeaweedFS-Mnema), [Mnemo issues](https://github.com/mnema-xyz/talk-mnemo-bot/issues).
License: AGPL-3.0 (Mnema Talk and these templates); Mnemo is MIT; SeaweedFS is
Apache-2.0.
