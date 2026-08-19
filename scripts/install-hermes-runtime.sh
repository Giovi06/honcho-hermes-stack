#!/usr/bin/env bash
# Install Hermes Agent runtime under the restricted `hermes` Unix account.
# Requires root only for the Node.js/npm package required by the remote desktop backend.
set -euo pipefail

HERMES_USER="hermes"
HERMES_HOME="/srv/hermes/home/.hermes"
HERMES_OS_HOME="/srv/hermes/home"
HERMES_BIN="$HERMES_OS_HOME/.local/bin/hermes"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi
id "$HERMES_USER" >/dev/null

if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
  apt-get update
  apt-get install -y nodejs npm
fi

if [ ! -x "$HERMES_BIN" ]; then
  runuser -u "$HERMES_USER" -- env \
    HOME="$HERMES_OS_HOME" \
    HERMES_HOME="$HERMES_HOME" \
    PATH="$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
    bash -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'
fi

# Install web, pseudo-terminal and messaging dependencies for remote Desktop + Telegram.
runuser -u "$HERMES_USER" -- env \
  HOME="$HERMES_OS_HOME" \
  HERMES_HOME="$HERMES_HOME" \
  PATH="$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
  bash -c 'cd "$HERMES_HOME/hermes-agent" && uv pip install -e ".[all]"'

# The vault path is non-secret runtime configuration used by the documentation skill.
install -d -o "$HERMES_USER" -g "$HERMES_USER" -m 0750 "$HERMES_HOME"
touch "$HERMES_HOME/.env"
chown "$HERMES_USER:$HERMES_USER" "$HERMES_HOME/.env"
chmod 0600 "$HERMES_HOME/.env"
if ! grep -q '^OBSIDIAN_VAULT_PATH=' "$HERMES_HOME/.env"; then
  printf 'OBSIDIAN_VAULT_PATH=/srv/hermes/vault\n' >> "$HERMES_HOME/.env"
fi

cat <<EOF

Hermes runtime is installed for the restricted account.

Next, run the interactive setup as the administrator in your own SSH terminal:
  sudo -u hermes -H env HOME=$HERMES_OS_HOME HERMES_HOME=$HERMES_HOME \\
    PATH=$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin \\
    $HERMES_BIN auth add openai-codex --no-browser

Open the displayed OpenAI URL on your Mac and complete the device-code login.
Then run:
  sudo -u hermes -H env HOME=$HERMES_OS_HOME HERMES_HOME=$HERMES_HOME \\
    PATH=$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin \\
    $HERMES_BIN model

Choose: ChatGPT or Codex Subscription.

Do not start the Gateway yet. Complete Honcho and Telegram setup first using
scripts/configure-hermes-interactive.sh.
EOF
