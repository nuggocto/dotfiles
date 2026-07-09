---
name: elixir
description: >
  Production-grade Elixir backend guidance focused on Phoenix, Ecto, the BEAM,
  and reliable, observable services. Use when working with Elixir/Phoenix code,
  .ex/.exs files, mix projects, Ecto schemas or migrations, LiveView, or BEAM
  services.
license: MIT
metadata:
  author: opencode
  version: "2.0.0"
---

# Elixir

Use this skill for production-grade Elixir applications, libraries, services, APIs, real-time apps, background jobs, and tooling on the BEAM. Apply Phoenix and Ecto guidance only when those technologies are present or are being deliberately selected. Prefer the repository's existing stack over generic defaults.

When behavior is uncertain, prefer current official Elixir, Erlang/OTP, Phoenix, and Ecto documentation plus the package's versioned HexDocs and upstream repository over memorized APIs.

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

## Opinionated starter options

Use these only for a new application when its requirements fit. They are ecosystem choices, not language-wide requirements.

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Elixir + Erlang/OTP pinned by `.tool-versions`, `mix.exs`, or CI | Keep CI and local tooling aligned |
| Build | `mix` | Standard build, deps, and task runner |
| Formatting | `mix format` | Format touched files or the full project |
| Testing | `mix test` (ExUnit) | Use tags, `setup`, and factories when helpful |
| HTTP | Phoenix + Bandit | Bandit is the default server for new Phoenix apps |
| Realtime | Phoenix LiveView / Channels | Use only when the interaction model justifies it |
| PubSub | `Phoenix.PubSub.PG2`; optionally `Phoenix.PubSub.Redis` | PG2 is bundled; Redis requires `:phoenix_pubsub_redis` |
| Database | Ecto + postgrex | SQL-first, schema-driven access |
| Migrations | Ecto migrations in `priv/repo/migrations/` | Use `change/0` only for reversible operations; otherwise define `up/0` and `down/0` |
| Background jobs | Oban | SQL-backed, observable, and retry-aware; supports PostgreSQL, MySQL, and SQLite engines |
| JSON | Repository-configured JSON library | Phoenix commonly uses Jason; Elixir 1.18+ also provides `JSON` |
| Validation | Ecto.Changeset | Centralize domain rules in changesets or contexts |
| Logging | `Logger` | Configure structured output and selected metadata keys |
| Metrics/events | `:telemetry` | Keep synchronous handlers fast and non-blocking |
| Tracing | OpenTelemetry instrumentation + exporter | Add only when distributed tracing is required |
| Password hashing | `argon2_elixir` (Argon2id) | If the service stores passwords |
| IDs | `Ecto.UUID` | Use v4 by default or version 7 when time ordering is required |
| Date/time | `DateTime` for instants; `NaiveDateTime` for timezone-less wall time | Store instants in UTC and convert at boundaries |
| Static analysis | Credo + Dialyzer when configured | Match the repository's quality gates |
| Integration tests | Ephemeral DB or `testcontainers-elixir` | When external systems affect behavior |

If the repository already uses alternatives such as Plug with Cowboy, Ash, Broadway, Quantum, or another established stack, stay consistent unless the user explicitly asks for a migration.

## Architecture defaults

- Keep controllers and live views focused on transport: parse input, call the context, map output.
- Use contexts as intentionally named plain-module APIs for related capabilities. They are useful Phoenix boundaries, not mandatory layers for every domain.
- Keep business rules and orchestration in cohesive application modules; let the operation coordinating atomic work own its transaction.
- Keep schemas focused on data shape, changesets, constraints, and query helpers.
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
    accounts.ex
    accounts/
      user.ex
      user_token.ex
  my_app_web.ex
  my_app_web/
    endpoint.ex
    router.ex
    controllers/
    live/
    components/
    plugs/
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

- Treat contexts as intentionally named public APIs where they improve cohesion; do not create them mechanically for every schema or operation.
- Keep schemas focused on data shape, changesets, and query helpers.
- Cast and validate untrusted input with changesets at boundaries; do not leak raw params deep into the system.
- Enforce uniqueness, referential integrity, and race-sensitive invariants with database constraints, then translate expected violations through changeset constraint functions.
- Keep SQL and transaction scope explicit in the application operation that owns the atomicity requirement.
- In applications using Phoenix scopes, accept the scope in context functions and constrain data access through it.
- Avoid putting business rules in controllers, live views, or templates.

## Errors and observability

