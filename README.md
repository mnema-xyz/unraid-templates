# Mnema Talk for Unraid

Community Apps templates for [Mnema Talk](https://mnema.xyz), a small
self-hosted home for one community: text channels, drop-in voice Talks and
screen sharing.

Mnema Talk needs PostgreSQL and S3-compatible storage (SeaweedFS), so the
template installs the whole stack as one Community Apps **compose package**
(Unraid 8 or newer). On Unraid 7 use the Compose Manager route in the
[install guide](https://github.com/mnema-xyz/talk/blob/main/doc/unraid.md).

| Path | What |
|---|---|
| `templates/mnema-talk.xml` | the Community Apps template |
| `mnema-talk/compose.yaml` | the stack the template installs (app, PostgreSQL, SeaweedFS) |
| `mnema-talk/.env.example` | the same settings for Compose Manager |
| `ca_profile.xml`, `icon.png` | repository profile and icon (256x256) |
| `pin-commit.sh` | pins the template to the commit of `mnema-talk/` |

Support: [GitHub issues](https://github.com/mnema-xyz/talk/issues). License: AGPL-3.0.
