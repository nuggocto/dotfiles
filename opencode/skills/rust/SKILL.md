---
name: rust
description: >
  Production-grade Rust backend guidance focused on idiomatic design,
  explicit error handling, safe concurrency, and reliable operations. Use when
  working with Rust code, .rs files, Cargo projects, or Rust services, APIs,
  and workers.
license: MIT
metadata:
  author: opencode
  version: "2.4.0"
---

# Rust

Use this skill for production-grade Rust applications, libraries, services, APIs, workers, and tooling. Apply the backend stack options only when creating or extending a backend service. Prefer the repository's existing stack over generic defaults.

Resolve the selected edition, workspace resolver, `rust-version`/MSRV, toolchain, Cargo configuration, features, and dependency versions from workspace and package manifests, `.cargo/config.toml`, `Cargo.lock`, `rust-toolchain.toml`, and CI before consulting APIs. Virtual workspaces have no package edition from which to infer a resolver, so verify that `[workspace].resolver` is explicit. Use a current patch release of the selected Rust line; in particular, do not ship artifacts built with Rust 1.97.0 because 1.97.1 fixes a known LLVM miscompilation. Use documentation for those versions; use latest docs to evaluate an upgrade, not as evidence that an API exists in the checked-out project. docs.rs hosts third-party crate documentation but does not make guidance official Rust-project policy.

## Workflow

1. Identify the program shape and constraints: application or library, runtime, entrypoint, storage, external I/O, latency target, and deployment model.
2. Start with manifests, entrypoints, configuration, implementation, tests, migrations, and CI. Follow imports, callers, trait implementations, generated-code inputs, and deployment configuration until the affected behavior and compatibility contracts are understood.
3. Preserve existing framework and crate choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps ownership, module boundaries, and error flow obvious.
5. Before editing a generated file, identify its source and pinned generator; change the input or template and regenerate instead of hand-editing output.
6. Verify with the narrowest useful commands first; widen to the repository's feature, target, MSRV, fmt, lint, test, doctest, and build matrix for broader changes.

## Default posture

- Prefer stable Rust, explicit ownership, and strong type boundaries.
- Prefer concrete types until an abstraction serves multiple implementations, downstream extensibility, or a useful design or testing boundary.
- Prefer thin transport layers, explicit transactions, and structured observability.
- Prefer clear synchronous-looking async code over clever abstractions.
- Avoid `unsafe`, proc-macro complexity, and unnecessary generics without a concrete payoff. When `unsafe` is required, minimize and encapsulate it and make its contracts explicit.

## Opinionated starter options

Use these only for a new backend application when its requirements fit. They are ecosystem choices, not language-wide best practices.

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Rust stable | Keep CI and local tooling aligned |
| Edition | 2024 for new unconstrained crates | Requires Rust 1.85+ and defaults to resolver 3; follow repository MSRV policy |
| HTTP | Axum + Tower | Good default for composable services |
| Async runtime | Tokio | Use one runtime consistently |
| Database | SQLx | Prefer SQL-first access and explicit queries |
| Serialization | `serde` + `serde_json` | Use for API/config DTOs; keep wire contracts explicit |
| Errors | `thiserror` + `anyhow` | Typed errors for reusable boundaries; `anyhow` for executable and application orchestration |
| Logging | `tracing` + `tracing-subscriber` | Structured logs and spans |
| Linting | `rustfmt` + `clippy` | Mirror CI and keep warning policy explicit |
| Validation | `garde` or existing repo choice | Keep validation centralized |
| Secrets | `secrecy` | Reduce accidental secret exposure |
| Password hashing | `argon2` (Argon2id) | If the service stores passwords |
| IDs | `uuid` (UUIDv7) | Prefer one ID strategy per service |
| Date/time | `time` | Use one time crate consistently |
| Integration tests | `testcontainers-rs` | When behavior depends on external services |
| Security checks | `cargo-deny`, `cargo-audit` | Use when deps or security posture change |

If the repository already uses alternatives such as Actix, SeaORM, Diesel, or `chrono`, stay consistent unless the user asks for a migration.

## Architecture options

- In larger services, handlers usually handle transport, application operations coordinate use cases, and adapters isolate persistence. Collapse layers when the indirection adds no clear ownership or testing boundary.
- Let the operation coordinating atomic work own its transaction; this is often an application service but does not require a dedicated service layer.
- Keep policy separate from query and driver plumbing where that separation improves cohesion.
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
  account/                 # organize around domain or capability
  postgres/                # add an adapter module when useful
