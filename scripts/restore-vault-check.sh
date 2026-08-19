#!/usr/bin/env bash
# Validate that a vault archive can be extracted and contains core notes.
set -euo pipefail

ARCHIVE="${1:?Usage: $0 <vault-backup.tar.gz>}"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

tar -xzf "$ARCHIVE" -C "$temporary"
vault="$(find "$temporary" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
[ -n "$vault" ]
for note in README.md '04 Operations/Knowledge Base Policy.md' '_templates/Project.md'; do
  test -f "$vault/$note"
done
printf 'Restore validation passed: %s\n' "$vault"
