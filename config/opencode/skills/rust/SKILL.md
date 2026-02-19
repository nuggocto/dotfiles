---
name: rust
description: >
  Production-grade Rust backend guidance focused on idiomatic design,
  explicit error handling, safe concurrency, and reliable operations.
---

# Rust Skill

## Core Philosophy

Be an honest, insightful programming partner. Challenge code when there are clear improvements in:

1. Efficiency
2. Readability and maintainability
3. Robustness and error handling
4. Scalability
5. Best practices and conventions
6. Security

If a solution is already idiomatic and solid, affirm it. Avoid churn and "refactor for refactor's sake." Explain the "why" behind suggestions.

## Rule Levels

Use this priority model to avoid over-constraining normal Rust work.

- MUST: hard requirements for reliability, correctness, and security.
- SHOULD: strong defaults; deviate only with clear context.
- MAY: optional choices based on scale, constraints, or product needs.

## Code Quality Principles

- Prefer iterators and combinators when they improve clarity.
- Keep functions focused and easy to scan; split only when it helps understanding.
- Make illegal states unrepresentable with enums/newtypes when practical.
- Handle errors explicitly; no silent failure paths.
- Minimize deep nesting and unnecessary indirection.
- Favor composition and traits over inheritance-style design.
- Enforce quality gates with tooling in CI.

## Project Philosophy

- Prefer zero-cost abstractions, explicit ownership, and strong type boundaries.
- Use dependencies intentionally; "stdlib-first" does not mean "no dependencies."
- Default to secure and observable behavior for networked services.

## Default Stack

These are default choices, not universal hard requirements.

| Category | Default | Level | Notes |
|----------|---------|-------|-------|
| Language | Rust stable | MUST | Keep toolchain pinned in CI |
| Edition | 2024 | SHOULD | Follow repository edition consistently |
| Web framework | Axum | SHOULD | Composable with Tower |
| Async runtime | Tokio | SHOULD | Production async runtime |
| DB access | SQLx | SHOULD | Async SQL, strong typing |
| Middleware | Tower / tower-http | SHOULD | Timeouts, tracing, limits |
| Error types | thiserror | MUST | Domain and application error enums |
| Error context | anyhow | MAY | Internal app/service boundaries |
| Logging | tracing + tracing-subscriber | MUST | Structured logs and spans |
| Validation | garde | SHOULD | Derive-based validation |
| Password hashing | argon2 (Argon2id) | MUST (if passwords) | Store parameters with hash |
| Secret handling | secrecy | SHOULD | Reduce accidental secret exposure |
| HTTP client | reqwest | SHOULD | Explicit timeout/retry policy |
| IDs | uuid (UUIDv7) | SHOULD | Time-sortable IDs |
| Date/time | time | SHOULD | Prefer one crate consistently |
| Dev reload | cargo-watch | MAY | Local dev loop (`cargo watch -x run`) |
| Integration tests | testcontainers-rs | SHOULD | Use when external deps affect behavior |
| Parameterized tests | rstest | MAY | Improves test readability |
| Security audit | cargo-deny + cargo-audit | SHOULD | Dependency/license hygiene |
| Message queues | lapin, async-nats | MAY | Add only when async workflow demands it |

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files/modules | `snake_case` | `user_repository.rs`, `mod user_service` |
| Structs/enums/traits | PascalCase | `UserService`, `UserRole`, `EmailSender` |
| Functions/methods | `snake_case` | `get_by_id`, `validate_input` |
| Variables | `snake_case` | `user_id`, `donation_count` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_RETRIES` |
| Type aliases | PascalCase | `type AppResult<T> = Result<T, AppError>` |
| Error types | `Error` suffix | `UserError`, `AppError` |
| Builders | `Builder` suffix | `UserBuilder` |
| Fallible ctors | `try_` prefix | `Config::try_from_env()` |
| Booleans | `is_`, `has_`, `can_` | `is_active`, `has_permission` |
| Unsafe APIs | `*_unchecked` suffix | `get_unchecked` |

Rust idioms:

- Use `Id`, not `ID`: `UserId`, `user_id`.
- Use `Uuid`, not `UUID`: `Uuid::now_v7()`.
- No `_async` suffix for async functions.
- Prefer explicit domain newtypes over raw primitives at boundaries.

## Traits, Modules, Imports

- Define traits at the consumer boundary by default.
- Start with concrete types; extract traits when multiple implementations or test seams are real.
- Keep traits small and behavior-focused.
- Prefer explicit `crate::` imports in production modules.
- Use `super::*` mainly in tests where locality is clear.

Example:

```rust
// good
use crate::domain::user::{model::User, service::UserService};