tests/
migrations/
```

## Rust conventions

- Use `snake_case` for modules, files, functions, and variables.
- Use `PascalCase` for structs, enums, traits, and type aliases.
- Use `SCREAMING_SNAKE_CASE` for constants.
- Use `Error` suffix for error types and `Builder` suffix for builders. Use `new` or `with_*` for constructors even when they return `Result`; use `try_*` when it meaningfully distinguishes a fallible variant from a related infallible operation.
- Use `Id`, not `ID`; use `Uuid`, not `UUID`; do not suffix async functions with `_async`.
- Prefer domain newtypes at boundaries instead of passing raw `String`, `i64`, or `Uuid` values everywhere.

## Modules, traits, and imports

- Define traits where their semantics are owned. Consumer-defined traits can decouple local callers; public traits may belong with the domain API and should account for coherence, downstream implementation, and sealing.
- Keep traits small and behavior-focused.
- Prefer `crate::...` imports in production modules.
- Reserve `use super::*;` mostly for tests where locality is obvious.
- Split modules when it improves ownership and readability, not just to create more files.

## Library contracts

- For reusable crates, treat public items, trait implementations, error chains, feature names/defaults, auto-trait behavior, and MSRV as compatibility contracts.
- Check Cargo's SemVer guidance before changing public structs, enums, traits, generic bounds, or exposed dependency errors. Keep features additive and test supported combinations rather than assuming `--all-features` is valid.
- Preserve the declared `rust-version` unless the requested change intentionally raises the project's MSRV under its documented policy. When raising it, update the declaration explicitly, treat it as a compatibility decision, and verify the declared version in CI. Document public APIs, error and panic conditions, and safety contracts; run doctests for changed public behavior.
- Keep `Cargo.lock` under version control unless the repository has a deliberate alternative. Use `--locked` for deterministic CI and release builds; use `--frozen` only when dependencies are already available and network access must also be prohibited.
- For an edition upgrade, run `cargo fix --edition` on the old edition for supported feature and target configurations, then change the manifest edition and rerun formatting, checks, tests, doctests, and release builds. Manually audit macros, generated code, unsafe changes, and doctests; automated fixes establish compatibility, not soundness.

## Errors and observability

- Do not use `unwrap()`, `expect()`, or `panic!` for malformed input, unavailable resources, I/O failure, or other recoverable conditions in request paths, jobs, or business logic.
- Use typed errors, often derived with `thiserror`, where callers need to inspect or recover from failures.
- Add context at I/O boundaries with `anyhow::Context` or equivalent internal wrappers.
- Convert infrastructure errors before they cross transport boundaries.
- Never leak internal error details to clients; log internals and return stable public codes.
- Use `tracing` fields and spans for request-scoped context such as `request_id`, `user_id`, and `trace_id`.

## Assertions, panics, and unsafe contracts

- Use `Result` and `Option` for expected runtime failure. Assertions and panics represent programmer errors, violated internal invariants, or an explicit process-fatal policy.
- `assert!`, `assert_eq!`, and `assert_ne!` remain active in optimized builds. Use them only when panicking is the intended response to an invariant violation.
- `debug_assert!`, `debug_assert_eq!`, and `debug_assert_ne!` may be removed when debug assertions are disabled. Keep their expressions free of required side effects and never rely on them for correctness or safety.
- Use `unwrap()` or `expect()` only when success is guaranteed by construction or a preceding exhaustive check and the panic remains acceptable under the application's failure policy. Prefer `expect()` with invariant-focused context when the reason is not obvious.
- `unreachable!()` is a panic for impossible control flow; use it only when the state is logically impossible. Never substitute `std::hint::unreachable_unchecked()` unless an `unsafe` proof establishes that reaching it cannot occur.
- A safe API must make invalid states unrepresentable or check safety preconditions in every build before entering `unsafe` code. A `debug_assert!` cannot uphold a memory-safety contract.
- Document public unsafe APIs with a `# Safety` contract, justify each unsafe block with a local `// SAFETY:` explanation, and keep the block as small as practical.
- Require explicit unsafe blocks inside `unsafe fn`. Edition 2024 warns for `unsafe_op_in_unsafe_fn` by default; for earlier editions enable the lint when working with unsafe code. Use `forbid(unsafe_code)` where unsafe is not expected and Miri or sanitizers for unsafe-heavy changes when applicable.
- For FFI and exported symbols, verify every foreign signature, safe or unsafe item classification, symbol name, and linker-section invariant. Edition 2024 requires unsafe extern blocks and unsafe forms of `no_mangle`, `export_name`, and `link_section`; automated migration syntax does not prove the contract sound.
- Avoid references to `static mut`; prefer scoped ownership, atomics, locks, `OnceLock`, or `LazyLock`. Mutate the process environment only before other threads can exist; Edition 2024 makes `std::env::set_var` and `remove_var` unsafe to expose that requirement.
- In tests, Rust's standard `assert!`, `assert_eq!`, `assert_ne!`, and pattern assertions are normal test expectations.
- Add non-redundant assertions at important internal boundaries when they improve defect detection. Do not mechanically assert every argument or return value.

## Async and concurrency

