---
name: repository-documentation
description: "Use as the final orchestrator step after code is verified."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [documentation, orchestration, markdown, git, obsidian, copilot]
    related_skills: [docs-merge-conflict-resolver]
---

# Repository Documentation

## When to use

Use this skill as the final stage of an implementation orchestrator, after code/configuration changes and their verification are complete but before declaring the task finished.

The repository's `docs/` folder is authoritative. Obsidian is an optional interface over the same files and must not become a second source of truth.

## Inputs

Read all of the following before editing documentation:

1. the human-approved `plan.md`;
2. the final code/configuration diff;
3. actual test, build, migration, and validation results;
4. relevant existing docs, ADRs, and repository instructions;
5. linked work-item acceptance criteria when available.

Treat the plan as intent, not proof. Document the final verified implementation.

## Documentation delta classification

Classify the change into zero or more categories:

- **Behavior / vertical slice** → update `docs/features/`.
- **Architecture or consequential trade-off** → update `docs/architecture/` and add/supersede an ADR when warranted.
- **Developer/operator task** → update `docs/how-to/`.
- **API/configuration/schema/contract** → update `docs/reference/`.
- **Deploy/monitor/rollback/recovery** → update `docs/operations/`.
- **Useful out-of-scope finding** → add a structured item to `docs/inbox/`.
- **No durable impact** → make no docs edit and state the evidence-based reason in the completion report.

Do not create every document for every change. Prefer the smallest edit to the existing authoritative page.

## Procedure

1. Read `docs/README.md`, `docs/AGENTS.md`, and the relevant pages.
2. Compare the approved plan to the final diff and verification output; note deviations.
3. Update current-state documentation. Remove or correct statements made false by the implementation.
4. Link to source paths, tests, ADRs, and operations guidance where that improves traceability.
5. Create an ADR only when a decision has meaningful alternatives and lasting consequences.
6. Capture unapproved findings in the inbox without implementing them or silently expanding scope.
7. Validate relative links, frontmatter, heading structure, commands, conflict markers, and sensitive data.
8. Report changed documentation paths, what was verified, and any intentional no-op.

## Writing rules

- Use concise, human-readable GitHub-flavored Markdown.
- Use normal relative Markdown links, not Obsidian-only wikilinks, for repository docs.
- Describe supported behavior and responsibility boundaries, not a line-by-line code narration.
- Do not paste raw logs, chats, prompts, generated reasoning, or large code blocks.
- Do not claim a command works unless it was safely executed; otherwise label it as an unverified example.
- Never include secrets, credentials, private keys, unredacted customer data, or sensitive production values.
- Update `last_verified` only after checking the page against code or a working system.

## Completion gate

Do not declare documentation complete until:

- the docs match the final implementation and verification evidence;
- affected behavior, contracts, architecture, and operations are covered where relevant;
- links resolve and no conflict markers remain;
- no duplicate source of truth was created;
- any out-of-scope item is structured and awaits human triage;
- documentation and code are in the same Git review unit.
