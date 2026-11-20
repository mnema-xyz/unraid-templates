# Mnema for Unraid

Community Apps templates for [Mnema Talk](https://mnema.xyz), a small
self-hosted home for one community (text channels, drop-in voice Talks and
screen sharing), and for **Mnemo**, its self-hosted AI helper bot.

| App | Template | Needs | Guide |
|---|---|---|---|
| Mnema Talk | `templates/mnema-talk.xml` | Unraid 8+ (compose package; Compose Manager on Unraid 7) | [install guide](https://github.com/mnema-xyz/talk/blob/main/doc/platform-notes.md#install-on-unraid-via-community-apps) |
| Mnemo | `templates/mnemo.xml` | a Talk server 3.1+, an AI provider key | [install guide](https://github.com/mnema-xyz/talk-mnemo-bot/blob/main/README.md#install-on-unraid) |

Mnema Talk needs PostgreSQL and S3-compatible storage (SeaweedFS), so the
template installs the whole stack as one Community Apps **compose package**
(Unraid 8 or newer). On Unraid 7 use the Compose Manager route in the
[install guide](https://github.com/mnema-xyz/talk/blob/main/doc/platform-notes.md#install-on-unraid-via-community-apps).

| Path | What |
|---|---|
| `templates/mnema-talk.xml` | the Talk Community Apps template |
| `templates/mnemo.xml` | the Mnemo Community Apps template (single container) |
| `mnema-talk/compose.yaml` | the stack the template installs (app, PostgreSQL, SeaweedFS) |
| `mnema-talk/.env.example` | the same settings for Compose Manager |
| `ca_profile.xml` | repository profile |
| `icon.png`, `icon-mnemo.png` | app icons (256x256) |
| `pin-commit.sh` | pins the template to the commit of `mnema-talk/` |

Support: [Talk issues](https://github.com/mnema-xyz/talk/issues), [Mnemo issues](https://github.com/mnema-xyz/talk-mnemo-bot/issues). License: AGPL-3.0 (Mnema Talk); Mnemo is MIT.
