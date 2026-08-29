# Architecture decision records

Use an ADR for a consequential architecture, security, data, infrastructure, or operational decision when meaningful alternatives exist.

## Naming

Use an immutable sequence and a short kebab-case title:

```text
0001-use-outbox-for-domain-events.md
0002-separate-tenant-databases.md
```

Copy [0000-template.md](0000-template.md) when creating a record.

## Lifecycle

- `proposed` — under review; may change.
- `accepted` — current decision.
- `superseded` — replaced by another ADR; link both records.
- `rejected` — considered and not selected.
- `deprecated` — intentionally no longer recommended but not directly superseded.

After acceptance, do not rewrite history to match a later design. Correct minor errors transparently; use a new ADR to change the decision and mark the old one as superseded.
