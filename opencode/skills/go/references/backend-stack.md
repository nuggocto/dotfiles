# Go backend stack

Read this reference when Chi, pgxpool, sqlc, Goose, or `log/slog` is present or
being selected for a new backend. Resolve exact module and tool versions first.

## Chi and net/http

- Use Chi as a thin `net/http` router. Keep handlers, middleware, tests, and
  server configuration based on standard `http.Handler` contracts.
- Group routes by feature and mount subrouters where that improves ownership.
  Apply authentication, request limits, and resource-loading middleware at the
  narrowest route scope that enforces the policy.
- Middleware order is semantic. Test panic recovery, request IDs, real client IP,
  logging, timeout, compression, authentication, and body-limit interactions.
- Configure an explicit `http.Server`, signal-driven shutdown, finite drain
  timeout, and ownership for work that must finish after request admission stops.

## pgxpool and sqlc

- Create one `pgxpool.Pool` at startup, ping it before readiness, size it across
  all replicas, monitor acquire waits and saturation, and close it on shutdown.
- Write reviewed SQL and let sqlc generate typed query code. Treat generated Go
  as output: change SQL or sqlc configuration, regenerate with the pinned tool,
  and inspect the diff.
- Keep sqlc interfaces narrow at the consuming operation when transactions or
  tests need substitution. Do not wrap every generated method in boilerplate.
- Let the application operation own the transaction. Pass the transaction-bound
  generated query set through the operation, keep transactions short, and always
  commit or roll back explicitly.

## Goose

- Prefer SQL migrations unless a migration genuinely needs Go behavior. Keep
  files ordered, immutable after release, and safe for overlapping application
  versions.
- Run migrations once as a deployment step, not in every server process. Review
  locks, transaction support, rollback policy, and large backfills separately.
- Use timestamp versions during concurrent development only if the repository's
  release process normalizes or safely orders them. Preserve established policy.

## slog

- Construct the logger and handler at startup. Use JSON where machine ingestion
  needs it and pass a logger or scoped logger through explicit dependencies.
- Use stable attribute keys and context-aware methods when request or trace
  context is available. Redact secrets with boundary-owned values or handlers.
- Log an operational failure once where it is handled or terminates work. Avoid
  eager expensive values on disabled log paths and custom wrappers that report
  the wrong source location.

## Verification and sources

- Test the full router with `httptest`, SQL against a migrated disposable
  database, generated-code drift, migration up/down policy, readiness, and
  graceful shutdown.
- Chi: `https://go-chi.io/`
- pgxpool: `https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool`
- sqlc: `https://docs.sqlc.dev/`
- Goose: `https://pressly.github.io/goose/`
- slog: `https://pkg.go.dev/log/slog`
