# Self-hosted Honcho memory for Hermes

A reproducible, **pinned** self-hosted Honcho deployment for Hermes Agent:

- Honcho API and Deriver worker built from upstream `plastic-labs/honcho` **v3.0.12** (Git submodule)
- PostgreSQL 15 with `pgvector`, persistent named volume
- Redis with AOF persistence, persistent named volume
- localhost-only host ports by default
- free local inference using Ollama (no LMM SaaS subscription or API key)

> [!IMPORTANT]
> Honcho does **not** need the full Supabase stack. It only requires PostgreSQL with the pgvector extension. Running Supabase Auth, Storage, Studio, Realtime, etc. provides no benefit for this integration and needlessly consumes resources.

## Architecture

```text
Hermes Agent ──HTTP──> Honcho API ──> PostgreSQL + pgvector (durable memory)
                         │
                         ├──────> Redis (cache/locks)
                         └──────> Ollama OpenAI-compatible API (local inference)
                                      ├── Qwen3 4B: tool-capable reasoning/extraction
                                      └── nomic-embed-text: 768-dimension embeddings
```

Honcho's API and database bind only to `127.0.0.1`. Do not publish port 8000 directly to the Internet. For remote Hermes, use a private overlay network (Tailscale) or an SSH tunnel; add reverse-proxy TLS plus Honcho authentication only after the local proof-of-concept is successful.

## Mac validation (M1 Pro, 16 GB)

### 1. Prepare the deployment configuration

```bash
cd ~/Projects/honcho-hermes-stack
python3 scripts/bootstrap.py
```

This creates `.env` with a random database password and mode `0600`.

### 2. Use native Ollama for Metal acceleration

An Ollama container on macOS normally executes inside Docker's Linux VM and is not the appropriate default for Apple Metal acceleration. Install/start the native macOS application, then:

```bash
ollama serve                    # only if the app has not already started the local service
ollama pull qwen3:4b
ollama pull nomic-embed-text
curl http://127.0.0.1:11434/v1/models
```

`qwen3:4b` is the practical starter tier for this 16 GB laptop. It supports tool calling. `nomic-embed-text` supplies 768-dimensional embeddings. Do not change either model without also reviewing the embedding dimension and reinitializing the vector data.

### 3. Build and run

```bash
docker compose up -d --build
docker compose ps
./scripts/verify.sh
```

The initial Honcho build compiles dependencies and can take several minutes. Subsequent starts use Docker cache.

### 4. Connect Hermes

```bash
hermes memory setup honcho
```

Use `http://localhost:8000` as the self-hosted base URL and leave the local token blank while `AUTH_USE_AUTH=false`. Then confirm with:

```bash
hermes memory status
```

Start a **new** Hermes session after setup. Tell it a unique preference, wait about a minute for the Deriver, then start another new session and ask what it knows about you. Inspect worker progress with:

```bash
docker compose logs --tail=100 deriver
```

## Ubuntu Server deployment

### Recommended first production-like mode: all containers

This starts the same Honcho stack and a containerized Ollama instance:

```bash
cd ~/honcho-hermes-stack
python3 scripts/bootstrap.py
# Edit .env: OLLAMA_BASE_URL=http://ollama:11434/v1
# Then:
docker compose -f compose.yaml -f compose.ollama.yaml up -d --build
```

The `ollama-models` one-shot service downloads the configured models into the `ollama-data` volume. Verify with `./scripts/verify.sh` and `docker compose logs deriver --tail=100`.

CPU-only inference is functional but can be slow. Before choosing a model for a server or customer, benchmark with its actual CPU/RAM/GPU. For NVIDIA hardware, add a separately reviewed GPU override; never assume GPU access is available inside Docker.

### Secure remote access

For a single private Hermes machine, retain localhost-only bindings and use SSH forwarding:

```bash
ssh -N -L 8000:127.0.0.1:8000 your-server
```

For a fleet/customer deployment, introduce a dedicated reverse proxy and enable `AUTH_USE_AUTH=true` with a unique `AUTH_JWT_SECRET`; issue least-privilege, revocable keys rather than sharing a broad bearer token. Put TLS, access control, backup/restore testing, monitoring and update policy in the product deployment design.

## Operations

```bash
# status / logs
docker compose ps
docker compose logs -f api deriver

# stop without deleting durable state
docker compose down

# backup (create the destination first; contains private conversation data)
mkdir -p backups
docker compose exec -T database pg_dump -U honcho honcho > "backups/honcho-$(date +%F).sql"

# restore — destructive to the target database; stop API/deriver first
docker compose stop api deriver
cat backups/honcho-YYYY-MM-DD.sql | docker compose exec -T database psql -U honcho -d honcho
```

## Updating Honcho deliberately

Do not track upstream `main` in a persistent/customer installation. The submodule pins the reviewed upstream version. Upgrade in a branch, run local validation and a backup/restore rehearsal, then commit the submodule pointer:

```bash
git -C honcho fetch --tags
git -C honcho checkout vX.Y.Z
# review release notes, rebuild, run ./scripts/verify.sh
git add honcho && git commit -m "chore: upgrade Honcho to vX.Y.Z"
```

A GitHub repository is useful for your **deployment configuration, documentation, CI validation and versioned submodule pointer**. Docker Hub is optional; it only saves build time. It does not remove the need to pin/review source, preserve database volumes, manage secrets outside Git, or run migrations/backups.

## Licensing note

Honcho is AGPL-3.0. If you distribute an image or provide it as a network service to customers, carefully review the AGPL obligations (including corresponding-source availability) with legal counsel. Keep the upstream submodule and notices intact. This repository contains deployment configuration; it is not a substitute for a commercial licensing review.
