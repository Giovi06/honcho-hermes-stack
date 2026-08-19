# Obsidian Knowledge Vault + Hermes Implementation Plan

> **For Hermes:** Execute this plan task-by-task, preserving the security boundaries and validating each milestone before deploying to the Ubuntu host.

**Goal:** Add a self-hosted Obsidian browser UI and a filesystem-first Markdown vault to the Hermes/Honcho deployment, so curated project architecture, decisions, observations, runbooks, and personal documentation persist as human-readable notes.

**Architecture:** The Obsidian vault is an owner-controlled host directory, not a Docker volume or a database. The restricted `hermes` Linux user writes Markdown directly to that directory; the Obsidian GUI container mounts the same directory and is isolated from the Honcho/Hermes network. Honcho remains the cross-session conversational/user-model memory; Obsidian becomes the curated, inspectable knowledge base and documentation system.

**Tech Stack:** Docker Compose; `lscr.io/linuxserver/obsidian`; Markdown/Obsidian wikilinks; Linux UID/GID permissions; dedicated Docker networks; Tailscale or SSH tunneling initially; existing Honcho + PostgreSQL/pgvector + Redis + Ollama stack.

---

## 1. Requirements and decisions

### Accepted requirements

1. Obsidian must be accessible from a browser on the headless Ubuntu server.
2. Markdown files must remain directly available on the host filesystem.
3. Hermes must be able to create/read/update the vault without GUI automation.
4. Every meaningful project started with Hermes should have durable, human-readable documentation:
   - project overview and scope;
   - architecture;
   - decisions and rationale;
   - implementation observations / discoveries;
   - runbooks / operational notes;
   - curated hand-off summary.
5. Giovanni must be able to inspect or edit the same data through the Obsidian UI.
6. Honcho must remain the long-term conversational memory system, not be replaced by the vault.
7. Hermes on the Ubuntu host must run as a restricted non-root user. It must not receive passwordless `sudo` or Docker group access.

### Explicit non-goals for phase 1

- Do not expose the Obsidian GUI directly to the public Internet.
- Do not use a Docker socket in the Obsidian container.
- Do not use the Obsidian container as Hermes’ execution environment.
- Do not automatically archive raw chat transcripts or credentials into Markdown.
- Do not run full Supabase.
- Do not implement multi-user collaborative editing, mobile sync, a public knowledge portal, or a Git-based automated commit bot yet.

### Core decision: two complementary memory layers

| Layer | System | Purpose | Data form |
|---|---|---|---|
| Conversation/user memory | Honcho | Semantic recall, user modeling, derived conclusions, session continuity | PostgreSQL + pgvector |
| Curated project knowledge | Obsidian vault | Architecture, decisions, runbooks, project status, human-readable notes | Markdown files |

The agent must use Honcho for recall/search across conversations and the vault for authoritative project documentation. A note may link to a project or decision; it must not claim to be a complete replica of Honcho.

---

## 2. Security architecture

### 2.1 Linux identities

Create a dedicated service account on Ubuntu:

- account: `hermes`
- home: `/srv/hermes/home`
- shell: `/usr/sbin/nologin` by default; grant a controlled shell only if interactive CLI maintenance requires it
- no `sudo`
- not in the `docker` group
- no ownership of `/srv/honcho` secrets, host SSH private keys, or system configuration

Create a dedicated shared vault group:

- group: `hermes-vault`
- vault path: `/srv/hermes/vault`
- group-write permissions through setgid directories
- only Giovanni’s administrator account, the restricted Hermes account, and the Obsidian container’s mapped UID/GID may read/write it

**Principle:** file permissions are the primary boundary. The agent gets access only to its dedicated working roots plus the vault—not broad host-root access.

### 2.2 Docker isolation

Create two independent networks:

- `honcho-net` — internal-only: `api`, `deriver`, `database`, `redis`, `ollama`.
- `obsidian-ui-net` — Obsidian GUI only.

Do **not** attach Obsidian to `honcho-net`. Do not mount `/var/run/docker.sock`, `/`, `$HOME`, or the Hermes home directory in the Obsidian container.

The LinuxServer Obsidian image provides a GUI terminal with passwordless sudo **inside its container**, so the container must be treated as a browser-accessible privileged application boundary. Its only writable host mounts must be:

- `/vault` → `/srv/hermes/vault`
- `/config` → `/srv/obsidian/config`

### 2.3 Remote access policy

