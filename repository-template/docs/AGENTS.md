# Documentation agent instructions

These instructions apply to files under `docs/`.

- Treat repository documentation as part of the product and update it in the same change as affected code.
- Run documentation work after implementation and verification. Use the final diff and real validation results; do not copy claims from a plan without checking them.
- Describe the current supported state. Do not turn docs into an implementation diary, transcript, or release-note duplicate.
- Use GitHub-flavored Markdown and relative Markdown links. Essential content must remain useful without Obsidian or plugins.
- Prefer the smallest edit to an existing authoritative page. Avoid duplicate pages and speculative content.
- Add an ADR only for a consequential architecture, security, data, or operational decision with meaningful alternatives.
- Put unapproved ideas, evidenced legacy/debt findings, open questions, and documentation gaps in `inbox/` using its template. The inbox is temporary and does not replace the work-item tracker.
- Link to source files and symbols when useful, but do not paste large code blocks that will drift.
- Verify commands before documenting them. Mark examples clearly when they cannot be executed safely.
- Never add secrets, credentials, private keys, unredacted customer data, or sensitive production values.
- Before completion, check relative links, frontmatter, headings, and unresolved conflict markers.
- When resolving a docs conflict, preserve unique facts from both sides and escalate contradictory decisions or unsafe operational guidance instead of guessing.
