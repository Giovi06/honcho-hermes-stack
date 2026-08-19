# Hermes server runtime: Codex subscription + Telegram

## Purpose

Hermes runs as the restricted Unix account `hermes`, while the administrator starts the one-time installers with `sudo`. The model is authenticated by OpenAI Codex/ChatGPT device-code OAuth; no API key or local credential copy is used.

## Phase 1: install the runtime

```bash
cd ~/honcho-hermes-stack-staging
sudo ./scripts/install-hermes-runtime.sh
```

This installs Node.js/npm only because the remote Desktop backend needs the Hermes web frontend. It installs Hermes and `[all]` dependencies under `/srv/hermes/home`; it does not create a Gateway service yet.

## Phase 2: interactive configuration

Run this in the same SSH terminal. It prints a device-login URL/code; open it on the Mac and complete Codex subscription login there:

```bash
sudo -u hermes -H env \
  HOME=/srv/hermes/home \
  HERMES_HOME=/srv/hermes/home/.hermes \
  PATH=/srv/hermes/home/.local/bin:/usr/local/bin:/usr/bin:/bin \
  /srv/hermes/home/.local/bin/hermes auth add openai-codex --no-browser
```

Then run the interactive configuration script. It intentionally prompts for Telegram token and user allowlist; never paste those values into chat:

```bash
sudo -u hermes -H env \
  HOME=/srv/hermes/home \
  HERMES_HOME=/srv/hermes/home/.hermes \
  PATH=/srv/hermes/home/.local/bin:/usr/local/bin:/usr/bin:/bin \
  /srv/honcho-hermes-stack/scripts/configure-hermes-interactive.sh
```

Choose **ChatGPT or Codex Subscription** in the model picker. For Honcho use `http://127.0.0.1:18400` with no local bearer token.

## Phase 3: persistent services

Only after both Codex and Telegram setup finish:

```bash
sudo ./scripts/install-hermes-services.sh
```

This starts:

- `hermes-gateway-*.service` — persistent Telegram gateway;
- `hermes-serve.service` — remote desktop backend on `127.0.0.1:18406`.

## Hermes Desktop remote connection

From the Mac:

```bash
ssh -N -L 18406:127.0.0.1:18406 giovanni@192.168.1.132
```

In Hermes Desktop: **Settings → Gateways → Connection mode → Remote gateway**, then use:

```text
http://localhost:18406
```

Keep this localhost+SSH-tunnel mode initially. Do not create a public `hermes.innamorato.duckdns.org` route until dashboard basic authentication is explicitly configured and tested.

## Rollback

```bash
sudo systemctl disable --now hermes-serve.service || true
sudo rm -f /etc/systemd/system/hermes-serve.service
sudo systemctl daemon-reload

# Hermes gateway service: use the installed CLI's stop/remove path if available.
sudo -u hermes -H env HOME=/srv/hermes/home HERMES_HOME=/srv/hermes/home/.hermes \
  /srv/hermes/home/.local/bin/hermes gateway stop --all || true

sudo rm -rf /srv/hermes/home
sudo apt purge nodejs npm
```

The last two lines remove the Hermes installation and the Node/npm packages added by phase 1. Vault and Honcho are deliberately not removed by this Hermes-only rollback.
