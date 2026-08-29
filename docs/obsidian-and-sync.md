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
open https://localhost:18401
```

Accept the container's self-signed HTTPS certificate only for this localhost validation. In the GUI, open `/vault` as the vault folder.

## Ubuntu access through SSH only

The server uses the dedicated `18400–18411` range. Keep Obsidian bound to `127.0.0.1:18401`; do not publish it directly to the LAN or Internet. From the Mac:

```bash
ssh -N -L 18401:127.0.0.1:18401 giovanni@192.168.1.132
```

Then browse to `https://localhost:18401` and open `/vault`.

## Syncthing vault sync

Syncthing syncs the `/srv/hermes/vault` files to a local Mac vault; it does not need or use Obsidian Sync. Pair only explicitly approved device IDs. The server Syncthing UI stays on localhost via SSH forwarding:

```bash
ssh -N -L 18402:127.0.0.1:18402 giovanni@192.168.1.132
```

Before pairing, configure Syncthing GUI authentication. Then configure the Mac device with the server's manual peer address `tcp://192.168.1.132:18403`; LAN discovery UDP/21027 is intentionally not published. Sync the vault root but ignore device-local UI state:

```text
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.trash/
```

Do not ignore `.obsidian/` wholesale: selected plugins, themes and core vault settings may be intentionally shared later. Resolve conflicts deliberately—Obsidian Markdown is not a collaborative real-time editor.

## Repository documentation at work

Keep company repository documentation in each repository's `docs/` folder and synchronize it with the company's normal Git remote. Do not copy it into this personal/server vault or synchronize it through this Syncthing deployment unless company policy explicitly approves that data flow.

For the proof of concept, a developer can use Obsidian's **Open folder as vault** action on a repository's `docs/` directory. Obsidian supports multiple vaults, so each repository can remain isolated while using the same installed application. The repository template ignores `.obsidian/` because vault registration, workspace layout, recent files, and plugin state are machine-local. Essential repository documentation must remain readable in GitHub and VS Code without Obsidian.

See [Repository documentation proof of concept](repository-documentation-poc.md) for the recommended structure, orchestrator stage, GitHub Copilot integration, and conflict policy.