- Let the supervisor handle programmer errors and unexpected crashes; return `{:ok, _}` / `{:error, _}` tuples for expected failures.
- Do not discard fallible results. Pattern-match, propagate, or explicitly handle `{:error, reason}` variants from I/O, database, and external calls.
- Convert infrastructure errors into stable domain errors before crossing context boundaries.
- Never leak internal error details to clients; log internals and return stable public codes.
- Set `Logger.metadata` in the process that emits the log and explicitly propagate relevant context to spawned processes.
- Emit Telemetry events for important operations, keep synchronous handlers non-blocking, and attach metrics or exporters in one place.

## Concurrency, processes, and state

- Every long-running process needs a supervisor, a shutdown path, and an explicit reason to exist.
- Use processes to model runtime properties such as state, concurrency, shared-resource ownership, and failure isolation. Never use a GenServer merely to organize code.
- Avoid `Task.async` without a corresponding await or yield. For bounded fan-out, use `Task.async_stream/3` or supervised `async_stream` with explicit `:max_concurrency`; use `Task.yield_many/2` only to collect already-started tasks.
- Prefer `GenServer.call` over `cast` when the caller needs backpressure or confirmation.
- Keep process-owned lifecycle state in the process. Pass caller-specific and request-specific data explicitly unless retaining it is part of the process contract.
- Use process dictionaries and `:persistent_term` sparingly and document why they are needed.

## HTTP, database, and security

- Use `Plug.Conn.Status` / `Phoenix.Controller` helpers, not raw numeric status codes.
- Set body size limits, timeouts, and explicit CORS rules at the endpoint/plug level.
- Keep response and error envelopes stable within an API surface.
- The operation coordinating an atomic use case owns the transaction boundary.
- Keep SQL in Ecto queries or repository functions, not in controllers or live views.
- Use parameterized queries only; watch for N+1 patterns on hot paths and preload deliberately.
- Use Argon2id for human-chosen passwords. Generate opaque tokens with `:crypto.strong_rand_bytes/1`, use a vetted signed or encrypted format for self-contained tokens, store bearer-token digests rather than plaintext, and validate expiry and claims explicitly.
- Avoid logging secrets, raw tokens, or sensitive params; filter them at the endpoint.

## Serialization and API contracts

- Use the repository's configured JSON library for transport DTOs; avoid forcing domain types to match wire shapes.
- Treat JSON keys, defaults, omitted fields, unknown-field behavior, and time formats as API contract decisions.
- Prefer explicit request and response structs or Phoenix view patterns at service boundaries.
- Use Ecto.Changeset validation to reject invalid input before it reaches domain logic.

## Testing and verification

- Keep ExUnit tests close to the code when locality improves understanding.
- Use `setup`, `setup_all`, tags, and factories (e.g. ExMachina) consistently.
- Add integration tests with real dependencies when mocks would hide important behavior.
- Test both happy paths and error paths; assert on `{:error, _}` shapes, not just success.
- Run `mix format --check-formatted` and `mix test` for substantial changes. Run `mix credo --strict` and `mix dialyzer` only when Credo and Dialyxir are configured.
- Run `mix hex.audit` when dependency or security posture changes. Use `mix deps.audit` only when `mix_audit` is configured.

## Guardrails

- Do not put business logic in controllers, live views, or templates.
- Do not introduce global mutable process state when explicit arguments will do.
- Do not fire-and-forget critical work. Use a durable queue or transactional outbox, such as Oban, when work must survive process or node restarts; use supervised processes only when restart-time loss is acceptable and completion or failure is observed.
- Do not add dependencies for tiny conveniences without a clear maintenance win.
- Do not refactor broadly when a small targeted fix solves the problem.

## Native extensions

For native code implemented in Rust or Zig, apply `@tiger_style/` and the corresponding language skill (`@rust/` or `@zig/`). Minimize and precisely type the boundary. Keep regular NIF calls short and use correctly classified dirty schedulers for unavoidable lengthy work. A crashing NIF can crash the entire BEAM VM and cannot be recovered by supervision; use an external OS process through a port when crash isolation is required.

## Response expectations

For substantial changes using this skill:

1. State the architecture and supervision impact of the change in plain language.
2. Call out trade-offs when choosing libraries, process models, or context boundaries.
3. Prefer concrete file-level guidance over abstract Elixir advice.
4. Point to official project docs or the package's versioned HexDocs and upstream repository when specifics matter.
5. End with the most relevant verification commands or follow-up checks.
