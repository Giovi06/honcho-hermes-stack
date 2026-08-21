#!/usr/bin/env bash
# Install Hermes Agent runtime under the restricted `hermes` Unix account.
# Requires root only for the Node.js/npm package required by the remote desktop backend.
set -euo pipefail

HERMES_USER="hermes"
HERMES_HOME="/srv/hermes/home/.hermes"
HERMES_OS_HOME="/srv/hermes/home"
HERMES_BIN="$HERMES_OS_HOME/.local/bin/hermes"
HERMES_SOURCE_ARCHIVE="${HERMES_SOURCE_ARCHIVE:-/home/giovanni/hermes-agent-source.tar.gz}"
HERMES_SOURCE_DIR="$HERMES_HOME/hermes-agent"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi
id "$HERMES_USER" >/dev/null

# Earlier vault-skill provisioning may have created the profile parent as root.
# Hermes' official installer runs as the restricted user and must own this
# profile tree; it does not grant that user access outside its own home.
install -d -o "$HERMES_USER" -g "$HERMES_USER" -m 0750 "$HERMES_HOME"
chown -R "$HERMES_USER:$HERMES_USER" "$HERMES_HOME"

if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
  apt-get update
  apt-get install -y nodejs npm
fi

if [ ! -x "$HERMES_BIN" ]; then
  # Prefer the clean source archive staged from the administrator's verified
  # workstation checkout. This avoids GitHub HTTP 429 and transfers no local
  # credentials, Git metadata, virtualenvs, node_modules or local changes.
  if [ -f "$HERMES_SOURCE_ARCHIVE" ]; then
    test ! -e "$HERMES_SOURCE_DIR" || { echo "Unexpected existing source: $HERMES_SOURCE_DIR" >&2; exit 1; }
    install -d -o "$HERMES_USER" -g "$HERMES_USER" -m 0750 "$HERMES_SOURCE_DIR"
    tar -xzf "$HERMES_SOURCE_ARCHIVE" -C "$HERMES_SOURCE_DIR"
    chown -R "$HERMES_USER:$HERMES_USER" "$HERMES_SOURCE_DIR"
  else
    # Fallback for a normal network path when no staged source is present.
    runuser -u "$HERMES_USER" -- env \
      HOME="$HERMES_OS_HOME" \
      HERMES_HOME="$HERMES_HOME" \
      PATH="$HERMES_HOME/bin:$HERMES_HOME/node/bin:$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
      bash -c 'cd "$HOME" && curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'
  fi
fi

test -f "$HERMES_SOURCE_DIR/pyproject.toml" || { echo 'Hermes source is incomplete.' >&2; exit 1; }
test -x "$HERMES_HOME/bin/uv" || { echo 'Managed uv is missing.' >&2; exit 1; }
test -x "$HERMES_HOME/node/bin/node" || { echo 'Managed Node 26 is missing.' >&2; exit 1; }

# Build a fresh Linux venv; never copy a macOS venv or node_modules.
runuser -u "$HERMES_USER" -- env \
  HOME="$HERMES_OS_HOME" \
  HERMES_HOME="$HERMES_HOME" \
  PATH="$HERMES_HOME/bin:$HERMES_HOME/node/bin:$HERMES_OS_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
  bash -c 'cd "$HERMES_HOME/hermes-agent" && "$HERMES_HOME/bin/uv" venv .venv --python 3.11 && "$HERMES_HOME/bin/uv" pip install -e ".[all]"'

# Provide the managed CLI launcher normally created by the official installer.
install -d -o "$HERMES_USER" -g "$HERMES_USER" -m 0750 "$HERMES_OS_HOME/.local/bin"
cat > "$HERMES_BIN" <<EOF
#!/bin/sh
exec "$HERMES_SOURCE_DIR/.venv/bin/python" -m hermes_cli.main "\$@"
EOF
chown "$HERMES_USER:$HERMES_USER" "$HERMES_BIN"
chmod 0750 "$HERMES_BIN"

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
