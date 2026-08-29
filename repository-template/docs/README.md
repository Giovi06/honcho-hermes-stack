---
type: documentation-index
status: current
owners: []
last_verified: "YYYY-MM-DD"
---

# Repository documentation

This folder is the canonical human-readable documentation for this repository. Documentation changes are reviewed and versioned with the code they describe. Obsidian may be used as an optional local interface; it is not required to read or maintain these files.

## Start here

- [Architecture](architecture/README.md) — system context, boundaries, and decisions
- [Features](features/README.md) — behavior and vertical-slice documentation
- [How-to guides](how-to/README.md) — task-oriented developer and operator guidance
- [Reference](reference/README.md) — APIs, configuration, schemas, and conventions
- [Operations](operations/README.md) — deployment, monitoring, recovery, and troubleshooting
- [Inbox](inbox/README.md) — temporary triage for ideas, debt discoveries, open questions, and documentation gaps

## Contribution rules

1. Describe current, verified behavior—not the intended plan or implementation history.
2. Update the smallest authoritative page in the same change as affected code.
3. Use relative Markdown links so content works in GitHub, VS Code, and Obsidian.
4. Link to source paths instead of duplicating large code excerpts.
5. Update `last_verified` only when the page has actually been checked against code or a working system.
6. Do not store secrets, credentials, private keys, unredacted customer data, or production connection strings.
7. Follow [AGENTS.md](AGENTS.md) for automated documentation work.
