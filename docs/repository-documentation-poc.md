# Repository documentation proof of concept

## Decision summary

Use **`docs/`** (plural) as the canonical documentation directory in every code repository.

The repository remains the source of truth. Git versions code and documentation in the same branch and pull request. Obsidian is an optional local reader/editor for those Markdown files, not a required runtime, a second copy, or a synchronization layer.

This keeps the workflow usable in GitHub, VS Code, GitHub Copilot, command-line tools, and any Markdown renderer even if Obsidian is not approved or installed.

## Why `docs/` instead of `doc/`

There is no universal standard, but `docs/` is the stronger convention:

- GitHub Pages explicitly supports a repository's `/docs` folder as a publishing source.
- Many documentation generators and repositories use `docs/` by convention.
- The plural accurately describes a collection of documents.
- New contributors and tooling are more likely to discover it without configuration.

Use lowercase `docs/` consistently. Do not allow both `doc/` and `docs/` in the same organization.

## Source-of-truth boundaries

| Information | Canonical location | Purpose |
| --- | --- | --- |
| Current behavior, architecture, operations, and technical reference | Repository `docs/` | Durable documentation reviewed with code |
| Implementation intent and human approval | Orchestrator `plan.md` | Task-scoped contract; not a substitute for final documentation |
| Accepted future work | Team work-item tracker | Ownership, priority, scheduling, and reporting |
| Untriaged ideas, debt discoveries, and documentation gaps | `docs/inbox/` | Temporary, reviewable capture before disposition |
| Conversational or personal memory | Approved memory system | Recall; never the authoritative description of code |

Do not copy repository documentation into a separate central vault. Copies drift and make conflict ownership unclear.

## Proposed repository layout

```text
repository/
├── .github/
│   ├── copilot-instructions.md
│   └── instructions/
│       └── documentation.instructions.md
├── docs/
│   ├── README.md
│   ├── AGENTS.md
│   ├── architecture/
│   │   ├── README.md
│   │   └── adr/
│   │       ├── README.md
│   │       └── 0000-template.md
│   ├── features/
│   │   ├── README.md
│   │   └── _template.md
│   ├── how-to/
│   │   ├── README.md
│   │   └── _template.md
│   ├── reference/
│   │   └── README.md
│   ├── operations/
│   │   ├── README.md
│   │   └── _template.md
│   └── inbox/
│       ├── README.md
│       └── _template.md
└── source code
```