Phase 1 exposes Obsidian only on `127.0.0.1:<port>`. Access it via one of:

1. **Recommended:** Tailscale with ACLs, HTTPS and device identity.
2. SSH local forwarding: `ssh -L <local-port>:127.0.0.1:<server-port> <server>`.

Do not configure public port forwarding or an unauthenticated reverse proxy. If a public domain is later needed, add Caddy/reverse-proxy authentication, TLS, rate limits, and a separate threat-model review first.

---

## 3. Vault information architecture

Create this structure at `/srv/hermes/vault`:

```text
00 Inbox/
01 Projects/
  <project-slug>/
    Project.md
    Architecture.md
    Decisions.md
    Observations.md
    Runbook.md
    Status.md
02 Areas/
  Infrastructure/
  Personal/
  Learning/
03 Reference/
04 Operations/
  Backups.md
  Security.md
  Services.md
90 Archive/
_templates/
  Project.md
  Architecture.md
  Decision.md
  Observation.md
  Runbook.md
  Status.md
README.md
```

### Project-note contract

`01 Projects/<slug>/Project.md` is the project index and must contain YAML frontmatter:

```yaml
---
type: project
status: active
created: YYYY-MM-DD
owner: Giovanni
related_services: []
---
```

It links to `[[Architecture]]`, `[[Decisions]]`, `[[Observations]]`, `[[Runbook]]`, and `[[Status]]`.

The agent must create a project folder only after the project has a clear title/scope. Before that, it may record material in `00 Inbox/`.

### Documentation/write policy for Hermes

When a project begins or materially changes, Hermes must:

1. Create/update the project index with goal, scope, constraints, repository/path, and current status.
2. Document architectural decisions with rationale and rejected alternatives.
3. Append important implementation discoveries, blockers, and verification evidence to `Observations.md`.
4. Record any deployment/backup/security procedure in `Runbook.md`.
5. Add Obsidian wikilinks rather than duplicating facts across files.
6. Never write secrets, auth tokens, database passwords, private keys, or unredacted customer data to the vault.
7. Write concise curated conclusions—not raw tool logs or a full transcript.

---

## 4. Deployment implementation tasks

### Task 1: Inventory the Ubuntu host before changing it

**Objective:** Establish the actual server user, Docker state, current service topology, storage path, SSH access model and Tailscale availability.

**Files:**
- Create: `docs/ubuntu-host-readiness.md`

**Read-only commands to run once access is supplied:**

```bash
id
uname -a
lsb_release -a || cat /etc/os-release
getent group docker
systemctl is-active docker
systemctl is-active tailscaled || true
docker version
docker compose version
df -h /srv /var/lib/docker
free -h
```

**Acceptance criteria:** Exact non-root deployment user, persistent storage root, Docker availability and remote-access approach are known before mutations.

---

### Task 2: Create restricted OS ownership and storage roots

**Objective:** Establish a narrow least-privilege identity and persistent directory structure.

**Files:**
- Create: `/srv/hermes/home/`
- Create: `/srv/hermes/vault/`
- Create: `/srv/obsidian/config/`
- Create: `/srv/honcho/`
- Create: `docs/permissions.md`

**Implementation commands (adapt UID/GID after Task 1):**

```bash
sudo groupadd --system hermes-vault
sudo useradd --system --create-home --home-dir /srv/hermes/home \
  --shell /usr/sbin/nologin --groups hermes-vault hermes
sudo install -d -o hermes -g hermes-vault -m 2770 /srv/hermes/vault
sudo install -d -o root -g root -m 0750 /srv/obsidian/config /srv/honcho
```

**Verification:**

```bash
sudo -u hermes test -w /srv/hermes/vault
sudo -u hermes test ! -w /srv/honcho
sudo -u hermes sudo -n true; test $? -ne 0
```

**Acceptance criteria:** Hermes can write only its vault and explicitly granted workspaces; it cannot use sudo, Docker, or Honcho secrets.

---

### Task 3: Create the vault skeleton and note templates

**Objective:** Make the Markdown information architecture available before the Obsidian UI exists.

**Files:**
- Create: `vault/README.md`
- Create: `vault/_templates/Project.md`
- Create: `vault/_templates/Architecture.md`
- Create: `vault/_templates/Decision.md`
- Create: `vault/_templates/Observation.md`
- Create: `vault/_templates/Runbook.md`
- Create: `vault/_templates/Status.md`
- Create: empty folder tree listed in section 3

