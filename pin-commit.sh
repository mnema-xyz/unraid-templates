#!/bin/sh
# Pins the compose package draft to the commit that holds the current mnema-talk/compose.yaml.
# Run after every change to mnema-talk/, then commit and push the draft.
set -eu
cd "$(dirname "$0")"
sha=$(git log -n 1 --format=%H -- mnema-talk/)
[ -n "$sha" ] || { echo "commit mnema-talk/ first" >&2; exit 1; }
sed -i.bak -E "s#<ComposeSourceCommit>[^<]*</ComposeSourceCommit>#<ComposeSourceCommit>$sha</ComposeSourceCommit>#" pending/mnema-talk.xml.pending
rm -f pending/mnema-talk.xml.pending.bak
echo "pinned to $sha"
