# Knowledge Base Policy

## Hermes documentation contract

For every meaningful project, Hermes must:

1. Create/update `Project.md` with scope, constraints, repository/workspace and current status.
2. Record significant architecture choices in `Decisions.md`, including rationale and rejected alternatives.
3. Append verified discoveries, blockers and evidence to `Observations.md`.
4. Maintain `Runbook.md` for deploy, operation, backup and restore procedures.
5. Link related notes with Obsidian wikilinks.
6. Write concise, curated conclusions—not raw logs or full chat transcripts.

## Repository boundary

Current documentation about a codebase belongs in that repository's versioned `docs/` folder and must be reviewed with the code. This vault may hold personal project context and links, but it must not become a second copy of repository documentation. Company material must stay in company-approved storage and synchronization systems.

Repository docs use portable relative Markdown links so they remain readable in GitHub, VS Code and Obsidian. Obsidian-only wikilinks remain appropriate inside this personal vault.

## Data protection

Never store secrets, passwords, tokens, private keys, raw customer data, or unredacted connection strings.
