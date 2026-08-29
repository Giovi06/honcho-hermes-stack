# Documentation inbox

This folder is a temporary, Git-reviewed capture area for useful findings that do not belong in the current approved implementation.

## Appropriate items

- future improvements or ideas discovered during a vertical slice;
- evidenced legacy behavior or technical debt;
- unclear invariants and open architecture questions;
- missing, contradictory, or stale documentation;
- follow-up work that needs human triage before entering the team tracker.

## Not appropriate

- raw agent transcripts, scratch notes, or full command logs;
- unverified claims about code quality or security;
- current sprint status;
- accepted work that already belongs in the team tracker;
- secrets, credentials, customer data, or sensitive production values.

## Capture and triage

1. Copy [_template.md](_template.md) to a short, descriptive filename.
2. Include concrete evidence, impact, and a proposed next step.
3. Assign an owner or triage group and a review date when the process supports it.
4. During review, choose one disposition:
   - reject and remove/archive with a reason;
   - resolve as a documentation correction;
   - promote to the team work-item tracker and record the link;
   - accept an architecture decision and create an ADR.
5. Remove or archive completed items. This folder must not become a permanent shadow backlog.
