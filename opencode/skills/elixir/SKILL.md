---
name: elixir
description: >
  Production-grade Elixir backend guidance focused on Phoenix, Ecto, the BEAM,
  and reliable, observable services.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# Elixir

Use this skill for production-grade Elixir services, APIs, real-time apps, background-job systems, and internal backend tooling built on Phoenix, Ecto, and the BEAM. Prefer the repository's existing stack over generic defaults; use the defaults below only when the codebase has no clear standard.

When library behavior is uncertain, prefer the official Hex docs over memorized APIs.

## Workflow

1. Identify the service shape and constraints: runtime, supervision model, storage, external I/O, latency target, and deployment model.
2. Read only the files that govern the change: `mix.exs`, `config/`, entrypoints (`application.ex`), routers, contexts/schemas, migrations, tests, telemetry/observer code, and CI.
3. Preserve existing framework and library choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps function pipelines, process ownership, and error flow obvious.
5. Verify with the narrowest useful commands first; widen to full format/lint/test/build checks for broader changes.

## Default posture

- Prefer explicit functional pipelines, immutable data, and pattern matching.
- Prefer supervision trees and crash-only design for unexpected failures.
- Prefer thin transport layers (controllers/live views), explicit changesets, and telemetry-aware services.
- Prefer clear synchronous-looking async code over clever macro abstractions.
- Do not add metaprogramming, NIFs, or global process registries without a concrete payoff.

## Defaults when the repo has no standard

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Elixir + Erlang/OTP pinned by `.tool-versions`, `mix.exs`, or CI | Keep CI and local tooling aligned |
| Build | `mix` | Standard build, deps, and task runner |
| Formatting | `mix format` | Format touched files or the full project |
| Testing | `mix test` (ExUnit) | Use tags, `setup`, and factories when helpful |
| HTTP | Phoenix + Bandit | Bandit is the default server for new Phoenix apps |
| Realtime | Phoenix LiveView / Channels | Use only when the interaction model justifies it |
| PubSub | Phoenix.PubSub (PG adapter or Redis) | Match the deployment topology |
| Database | Ecto + postgrex | SQL-first, schema-driven access |
| Migrations | Ecto migrations in `priv/repo/migrations/` | One directional, reversible `change` when possible |
| Background jobs | Oban | Postgres-backed, observable, and retry-aware |
| JSON | Jason | Keep wire contracts explicit |
| Validation | Ecto.Changeset | Centralize domain rules in changesets or contexts |
| Logging | `Logger` + Telemetry | Structured metadata and request-scoped keys |
| Tracing | `:opentelemetry` | Add only when distributed tracing is required |
| Password hashing | `argon2_elixir` (Argon2id) | If the service stores passwords |
| IDs | `Ecto.UUID` or `uuidv7` | Prefer one ID strategy per service |
| Date/time | `DateTime` / `NaiveDateTime` | Keep time zones explicit and consistent |
| Static analysis | Credo + Dialyzer | Run on substantial or style-sensitive changes |
| Integration tests | Ephemeral DB or `testcontainers-elixir` | When external systems affect behavior |

If the repository already uses alternatives such as Plug with Cowboy, Ash, Broadway, Quantum, or another established stack, stay consistent unless the user explicitly asks for a migration.

## Architecture defaults

- Keep controllers and live views focused on transport: parse input, call the context, map output.
- Keep business rules, orchestration, and transaction ownership in contexts.
- Keep schemas, changesets, and persistence mapping in schema modules and repositories.
- Keep startup, supervision wiring, config, and graceful shutdown in `application.ex` and bootstrap modules.
- Keep shared plugs, middleware, error mapping, pagination, and telemetry events in a small web layer.

Suggested layout when starting from scratch:

```text
mix.exs
config/
lib/
  my_app/
    application.ex
    repo.ex
    accounts/
      user.ex
      user_token.ex
      accounts.ex
    web/
      router.ex
      controllers/
      live/
      components/
      plugs/
  my_app_web.ex
priv/
  repo/migrations/
  static/
test/
```

## Elixir conventions

