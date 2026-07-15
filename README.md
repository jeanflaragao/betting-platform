<div align="center">

# Betting Platform

**The operational core of a real-money wagering system — engineered around correctness, auditability, and concurrency-safety from the first commit.**

[![Status](https://img.shields.io/badge/status-foundation--phase-yellow)](#roadmap)
[![CI](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml/badge.svg)](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.2-CC342D?logo=ruby&logoColor=white)](backend/Dockerfile)
[![Rails](https://img.shields.io/badge/rails-8.0.5-CC0000?logo=rubyonrails&logoColor=white)](backend/Gemfile.lock)
[![PostgreSQL](https://img.shields.io/badge/postgresql-16-4169E1?logo=postgresql&logoColor=white)](infra/compose/docker-compose.yml)
[![Coverage](https://img.shields.io/badge/coverage-not--configured-lightgrey)](#testing-strategy)
[![License](https://img.shields.io/badge/license-TBD-lightgrey)](#license)

</div>

---

> [!IMPORTANT]
> **Project stage.** This repository is in its **foundation phase**. The engineering scaffolding — CI/CD, containerized local development, deployment pipeline, security scanning, and dependency automation — is in place and enforced on every push. Domain logic (accounts, wagering, settlement) has not been implemented yet and is tracked explicitly in the [Roadmap](#roadmap). This README documents only what exists in the codebase today; everything else is scoped as planned work, not shipped functionality.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Project Vision](#project-vision)
- [Current Status](#current-status)
- [Product Overview](#product-overview)
- [Current Capabilities](#current-capabilities)
- [Roadmap](#roadmap)
- [Architectural Layers](#architectural-layers)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Engineering Principles](#engineering-principles)
- [Guiding Principles](#guiding-principles)
- [Architecture Philosophy](#architecture-philosophy)
- [Engineering Decisions](#engineering-decisions)
- [Local Development](#local-development)
- [Testing Strategy](#testing-strategy)
- [API Documentation](#api-documentation)
- [Architecture Diagrams](#architecture-diagrams)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [About the Author](#about-the-author)
- [License](#license)

---

## Problem Statement

Betting operations move real money against prices that change by the second, under audit and regulatory scrutiny. A bet placed just before a market closes has to be accepted or rejected unambiguously. A settled market has to pay out exactly once. A disputed outcome has to be traceable back to the exact data that produced it.

These aren't edge cases in this domain — they're the normal operating conditions. Most backend systems are built around the opposite assumption: that state changes are sequential, low-stakes, and easy to reason about after the fact.

This project exists to work through that gap deliberately: to build a backend where correctness, concurrency-safety, and auditability are constraints the architecture satisfies from the first schema decision, not properties added once the business logic already works.

## Project Vision

A betting platform is not a form over a database. It is a financial system with a clock attached to it: money moves against odds that change in real time, settlement must be unambiguous even when an event's outcome is contested, and every balance change has to be reconstructable after the fact — for the user, for support, and for a regulator.

That combination of constraints is why this is not being built as a CRUD application:

- **Money correctness is non-negotiable.** Wallet balances must never be derived from application-level arithmetic alone; they need an auditable, append-only trail.
- **Concurrency is the default case, not the edge case.** Odds shift and bets are placed concurrently against the same market — the system has to reason about race conditions from the first schema decision, not retrofit locking later.
- **Settlement is irreversible.** Once a market is settled and payouts are issued, correctness has to be enforced by the data model and the process, not by careful manual review.
- **Every action needs a trail.** Support disputes, fraud review, and compliance all depend on being able to answer "what happened, and why" after the fact.

These constraints — not aesthetic preference — are what the architecture, technology choices, and CI setup documented below are built to satisfy.

## Current Status

- [x] Local development environment (Docker Compose + Makefile)
- [x] API-only Rails 8 application skeleton
- [x] CI/CD pipeline — security scan, lint, test — and dependency automation
- [x] Deployment scaffold (Kamal)
- [ ] Domain data model — in progress
- [ ] Authentication, authorization, and service layer — planned
- [ ] Financial engine — wallets, ledger, settlement — planned

Details for each item are in [Current Capabilities](#current-capabilities) and [Roadmap](#roadmap).

## Product Overview

The platform's target domain sits in sports and event wagering. The concepts below define the domain model the system is being designed around — implementation status for each is tracked explicitly in the [Roadmap](#roadmap), not implied here.

> The domain model intentionally focuses on operational workflows instead of user-facing betting interactions. The objective is to model the systems responsible for correctness, settlement, financial integrity, and operational management rather than the betting experience itself.

| Concept | Description |
|---|---|
| **Account** | A registered bettor, holding identity, authentication, and responsible-gambling limits. |
| **Wallet & Ledger** | The bettor's balance, backed by an append-only ledger of debits/credits rather than a single mutable column. |
| **Event** | A real-world occurrence (a match, a race, a fight) that can be wagered on. |
| **Market** | A specific question about an event (e.g. "who wins", "total goals over/under"). |
| **Selection / Odds** | A possible outcome within a market and its current price. |
| **Bet Slip** | One or more selections combined into a single wager with a stake. |
| **Settlement** | The process of resolving a market's outcome and applying payouts to affected ledgers. |

## Current Capabilities

Everything listed here exists in the codebase today and is exercised by CI. Nothing in this section is aspirational.

**Infrastructure & Developer Experience**
- Reproducible local environment via Docker Compose — PostgreSQL 16 provisioned with a single command (`infra/compose/docker-compose.yml`).
- `Makefile` entry points (`up`, `down`, `logs`, `migrate`) providing a consistent developer interface across the whole system.
- Poly-repo architecture: this repository orchestrates infrastructure and owns the deployment surface, while the Rails application lives in a versioned [git submodule](https://github.com/jeanflaragao/backend) — allowing the application and its infrastructure to evolve and be reviewed independently.
- One-command environment bootstrap (`bin/setup`) and server start (`bin/dev`) in the backend application.

**Backend Application (Rails, API-only)**
- Ruby on Rails 8.0.5 configured in API-only mode (`config.api_only = true`) — no view layer, no unnecessary middleware.
- Health-check endpoint (`GET /up`) suitable for load balancer / uptime monitoring integration.
- Encrypted credentials via Rails' built-in credentials store (`config/credentials.yml.enc`), keeping secrets out of source control.
- Database-backed adapters configured for cache, background jobs, and Action Cable (Solid Cache, Solid Queue, Solid Cable) — the Rails 8 default of avoiding a Redis dependency for these concerns.

**CI/CD & Quality Gates**
- GitHub Actions pipeline running on every push and pull request against `main`, with three independent jobs:
  - **Security scanning** — [Brakeman](https://brakemanscanner.org/) static analysis for common Rails vulnerabilities.
  - **Linting** — [RuboCop](https://github.com/rails/rubocop-rails-omakase) with the Rails Omakase house style.
  - **Automated tests** — the Minitest suite, run against a real PostgreSQL service container (not mocked).
- Dependabot configured for both `bundler` and `github-actions` ecosystems, checked daily.
- Kamal deployment configuration scaffolded (`config/deploy.yml`, `.kamal/`) for containerized, zero-downtime deploys, fronted by Thruster for asset caching/compression.

## Roadmap

Organized by engineering milestone rather than a flat feature list, so the path from today's scaffold to a functioning platform is legible at a glance. Longer-horizon, less-scoped ideas live separately under [Future Enhancements](#future-enhancements).

### Foundation
- [x] Dockerized PostgreSQL for local development
- [x] Poly-repo layout (orchestrator + `backend` submodule)
- [x] API-only Rails 8 application skeleton
- [x] Health-check endpoint
- [x] CI pipeline — security scan, lint, test
- [x] Dependency automation (Dependabot)
- [x] Deployment scaffold (Kamal + Thruster)

### Core Domain
- [ ] Domain data model (accounts, events, markets, odds) — in progress
- [ ] Authentication (`has_secure_password` or token-based, e.g. Devise/JWT)
- [ ] Authorization layer via policy objects (Pundit)
- [ ] Service objects for core use cases
- [ ] Query objects for complex reads
- [ ] JSON serialization layer (Blueprinter or `ActiveModel::Serializer`)
- [ ] Structured error handling and consistent API error envelope
- [ ] Test suite migration to RSpec + FactoryBot, including request specs
- [ ] OpenAPI / Swagger documentation

### Financial Engine
- [ ] Wallet and append-only ledger
- [ ] Concurrency-safe bet placement against live odds
- [ ] Settlement processing as a background job (Solid Queue)

### Product Intelligence
- [ ] CSV import for bulk event/market seeding
- [ ] AI-assisted risk/trading insights

### Scalability
- [ ] Caching strategy for odds and market data
- [ ] Rate limiting on public API endpoints
- [ ] Multi-tenancy (multi-brand / multi-jurisdiction support)

### Observability
- [ ] Structured logging, metrics, and distributed tracing
- [ ] Test coverage reporting (SimpleCov)

### Cloud
- [ ] Production deployment to AWS

## Architectural Layers

> The table below defines architectural responsibilities, not implementation status. It describes the blueprint this codebase is being built toward, derived from the API-only skeleton and configuration already in place (`config.api_only = true`, database-backed job/cache adapters, submodule separation of infra and app). Only **Controllers** and **Models** exist in skeletal form today; the rest are tracked in the [Roadmap](#roadmap).

**Layer Responsibility Matrix**

| Layer | Responsibility |
|---|---|
| **Controllers** | Translate HTTP into calls against services/models and models/services back into HTTP responses. No business logic — parameter handling, status codes, and delegation only. |
| **Models** | ActiveRecord persistence and data integrity (validations, associations, database constraints). No orchestration of multi-step business processes. |
| **Services** | Single-purpose objects encapsulating a business use case (e.g. `Bets::PlaceBet`, `Markets::Settle`). The place where money-moving logic actually lives. |
| **Policies** | Authorization decisions ("can this account perform this action on this resource") kept out of controllers and models. |
| **Query Objects** | Encapsulate non-trivial reads (reporting, reconciliation, filtering) that don't belong as ActiveRecord scopes. |
| **Background Jobs** | Asynchronous work — settlement processing, notifications — via Solid Queue, already configured as the default adapter. |
| **Error Handling** | A consistent API error envelope and centralized rescue handling, rather than ad hoc `rescue` blocks per controller. |
| **Authentication** | Verifying who is making the request. |
| **Authorization** | Verifying what the authenticated account is allowed to do (delegated to Policies). |
| **Testing** | Request specs verifying behavior at the HTTP boundary; service/model specs verifying business logic in isolation. |

## Technology Stack

### Backend

| Technology | Version | Purpose | Why |
|---|---|---|---|
| Ruby | 3.2 (pinned in `Dockerfile`) | Language runtime | Matches Rails 8's supported baseline. |
| Ruby on Rails | 8.0.5 | API-only application framework (`config.api_only = true`) | API-only strips the view layer this project doesn't need, keeping the surface area limited to the JSON contract. |
| PostgreSQL | 16 | System of record — primary relational datastore | Strong transactional guarantees, which an append-only ledger design depends on more than horizontal read scale at this stage. |
| Puma | ≥ 5.0 | Application server | Rails' default; no reason to deviate yet. |
| Solid Queue | Rails 8 default | Database-backed background job adapter | Avoids running Redis for jobs that don't yet need sub-millisecond latency — one fewer moving part locally and in staging. |
| Solid Cache | Rails 8 default | Database-backed `Rails.cache` adapter | Same rationale as Solid Queue. |
| Solid Cable | Rails 8 default | Database-backed Action Cable adapter | Configured by default; unused until a real-time feature (e.g. live odds) needs it. |
| Bootsnap | latest | Boot-time caching for faster startup | Standard Rails optimization. |

### Frontend

No client application exists in this repository. The backend is deliberately API-only (`config.api_only = true`) and designed to be consumed by a decoupled client — see [Roadmap](#roadmap).

### Infrastructure

| Technology | Purpose | Why |
|---|---|---|
| Docker / Docker Compose | Local PostgreSQL provisioning (`infra/compose/docker-compose.yml`) | Reproducible local environment without installing PostgreSQL natively on every machine. |
| Kamal | Containerized, zero-downtime deployment (`config/deploy.yml`) | Deploys to plain servers/containers without adopting a platform sized for a much larger system. |
| Thruster | HTTP asset caching/compression in front of Puma | Avoids standing up a separate reverse proxy for basic HTTP caching. |
| GitHub Actions | CI — security scan, lint, and test on every push/PR | Colocated with the code and requires no separate CI platform to operate. |
| Dependabot | Automated dependency updates (bundler + GitHub Actions) | Low-effort dependency hygiene without a manual audit cadence. |

### Testing

| Tool | Role | Status |
|---|---|---|
| Minitest | Default Rails test framework | Present (scaffold, no application tests yet) |
| Brakeman | Static security analysis | Active in CI |
| RSpec + FactoryBot | Target spec-style testing stack | Planned |
| Request specs | HTTP-boundary contract testing | Planned |
| SimpleCov | Coverage reporting | Planned |

### Developer Experience

| Tool | Purpose |
|---|---|
| RuboCop (Rails Omakase) | Enforced house code style |
| Brakeman | Security static analysis, run locally via `bin/brakeman` |
| `bin/setup` | One-command environment bootstrap |
| `bin/dev` | Local server start |
| dotenv-rails | Local environment variable management |
| debug | Rails 8 default interactive debugger |

## Project Structure

```text
betting-platform/
├── Makefile                     # up / down / logs / migrate — developer entry points
├── .gitmodules                  # declares `backend` as a git submodule
├── infra/
│   └── compose/
│       └── docker-compose.yml   # local PostgreSQL 16
└── backend/                     # git submodule → github.com/jeanflaragao/backend
    ├── app/
    │   ├── controllers/         # ApplicationController (ActionController::API)
    │   ├── jobs/                # ApplicationJob (Solid Queue)
    │   ├── mailers/
    │   └── models/              # ApplicationRecord
    ├── config/
    │   ├── application.rb       # API-only mode, autoloading
    │   ├── database.yml         # PostgreSQL, env-driven credentials
    │   ├── deploy.yml           # Kamal deployment config
    │   └── routes.rb            # currently: health check only
    ├── db/                      # cache/cable/queue schemas + seeds
    ├── test/                    # Minitest scaffold
    ├── .github/
    │   ├── workflows/ci.yml     # security scan · lint · test
    │   └── dependabot.yml
    ├── Dockerfile                # production multi-stage build
    ├── Gemfile / Gemfile.lock
    └── .rubocop.yml              # Rails Omakase house style
```

**Root repository** — owns local infrastructure provisioning and the deployment surface. Kept separate from application code so infrastructure changes don't require touching (or re-reviewing) the Rails app, and vice versa.

**`backend/`** — the Rails application itself, versioned as an independent repository and pulled in as a git submodule. This allows the API to be built, tested, and deployed on its own release cadence, and keeps the door open to additional services (a future frontend, a future worker service) being added as siblings rather than nested inside the API's repo.

## Engineering Principles

The principles below are used as engineering heuristics rather than rigid rules. Whenever a design decision requires violating one of them, the trade-off should be explicit and documented.

- **Thin controllers.** Controllers translate HTTP; they do not contain business logic. That logic belongs in service objects.
- **Service objects for use cases.** Multi-step business processes (placing a bet, settling a market) are modeled as single-purpose, testable objects rather than spread across callbacks and controller actions.
- **Separation of concerns.** Persistence (models), authorization (policies), business logic (services), and complex reads (query objects) are deliberately kept in separate layers.
- **SOLID, applied pragmatically.** Single-responsibility objects and dependency boundaries are favored over generic, prematurely abstract frameworks-within-the-framework.
- **Convention over configuration.** Rails defaults are used unless there's a concrete reason to deviate — evidenced by the current API-only, Omakase-styled, database-backed-adapter configuration.
- **RESTful APIs.** Resources and actions are modeled around standard HTTP verbs and status codes.
- **Tests at the boundary.** Request specs are the primary tool for verifying behavior as a client of the API would experience it, complemented by focused unit specs for services and models.
- **CI as a gate, not a formality.** Security scanning, linting, and tests block merges rather than running informationally — a failing build is treated as broken, not as a warning to address later.

## Guiding Principles

These are the underlying values the principles above are derived from.

- Correctness over convenience.
- Explicitness over magic.
- Simplicity over cleverness.
- Testability over shortcuts.
- Observability over assumptions.
- Evolutionary architecture over premature optimization.

## Architecture Philosophy

The layering described above isn't a Rails convention followed out of habit — each boundary exists to contain a specific way this domain can go wrong.

**Business rules live in services** because an operation like placing a bet touches multiple records — wallet, bet, ledger — that must succeed or fail together. Putting that logic in a controller action or a model callback makes the failure mode implicit; a service object makes it a single, testable unit.

**Controllers coordinate, they don't decide.** Their only job is turning a request into a service call and a result into an HTTP response. Understanding how a bet gets placed shouldn't require reading a controller.

**Policies authorize** because who-can-do-what changes independently of both the request shape and the persistence model. Coupling authorization to either makes both harder to change safely later.

**Models protect data integrity** at the layer closest to the database — validations and constraints — not business process. A model that also orchestrates a multi-step transaction is doing two jobs.

**Queries optimize reads** because a reconciliation report and a single record lookup are different problems. Conflating them tends to pull ActiveRecord scopes in directions that hurt both.

## Engineering Decisions

Architectural choices in this codebase are meant to be discoverable, not just inferable from the code. As services, query objects, error handling, authorization, and the testing strategy are implemented, the reasoning behind each decision — not just the resulting code — will be recorded as lightweight Architecture Decision Records (ADRs) under `docs/adr/`.

The goal is that a reviewer can find out *why* a decision was made — for example, why settlement runs as a background job instead of inline, or why authorization is a separate policy layer instead of model scopes — without reconstructing it from commit history.

## Local Development

### Prerequisites

- Docker and Docker Compose
- Ruby 3.2 (see `backend/Dockerfile` for the pinned version) and Bundler
- Git (with submodule support)

### Installation

```bash
# Clone with the backend submodule
git clone --recurse-submodules git@github.com:jeanflaragao/betting-platform.git
cd betting-platform

# If already cloned without submodules:
git submodule update --init --recursive
```

### Docker — start PostgreSQL

```bash
make up      # starts PostgreSQL 16 via infra/compose/docker-compose.yml
make logs    # follow container logs
make down    # stop and remove containers
```

### Backend setup

```bash
cd backend
bundle install
```

Create a `.env` file in `backend/` (loaded via `dotenv-rails`) matching the Compose credentials:

```env
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=betting_platform_development
```

### Database setup

```bash
# From the repository root — prepares both development and test databases
make migrate

# Equivalent, run directly from backend/:
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
```

### Running the server

```bash
cd backend
bin/dev   # starts Puma on http://localhost:3000

# Verify:
curl http://localhost:3000/up
```

### Running tests

```bash
cd backend
bin/rails test
```

### Linting & security

```bash
cd backend
bin/rubocop      # Rails Omakase style
bin/brakeman      # static security analysis
```

## Testing Strategy

The current setup uses Rails' default **Minitest** suite, exercised in CI (`bin/rails db:test:prepare test`) against a real PostgreSQL service container rather than a mocked database — a deliberate choice carried forward as the suite grows, so that CI reflects production database behavior. No application-level tests exist yet, since no application logic has been written.

**Planned testing direction** (tracked in the [Roadmap](#roadmap)):
- Migration to **RSpec** as the primary testing framework, with **FactoryBot** replacing fixtures for test data construction.
- **Request specs** as the default test type for new endpoints — verifying behavior at the HTTP boundary rather than reaching into controller internals.
- **Service specs** covering business logic in isolation from HTTP and persistence concerns.
- **SimpleCov** integrated into CI to track and enforce coverage as the domain layer is built out.
- Brakeman remains as the static security gate regardless of the spec framework used.

## API Documentation

No API documentation tooling is configured yet — the only route currently exposed is the health check (`GET /up`). Once the first domain resources exist, the plan is to adopt an OpenAPI-based toolchain (e.g. [rswag](https://github.com/rswag/rswag)) so that request specs double as the source of truth for a generated OpenAPI 3.0 spec, served via Swagger UI. This is tracked as **Planned** in the [Roadmap](#roadmap).

## Architecture Diagrams

### System Overview (current)

```mermaid
flowchart LR
    subgraph Local["Local Development"]
        Client[HTTP Client]
    end

    subgraph Compose["Docker Compose — infra/compose"]
        API["Rails API (Puma)<br/>localhost:3000"]
        DB[(PostgreSQL 16)]
    end

    subgraph GHA["GitHub Actions — on push / PR"]
        Sec["Security Scan<br/>Brakeman"]
        Lint["Lint<br/>RuboCop Omakase"]
        Test["Test Suite<br/>Minitest + PostgreSQL"]
    end

    Client -->|GET /up| API
    API --> DB
    Push([git push / pull_request]) --> Sec
    Push --> Lint
    Push --> Test
```

### Request Flow (current)

```mermaid
sequenceDiagram
    participant C as Client
    participant P as Puma
    participant R as Rails Router
    participant AC as ApplicationController
    participant DB as PostgreSQL

    C->>P: GET /up
    P->>R: dispatch request
    R->>AC: Rails::HealthController#show
    AC->>DB: verify connection
    AC-->>C: 200 OK
```

### Target Layered Architecture (planned)

```mermaid
flowchart TD
    Client[Client] --> Controller["Controllers<br/>thin, HTTP-only"]
    Controller --> Policy["Policies<br/>authorization"]
    Controller --> Service["Service Objects<br/>business logic"]
    Service --> Query["Query Objects<br/>complex reads"]
    Service --> Job["Background Jobs<br/>Solid Queue"]
    Service --> Model[ActiveRecord Models]
    Query --> Model
    Model --> DB[(PostgreSQL)]
    Service --> Serializer["Serializers<br/>JSON response shaping"]
    Serializer --> Controller
```

## Future Enhancements

Ideas beyond the scoped [Roadmap](#roadmap) — directionally likely, not yet committed to.

### Near-term Evolution
- Seed data and demo fixtures for a realistic local environment without production data.
- Feature flags for gradual rollout of new markets or wagering types without full deploys.
- Audit logs as an immutable, queryable trail for compliance and dispute resolution — distinct from the ledger's transactional record.

### Long-term Architecture
- Multi-region / high-availability deployment topology, once a single Kamal target stops being sufficient.

### Research Topics
- Event-driven architecture for settlement and notifications, decoupling side effects from the request/response cycle.

## Contributing

This is currently a solo portfolio project, developed openly. The conventions below are enforced regardless of contributor count, and describe how changes are expected to land:

- **Branching** — `feature/<short-description>`, `fix/<short-description>`, `chore/<short-description>`.
- **Commits** — [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `docs:`, `test:`), consistent with the existing history (`chore: bootstrap rails api backend`, `chore: configure postgres with docker compose`).
- **Before opening a PR** — run `bin/rubocop`, `bin/brakeman`, and `bin/rails test` locally; all three run again in CI and must pass before merge.
- **Pull requests** — scoped to a single concern, with a description of the *why*, not just the *what*.
- **Submodule changes** — if a change touches `backend/`, commit and merge there first, then bump the submodule pointer in the root repository as a separate, clearly-labeled commit.
- **Architectural changes** — changes that introduce new patterns or modify architectural boundaries should be accompanied by an Architecture Decision Record (ADR) under `docs/adr/`.

Issues and discussion are welcome via the GitHub issue tracker on either repository.

## About the Author

**Jean Aragão** ([@jeanflaragao](https://github.com/jeanflaragao))

This project is an ongoing engineering effort in software architecture and backend engineering, built around a financially sensitive domain — chosen deliberately because correctness and concurrency can't be faked with a CRUD scaffold. The engineering practices documented above (CI from the first commit, layered architecture, documented decisions) are as much the point of this project as the eventual feature set.

- LinkedIn: `[add LinkedIn profile URL]`
- Portfolio: `[add portfolio URL]`
- Email: `[add contact email]`

## License

No license has been declared yet. A `LICENSE` file will be added prior to any public release; until then, all rights are reserved by the author.
