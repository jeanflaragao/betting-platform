# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a **poly-repo** setup, not a monorepo:

- **`betting-platform`** (this repo, root) — owns local infrastructure provisioning and the deployment surface. Contains `Makefile`, `infra/compose/`, and the `backend` submodule pointer. Has no application code of its own.
- **`backend/`** — a **git submodule** pointing to `github.com/jeanflaragao/backend`, a separate repository. This is the actual Ruby on Rails application. It has its own git history, its own remote, and its own CI.

If `backend/` appears empty, the submodule hasn't been initialized:

```bash
git submodule update --init --recursive
```

Changes to application code belong in `backend/`'s own git history — commit there first, then bump the submodule pointer in the root repo as a separate commit if the root repo needs to reference the new revision.

## Project stage

This project is in its **foundation phase**: CI/CD, containerized local dev, and deployment scaffolding are in place, but no domain logic exists yet (no custom models, controllers, services, or tests beyond Rails' default scaffold). See `README.md` for the full picture — the "Current Features" section there lists only what is actually implemented; "Roadmap" tracks everything else. Don't assume domain concepts (accounts, bets, markets, wallets) described in the README's Product Overview exist in code — they don't yet.

## Commands

All application commands run from `backend/` unless noted.

### Infrastructure (from repo root)

```bash
make up       # start PostgreSQL 16 via infra/compose/docker-compose.yml
make down     # stop and remove containers
make logs     # follow container logs
make migrate  # cd backend && bin/rails db:prepare && RAILS_ENV=test bin/rails db:prepare
```

### Backend setup

```bash
cd backend
bundle install
bin/setup        # idempotent: installs deps, prepares db, clears logs/tmp, starts server
```

Requires a `.env` (loaded via `dotenv-rails`) with `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME` — `config/database.yml` has no defaults and will fail to connect without them.

### Running the server

```bash
bin/dev                        # starts Puma on :3000
curl http://localhost:3000/up  # health check — currently the only route
```

### Tests

```bash
bin/rails test                          # full suite (Minitest — Rails default, not RSpec)
bin/rails test test/models/foo_test.rb  # single file
bin/rails test test/models/foo_test.rb:12   # single test at line 12
```

Tests run in parallel by default (`parallelize(workers: :number_of_processors)` in `test/test_helper.rb`). CI runs `bin/rails db:test:prepare test` against a real PostgreSQL service container, not a mock.

### Linting & security

```bash
bin/rubocop        # RuboCop, Rails Omakase house style (.rubocop.yml just inherits the gem's config — no local overrides)
bin/brakeman        # static security analysis
```

Both run in CI (`.github/workflows/ci.yml`) alongside the test suite, as independent jobs, on every push and PR to `main`.

## Architecture notes

- **API-only Rails app** (`config.api_only = true` in `config/application.rb`) — no views, no asset pipeline, no session/cookie middleware by default.
- **No Redis dependency**: background jobs, cache, and Action Cable all use the Rails 8 **Solid** adapters (Solid Queue, Solid Cache, Solid Cable), which are database-backed against the same PostgreSQL instance. Their schemas live in `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb` (separate from the primary `db/schema.rb` once it exists) — see `config/database.yml`'s `queue`/`cache`/`cable` production entries and `config/queue.yml`.
- **Deployment** is scaffolded for Kamal (`config/deploy.yml`, `.kamal/`), fronted by Thruster — not yet pointed at real infrastructure (placeholder IPs/hosts in `deploy.yml`).
- **Ruby version**: `.ruby-version` is set to `system` (not pinned); the only concrete version reference is `ARG RUBY_VERSION=3.2.2` in `backend/Dockerfile`.
- **CORS** (`config/initializers/cors.rb`) is present but fully commented out — cross-origin requests are not currently permitted.

When adding domain code, follow the layering described in `README.md`'s Architecture section (thin controllers → service objects for business logic → policy objects for authorization → query objects for complex reads), since none of those layers exist yet to copy conventions from.
