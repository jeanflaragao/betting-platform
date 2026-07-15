<div align="center">

# Betting Platform

**The operational core of a real-money wagering system — engineered around correctness, auditability, and concurrency-safety from the first commit.**

[![Status](https://img.shields.io/badge/status-foundation--phase-yellow)](#roadmap)
[![CI](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml/badge.svg)](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.2-CC342D?logo=ruby&logoColor=white)](backend/Dockerfile)
[![Rails](https://img.shields.io/badge/rails-8.0.5-CC0000?logo=rubyonrails&logoColor=white)](backend/Gemfile.lock)
[![PostgreSQL](https://img.shields.io/badge/postgresql-16-4169E1?logo=postgresql&logoColor=white)](infra/compose/docker-compose.yml)
[![License](https://img.shields.io/badge/license-TBD-lightgrey)](#license)

</div>

---

> [!IMPORTANT]
> **Project stage.** This repository is in its **foundation phase**. The engineering scaffolding — CI/CD, containerized local development, deployment pipeline, security scanning, and dependency automation — is in place and enforced on every push. Domain logic (accounts, wagering, settlement) has not been implemented yet and is tracked explicitly in the [Roadmap](#roadmap). This README documents only what exists today; everything else is scoped as planned work, not shipped functionality.

## Table of Contents

- [What is this project?](#what-is-this-project)
- [What problem does it solve?](#what-problem-does-it-solve)
- [Why does it exist?](#why-does-it-exist)
- [High-level architecture](#high-level-architecture)
- [Repository structure](#repository-structure)
- [Quick Start](#quick-start)
- [Documentation Index](#documentation-index)
- [Roadmap](#roadmap)
- [About](#about)
- [License](#license)

## What is this project?

A backend-first engineering effort building the operational core of a real-money sports and event wagering platform: accounts, wallets, markets, odds, bet slips, and settlement. The full domain model is described in [docs/architecture/domain.md](docs/architecture/domain.md) — none of it is implemented yet, by design (see the foundation-phase note above and the [Roadmap](#roadmap)).

The repository is structured as a **poly-repo**: this repo owns local infrastructure and deployment; the Rails application lives in a separate, independently-versioned [`backend`](https://github.com/jeanflaragao/backend) repository, pulled in as a git submodule.

## What problem does it solve?

Betting operations move real money against prices that change by the second, under audit and regulatory scrutiny. A bet placed just before a market closes has to be accepted or rejected unambiguously. A settled market has to pay out exactly once. A disputed outcome has to be traceable back to the exact data that produced it.

These aren't edge cases in this domain — they're the normal operating conditions. Most backend systems are built around the opposite assumption: that state changes are sequential, low-stakes, and easy to reason about after the fact. This project works through that gap deliberately.

## Why does it exist?

A betting platform is not a form over a database — it's a financial system with a clock attached to it. Money moves against odds that change in real time, settlement must be unambiguous even when an outcome is contested, and every balance change has to be reconstructable after the fact — for the user, for support, and for a regulator.

That's why this isn't being built as a CRUD application: money correctness is non-negotiable, concurrency is the default case rather than the edge case, settlement is irreversible, and every action needs an audit trail. These constraints — not aesthetic preference — drive the architecture, technology choices, and CI setup. The full reasoning lives in [docs/architecture/overview.md](docs/architecture/overview.md).

## High-level architecture

```mermaid
flowchart LR
    subgraph Local["Local Development"]
        Client[HTTP Client]
    end

    subgraph Compose["Docker Compose"]
        API["Rails API (Puma)<br/>localhost:3000"]
        DB[(PostgreSQL 16)]
    end

    subgraph GHA["GitHub Actions — on push / PR"]
        Sec["Security Scan"]
        Lint["Lint"]
        Test["Test Suite"]
    end

    Client -->|GET /up| API
    API --> DB
    Push([git push / pull_request]) --> Sec
    Push --> Lint
    Push --> Test
```

An API-only Rails 8 backend, Postgres as the single system of record (also backing cache, jobs, and Action Cable via Rails 8's Solid adapters — no Redis dependency), containerized locally via Docker Compose, and deployed via Kamal. For the full system diagrams, the target layered architecture (controllers → services → policies → query objects), and the domain model, see the [Documentation Index](#documentation-index) below.

## Repository structure

```text
betting-platform/
├── README.md                 # you are here
├── Makefile                  # up / down / logs / migrate — developer entry points
├── infra/compose/            # local PostgreSQL 16 (Docker Compose)
├── backend/                  # git submodule → github.com/jeanflaragao/backend (Rails API)
│   └── README.md             # backend implementation guide
├── frontend/                 # not yet implemented
│   └── README.md
└── docs/
    ├── architecture/         # system, backend, and domain design docs
    ├── adr/                  # architecture decision records
    ├── api/                  # API documentation strategy
    └── development/          # local setup and contribution workflow
```

**Root repository** — owns local infrastructure provisioning and the deployment surface. Kept separate from application code so infrastructure changes don't require touching (or re-reviewing) the Rails app, and vice versa.

**`backend/`** — the Rails application, versioned as an independent repository and pulled in as a git submodule, so the API can be built, tested, and deployed on its own release cadence. See [why](docs/architecture/overview.md#poly-repo-model).

## Quick Start

```bash
# Clone with the backend submodule
git clone --recurse-submodules git@github.com:jeanflaragao/betting-platform.git
cd betting-platform

# Start PostgreSQL
make up

# Backend setup (needs a .env — see docs/development)
cd backend
bundle install
bin/setup

# Verify
curl http://localhost:3000/up
```

Full setup instructions (environment variables, database prep, running tests) live in [docs/development](docs/development/README.md).

## Documentation Index

| Document | Purpose |
|----------|---------|
| [backend/README.md](backend/README.md) | Backend architecture and implementation — practical guide for engineers working in the Rails app |
| [frontend/README.md](frontend/README.md) | Frontend status and planned direction |
| [docs/architecture/overview.md](docs/architecture/overview.md) | System-level architecture, poly-repo rationale, diagrams |
| [docs/architecture/backend.md](docs/architecture/backend.md) | Backend layering, target architecture, design philosophy |
| [docs/architecture/domain.md](docs/architecture/domain.md) | Domain model (accounts, markets, odds, settlement) |
| [docs/adr/README.md](docs/adr/README.md) | Architecture Decision Records |
| [docs/api/README.md](docs/api/README.md) | API documentation strategy |
| [docs/development/README.md](docs/development/README.md) | Local setup and contribution workflow |

## Roadmap

Organized by engineering milestone rather than a flat feature list, so the path from today's scaffold to a functioning platform is legible at a glance.

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

### Future Enhancements

Ideas beyond the scoped roadmap above — directionally likely, not yet committed to:

- Seed data and demo fixtures for a realistic local environment without production data.
- Feature flags for gradual rollout of new markets or wagering types without full deploys.
- Audit logs as an immutable, queryable trail for compliance and dispute resolution — distinct from the ledger's transactional record.
- Multi-region / high-availability deployment topology, once a single Kamal target stops being sufficient.
- Event-driven architecture for settlement and notifications, decoupling side effects from the request/response cycle.

## About

**Jean Aragão** ([@jeanflaragao](https://github.com/jeanflaragao))

This project is an ongoing engineering effort in software architecture and backend engineering, built around a financially sensitive domain — chosen deliberately because correctness and concurrency can't be faked with a CRUD scaffold. The engineering practices documented throughout this repository (CI from the first commit, layered architecture, documented decisions) are as much the point of this project as the eventual feature set.

- LinkedIn: `https://www.linkedin.com/in/aragao-jean/`

Contributions, issues, and discussion are welcome — see [docs/development](docs/development/README.md#contributing) for conventions.

## License

No license has been declared yet. A `LICENSE` file will be added prior to any public release; until then, all rights are reserved by the author.