This is deliberately small. It borrows the user-needs distinction from [Diátaxis](https://diataxis.fr/) without forcing every repository to create empty tutorial, how-to, reference, and explanation trees.

- `features/` describes behavior and vertical slices.
- `architecture/` explains system boundaries; `adr/` records consequential decisions.
- `how-to/` contains task-oriented developer or operator instructions.
- `reference/` contains facts such as APIs, configuration, schemas, and conventions.
- `operations/` contains deploy, rollback, monitoring, recovery, and troubleshooting procedures.
- `inbox/` temporarily captures useful findings outside the approved implementation scope.

Folders should be created only when needed. Empty template folders in this proof of concept demonstrate the target structure.

## Markdown portability rules

Repository documentation is **GitHub-flavored Markdown first and Obsidian-compatible second**.

1. Use normal relative Markdown links (for example, link text `Architecture` targeting `architecture/README.md`) rather than `[[wikilinks]]`.
2. Use YAML frontmatter only for small, stable metadata that humans and tools can maintain.
3. Link to source paths and symbols instead of duplicating large code excerpts.
4. Use Mermaid only if every required review and publishing surface supports it.
5. Do not depend on community plugins, Dataview queries, or Obsidian-only embeds for essential content.
6. Never store secrets, credentials, private keys, unredacted customer data, or production connection strings.

## Orchestrator documentation stage

The documentation stage runs after implementation and verification, but before the task is declared complete.

### Inputs

- the human-approved `plan.md`;
- the final code and configuration diff;
- test/build/validation results;
- existing repository documentation;
- accepted ADRs and repository instructions.

### Procedure

1. **Inspect, do not assume.** Read the final diff and relevant existing docs. The plan describes intent; the implementation and verification results describe reality.
2. **Classify the documentation delta.** Decide whether the change affects behavior, architecture, operations, reference material, or no durable documentation.
3. **Update the smallest authoritative set.** Prefer editing an existing page over creating a near-duplicate. Create a feature page only when it improves discoverability.
4. **Record decisions separately.** Add an ADR only for consequential choices with meaningful alternatives. Do not create an ADR for routine implementation details.
5. **Capture out-of-scope findings carefully.** Add a structured inbox item for a useful idea, legacy/debt finding, missing documentation, or follow-up that was not approved in the current plan. Link a tracker item once one exists.
6. **Validate.** Check links, headings, frontmatter, conflict markers, sensitive data, and consistency with the implemented code.
7. **Report the documentation delta.** The completion summary states which docs changed or explicitly says why no durable docs change was needed.

### Completion gate

The stage passes only when:

- docs describe the current implemented state rather than planned or historical state;
- commands and operational procedures were verified or clearly marked as unverified examples;
- links resolve within the repository;
- no unresolved merge markers remain;
- no sensitive data was introduced;
- changed code paths are traceable from the relevant feature/reference/operations page when that traceability is useful;
- the code and documentation are included in the same review unit.

A no-op documentation result is valid for changes such as internal refactoring with no observable, architectural, operational, or reference impact, but the orchestrator must state the reason.

## Inbox lifecycle

`docs/inbox/` is not a second backlog and not a place for agent transcripts.

Appropriate items include:

- a future improvement discovered while implementing another slice;
- legacy behavior or technical debt with concrete evidence;
- an unclear invariant or open architecture question;
- a documentation gap;
- a potentially useful idea that needs human triage.

Each item must state evidence, impact, proposed next step, and disposition. During triage, the team either:

1. rejects and removes/archives it with a reason;
2. resolves it in documentation;
3. promotes it to the work-item tracker and records the link;
4. accepts a decision and records an ADR.

Stale inbox items are a process failure. Assign a review cadence and ownership during the proof of concept.

## Obsidian adoption model

Obsidian supports opening an existing folder as a vault and managing multiple vaults. Its current license permits free personal, commercial, and non-profit use; the optional Commercial license is a support purchase rather than a commercial-use requirement. The organization's normal software approval, security review, plugin policy, and data-handling rules still apply.

For the proof of concept, open each repository's `docs/` directory as a separate vault. This avoids indexing source trees and dependency folders and prevents collisions between common filenames such as `README.md`. Keep Obsidian in restricted mode with no community plugins unless they are separately approved, and use the company's Git remote rather than Obsidian Sync or Publish.

The `.obsidian/` directory is local UI state and is ignored by the template. Do not version a developer's workspace layout, recent files, plugin state, or absolute paths. If the guild later approves shared settings, allowlist specific reviewed configuration files rather than committing the whole directory.

Vault registration is machine-local and uses local paths, so a repository config file should not try to register every developer's vault automatically. Onboarding is a one-time **Open folder as vault** action. Automation can be evaluated later, but it must remain optional.

> [!IMPORTANT]
> Company repository documentation must remain in company-approved storage. Do not synchronize work repositories into a personal Obsidian vault, personal Git remote, Syncthing instance, or self-hosted server unless the employer explicitly approves that data flow.

## Git and merge conflicts

Documentation changes use the normal branch and pull-request workflow. Prefer small, topical pages over shared append-only logs because large shared files create unnecessary conflicts.

The `docs-merge-conflict-resolver` skill in this repository performs a semantic three-way merge. It must not use last-writer-wins. Contradictory accepted decisions, security statements, operational commands, or delete-versus-substantive-edit conflicts require human review.

## GitHub Copilot integration

GitHub Copilot supports:

- repository-wide `.github/copilot-instructions.md` instructions, including Copilot in VS Code;
- path-specific `.github/instructions/NAME.instructions.md` instructions, currently limited by GitHub to Copilot cloud agent and Copilot code review;
- nearest-scope `AGENTS.md` files for agent surfaces that support agent instructions.

This proof of concept includes all three layers. The repository-wide file makes the final documentation stage visible in the VS Code workflow; the path-specific file adds focused rules to supported review/cloud-agent work; `docs/AGENTS.md` scopes instructions to agents working below `docs/`.

The proof of concept deliberately ships **templates, not an automated copier**. Repository bootstrapping is a reviewed Git change: copy only the required files from `repository-template/`, preserve existing `docs/` and `.github/copilot-instructions.md`, and merge the **Documentation completion** section deliberately when repository-wide Copilot instructions already exist. This avoids turning a documentation convention into a cross-platform filesystem-mutating tool and keeps every adoption decision visible in the repository pull request.

## Proof-of-concept rollout

1. Select one representative repository with active vertical-slice work.
2. Add the required `repository-template/` files in a dedicated pull request; preserve existing documentation and manually merge any existing Copilot instructions.
3. Add repository-specific owners and links to `docs/README.md`.
4. Open that repository's `docs/` folder as a local Obsidian vault for volunteers.
5. Make the orchestrator's documentation stage use the `repository-documentation` skill.
6. Measure over several pull requests:
   - docs updated when behavior changed;
   - reviewer corrections required;
   - broken links or stale statements;
   - merge-conflict frequency and resolution time;
   - inbox promotion/closure time;
   - developer usefulness with and without Obsidian.
7. Present evidence and policy questions to the technical governance body before organization-wide installation or plugin standardization.

## References

- [GitHub: adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)
- [GitHub Pages: configuring a publishing source](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [Obsidian: license overview](https://obsidian.md/license)
- [Obsidian Help: create a vault](https://help.obsidian.md/vault)
- [Obsidian Help: manage vaults](https://help.obsidian.md/manage-vaults)
- [Diátaxis documentation framework](https://diataxis.fr/)
