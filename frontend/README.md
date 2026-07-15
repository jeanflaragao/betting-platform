# Frontend

## Status

Not implemented. No client application exists in this repository yet — see the [Roadmap](../README.md#roadmap).

## Purpose

A decoupled client consuming the [backend](../backend/README.md) API, which is deliberately built API-only (`config.api_only = true`) with no view layer or session/cookie middleware. The backend does not assume any particular client today, so this frontend's job will be to turn the JSON contract into the actual betting experience for end users — placing bets, viewing live odds, and tracking settlement outcomes.

## Planned architecture

Once started, this will follow the same separation-of-concerns discipline as the backend: presentation components kept thin, with state management and API interaction isolated behind a dedicated data layer rather than scattered across components. Exact patterns will be documented here once implementation begins, and cross-linked from [docs/architecture](../docs/architecture/overview.md).

## Future technologies

No stack has been committed to yet. This section will be filled in — and CORS enabled on the backend (currently commented out in `config/initializers/cors.rb`) — once frontend work starts.
