# One-time Ubuntu installation

## What this installs

The installer creates only these server resources:

```text
Unix user:       hermes             (restricted, no sudo, no Docker group)
Unix group:      hermes-vault
Directories:     /srv/honcho-hermes-stack
                 /srv/hermes/home
                 /srv/hermes/vault
                 /srv/obsidian/config
                 /srv/syncthing/config
Docker services: Honcho API, Deriver, PostgreSQL/pgvector, Redis, Ollama,
                 Obsidian UI, Syncthing
```

It does not modify your SSH daemon, firewall, Tailscale, router, existing Docker containers or existing home directory data.

## Review before execution

The staged source is at:

```bash
~/honcho-hermes-stack-staging
```

Inspect the installer and its supporting scripts:

```bash
cd ~/honcho-hermes-stack-staging
less scripts/install-ubuntu-stack.sh
sha256sum scripts/install-ubuntu-stack.sh scripts/provision-server-storage.sh
```

## Execute exactly once

```bash
cd ~/honcho-hermes-stack-staging
sudo ./scripts/install-ubuntu-stack.sh giovanni
```

The command will prompt only in your own SSH terminal for your sudo password. The assistant never receives it.

## Rollback

```bash
cd /srv/honcho-hermes-stack
docker compose -f compose.yaml -f compose.ollama.yaml down -v --remove-orphans
docker compose -f compose.obsidian.yaml down -v --remove-orphans
docker compose -f compose.syncthing.yaml down -v --remove-orphans

sudo rm -rf /srv/honcho-hermes-stack /srv/hermes /srv/obsidian /srv/syncthing
sudo gpasswd -d giovanni hermes-vault || true
sudo userdel -r hermes
sudo groupdel hermes-vault
rm -rf ~/honcho-hermes-stack-staging
```

This deliberately destroys the Honcho database, Ollama models, Obsidian configuration, Syncthing configuration and vault. Back them up first if you want to preserve data.