- Use `PascalCase` for module names and aliases.
- Use `snake_case` for functions, variables, files, and directories.
- Use `__MODULE__` sparingly and only when it materially improves clarity.
- Name boolean functions and guards with a trailing `?`.
- Provide bang variants (`!`) only where raising is a clear, documented contract.
- Prefer `|>` pipelines for sequences of transformations.
- Prefer pattern matching and `case`/`with`/`for` over nested conditionals.
- Use atoms for named constants and struct keys; avoid dynamic atom creation from external input.

## Contexts, schemas, and changesets

- Treat contexts as the public API of a domain boundary.
- Keep schemas focused on data shape, changesets, and query helpers.
- Validate at the boundary with changesets; do not leak raw params deep into the system.
- Keep SQL and transaction scope explicit in contexts or repository modules.
- Avoid putting business rules in controllers, live views, or templates.

## Errors and observability

- Let the supervisor handle programmer errors and unexpected crashes; return `{:ok, _}` / `{:error, _}` tuples for expected failures.
- Never silently ignore `:ok` results or `{:error, _}` matches from I/O, DB, or external calls.
- Convert infrastructure errors into stable domain errors before crossing context boundaries.
- Never leak internal error details to clients; log internals and return stable public codes.
- Use `Logger.metadata` for request-scoped context such as `request_id`, `user_id`, and `trace_id`.
- Emit Telemetry events for important operations and attach metrics in one place.

## Concurrency, processes, and state

- Every long-running process needs a supervisor, a shutdown path, and an explicit reason to exist.
- Use GenServers only when you need stateful, serialized access; prefer pure functions otherwise.
- Avoid `Task.async` without a corresponding `await`; use `Task.yield_many` for bounded fan-out.
- Prefer `GenServer.call` over `cast` when the caller needs backpressure or confirmation.
- Do not store `context` in process state; pass it explicitly through arguments.
- Use process dictionaries and `:persistent_term` sparingly and document why they are needed.

## HTTP, database, and security

- Use `Plug.Conn.Status` / `Phoenix.Controller` helpers, not raw numeric status codes.
- Set body size limits, timeouts, and explicit CORS rules at the endpoint/plug level.
- Keep response and error envelopes stable within an API surface.
- Service/context layer owns transaction boundaries.
- Keep SQL in Ecto queries or repository functions, not in controllers or live views.
- Use parameterized queries only; watch for N+1 patterns on hot paths and preload deliberately.
- Use Argon2id for passwords, short-lived tokens, and explicit validation for token claims.
- Avoid logging secrets, raw tokens, or sensitive params; filter them at the endpoint.

## Serialization and API contracts

- Use Jason for transport and config DTOs; avoid forcing domain types to match JSON shape.
- Treat JSON keys, defaults, omitted fields, unknown-field behavior, and time formats as API contract decisions.
- Prefer explicit request and response structs or Phoenix view patterns at service boundaries.
- Use Ecto.Changeset validation to reject invalid input before it reaches domain logic.

## Testing and verification

- Keep ExUnit tests close to the code when locality improves understanding.
- Use `setup`, `setup_all`, tags, and factories (e.g. ExMachina) consistently.
- Add integration tests with real dependencies when mocks would hide important behavior.
- Test both happy paths and error paths; assert on `{:error, _}` shapes, not just success.
- Run `mix format`, `mix test`, `mix credo --strict`, and `mix dialyzer` for substantial changes.
- Run `mix deps.audit` or `mix hex.audit` when dependency or security posture changes.

## Guardrails

- Do not put business logic in controllers, live views, or templates.
- Do not introduce global mutable process state when explicit arguments will do.
- Do not fire-and-forget critical work; use Oban or a supervised process with confirmation.
- Do not add dependencies for tiny conveniences without a clear maintenance win.
- Do not refactor broadly when a small targeted fix solves the problem.

## Native extensions

For NIFs, ports, or shared libraries implemented in Rust or Zig, apply `@tiger_style/` and the corresponding language skill (`@rust/` or `@zig/`). Keep the Elixir boundary thin, well-supervised, and isolated from the BEAM scheduler when the native code can block or crash.

## Response expectations

When using this skill:

1. State the architecture and supervision impact of the change in plain language.
2. Call out trade-offs when choosing libraries, process models, or context boundaries.
3. Prefer concrete file-level guidance over abstract Elixir advice.
4. Point to relevant Hex docs when library specifics matter.
5. End with the most relevant verification commands or follow-up checks.
