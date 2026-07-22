# SESSION.md

Project memory for the Technical Lead workflow. Updated at the end of every completed task — read this before ROADMAP/README context to know where things actually stand, not just where the roadmap says they should.

**Last updated:** 2026-07-21

---

## Current milestone

**Core Domain — Bookmaker Account Management** (see root `README.md#roadmap`).

## Current feature

Bookmaker deletion (unguarded) + structured API error envelope. Both tracked on the roadmap; work exists in `backend/` as **uncommitted, unmerged changes** — not yet a commit, not yet a PR. Guard descoped — see Decision Log.

## Completed work

- Error envelope groundwork: `app/controllers/concerns/error_handler.rb`, `app/errors/application_error.rb`.
- `DELETE /api/v1/bookmakers/:id` route wired in `BookmakersController#destroy`.
- Request spec skeleton at `spec/requests/api/v1/bookmakers/destroy_spec.rb`.

## Pending work

*(Not yet implemented — see prior instruction to hold off on code changes this session.)*

- Fix the autoload bug in `app/services/bookmakers/destroy_service.rb` (see Technical debt — this blocks the feature from booting at all, independent of the guard decision).
- Remove `app/errors/bookmakers/active_accounts_exist_error.rb` — dead code now that the guard is descoped (or leave in place with a comment if the follow-up is expected soon; decide at implementation time).
- Fix request-spec bugs: bookmaker fixtures are created under `create(:user)` instead of the authenticated `user`, so all cases currently exercise the 404 path regardless of intent.
- Drop the "when the bookmaker has active accounts" spec context — no longer applicable now that the guard is descoped.
- Finish the error-envelope migration: `ApplicationController#render_forbidden` still returns the old flat `{ error: "Forbidden" }` shape while `ErrorHandler` introduces the new nested `{ error: { code, message } }` shape. `ApplicationController`'s now-redundant `rescue_from ActiveRecord::RecordNotFound` / `render_not_found` (shadowed by the `ErrorHandler` concern) should be removed.

## Architectural decisions

None formally recorded as ADRs yet (`docs/adr/README.md` index is still empty — correctly, per that doc's own framing of the foundation phase). Smaller decisions tracked below per the ADR policy's "record in a Decision Log if small."

### Decision Log

**2026-07-21 — Descope the active-accounts deletion guard; ship unguarded bookmaker deletion.**
- **Context:** The roadmap item "Bookmaker deletion with business-rule guards" implicitly depends on an `Account` model, which doesn't exist yet (`Account` is scoped under the not-yet-started Financial Engine milestone). The in-progress branch had started building the guard (`ActiveAccountsExistError`) ahead of that dependency.
- **Decision:** Ship `DELETE /api/v1/bookmakers/:id` without the active-accounts guard now. Re-introduce the guard once the Financial Engine milestone brings a real `Account` model into existence — don't pull forward a stub model just to unblock this.
- **Consequences:** Bookmaker deletion is temporarily unsafe with respect to linked accounts (moot today since no accounts can exist yet, but will need re-review the moment `Account` ships). Roadmap's "Core Domain" bullet for deletion should be marked done-without-guard, with the guard itself re-added as a Financial Engine follow-up rather than a Core Domain blocker.

## Technical debt

- **Blocking:** `app/services/bookmakers/destroy_service.rb` defines `DestroyService` at the top level instead of `Bookmakers::DestroyService`, violating Zeitwerk's file-path/constant-path convention (and the naming convention documented in `backend/README.md#naming-conventions`). Raises `Zeitwerk::NameError` on load. Must be fixed before this code can run at all.
- Follow-up owed: re-add the active-accounts deletion guard once `Account` exists (see Decision Log above). Not tracked as debt in the "sloppy" sense — a deliberate, documented deferral — but must not be forgotten when Financial Engine work starts.
- Root repo has no `.github/` governance surface: no PR template, issue templates, `CODEOWNERS`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`. Backend submodule correctly has its own CI/Dependabot config; this gap is root-level only. Low urgency (solo author), but cheap and portfolio-visible.
- `docs/adr/0000-template.md` doesn't exist as a copyable file; the template is inlined in `docs/adr/README.md` only.

## Next recommended task

Implement the descoped version: fix the `Zeitwerk` autoload bug, remove the now-dead `ActiveAccountsExistError` guard code and its spec context, fix the request-spec fixture bug (wrong user), and finish the error-envelope migration (`render_forbidden` shape + dead `rescue_from` in `ApplicationController`). None of this has been touched yet — this session was documentation/decision-only per explicit instruction.

## Suggested prompt for next session

> Implement the descoped bookmaker-deletion feature per SESSION.md's Decision Log (2026-07-21): fix the Zeitwerk autoload bug in `destroy_service.rb`, remove the active-accounts guard code and its spec context, fix the request-spec fixture bug (bookmaker created under the wrong user), and finish the error-envelope migration so `render_forbidden` matches the new nested shape.
