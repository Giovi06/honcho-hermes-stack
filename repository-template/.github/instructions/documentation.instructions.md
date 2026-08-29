---
applyTo: "docs/**/*.md"
---

# Repository documentation instructions

- Treat `docs/` as the canonical human-readable documentation for this repository.
- Use GitHub-flavored Markdown, YAML frontmatter, and relative Markdown links. Do not require Obsidian-only wikilinks, embeds, or plugins for essential content.
- Derive documentation from the final implemented and verified state, not solely from `plan.md`.
- Update the smallest relevant existing page. Avoid duplicate feature, architecture, reference, and operations descriptions.
- Describe current behavior and boundaries; do not create implementation diaries or paste raw agent transcripts.
- Add an ADR only for consequential decisions with meaningful alternatives.
- Put useful out-of-scope ideas, evidenced legacy/debt findings, open questions, and documentation gaps in `docs/inbox/` using its template.
- Link to source paths and tests where useful. Never include secrets, credentials, private keys, unredacted customer data, or sensitive production values.
- Validate links, headings, frontmatter, commands, and conflict markers before completing the change.