- Give long-lived or critical spawned tasks an explicit owner and lifecycle policy: track handles, propagate cancellation or shutdown, and await completion when correctness requires it. Dropping a Tokio `JoinHandle` detaches the task rather than cancelling it.
- Treat cancellation as possible at every `.await`. Before racing or timing out a future, verify that dropping it is safe or isolate non-cancellation-safe work in an owned task with an explicit completion policy. In `tokio::select!` loops, preserve partial state and account for branch fairness and shutdown priority.
- Prefer bounded concurrency (`Semaphore`, worker pools, backpressure) over unbounded fan-out.
- Use `spawn_blocking` for bounded blocking work. Bound CPU-heavy parallelism or use a dedicated executor; started blocking tasks generally cannot be aborted, so account for shutdown behavior.
- Do not hold a blocking `std::sync::Mutex` guard across `.await`. Keep all lock critical sections short; use `tokio::sync::Mutex` only when a guard genuinely must span `.await`.
- Prefer message passing when ownership transfer is clearer than shared mutable state.

## HTTP, database, and security

- Use `http::StatusCode` constants, not numeric literals.
- Set body size limits, handler timeouts, outbound timeouts, and bounded response reads. Do not enable CORS unless a cross-origin browser client requires it; then allowlist exact trusted origins, methods, and headers.
- Keep response and error envelopes stable within a service.
- The operation coordinating an atomic use case owns the transaction boundary.
- Keep SQL and persistence mapping in cohesive adapter modules where that boundary is useful; avoid policy logic in query plumbing.
- Use parameterized queries only; watch for N+1 patterns on hot paths.
- Before changing schema or performance-sensitive SQL, load the matching database skill. Account for table size, lock behavior, deployment order, and overlap between old and new application versions; prefer expand-and-contract changes and separate bounded backfills from deploy-time migrations.
- Use Argon2id for password hashing. Use cryptographically random opaque tokens or a vetted token format, keep credentials short-lived where appropriate, and explicitly validate required token claims.
- Use secret wrappers where practical and avoid logging sensitive values.
- Load `@security/` for authentication, authorization, cryptography, user-controlled URLs or paths, uploads, commands, deserialization, or templates. Bound request, response, decompression, and collection sizes and enforce authorization from server-owned identity and resource scope.

## Serialization and API contracts

- Use `serde` for transport, config, and persistence DTOs; avoid forcing domain types to match JSON shape.
- Treat field names, defaults, skipped fields, and unknown-field behavior as API contract decisions.
- Prefer explicit request and response structs at service boundaries.
- Use strict deserialization such as `#[serde(deny_unknown_fields)]` only when rejecting unknown input is intentional.

## Testing and verification

- Use `@test-quality/` when writing or reviewing tests. Keep unit tests close to the code when that improves locality.
- Add integration tests with real dependencies when external systems affect behavior.
- Use property tests, fuzzing, or benchmarks when invariants or performance justify them.
- Use `@benchmark/` for performance claims. Benchmark the shipped crate or binary in the intended release profile and report target, features, and LTO settings.
- Run `cargo fmt --all -- --check`, repository/CI-equivalent Clippy, tests, and doctests. Derive the matrix from CI: verify default features, no-default-features where supported, documented combinations, affected targets, and the declared MSRV. A current-stable build does not prove MSRV support. Use `--all-features` only when all features are designed to coexist. With Cargo 1.97+, prefer `build.warnings = "deny"` or `CARGO_BUILD_WARNINGS=deny` over injecting `-D warnings`; follow existing repository policy for older Cargo versions.
- For shipped binaries or native libraries, build and smoke-test the actual release profile and deployment target with `--locked`. Review panic strategy, overflow checks, debug information, LTO, target features, stripping, symbol mangling, and debugger/profiler/crash-symbolization compatibility rather than assuming development-profile behavior carries over. Inspect linker diagnostics, including `linker_messages` on Rust 1.97+, before suppressing them.
- Use `@qa/` to exercise the shipped binary or library integration as a real consumer; unit tests and compilation do not verify packaging, startup, or supported-platform behavior.
- Run `cargo deny check` or `cargo audit` when dependency or security-sensitive work is involved.

## Guardrails

- Avoid mixing transport, use-case, and persistence concerns when doing so obscures ownership or testing; small cohesive modules may combine them.
- Do not introduce global mutable state when scoped ownership will do.
- Do not fire-and-forget critical work.
- Do not add dependencies for tiny conveniences without a clear maintenance win.
- Do not refactor broadly when a small targeted fix solves the problem.

## Primary references

- Rust release notes: `https://doc.rust-lang.org/stable/releases.html`
- Rust 2024 Edition Guide: `https://doc.rust-lang.org/edition-guide/rust-2024/`
- Cargo reference: `https://doc.rust-lang.org/stable/cargo/reference/`
- Rust standard library: `https://doc.rust-lang.org/stable/std/`

## Response expectations

For substantial changes using this skill:

1. State the architecture impact of the change in plain language.
2. Call out trade-offs when choosing crates, async patterns, or boundaries.
3. Prefer concrete file-level guidance over abstract Rust advice.
4. Point to official Rust docs or the crate's versioned API docs and upstream repository when specifics matter.
5. End with the most relevant verification commands or follow-up checks.
