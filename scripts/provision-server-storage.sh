#!/usr/bin/env bash
# Provision server-side least-privilege storage for Hermes and the Obsidian vault.
set -euo pipefail

ADMIN_USER="${1:?Usage: $0 <existing-admin-user>}"
HERMES_USER="${HERMES_USER:-hermes}"
VAULT_GROUP="${VAULT_GROUP:-hermes-vault}"

if [ "$(id -u)" -ne 0 ]; then
  echo 'Run as root via sudo.' >&2
  exit 1
fi
id "$ADMIN_USER" >/dev/null

getent group "$VAULT_GROUP" >/dev/null || groupadd --system "$VAULT_GROUP"
if ! id "$HERMES_USER" >/dev/null 2>&1; then
  useradd --system --create-home --home-dir "/srv/hermes/home" \
    --shell /usr/sbin/nologin --groups "$VAULT_GROUP" "$HERMES_USER"
fi
usermod -aG "$VAULT_GROUP" "$ADMIN_USER"

install -d -o "$HERMES_USER" -g "$VAULT_GROUP" -m 2770 /srv/hermes/vault
install -d -o "$HERMES_USER" -g "$VAULT_GROUP" -m 2770 /srv/obsidian/config
install -d -o "$HERMES_USER" -g "$HERMES_USER" -m 0750 /srv/hermes/home

printf 'Provisioned restricted user and vault storage.\n'
printf 'Hermes UID: %s\n' "$(id -u "$HERMES_USER")"
printf 'Vault GID:  %s\n' "$(getent group "$VAULT_GROUP" | cut -d: -f3)"
printf 'Admin %s must log out/in before new group membership applies.\n' "$ADMIN_USER"
printf 'Verification:\n'
printf '  sudo -u %s test -w /srv/hermes/vault\n' "$HERMES_USER"
printf '  sudo -u %s sudo -n true  # must fail\n' "$HERMES_USER"
