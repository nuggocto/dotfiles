---
name: gleam
description: >
  Production-grade Gleam guidance focused on type-safe functional programs for
  Erlang and JavaScript targets. Use when working with Gleam code, .gleam
  files, gleam.toml projects, BEAM services, Wisp/Mist handlers, or Gleam
  libraries and tooling.
license: MIT
metadata:
  author: opencode
  version: "2.1.0"
---

# Gleam

Use this skill for production-grade Gleam applications, libraries, services, APIs, and tooling targeting Erlang or JavaScript. Apply BEAM, Wisp, Mist, pog, Squirrel, and OTP guidance only when those technologies are present or are being deliberately selected. Prefer the repository's existing stack over generic defaults.

Resolve the compiler range, Erlang/OTP or JavaScript runtime, target, and package versions from `gleam.toml`, `manifest.toml`, runtime pins, and CI before consulting APIs. Use documentation matching those versions; use current docs to evaluate upgrades rather than assuming local availability.

Apply `@tiger_style/` as an engineering overlay for bounds, actor ownership, resource accounting, and invariants. Gleam and target-runtime semantics take precedence for `Result`, process failures, supervision, foreign code, and tests.

## Workflow

1. Identify the program shape and constraints: Erlang or JavaScript target, application or library, actor model, storage, external I/O, latency target, and deployment model.
2. Read the files that govern the change: `gleam.toml`, `manifest.toml`, relevant `src/`, `dev/`, and `test/` modules, foreign code, generated SQL inputs, deployment config, and CI.
3. Preserve existing framework and package choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps types, function pipelines, actor ownership, and error flow obvious.
5. Before editing generated code, identify its source and pinned generator, then regenerate instead of hand-editing output.
6. Verify with the narrowest useful commands first; widen to every supported target/runtime and full format/test/build checks.

## Default posture

- Annotate every module function's arguments and return type; prefer immutable data and exhaustive pattern matching.
- Prefer pure functions and cohesive, domain-oriented modules. Do not fragment modules merely to keep files small or mirror design-pattern layers.
- Prefer the Gleam standard library and small, well-maintained Hex packages.
- Prefer deliberate lifecycle management and bounded concurrency over clever abstractions.
- Minimize all externals and keep foreign boundaries precisely typed, small, and well tested.

## Opinionated starter options

Use these only for a new application when its target and requirements fit. They are ecosystem choices, not language-wide best practices.

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Compiler range in `gleam.toml`; exact runtime pin in CI or the repo's environment manager when needed | Commit `manifest.toml` and align CI and local tooling |
| Checking/build | `gleam check` and `gleam build` | Use `gleam build --warnings-as-errors` when CI treats warnings as failures |
| Formatting | `gleam format`; `gleam format --check` in CI | Format touched files or the full project |
| Testing | `gleam test`; gleeunit for generated projects | The command runs the package's test entrypoint on either target |
| BEAM HTTP server | Mist | Lightweight HTTP and WebSocket option for Erlang-target applications |
| BEAM web framework | Wisp | Handlers, middleware, request parsing, response helpers, and a Mist adapter |
| PostgreSQL | pog; optionally Squirrel for PostgreSQL 16+ | Squirrel requires a reachable schema-compatible database during generation |
| Migrations | Versioned SQL with the deployment-owned tool or project runner | Keep migrations separate from Squirrel query inputs |
| JSON | `gleam_json` | Explicit encode/decode functions |
| Validation | Explicit boundary functions; Wisp middleware when applicable | Keep validation close to the boundary it protects |
| Logging | Target-appropriate project logger | Verify that the chosen binding supports required structured metadata |
| IDs | `youid` when UUIDs fit the domain | Choose the UUID version from storage and interoperability requirements |
| Date/time | Core-team `gleam_time`, defaulting to `gleam/time/timestamp` for instants | Add another package only for missing functionality |
| Static analysis | `gleam check` + `gleam format --check` | The compiler is the first line of defense |
| Integration tests | Real isolated dependencies | Use when external behavior matters |

If the repository already uses alternatives such as a different HTTP server, database layer, or migration strategy, stay consistent unless the user explicitly asks for a migration.

## Module and architecture defaults

- Organize modules around the business domain and the API they present, not around generic handler/service/repository categories.
- Keep a small entrypoint or transport adapter when it clarifies the boundary, but do not create layers or directories before they earn their indirection.
- Let the operation coordinating atomic work own its transaction boundary.
- Keep generated persistence code behind a cohesive domain-facing API when exposing it directly would leak implementation details.
- On the Erlang target, keep BEAM startup, supervision wiring, config, and shutdown behavior near the application entrypoint. Do not apply these concepts mechanically to JavaScript targets.

Suggested layout when starting from scratch:

```text
gleam.toml
manifest.toml
src/
  my_app.gleam
  my_app/
    account.gleam
    billing.gleam
    router.gleam             # when the application serves HTTP
    account/
      sql/
        find_account.sql     # when using Squirrel
migrations/                  # not under a Squirrel sql directory
test/
```

## Gleam conventions

- Use `snake_case` for module names, functions, variables, files, and directories.
- Use `PascalCase` for custom types and constructors.
- Use `Option` and `Result` instead of null-like sentinels.
- Prefer custom types and records over loosely typed maps for domain data.
- Use the pipe operator (`|>`) for sequences of transformations.
- Use exhaustive `case` expressions; missing branches for finite types are compile errors.
- Avoid catch-all patterns when naming every variant preserves compiler assistance during refactoring.

## Types, functions, and modules