// acceptable in tests
use super::*;
```

## Project Layout (Template)

Use this as a starting point and adapt names to your domain.

```text
project/
├── src/
│   ├── main.rs                     # entrypoint
│   ├── lib.rs
│   ├── startup.rs                  # bootstrapping, tracing, shutdown
│   ├── config.rs                   # env/config parsing
│   ├── router.rs                   # route wiring only
│   │
│   ├── domain/
│   │   ├── mod.rs
│   │   └── user/
│   │       ├── mod.rs
│   │       ├── model.rs
│   │       ├── service.rs
│   │       ├── repository.rs
│   │       ├── handlers.rs
│   │       └── error.rs
│   │
│   ├── infrastructure/
│   │   ├── mod.rs
│   │   ├── database.rs
│   │   ├── cache.rs
│   │   ├── queue.rs
│   │   └── security/
│   │       ├── mod.rs
│   │       ├── password.rs
│   │       └── token.rs
│   │
│   └── shared/
│       ├── mod.rs
│       ├── errors.rs
│       ├── extractors.rs
│       ├── pagination.rs
│       └── middleware/
│           ├── mod.rs
│           ├── request_id.rs
│           ├── security_headers.rs
│           └── metrics.rs
│
├── sql/
│   ├── migrations/
│   └── queries/
│
├── tests/
│   ├── integration/
│   │   ├── mod.rs
│   │   ├── helpers.rs
│   │   └── user_tests.rs
│   └── testutil/
│       └── fixtures.rs
│
├── Cargo.toml
├── Cargo.lock
├── clippy.toml
├── rustfmt.toml
├── .cargo/config.toml
├── justfile
├── docker-compose.yml
└── README.md
```

## Request Flow

```text
HTTP Request
    -> Handlers    (extract + map transport)
    -> Service     (business rules + orchestration + transactions)
    -> Repository  (SQLx query/mapping)
    -> Database
```

### Layer Responsibilities

| Layer | Does | Does NOT | Test Focus |
|-------|------|----------|------------|
| Handlers | Extract path/query/body, call services, map errors to responses | Business rules, SQL | Serialization, status codes, auth extraction |
| Service | Business rules, transactions, orchestration | HTTP concerns, raw SQL | Rules, rollback behavior, error paths |
| Repository | SQLx operations and mapping | Domain policy, HTTP concerns | Query correctness, mapping, DB errors |

## Anti-Patterns to Avoid

No god modules:

```text
bad:  domain/user/handlers.rs with all domain logic mixed in
good: split model/service/repository/handlers with explicit boundaries
```

Avoid fire-and-forget tasks:

- Do not `tokio::spawn` and ignore `JoinHandle` for critical work.
- Every spawned task needs an owner, cancellation path, and shutdown behavior.

Never ignore failures:

- No `unwrap()`/`expect()` in request paths or business logic.
- No `println!` for operational logs; use `tracing`.
- No `panic!` outside startup and tests.

## Error Handling

| Situation | Use |
|-----------|-----|
| Domain/application errors | `thiserror` enums |
| Internal context wrapping | `anyhow::Context` (internal only) |
| Public result alias | `type AppResult<T> = Result<T, AppError>` |
| Error propagation | `?` operator |
| Optional value required | `ok_or(...)` / `ok_or_else(...)` |

Rules:

- Add contextual error messages at infrastructure boundaries.
- Convert infra errors to domain/app errors before returning to transport.
- Never leak internal error details to clients; log internals, return stable codes.

## Logging and Tracing

- Use structured logs with `tracing` fields.
- Add spans for handlers/services (`#[instrument]`) and skip heavy args.
- Include correlation fields where possible (`request_id`, `user_id`, `trace_id`).

Example:

```rust
#[tracing::instrument(skip(self, db), fields(user_id = %user_id))]
pub async fn create_user(&self, db: &sqlx::PgPool, user_id: Uuid) -> AppResult<()> {
    tracing::info!("user_created");
    Ok(())
}
```

## Validation

