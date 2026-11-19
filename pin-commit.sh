#!/bin/sh
# Pins the template to the commit that holds the current mnema-talk/compose.yaml.
# Run after every change to mnema-talk/, then commit and push the template.
set -eu
cd "$(dirname "$0")"
sha=$(git log -n 1 --format=%H -- mnema-talk/)
[ -n "$sha" ] || { echo "commit mnema-talk/ first" >&2; exit 1; }
sed -i.bak -E "s#<ComposeSourceCommit>[^<]*</ComposeSourceCommit>#<ComposeSourceCommit>$sha</ComposeSourceCommit>#" templates/mnema-talk.xml
rm -f templates/mnema-talk.xml.bak
echo "pinned to $sha"
