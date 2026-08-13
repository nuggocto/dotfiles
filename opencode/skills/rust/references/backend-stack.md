# Rust backend stack

Read this reference when creating or changing an API built with Axum, Tokio,
Tower, and SQLx. Resolve exact crate versions and features from `Cargo.toml` and
`Cargo.lock`, then use their versioned docs.

## Axum and Tower

- Build one `Router` from feature-oriented route modules. Keep handlers focused
  on extraction, authorization results, one application operation, and response
  mapping.
- Put shared dependencies in a small cloneable application state and attach it
  with `Router::with_state`. Do not turn state into an unstructured service
  locator or hold request-specific values there.
- Use Tower and `tower-http` middleware for cross-cutting HTTP behavior. Layer
  order changes semantics, so test timeout, tracing, request ID, compression,
  body-limit, CORS, and error-mapping interactions.
- Bound request bodies, response reads, concurrency, and handler duration. Map
  middleware errors to stable responses rather than leaking internal failures.
- Use the selected Axum version's server API, such as `axum::serve` on current
  releases or the documented equivalent on older lines. Trigger graceful
  shutdown from process signals, stop accepting requests, apply a finite drain
  deadline, and wait for owned background tasks that must finish.

## Tokio

- Use one runtime and pass cancellation explicitly. A dropped `JoinHandle`
  detaches its task; retain handles for work whose completion or failure matters.
- Prefer bounded channels, semaphores, and task sets. Use `spawn_blocking` only
  for bounded blocking work and account for the fact that started blocking work
  is not reliably abortable.
- For service shutdown, detect the trigger, notify every owned task, close task
  admission, and await completion under a deadline.

## SQLx

- Enable only the selected runtime, database, TLS, migration, and macro features.
  Keep TLS verification enabled across untrusted networks.
- Create one pool during startup, prove connectivity before readiness, size it
  across all replicas, expose saturation metrics, and close it during shutdown.
- Prefer reviewed SQL with `query!`, `query_as!`, or file-backed variants when
  compile-time checking fits. Keep SQLx offline metadata synchronized when CI
  cannot reach a schema database.
- Let the application operation own transactions. Keep them short, avoid remote
  calls while holding locks or connections, and explicitly commit or roll back.
- Run migrations in one deployment-owned step, not independently in every API
  replica. Review lock behavior and use expand-and-contract changes.

## Verification

- Test handlers through the complete router and middleware stack.
- Test SQL against a migrated disposable database, including constraints,
  rollback, pool exhaustion, timeout, and decoder failures.
- Smoke-test startup, readiness, signal handling, request draining, and shutdown
  with the release artifact.

## Sources

- Axum: `https://docs.rs/axum/`
- Tokio: `https://tokio.rs/tokio/`
- Tower: `https://docs.rs/tower/`
- SQLx: `https://docs.rs/sqlx/`
