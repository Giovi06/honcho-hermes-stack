---
name: docs-merge-conflict-resolver
description: "Use for semantic three-way merges of repository Markdown docs."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [documentation, git, merge-conflicts, markdown, obsidian]
    related_skills: [repository-documentation]
---

# Documentation Merge Conflict Resolver

## Scope

Use this skill only for conflicted, human-readable documentation files and their small text metadata under `docs/` (Markdown, YAML, JSON used by docs tooling).

Do not use it to resolve source code, binaries, generated assets, database migrations, lock files, secrets, or Obsidian workspace/cache files. Stop and hand those files to the appropriate owner or resolver.

## Safety principles

- Perform a semantic three-way merge using base, ours, and theirs. Never use blanket `--ours`, `--theirs`, or last-writer-wins for the whole file.
- Preserve unique verified facts from both sides when they are compatible.
- Current-state pages must describe one coherent current state; do not concatenate contradictory versions.
- Accepted ADRs are historical records. Supersede decisions with a new ADR rather than rewriting accepted history.
- Do not invent evidence, commands, dates, owners, statuses, or decisions.
- Never preserve secrets or sensitive data merely because one side added them.

## Sensitive-material incident handling

If a credential, token, private key, connection string with credentials, customer data, or other sensitive material appears in base, ours, theirs, the working tree, or the staged diff:

1. Stop the merge immediately. Do not stage, commit, push, quote, or copy the sensitive value into notes or chat.
2. Notify the repository's security/incident owner through the approved channel and identify only the affected path and revision unless policy requires more.
3. Revoke or rotate exposed credentials; deleting the text is not sufficient.
4. Follow the organization's approved Git-history remediation and evidence-retention procedure for every affected local and remote ref.
5. Resume the documentation merge only after the incident owner confirms the containment and cleanup steps.

Do not silently omit a secret and continue. Exposure in either branch or Git history remains an incident even when the final merged file is clean. Before rendering conflicted content into a terminal, chat, or report, run the repository's approved secret scanner against the affected stages and refs with redacted or metadata-only output. If approved scanning is unavailable and sensitive material is suspected, stop and escalate rather than inspecting or reproducing the value.

## Procedure

1. Confirm the working tree and list unresolved files with `git status --short` and `git diff --name-only --diff-filter=U`.
2. Refuse or separate any conflict outside the documented scope.
3. For each documentation conflict, inspect:
   - base: `git show ':1:docs/path with spaces.md'`;
   - ours: `git show ':2:docs/path with spaces.md'`;
   - theirs: `git show ':3:docs/path with spaces.md'`;
   - relevant code, tests, ADRs, and nearby docs needed to establish current truth.

   Quote each complete stage specification as one shell argument. Substitute the literal repository-relative path without evaluating it as shell syntax.
4. Classify the page:
   - current-state feature/architecture/reference/operations page;
   - append-like inbox/index page;
   - immutable ADR or historical record;
   - generated documentation.
5. Merge by structure and meaning:
   - preserve compatible frontmatter keys explicitly;
   - deduplicate equivalent headings, links, list items, and facts;
   - keep relative links valid after renames;
   - order append-like entries deterministically by stable identifier/date, not by branch preference;
   - make current-state prose agree with the merged implementation.
6. Escalate instead of guessing when any of these occur:
   - contradictory accepted architecture/security/data decisions;
   - incompatible operational commands or rollback procedures;
   - delete-versus-substantive-edit with unclear intent;
   - conflicting ownership, status, or compliance statements;
   - generated output whose generator/source cannot be identified;
   - insufficient code or test evidence to establish current behavior.
7. Remove all conflict markers, stage only files actually resolved, and review the staged diff.
8. Run repository documentation validation and relevant tests/checks.
9. Hand the resolved documentation back to the `repository-documentation` completion gate when the merge changes current-state documentation, so it is checked against the final implementation and verification evidence.

## Validation

At minimum, verify:

```bash
git diff --check
git diff --cached --check
git diff --name-only --diff-filter=U
```

Also run the repository's Markdown linter, link checker, site build, or docs tests when present. Confirm that:

- no `<<<<<<<`, `=======`, or `>>>>>>>` markers remain;
- relative links and renamed targets resolve;
- YAML frontmatter remains parseable;
- headings are unique enough for stable anchors;
- code/commands and current-state claims match the merged implementation;
- no sensitive material was introduced.

A clean conflict-marker check is necessary but not sufficient. Report any human decision still required and do not mark the merge complete while unresolved meaning remains.
