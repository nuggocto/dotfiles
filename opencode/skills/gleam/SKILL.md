---
name: gleam
description: >
  Production-grade Gleam backend guidance focused on type-safe functional
  services on the BEAM, using Wisp, Mist, Squirrel, and the Gleam ecosystem.
  Use when working with Gleam code, .gleam files, gleam.toml projects,
  Wisp/Mist handlers, or Squirrel SQL.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# Gleam

Use this skill for production-grade Gleam services, APIs, and backend tooling running on the Erlang VM. Prefer the repository's existing stack over generic defaults; use the defaults below only when the codebase has no clear standard.

When library behavior is uncertain, prefer the official Hex docs over memorized APIs.

## Workflow

1. Identify the service shape and constraints: runtime, actor model, storage, external I/O, latency target, and deployment model.
2. Read only the files that govern the change: `gleam.toml`, `manifest.toml`, entrypoints, router, handlers, domain modules, Squirrel SQL files, tests, and CI.
3. Preserve existing framework and package choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps types, function pipelines, actor ownership, and error flow obvious.
5. Verify with the narrowest useful commands first; widen to full format/test/build checks for broader changes.

## Default posture

- Prefer explicit types, immutable data, and exhaustive pattern matching.
- Prefer small, pure functions and narrow, behavior-focused modules.
- Prefer the Gleam standard library and small, well-maintained Hex packages.
- Prefer clear actor supervision and bounded concurrency over clever abstractions.
- Do not add unsafe Erlang FFI, metaprogramming, or global mutable state without a concrete payoff.

## Defaults when the repo has no standard

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Gleam + Erlang/OTP pinned by `.tool-versions` or CI | Keep CI and local tooling aligned |
| Build | `gleam build` | Type-checked, reproducible builds |
| Formatting | `gleam format` | Format touched files or the full project |
| Testing | `gleam test` (gleeunit) | Standard test runner on the BEAM |
| HTTP server | Mist | Lightweight HTTP/1.1 and WebSocket server |
| Web framework | Wisp | Built on Mist; handles routing, middleware, and requests |
| Database | Squirrel + pog | Type-safe generated SQL over the `pog` Postgres driver |
| Migrations | Plain SQL migrations (e.g. Flyway, sqitch, or a project script) | Keep schema changes versioned outside application code |
| JSON | `gleam_json` | Explicit encode/decode functions |
| Validation | Custom validators + Wisp middleware | Keep validation centralized at the boundary |
| Logging | Erlang `logger` via Gleam bindings or project logger | Structured metadata and request-scoped keys |
| IDs | `gleam_uuid` or `youid` | Prefer one ID strategy per service |
| Date/time | `birl` | Keep time zones explicit and consistent |
| Static analysis | Gleam's type checker + `gleam format` | The type checker is the first line of defense |
| Integration tests | Real PostgreSQL instance | When external deps affect behavior |

If the repository already uses alternatives such as a different HTTP server, database layer, or migration strategy, stay consistent unless the user explicitly asks for a migration.

## Architecture defaults

- Keep handlers focused on transport: parse input, call domain logic, encode output.
- Keep business rules, orchestration, and transaction ownership in domain/service modules.
- Keep SQL and persistence details in Squirrel-generated modules and thin adapter functions.
- Keep startup, supervision wiring, config, and shutdown behavior in the main `app.gleam` or bootstrap modules.
- Keep shared middleware, error mapping, and request helpers small and explicit.

Suggested layout when starting from scratch:

```text
gleam.toml
manifest.toml
src/
  my_app.gleam
  my_app/
    router.gleam
    handlers/
    middleware/
    domain/
    persistence/
sql/
  queries/
  migrations/
test/
```

## Gleam conventions