- Make invalid states unrepresentable with custom types.
- Keep modules cohesive; split them when the resulting public API is clearer, not merely because a file is large.
- Qualify functions and constants from imported modules. Import types and constructors unqualified only when that improves readability.
- Use singular, package-prefixed module paths and annotate every module function's arguments and return type.
- Define types at the boundaries where data enters or leaves the system.
- Use phantom or opaque types when they enforce a concrete invariant or staged API.

## Errors and observability

- Model expected failures with `Result`; use `Option` for optional values.
- Never silently ignore `Error` variants from I/O, DB, or external calls.
- Add context at I/O and FFI boundaries before errors cross higher-level APIs.
- Never leak internal error details to clients; log internals and return stable public codes.
- Include request-scoped keys such as `request_id`, `user_id`, and `trace_id` in logs when available.
- Emit telemetry or log events for important operations and attach metrics in one place.

## Concurrency, actors, and context

- On the Erlang target, put long-lived services, pools, and restartable workers in a deliberate supervision tree. Actors process messages serially, so keep handlers bounded, use explicit call timeouts, and move independent slow work to supervised processes.
- Use actors when stateful serialized access, concurrency, or fault isolation is required; prefer pure functions otherwise. BEAM mailboxes are not automatically bounded, so enforce admission control or request/reply backpressure and monitor growth.
- Propagate request context explicitly; do not hide it in process dictionaries or ambient state.
- On the Erlang target, never derive atoms or process names from external or unbounded input. Create the finite set of `process.Name` values during startup; atoms are not garbage-collected.
- On the Erlang target, BEAM processes are preemptively scheduled, but blocking NIF or foreign work can block scheduler threads. On JavaScript targets, execution follows the selected runtime's event loop and blocking foreign JavaScript blocks that loop.
- For multi-target packages, provide compatible implementations or externals for every supported target and compile and test each target; do not silently make a multi-target module target-specific.

## HTTP, database, and security

- Wisp has no special router abstraction; use ordinary pattern matching unless the project has adopted another router.
- Prefer named Wisp response helpers for common cases and explicit integer status codes where its API requires them.
- Configure body limits and timeouts at the layer that owns them. Do not enable CORS unless a cross-origin browser client requires it; then allowlist exact trusted origins, methods, and headers.
- Keep response and error envelopes stable within an API surface.
- The operation coordinating an atomic use case owns the transaction boundary.
- When using Squirrel, keep query files under `src/**/sql/*.sql`, run `gleam run -m squirrel`, and do not hand-edit generated `sql.gleam` files.
- Bind all untrusted SQL values; strictly allowlist any dynamic identifiers or syntax. Watch for N+1 patterns on hot paths.
- Before schema or performance-sensitive query changes, load the matching database skill. Account for table size, locks, deployment order, and overlapping releases; prefer expand-and-contract changes and separate bounded backfills from deploy-time migrations.
- For production pog connections, use verified TLS unless an equivalent trusted boundary provides and verifies transport security.
- Use Argon2id only for human-chosen passwords. Generate bearer tokens with target-appropriate cryptographically secure randomness or a vetted token format, and avoid logging secrets or raw tokens.
- Load `@security/` for authentication, authorization, user-controlled URLs or paths, uploads, command execution, deserialization, or cryptography. Enforce authorization from server-owned identity and scope and bound request, response, decompression, and collection sizes.

## Serialization and API contracts

- Use `gleam_json` for transport and config DTOs; keep encode/decode functions explicit.
- Treat field names, defaults, optional fields, unknown-field behavior, and time formats as API contract decisions.
- Prefer explicit request and response types at handler boundaries.
- Decide and test the unknown-field policy. Standard field decoders ignore extra fields; add explicit key validation only when strict rejection is required.

## Testing and verification

- In gleeunit projects, keep tests under `test/`; test functions must be public and conventionally end in `_test`, and the package test entrypoint must invoke `gleeunit.main()`.
- Use table-driven tests with lists of input/expected pairs when a behavior has many cases.
- Add integration tests with real dependencies when mocks would hide important behavior.
- Test both happy paths and error paths; assert on `Error(_)` shapes, not just success.
- Run `gleam format --check`, `gleam check`, `gleam test`, and `gleam build --warnings-as-errors` for substantial changes when repository policy supports them. For multi-target packages, run the configured build and test commands for both Erlang and JavaScript targets and selected JS runtimes.
- After changing Squirrel query files, run `gleam run -m squirrel`; use `gleam run -m squirrel check` in CI.

## Guardrails

- Do not fragment cohesive domain APIs into generic technical layers.
- Do not let transport concerns dictate domain types or policy.
- Do not introduce global mutable state when explicit arguments will do.
- Do not start long-lived or critical actors without deliberate ownership and lifecycle behavior.
- Do not add dependencies for tiny conveniences without a clear maintenance win.
- Do not refactor broadly when a small targeted fix solves the problem.

## Native extensions

For native code implemented in Rust, apply `@rust/` in addition to this skill. For other native languages, inspect their toolchain and repository contracts directly. Minimize and precisely type the boundary. Keep regular NIF calls short and use correctly classified dirty schedulers for unavoidable lengthy work. A crashing NIF can crash the entire BEAM VM and cannot be recovered by supervision; use an external OS process through a port when crash isolation is required.

## Response expectations

For substantial changes using this skill:

1. State the architecture and actor/supervision impact of the change in plain language.
2. Call out trade-offs when choosing packages, concurrency patterns, or type boundaries.
3. Prefer concrete file-level guidance over abstract Gleam advice.
4. Point to official Gleam docs or the package's versioned HexDocs and upstream repository when specifics matter.
5. End with the most relevant verification commands or follow-up checks.
