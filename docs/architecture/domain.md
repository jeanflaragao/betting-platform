# Domain Model

> Implementation status is called out per concept below and tracked in the [Roadmap](../../README.md#roadmap) — this document describes the target shape of the domain, not just what's already built.

The platform's domain is the **operational and financial management of betting activity**, not betting itself. It intentionally excludes odds, markets, live wagering, and settlement mechanics — those belong to a sportsbook, which this is not. The objective is to model the accounts, money movement, and outcomes an operation needs to track to answer "is this profitable, and where," not to reproduce the experience of placing a bet.

| Concept | Description | Status |
|---|---|---|
| **User** | The authenticated operator of the platform — owns bookmakers and, transitively, everything scoped beneath them. | Implemented |
| **Bookmaker** | An external betting company/site the user operates with (name, website, country, status, currency). Represents *which* bookmaker, not a specific funded account at it. | Implemented |
| **Account** | A specific account held at a `Bookmaker` — a bookmaker can have more than one linked account (e.g. across currencies or operators). A `Bookmaker` cannot be deleted while it has active accounts. | In progress — referenced by request specs and a dedicated error class (`Bookmakers::ActiveAccountsExistError`), no migration yet |
| **Transaction (Deposit / Withdrawal)** | A funds movement in or out of an `Account`, forming an append-only ledger rather than a mutable balance column. | Planned |
| **Bankroll** | The available balance for an account, or aggregated across a set of accounts — a projection derived from the transaction ledger, never stored as a single mutable figure. | Planned |
| **Operational Expense** | A cost not tied to a specific bet or account (e.g. software, data feeds, staff) — factored into profitability alongside betting results. | Planned |
| **Bet Record** | A historical record of a wager already placed at a bookmaker — stake, odds taken, outcome — captured after the fact for profitability analysis. This system never places a bet; it only records the result of one that happened elsewhere. | Planned |
| **Account Limitation** | A restriction a bookmaker imposes on an account (stake limits, withdrawal holds, closures) — tracked so it can explain gaps in an account's activity or profitability. | Planned |
| **Reconciliation / Profitability Report** | A derived view combining ledger entries, bet records, and expenses into a profit-and-loss figure per account, bookmaker, or period. | Planned |

## Why the ledger is a first-class concept

Bankroll figures are never derived from application-level arithmetic alone — a mutable `balance` column can't answer "how did we get here" when a discrepancy against a bookmaker's own numbers needs to be investigated. The transaction ledger is the system of record; bankroll and reporting figures are projections of it. This is the same reasoning that drives the [Financial Engine roadmap milestone](../../README.md#roadmap) and the emphasis on concurrency-safety in [backend.md](backend.md).

## Relationship to the roadmap

`Account` is the target shape for the next slice of the **Core Domain** milestone; the ledger, bankroll, expenses, bet records, and reporting are the **Financial Engine** milestone. As each concept is implemented, this document should be updated to reflect actual tables/models rather than the target design — at that point, cross-link to the relevant ADRs in [`docs/adr/`](../adr/README.md) for the reasoning behind schema decisions (e.g. how the ledger enforces append-only writes).
