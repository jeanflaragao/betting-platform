# API Documentation

## Current state

No API documentation tooling is configured yet. The only route currently exposed is the health check:

```bash
curl http://localhost:3000/up
```

There is nothing else to document until domain resources exist — see the [Roadmap](../../README.md#roadmap).

## Planned direction

Once the first domain resources exist, the plan is to adopt an OpenAPI-based toolchain — [rswag](https://github.com/rswag/rswag) is the leading candidate — so that request specs double as the source of truth for a generated OpenAPI 3.0 spec, served via Swagger UI. This keeps the documentation from drifting out of sync with the actual API contract, since a broken spec fails the same test suite that gates merges.

This is tracked as **Planned** under the Core Domain milestone in the [Roadmap](../../README.md#roadmap). Once implemented, this document will hold (or link to) the generated spec and describe authentication, versioning, and error envelope conventions for API consumers.
