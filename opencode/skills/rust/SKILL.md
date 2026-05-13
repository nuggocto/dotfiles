---
name: rust
description: >
  Production-grade Rust backend guidance focused on idiomatic design,
  explicit error handling, safe concurrency, and reliable operations.
license: MIT
metadata:
  author: opencode
  version: "2.0.0"
---

# Rust

Use this skill for production-grade Rust services, APIs, workers, and backend tooling. Prefer the repository's existing stack over generic defaults; use the defaults below only when the codebase has no clear standard.

## Workflow

1. Identify the service shape and constraints: runtime, entrypoint, storage, external I/O, latency target, and deployment model.
2. Read only the files that govern the change: `Cargo.toml`, entrypoints, config, router, domain/service/repository modules, tests, migrations, and CI.
3. Preserve existing framework and crate choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps ownership, module boundaries, and error flow obvious.
5. Verify with the narrowest useful commands first; widen to full fmt/lint/test/build checks for broader changes.

## Default posture

- Prefer stable Rust, explicit ownership, and strong type boundaries.
- Prefer concrete types first; extract traits only for a real second implementation or a real test seam.
- Prefer thin transport layers, explicit transactions, and structured observability.
- Prefer clear synchronous-looking async code over clever abstractions.
- Do not add `unsafe`, deep macro magic, or unnecessary generics without a concrete payoff.

## Defaults when the repo has no standard

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Rust stable | Keep CI and local tooling aligned |
| Edition | 2024 | Follow the repo if already pinned |
| HTTP | Axum + Tower | Good default for composable services |
| Async runtime | Tokio | Use one runtime consistently |
| Database | SQLx | Prefer SQL-first access and explicit queries |
| Serialization | `serde` + `serde_json` | Use for API/config DTOs; keep wire contracts explicit |
| Errors | `thiserror` + `anyhow` | `anyhow` for internal app boundaries only |
| Logging | `tracing` + `tracing-subscriber` | Structured logs and spans |
| Linting | `rustfmt` + `clippy` | Mirror CI; use `-D warnings` for substantial changes when supported |
| Validation | `garde` or existing repo choice | Keep validation centralized |
| Secrets | `secrecy` | Reduce accidental secret exposure |
| Password hashing | `argon2` (Argon2id) | If the service stores passwords |
| IDs | `uuid` (UUIDv7) | Prefer one ID strategy per service |
| Date/time | `time` | Use one time crate consistently |
| Integration tests | `testcontainers-rs` | When behavior depends on external services |
| Security checks | `cargo-deny`, `cargo-audit` | Use when deps or security posture change |

If the repository already uses alternatives such as Actix, SeaORM, Diesel, or `chrono`, stay consistent unless the user asks for a migration.

## Architecture defaults

- Keep handlers/controllers focused on transport: parse input, call service, map output.
- Keep business rules, orchestration, and transaction ownership in services.
- Keep SQL, persistence mapping, and driver details in repositories.
- Keep startup, config, tracing setup, and graceful shutdown in dedicated bootstrap code.
- Keep shared middleware, extractors, pagination, and error envelopes in a small shared layer.

Suggested layout when starting from scratch:

```text
src/
  main.rs
  lib.rs
  startup.rs
  config.rs
  router.rs
  domain/
  infrastructure/
  shared/
tests/
sql/migrations/
```

## Rust conventions

- Use `snake_case` for modules, files, functions, and variables.
- Use `PascalCase` for structs, enums, traits, and type aliases.
- Use `SCREAMING_SNAKE_CASE` for constants.
- Use `Error` suffix for error types, `Builder` suffix for builders, and `try_` for fallible constructors.
- Use `Id`, not `ID`; use `Uuid`, not `UUID`; do not suffix async functions with `_async`.
- Prefer domain newtypes at boundaries instead of passing raw `String`, `i64`, or `Uuid` values everywhere.

## Modules, traits, and imports

- Define traits at the consumer boundary by default, not beside the implementation.
- Keep traits small and behavior-focused.
- Prefer `crate::...` imports in production modules.
- Reserve `use super::*;` mostly for tests where locality is obvious.
- Split modules when it improves ownership and readability, not just to create more files.

## Errors and observability

- Never `unwrap()`, `expect()`, or `panic!` in request paths, jobs, or business logic.
- Use `thiserror` enums for domain and application errors.
- Add context at I/O boundaries with `anyhow::Context` or equivalent internal wrappers.
- Convert infrastructure errors before they cross transport boundaries.
- Never leak internal error details to clients; log internals and return stable public codes.
- Use `tracing` fields and spans for request-scoped context such as `request_id`, `user_id`, and `trace_id`.

## Async and concurrency

- Every spawned task needs an owner, cancellation path, and shutdown behavior.
- Prefer bounded concurrency (`Semaphore`, worker pools, backpressure) over unbounded fan-out.
- Use `spawn_blocking` for CPU-heavy or blocking work in async services.
- Avoid holding mutex guards across `.await` points.
- Prefer message passing when ownership transfer is clearer than shared mutable state.

## HTTP, database, and security

- Use `http::StatusCode` constants, not numeric literals.
- Set body size limits, handler timeouts, outbound timeouts, and explicit CORS rules.
- Keep response and error envelopes stable within a service.
- Service layer owns transaction boundaries.
- Keep SQL and persistence mapping in repositories; avoid policy logic in query code.
- Use parameterized queries only; watch for N+1 patterns on hot paths.
- Prefer explicit migrations in `sql/migrations/` with one naming convention per repo.
- Use Argon2id for passwords, short-lived tokens, and explicit validation for token claims.
- Use secret wrappers where practical and avoid logging sensitive values.

## Serialization and API contracts

- Use `serde` for transport, config, and persistence DTOs; avoid forcing domain types to match JSON shape.
- Treat field names, defaults, skipped fields, and unknown-field behavior as API contract decisions.
- Prefer explicit request and response structs at service boundaries.
- Use strict deserialization such as `#[serde(deny_unknown_fields)]` only when rejecting unknown input is intentional.

## Testing and verification

- Keep unit tests close to the code when that improves locality.
- Add integration tests with real dependencies when external systems affect behavior.
- Use property tests, fuzzing, or benchmarks when invariants or performance justify them.
- Run `cargo fmt --all`, repo/CI-equivalent `cargo clippy`, and `cargo test`; for normal workspaces this is usually `cargo clippy --workspace --all-targets --all-features -- -D warnings` and `cargo test --workspace --all-features`.
- Run `cargo deny check` or `cargo audit` when dependency or security-sensitive work is involved.

## Guardrails

- Do not mix handler, service, and repository responsibilities in one module.
- Do not introduce global mutable state when scoped ownership will do.
- Do not fire-and-forget critical work.
- Do not add dependencies for tiny conveniences without a clear maintenance win.
- Do not refactor broadly when a small targeted fix solves the problem.

## Response expectations

When using this skill:

1. State the architecture impact of the change in plain language.
2. Call out trade-offs when choosing crates, async patterns, or boundaries.
3. Prefer concrete file-level guidance over abstract Rust advice.
4. End with the most relevant verification commands or follow-up checks.
