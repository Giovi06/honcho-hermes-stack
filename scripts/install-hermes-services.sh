#!/usr/bin/env bash
# Install persistent systemd services after Codex, Honcho and Telegram setup complete.
set -euo pipefail

HERMES_USER="hermes"
HERMES_OS_HOME="/srv/hermes/home"
HERMES_HOME="$HERMES_OS_HOME/.hermes"
HERMES_BIN="$HERMES_OS_HOME/.local/bin/hermes"
SERVICE=/etc/systemd/system/hermes-serve.service

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi
test -x "$HERMES_BIN"
test -f "$HERMES_HOME/auth.json" || { echo 'Codex OAuth is not configured yet.' >&2; exit 1; }

# Gateway service is Hermes-managed and runs under the restricted account.
env HOME="$HERMES_OS_HOME" HERMES_HOME="$HERMES_HOME" \
  PATH="$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
  "$HERMES_BIN" gateway install --system --run-as-user "$HERMES_USER" --start-now

# Desktop backend: localhost only. Access it through SSH tunnelling in phase 1.
cat > "$SERVICE" <<EOF
[Unit]
Description=Hermes remote desktop backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$HERMES_USER
Group=$HERMES_USER
WorkingDirectory=$HERMES_OS_HOME
Environment=HOME=$HERMES_OS_HOME
Environment=HERMES_HOME=$HERMES_HOME
Environment=OBSIDIAN_VAULT_PATH=/srv/hermes/vault
Environment=PATH=$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HERMES_BIN serve --host 127.0.0.1 --port 18406
Restart=on-failure
RestartSec=5
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ReadWritePaths=$HERMES_OS_HOME /srv/hermes/vault

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hermes-serve.service
systemctl --no-pager --full status hermes-serve.service

echo 'Services installed. Verify:'
echo '  systemctl status hermes-serve.service'
echo '  env HOME=/srv/hermes/home HERMES_HOME=/srv/hermes/home/.hermes /srv/hermes/home/.local/bin/hermes gateway status --system --deep'
echo 'Mac tunnel: ssh -N -L 18406:127.0.0.1:18406 giovanni@192.168.1.132'
