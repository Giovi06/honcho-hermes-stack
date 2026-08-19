# Obsidian UI and vault synchronization

## Security model

The vault is a normal Markdown filesystem. It is not stored inside a Docker volume and does not contain Honcho/PostgreSQL data.

The Obsidian GUI is a browser-accessed desktop container. It has a terminal with passwordless `sudo` **inside the container**, so it is deliberately isolated from the Honcho network and mounts only the vault and its own configuration directory. It must never receive the Docker socket, host root, the Hermes home, or Honcho secrets.

## Local validation

```bash
cd ~/Projects/honcho-hermes-stack
python3 scripts/init-vault.py --vault "$PWD/runtime/vault"
docker compose -f compose.obsidian.yaml config --quiet
docker compose -f compose.obsidian.yaml up -d
open https://localhost:3001
```

Accept the container's self-signed HTTPS certificate only for this localhost validation. In the GUI, open `/vault` as the vault folder.

## Ubuntu access through SSH only

Keep the service bound to `127.0.0.1:3001`; do not publish it to the LAN or Internet. From the Mac:

```bash
ssh -N -L 3001:127.0.0.1:3001 giovanni@192.168.1.132
```

Then browse to `https://localhost:3001` and open `/vault`.

## Syncthing vault sync

Syncthing syncs the `/srv/hermes/vault` files to a local Mac vault; it does not need or use Obsidian Sync. Pair only explicitly approved device IDs. The server Syncthing UI stays on localhost via SSH forwarding:

```bash
ssh -N -L 8384:127.0.0.1:8384 giovanni@192.168.1.132
```

Before pairing, configure Syncthing GUI authentication. Sync the vault root but ignore device-local UI state:

```text
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.trash/
```

Do not ignore `.obsidian/` wholesale: selected plugins, themes and core vault settings may be intentionally shared later. Resolve conflicts deliberately—Obsidian Markdown is not a collaborative real-time editor.
