#!/usr/bin/env bash
# One-time privileged installer. Run locally on the Ubuntu server with sudo.
# It does not install Hermes CLI itself; it only prepares the restricted account,
# knowledge vault and the Honcho/Obsidian/Syncthing container stack.
set -euo pipefail

ADMIN_USER="${1:?Usage: sudo $0 <existing-admin-user> [--resume]}"
MODE="${2:-}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DEPLOY_DIR="/srv/honcho-hermes-stack"
HERMES_USER="hermes"
VAULT_GROUP="hermes-vault"

if [ "$(id -u)" -ne 0 ]; then
  echo 'Run this script with sudo.' >&2
  exit 1
fi
id "$ADMIN_USER" >/dev/null
if [ -e "$DEPLOY_DIR" ] && [ "$MODE" != "--resume" ]; then
  echo "Refusing to overwrite existing deployment: $DEPLOY_DIR" >&2
  echo "If this is an interrupted initial install, re-run with --resume." >&2
  exit 1
fi
if [ -n "$MODE" ] && [ "$MODE" != "--resume" ]; then
  echo "Unknown mode: $MODE" >&2
  exit 1
fi
command -v docker >/dev/null || { echo 'Docker is required.' >&2; exit 1; }
docker compose version >/dev/null

# 1. Least-privilege account and persistent host paths (idempotent).
"$SOURCE_DIR/scripts/provision-server-storage.sh" "$ADMIN_USER"

# 2. Copy a clean reviewed deployment. Never copy workstation secrets/runtime data.
install -d -o "$ADMIN_USER" -g "$ADMIN_USER" -m 0750 "$DEPLOY_DIR"
tar -C "$SOURCE_DIR" \
  --exclude=.git --exclude=.env --exclude=runtime --exclude=backups \
  --exclude=.DS_Store --exclude='__pycache__' -cf - . \
  | tar -C "$DEPLOY_DIR" -xf -
chown -R "$ADMIN_USER:$ADMIN_USER" "$DEPLOY_DIR"
chmod 0750 "$DEPLOY_DIR"

# 3. Fresh server-only secrets on the first run; preserve them while resuming.
if [ ! -f "$DEPLOY_DIR/.env" ]; then
  runuser -u "$ADMIN_USER" -- python3 "$DEPLOY_DIR/scripts/bootstrap.py"
fi
HERMES_UID="$(id -u "$HERMES_USER")"
VAULT_GID="$(getent group "$VAULT_GROUP" | cut -d: -f3)"
python3 - "$DEPLOY_DIR/.env" "$HERMES_UID" "$VAULT_GID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
uid, gid = sys.argv[2:]
values = {
    "HONCHO_PORT": "18400",
    "POSTGRES_PORT": "18410",
    "REDIS_PORT": "18411",
    "OLLAMA_HOST_PORT": "18404",
    "OLLAMA_BASE_URL": "http://ollama:11434/v1",
    "OBSIDIAN_PUID": uid,
    "OBSIDIAN_PGID": gid,
    "OBSIDIAN_VAULT_PATH": "/srv/hermes/vault",
    "OBSIDIAN_CONFIG_PATH": "/srv/obsidian/config",
    "OBSIDIAN_HTTPS_PORT": "18401",
    "SYNCTHING_PUID": uid,
    "SYNCTHING_PGID": gid,
    "SYNCTHING_CONFIG_PATH": "/srv/syncthing/config",
    "SYNCTHING_GUI_PORT": "18402",
    "SYNCTHING_LISTEN_BIND": "0.0.0.0",
    "SYNCTHING_LISTEN_PORT": "18403",
}
lines, seen = [], set()
for line in path.read_text().splitlines():
    key, separator, value = line.partition("=")
    if separator and key in values:
        lines.append(f"{key}={values[key]}")
        seen.add(key)
    else:
        lines.append(line)
for key, value in values.items():
    if key not in seen:
        lines.append(f"{key}={value}")
path.write_text("\n".join(lines) + "\n")
path.chmod(0o600)
PY
chown "$ADMIN_USER:$ADMIN_USER" "$DEPLOY_DIR/.env"

# 4. Seed the Markdown vault and install the future Hermes documentation skill.
# The deployment source is intentionally unreadable to the restricted account,
# so seed as root then transfer only vault ownership to `hermes`.
python3 "$DEPLOY_DIR/scripts/init-vault.py" --vault /srv/hermes/vault
chown -R "$HERMES_USER:$VAULT_GROUP" /srv/hermes/vault
find /srv/hermes/vault -type d -exec chmod 2770 {} +
find /srv/hermes/vault -type f -exec chmod 0640 {} +
install -d -o "$HERMES_USER" -g "$HERMES_USER" -m 0750 \
  /srv/hermes/home/.hermes/skills/project-knowledge-base
install -o "$HERMES_USER" -g "$HERMES_USER" -m 0640 \
  "$DEPLOY_DIR/hermes-skill/project-knowledge-base/SKILL.md" \
  /srv/hermes/home/.hermes/skills/project-knowledge-base/SKILL.md

# 5. Launch services. API/UIs are localhost-only; Syncthing transport uses LAN ports.
cd "$DEPLOY_DIR"
docker compose -f compose.yaml -f compose.ollama.yaml up -d --build
docker compose -f compose.obsidian.yaml up -d
docker compose -f compose.syncthing.yaml up -d

cat <<EOF

Installation launched.

Deployment directory: $DEPLOY_DIR
Vault:                /srv/hermes/vault
Hermes UID:           $HERMES_UID
Vault GID:            $VAULT_GID

Next verification commands:
  cd $DEPLOY_DIR
  ./scripts/verify.sh
  docker compose -f compose.obsidian.yaml ps
  docker compose -f compose.syncthing.yaml ps

SSH tunnel from the Mac for Obsidian:
  ssh -N -L 18401:127.0.0.1:18401 $ADMIN_USER@192.168.1.132

SSH tunnel from the Mac for Syncthing administration:
  ssh -N -L 18402:127.0.0.1:18402 $ADMIN_USER@192.168.1.132
EOF
