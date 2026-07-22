# Architecture Decision Records

An ADR is a short, immutable record of a single architectural decision: the context that forced it, the decision itself, and the trade-offs accepted. The goal is that a reviewer can find out *why* a decision was made — for example, why reconciliation runs as a background job instead of inline, or why authorization is a separate policy layer instead of model scopes — without reconstructing it from commit history or asking the author directly.

## When to write one

Any change that introduces a new architectural pattern or modifies an existing architectural boundary should be accompanied by an ADR. Examples that will warrant one as the domain layer is built out:

- Choosing a background job strategy for reconciliation processing.
- Choosing how authorization is modeled (policy objects vs. model scopes vs. a gem).
- Choosing the ledger's concurrency-control mechanism (e.g. optimistic locking vs. `SELECT ... FOR UPDATE`).
- Choosing the API serialization approach.

Routine implementation detail (a new controller action, a new validation) does not need one.

## Format

Each ADR is a single Markdown file, numbered sequentially: `docs/adr/0001-short-title.md`. A minimal template:

```markdown
# 0001: Short title of the decision

## Status
Proposed | Accepted | Superseded by 000X

## Context
What forced this decision? What constraints were in play?

## Decision
What was decided.

## Consequences
What becomes easier or harder as a result. What trade-offs were accepted.
```

## Index

No ADRs have been written yet — this repository is still in its foundation phase, and no decision requiring one has been made beyond what's already documented in [docs/architecture](../architecture/overview.md). This index will list each ADR by number and title as they're added.
