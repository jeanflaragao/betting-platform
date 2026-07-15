# Development Guide

Setup and contribution workflow for the whole poly-repo (root infrastructure + the `backend` submodule). For backend-specific commands (tests, linting, folder structure), see [backend/README.md](../../backend/README.md).

## Prerequisites

- Docker and Docker Compose
- Ruby 3.2 (see `backend/Dockerfile` for the pinned version) and Bundler
- Git (with submodule support)

## Infrastructure & tooling choices

| Tool | Purpose | Why |
|---|---|---|
| Docker / Docker Compose | Local PostgreSQL provisioning (`infra/compose/docker-compose.yml`) | Reproducible local environment without installing PostgreSQL natively on every machine. |
| GitHub Actions | CI — security scan, lint, and test on every push/PR | Colocated with the code and requires no separate CI platform to operate. |
| Dependabot | Automated dependency updates (bundler + GitHub Actions) | Low-effort dependency hygiene without a manual audit cadence. |

Backend-specific technology choices (Rails, PostgreSQL, Solid adapters, Kamal, testing stack) are documented in [backend/README.md](../../backend/README.md#technology-stack).

## Clone

```bash
# Clone with the backend submodule
git clone --recurse-submodules git@github.com:jeanflaragao/betting-platform.git
cd betting-platform

# If already cloned without submodules:
git submodule update --init --recursive
```

## Start PostgreSQL

```bash
make up      # starts PostgreSQL 16 via infra/compose/docker-compose.yml
make logs    # follow container logs
make down    # stop and remove containers
```

## Backend setup

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

## Database setup

```bash
# From the repository root — prepares both development and test databases
make migrate

# Equivalent, run directly from backend/:
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
```

## Running the server

```bash
cd backend
bin/dev   # starts Puma on http://localhost:3000

# Verify:
curl http://localhost:3000/up
```

## Running tests and linters

```bash
cd backend
bin/rails test     # Minitest suite
bin/rubocop        # Rails Omakase style
bin/brakeman       # static security analysis
```

All three run again in CI and must pass before merge.

## Contributing

This is currently a solo portfolio project, developed openly. The conventions below are enforced regardless of contributor count, and describe how changes are expected to land:

- **Branching** — `feature/<short-description>`, `fix/<short-description>`, `chore/<short-description>`.
- **Commits** — [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `docs:`, `test:`), consistent with the existing history (`chore: bootstrap rails api backend`, `chore: configure postgres with docker compose`).
- **Before opening a PR** — run `bin/rubocop`, `bin/brakeman`, and `bin/rails test` locally; all three run again in CI and must pass before merge.
- **Pull requests** — scoped to a single concern, with a description of the *why*, not just the *what*.
- **Architectural changes** — changes that introduce new patterns or modify architectural boundaries should be accompanied by an Architecture Decision Record under [`docs/adr/`](../adr/README.md).

Issues and discussion are welcome via the GitHub issue tracker on either repository.

### Submodule workflow

Since `backend/` is a separate git repository:

1. Commit and merge application code changes in `backend/`'s own history first.
2. Then, in the root repository, bump the submodule pointer as a separate, clearly-labeled commit (e.g. `chore: bump backend submodule to <sha>`).

Never mix an application-code change and a submodule-pointer bump in the same commit — they belong to different repositories' review processes.