- Use `snake_case` for module names, functions, variables, files, and directories.
- Use `PascalCase` for custom types and constructors.
- Use `Option` and `Result` instead of null-like sentinels.
- Prefer custom types and records over loosely typed maps for domain data.
- Use the pipe operator (`|>`) for sequences of transformations.
- Use `case` expressions with exhaustive pattern matching; let the compiler warn about missing branches.
- Keep functions small enough to reason about in one screenful.

## Types, functions, and modules

- Make invalid states unrepresentable with custom types.
- Keep modules cohesive; split when a module mixes transport, domain, and persistence concerns.
- Prefer explicit imports; avoid wildcard imports that hide dependencies.
- Define types at the boundaries where data enters or leaves the system.
- Use phantom types or opaque types when a value needs to carry a provenance guarantee.

## Errors and observability

- Model expected failures with `Result`; use `Option` for optional values.
- Never silently ignore `Error` variants from I/O, DB, or external calls.
- Add context at I/O and FFI boundaries before errors cross higher-level APIs.
- Never leak internal error details to clients; log internals and return stable public codes.
- Include request-scoped keys such as `request_id`, `user_id`, and `trace_id` in logs when available.
- Emit telemetry or log events for important operations and attach metrics in one place.

## Concurrency, actors, and context

- Every actor needs a supervisor, a shutdown path, and an explicit owner.
- Use actors only when stateful, serialized access or isolation is required; prefer pure functions otherwise.
- Propagate request context explicitly; do not hide it in process dictionaries or ambient state.
- Avoid unbounded actor or process creation; use worker pools or backpressure for fan-out.
- Be explicit about blocking calls and CPU-heavy work; move them off the critical path when possible.

## HTTP, database, and security

- Use Wisp helpers and explicit status values, not raw numeric literals.
- Set body size limits, timeouts, and CORS rules in middleware near the router.
- Keep response and error envelopes stable within an API surface.
- Domain/service layer owns transaction boundaries.
- Keep SQL in `.sql` files consumed by Squirrel; do not hand-edit generated code.
- Use parameterized queries only; watch for N+1 patterns on hot paths.
- Prefer SQL migrations with reversible steps when possible.
- Use Argon2id for passwords and avoid logging secrets or raw tokens.

## Serialization and API contracts

- Use `gleam_json` for transport and config DTOs; keep encode/decode functions explicit.
- Treat field names, defaults, optional fields, unknown-field behavior, and time formats as API contract decisions.
- Prefer explicit request and response types at handler boundaries.
- Reject unknown JSON fields intentionally, not by accident.

## Testing and verification

- Keep gleeunit tests close to the code when locality improves understanding.
- Use table-driven tests with lists of input/expected pairs when a behavior has many cases.
- Add integration tests with real dependencies when mocks would hide important behavior.
- Test both happy paths and error paths; assert on `Error(_)` shapes, not just success.
- Run `gleam format`, `gleam test`, and `gleam build` for substantial changes.
- Regenerate Squirrel code after changing `.sql` files and verify the build still passes.

## Guardrails

- Do not let handlers accumulate business logic.
- Do not let services reach into transport concerns.
- Do not introduce global mutable state when explicit arguments will do.
- Do not start background actors without ownership and shutdown.
- Do not add dependencies for tiny conveniences without a clear maintenance win.
- Do not refactor broadly when a small targeted fix solves the problem.

## Native extensions

For Erlang NIFs, ports, or shared libraries implemented in Rust or Zig, apply `@tiger_style/` and the corresponding language skill (`@rust/` or `@zig/`). Keep the Gleam boundary thin, well-supervised, and isolated from the BEAM scheduler when the native code can block or crash.

## Response expectations

When using this skill:

1. State the architecture and actor/supervision impact of the change in plain language.
2. Call out trade-offs when choosing packages, concurrency patterns, or type boundaries.
3. Prefer concrete file-level guidance over abstract Gleam advice.
4. Point to relevant Hex docs when library specifics matter.
5. End with the most relevant verification commands or follow-up checks.