- Validate request DTOs at handler boundaries.
- Enforce domain invariants again in service layer when correctness matters.
- Keep validation rules centralized and reusable.
- Reject unknown/extra fields when strict API contracts are expected.

## Security Defaults

- Passwords: Argon2id with tuned parameters for your hardware/latency budget.
- Secrets: use `SecretString`/`SecretVec` where practical.
- Tokens/JWT: short-lived access tokens, explicit claim validation (`exp`, `iat`, `sub`, audience/issuer as needed).
- SQL: parameterized queries only (never string-concatenated SQL).
- Headers: enforce security headers middleware (HSTS, CSP, frame protections) where appropriate.

## Async and Concurrency

- Use bounded concurrency (`Semaphore`, worker pools, backpressure) for fan-out work.
- Use cancellation-aware orchestration (`tokio::select!`, shutdown signals, cancellation token patterns).
- Use `spawn_blocking` for CPU-heavy or blocking operations in async contexts.
- Avoid long-held mutex guards across `.await` points.
- Prefer message passing/channels where ownership transfer is clearer than shared mutable state.

## HTTP Standards and Safety

- Use `http::StatusCode` constants, not numeric literals.
- Set body size limits (`DefaultBodyLimit` / explicit limits on upload routes).
- Set timeout policy for handlers and outbound calls.
- Configure CORS explicitly (origins, methods, headers), not wildcard by default.
- Keep response envelope and error schema stable across endpoints.

Recommended response envelopes:

- Success: `{ "data": T }`
- Error: `{ "error": string, "code": string, "details": map }`
- Paginated: `{ "data": []T, "total": int, "page": int, "per_page": int }`

## Database and Transactions

- Service layer owns transaction boundaries.
- Repositories accept `&mut Transaction<'_, Postgres>` (or compatible executor abstraction).
- Keep SQL in repositories and business decisions in services.
- Prevent N+1 query patterns on hot endpoints.
- Prefer explicit migrations over implicit schema drift.

## SQLx Migrations

- Location: `sql/migrations/`.
- Naming default: `YYYYMMDDHHMMSS_description.sql`.
- Keep migrations reversible when possible.
- Use one naming strategy per repository and keep it consistent.

## Workspace Lints and Tooling

- Configure workspace-wide lints in root `Cargo.toml`.
- Avoid enabling `clippy::pedantic` wholesale; enable targeted lints instead.
- Keep lint levels pragmatic for application code, stricter for libraries.

Minimal pattern:

```toml
[workspace.lints.rust]
unsafe_code = "deny"
rust_2018_idioms = { level = "warn", priority = -1 }

[workspace.lints.clippy]
all = { level = "warn", priority = -1 }
```

## Testing Standards

### Unit Tests

- Prefer table-driven/parameterized tests (`rstest`) when many cases exist.
- Cover happy path, error path, and edge cases.
- Keep tests close to code with `#[cfg(test)] mod tests` where practical.
- Use `#[tokio::test]` for async behavior.

### Integration Tests

- Use real dependencies (often via `testcontainers-rs`) when behavior depends on them.
- Isolate state with per-test databases/schemas or robust cleanup.
- Keep setup deterministic and CI-friendly.

### Other Test Types

- Add property tests for invariant-heavy logic (`proptest`) when valuable.
- Add benchmarks for hot paths (`criterion`).
- Add fuzz tests for parser/decoder boundaries (`cargo-fuzz`) where risk justifies it.

### Contract Testing

For external APIs, use record/replay or contract tests when provider changes can break CI.

## Code Quality Checklist

Before committing:

- [ ] Business logic stays in services, not handlers.
- [ ] No `unwrap()`/`expect()` in production paths.
- [ ] Structured logs/spans with `tracing` (no `println!`).
- [ ] Input validation present for external-facing endpoints.
- [ ] Outbound I/O has explicit timeout and retry policy.
- [ ] Spawned tasks have ownership and shutdown behavior.
- [ ] Transaction boundaries are explicit and tested.
- [ ] Migrations are applied and validated in test/dev flow.
- [ ] `cargo fmt --all` passes.
- [ ] `cargo clippy --all-targets --all-features -- -D warnings` passes.
- [ ] `cargo test --all-features` passes.
- [ ] `cargo deny check` reviewed.
- [ ] `cargo audit` reviewed.
- [ ] Graceful shutdown handles SIGINT/SIGTERM.
- [ ] No `TODO`/`FIXME` without issue reference.
