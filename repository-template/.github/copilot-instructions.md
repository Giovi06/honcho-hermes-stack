# GitHub Copilot repository instructions

## Documentation completion

- Treat `docs/` as the canonical human-readable documentation for this repository.
- After implementing and verifying a code or configuration change, evaluate its documentation impact before declaring the task complete.
- Derive documentation from the final diff and real verification results, not solely from `plan.md`.
- Update the smallest relevant current-state page and keep documentation in the same pull request as affected code.
- Use GitHub-flavored Markdown and relative Markdown links so the content remains useful in GitHub, VS Code, and Obsidian without plugins.
- Use `docs/inbox/` only for structured, out-of-scope ideas, evidenced legacy/debt findings, open questions, and documentation gaps awaiting human triage.
- Never include secrets, credentials, private keys, unredacted customer data, or sensitive production values.
- Validate links, frontmatter, commands, and conflict markers before completing the change.
