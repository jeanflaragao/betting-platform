# Domain Model

> None of the concepts below exist as code yet — no models, tables, or migrations. This document describes the domain the system is being designed around, so the shape of the eventual data model is legible before it's built. Implementation status is tracked in the [Roadmap](../../README.md#roadmap), not here.

The platform's target domain sits in sports and event wagering. The domain model intentionally focuses on operational workflows instead of user-facing betting interactions — the objective is to model the systems responsible for correctness, settlement, financial integrity, and operational management, rather than the betting experience itself.

| Concept | Description |
|---|---|
| **Account** | A registered bettor, holding identity, authentication, and responsible-gambling limits. |
| **Wallet & Ledger** | The bettor's balance, backed by an append-only ledger of debits/credits rather than a single mutable column. |
| **Event** | A real-world occurrence (a match, a race, a fight) that can be wagered on. |
| **Market** | A specific question about an event (e.g. "who wins", "total goals over/under"). |
| **Selection / Odds** | A possible outcome within a market and its current price. |
| **Bet Slip** | One or more selections combined into a single wager with a stake. |
| **Settlement** | The process of resolving a market's outcome and applying payouts to affected ledgers. |

## Why the ledger is a first-class concept

Wallet balances are never derived from application-level arithmetic alone — a mutable `balance` column can't answer "how did we get here" when a dispute or an audit requires it. The ledger is the system of record; the wallet balance is a projection of it. This is the same reasoning that drives the [Financial Engine roadmap milestone](../../README.md#roadmap) and the emphasis on concurrency-safety in [backend.md](backend.md).

## Relationship to the roadmap

This model is the target shape for the **Core Domain** and **Financial Engine** roadmap milestones. As each concept is implemented, this document should be updated to reflect actual tables/models rather than the target design — at that point, cross-link to the relevant ADRs in [`docs/adr/`](../adr/README.md) for the reasoning behind schema decisions (e.g. how the ledger enforces append-only writes).
