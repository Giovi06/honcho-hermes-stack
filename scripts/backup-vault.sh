#!/usr/bin/env bash
# Create a timestamped filesystem backup of an Obsidian vault.
set -euo pipefail

VAULT_PATH="${1:?Usage: $0 <vault-path> [backup-directory>}"
BACKUP_DIR="${2:-./backups}"
VAULT_PATH="$(cd "$VAULT_PATH" && pwd -P)"
mkdir -p "$BACKUP_DIR"
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd -P)"
name="$(basename "$VAULT_PATH")"
archive="$BACKUP_DIR/${name}-$(date +%Y%m%d-%H%M%S).tar.gz"

tar -C "$(dirname "$VAULT_PATH")" -czf "$archive" "$name"
printf 'Created plaintext vault archive: %s\n' "$archive"
printf 'Store this archive in encrypted off-device backup storage.\n'