**Template criteria:** Include frontmatter (`type`, `created`, `status`, `tags`) and concise sections; templates must have no credentials or customer data.

**Verification:**

```bash
sudo -u hermes find /srv/hermes/vault -type f -name '*.md' -print
sudo -u hermes test -w /srv/hermes/vault/_templates/Project.md
```

---

### Task 4: Add Obsidian UI as an isolated Compose override

**Objective:** Run the supported LinuxServer Obsidian GUI container without granting access to Honcho services or the Docker host.

**Files:**
- Create: `compose.obsidian.yaml`
- Modify: `.env.example`
- Modify: `README.md`
- Create: `docs/obsidian-ui.md`

**Compose shape:**

```yaml
services:
  obsidian:
    image: lscr.io/linuxserver/obsidian:<reviewed-pinned-tag>
    environment:
      PUID: "${OBSIDIAN_PUID}"
      PGID: "${OBSIDIAN_PGID}"
      TZ: "Europe/Zurich"
    volumes:
      - ${OBSIDIAN_VAULT_PATH}:/vault:rw
      - ${OBSIDIAN_CONFIG_PATH}:/config:rw
    ports:
      - "127.0.0.1:${OBSIDIAN_HTTPS_PORT}:3001"
    networks:
      - obsidian-ui-net
    shm_size: "1gb"
    restart: unless-stopped

networks:
  obsidian-ui-net:
    internal: true
```

**Mandatory exclusions:** No `privileged`, no Docker socket, no `network_mode: host`, no mount of `/`, `$HOME`, `/srv/honcho`, `/srv/hermes/home`, or SSH keys.

**Verification:**

```bash
docker compose -f compose.yaml -f compose.obsidian.yaml config --quiet
docker compose -f compose.yaml -f compose.obsidian.yaml up -d obsidian
docker compose ps obsidian
curl -kI https://127.0.0.1:${OBSIDIAN_HTTPS_PORT}/
```

Open the GUI through a tunnel/Tailscale, select `/vault` as the vault root and verify a test Markdown note appears. Delete the test note afterward.

---

### Task 5: Wire Hermes to the shared vault safely

**Objective:** Give the restricted Hermes process a single resolved vault path and a repeatable documentation workflow.

**Files:**
- Create: `/srv/hermes/home/.config/hermes/obsidian.env` or secure systemd environment configuration
- Create: `skills/project-knowledge-base/SKILL.md` in the Hermes profile
- Create: `docs/hermes-vault-workflow.md`

**Configuration:**

```dotenv
OBSIDIAN_VAULT_PATH=/srv/hermes/vault
```

Do not put a non-secret path into a shared secret file without considering service ownership. For a systemd-managed Hermes process, use `EnvironmentFile=` owned by root and readable only by the Hermes service account.

**Skill behavior:** The `project-knowledge-base` skill should be loaded whenever Hermes starts/plans/modifies a project. It must follow the documentation/write policy in section 3 and use filesystem note tools, not GUI clicks.

**Verification:** Run Hermes as the `hermes` Unix user and request a test project brief; prove only files under `/srv/hermes/vault/01 Projects/<slug>/` are created.

---

### Task 6: Integrate vault lifecycle with project work

**Objective:** Make documentation habitual and inspectable, without pretending that it is an automatic replacement for Honcho.

**Files:**
- Modify: `skills/project-knowledge-base/SKILL.md`
- Create: `vault/04 Operations/Knowledge-base-policy.md`

**Workflow:**

1. Start project → create `Project.md`, `Architecture.md`, `Decisions.md`, `Status.md`.
2. Make architectural decision → append decision record and link it from project index.
3. Discover noteworthy implementation fact → append a concise observation with evidence/source.
4. Finish milestone → update status and hand-off/runbook.
5. On restart/new session → read the project index and status note before acting.
6. Use Honcho for cross-session personal/conversation recall; use the vault for project documentation.

**Acceptance criteria:** A newly started project can be opened in Obsidian and understood by Giovanni without reading a chat transcript.

---

### Task 7: Backups, restore check and retention

**Objective:** Protect both durable but different data stores.

**Files:**
- Create: `scripts/backup-vault.sh`
- Create: `scripts/restore-vault-check.sh`
- Modify: `scripts/backup-honcho.sh` or existing backup documentation
- Create: `docs/backups.md`

**Requirements:**

