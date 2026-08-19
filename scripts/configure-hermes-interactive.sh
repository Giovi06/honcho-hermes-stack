#!/usr/bin/env bash
# Run interactively as the restricted Hermes user after install-hermes-runtime.sh.
# This script intentionally prompts for OAuth/device authorization and the Telegram token.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/srv/hermes/home/.hermes}"
HERMES_BIN="${HERMES_BIN:-/srv/hermes/home/.local/bin/hermes}"

if [ "$(id -u)" -eq 0 ]; then
  echo 'Do not run as root. Use sudo -u hermes -H env ... as documented.' >&2
  exit 1
fi

echo 'Step 1/3: Configure Codex subscription model if not already completed.'
"$HERMES_BIN" model

echo 'Step 2/3: Configure local self-hosted Honcho memory.'
"$HERMES_BIN" memory setup honcho

echo 'Use base URL: http://127.0.0.1:18400'
echo 'Leave local bearer token blank (Honcho is loopback-only in phase 1).'

echo 'Step 3/3: Configure Telegram gateway.'
"$HERMES_BIN" gateway setup

echo 'Enter the Telegram bot token and allow only your numeric Telegram user ID.'
echo 'After this completes, run install-hermes-services.sh as root.'
