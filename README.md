# Mnema for Unraid

Community Apps templates for [Mnema Talk](https://mnema.xyz), a small
self-hosted home for one community (text channels, drop-in voice Talks and
screen sharing), and for **Mnemo**, its self-hosted AI helper bot.

| App | Template | Needs | Guide |
|---|---|---|---|
| Mnema Talk | not listed yet (see below) | Compose Manager on Unraid 7 and 8 | [install guide](https://github.com/mnema-xyz/talk/blob/main/doc/platform-notes.md#install-on-unraid-via-community-apps) |
| Mnemo | `templates/mnemo.xml` | a Talk server 3.1+, an AI provider key | [install guide](https://github.com/mnema-xyz/talk-mnemo-bot/blob/main/README.md#install-on-unraid) |

Mnema Talk needs PostgreSQL and S3-compatible storage (SeaweedFS), so it is
meant to ship as one Community Apps **compose package** (Unraid 8 or newer).
The draft is in `pending/mnema-talk.xml.pending` until the compose package
contract is published and the template passes the Community Apps scan. Until
then, install Talk with the Compose Manager route in the
[install guide](https://github.com/mnema-xyz/talk/blob/main/doc/platform-notes.md#install-on-unraid-via-community-apps).

| Path | What |
|---|---|
| `pending/mnema-talk.xml.pending` | the Talk compose package draft (not scanned by Community Apps) |
| `templates/mnemo.xml` | the Mnemo Community Apps template (single container) |
| `mnema-talk/compose.yaml` | the stack the template installs (app, PostgreSQL, SeaweedFS) |
| `mnema-talk/.env.example` | the same settings for Compose Manager |
| `ca_profile.xml` | repository profile |
| `icon.png`, `icon-mnemo.png` | app icons (256x256) |
| `pin-commit.sh` | pins the template to the commit of `mnema-talk/` |

Support: [Talk issues](https://github.com/mnema-xyz/talk/issues), [Mnemo issues](https://github.com/mnema-xyz/talk-mnemo-bot/issues). License: AGPL-3.0 (Mnema Talk); Mnemo is MIT.