- Back up `/srv/hermes/vault` as files, preserving owner/mode/timestamps.
- Back up Honcho PostgreSQL with `pg_dump` separately.
- Store encrypted copies off-device.
- Test restoration into a non-production temporary directory/database.
- Do not rely on Docker volumes as a backup strategy.

**Acceptance criteria:** A documented and actually tested restore of both a vault note and the Honcho database exists.

---

### Task 8: Harden and operationalize before using it as a daily service

**Objective:** Ensure restarts, upgrades, service failure and remote access are safe.

**Files:**
- Create: `compose.production.yaml` only after a specific host review
- Create: `docs/security.md`
- Create: `docs/operations.md`

**Checklist:**

- [ ] Services start after host reboot.
- [ ] All secret files are mode `0600`, excluded from Git.
- [ ] Obsidian GUI remains localhost/Tailscale-only.
- [ ] Honcho API uses authentication before any non-local connection is allowed.
- [ ] Obsidian never shares Docker network with database/Redis/Honcho.
- [ ] Image versions are pinned/reviewed; unattended automatic image upgrades are disabled.
- [ ] `docker compose logs` and health checks are documented.
- [ ] CPU/RAM use is observed during an Ollama Deriver run.
- [ ] Backup and restore test is recorded.

---

## 5. Expected file changes in the existing deployment repository

```text
honcho-hermes-stack/
├── compose.yaml                         # Honcho stack; no Obsidian dependency
├── compose.ollama.yaml                  # Internal Ollama profile
├── compose.obsidian.yaml                # New isolated Obsidian UI profile
├── .env.example                         # Obsidian UID/GID/path/port placeholders
├── README.md                             # Compose combinations + security posture
├── docs/
│   ├── ubuntu-host-readiness.md
│   ├── permissions.md
│   ├── obsidian-ui.md
│   ├── hermes-vault-workflow.md
│   ├── knowledge-base-policy.md
│   ├── backups.md
│   ├── security.md
│   └── operations.md
├── scripts/
│   ├── backup-vault.sh
│   └── restore-vault-check.sh
└── .hermes/plans/
    └── 2026-08-19_144138-obsidian-knowledge-vault.md
```

The actual vault is deliberately outside the Git deployment repository on the server: `/srv/hermes/vault`. Its backup/versioning policy is separate from infrastructure Git history.

---

## 6. Risks, trade-offs and open questions

| Topic | Risk / trade-off | Decision for phase 1 |
|---|---|---|
| Obsidian browser GUI | It is a full remote desktop-style app with a terminal in the container | Restrict to localhost/Tailscale; isolate network and mounts |
| Concurrent edit conflicts | Hermes and Giovanni may edit one Markdown file simultaneously | Keep notes small; avoid simultaneous edits; later add Git/Syncthing only after need is proven |
| Untrusted input | Web/chat content can attempt to influence generated notes | Treat external content as data; record only curated conclusions |
| Vault privacy | Notes may contain sensitive personal/business context | Least privilege, encrypted backup, no public exposure |
| Honcho vs. vault duplication | Two systems can drift | Define roles: Honcho = conversational recall, vault = authoritative curated docs |
| Limited Hermes user | Limits direct server maintenance ability | Use explicit administrator-operated deployment/runbook paths; do not grant root by default |
| VM with agent root | Stronger agent freedom but bigger attack blast radius | Defer until the restricted-user deployment proves too limiting; use VM/snapshots if adopted |

### Questions to resolve immediately before server execution

1. Does the Ubuntu server already have Tailscale, a domain/reverse proxy, or only SSH access?
2. Which administrator account and UID/GID should own `/srv/hermes/vault`?
3. Does Giovanni want the vault also synchronized to the Mac Obsidian desktop later, or is browser access sufficient for phase 1?
4. Should a customer/company deployment receive one vault per tenant/user, or is this first design strictly single-user?

---

## 7. Definition of done

The phase-1 solution is complete only when all are true:

1. A restricted non-root `hermes` account runs Hermes and can write only to designated working roots and `/srv/hermes/vault`.
2. Obsidian opens the same vault through a browser over a private connection.
3. A Hermes-created project has an Obsidian-visible index, architecture, decisions, observations and status notes.
4. Honcho remains functional and separate, with PostgreSQL/pgvector and Redis inaccessible to the Obsidian container.
5. Vault and Honcho database backups both complete and a restore test is documented.
6. No secret, Docker socket, host root path, or Honcho credential is available to the Obsidian GUI container.
