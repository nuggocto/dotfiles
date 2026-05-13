---
name: go
description: >
  Production-grade Go backend guidance focused on idiomatic code, clear
  architecture boundaries, reliability, and testability.
license: MIT
metadata:
  author: opencode
  version: "2.0.0"
---

# Go

Use this skill for production-grade Go services, APIs, workers, and internal backend tooling. Prefer the repository's existing patterns over generic defaults; use the defaults below when the codebase does not already have a clear standard.

## Workflow

1. Identify the service shape and constraints: entrypoint, transport, storage, concurrency model, latency target, and deployment model.
2. Read only the files that control the behavior you are changing: `go.mod`, `cmd/`, `internal/`, `sql/`, config, tests, migrations, and CI.
3. Preserve established framework and package choices unless they are unsafe, broken, or clearly fighting the request.
4. Make the smallest change that keeps package boundaries, error flow, and ownership easy to follow.
5. Verify with the narrowest useful commands first; expand to broader fmt/lint/test/build checks for larger work.

## Default posture

- Prefer the standard library and small dependencies.
- Prefer concrete types first; introduce interfaces only for real seams.
- Prefer constructor injection, explicit context propagation, and structured logging.
- Prefer simple package layouts over layered ceremony.
- Do not add abstractions, frameworks, or concurrency machinery before they are needed.

## Defaults when the repo has no standard

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Go version in `go.mod` | Keep CI and local tooling aligned |
| Formatting | `gofmt` + `goimports` | Format touched files and keep imports grouped |
| HTTP | `net/http` + Chi | Small surface area, stdlib-friendly |
| Database | `pgx` + `sqlc` | SQL-first and type-safe generated access |
| Migrations | Goose SQL migrations | Prefer SQL migrations over Go migrations |
| JSON | `encoding/json` | Use explicit request/response DTOs and stable tags |
| Logging | `log/slog` | Structured logging only |
| Validation | `go-playground/validator` | Keep custom validators centralized |
| Password hashing | Argon2id | If the service stores passwords |
| IDs | UUIDv7 | Prefer one ID strategy per service |
| Integration tests | `testcontainers-go` | When external deps affect behavior |
| Static analysis | `go vet`, `staticcheck` | Treat both as normal quality gates |
| Vulnerability review | `govulncheck` | Run when deps or exposure change |

If the repository already uses Echo, Gin, Fiber, GORM, Bun, or another established stack, stay consistent unless the user explicitly asks for a migration.

## Architecture defaults

- Keep handlers thin: parse transport input, validate, call service, write response.
- Keep business rules, orchestration, and transaction ownership in services.
- Keep SQL, persistence details, and generated query code in repository or database packages.
- Keep startup, wiring, config, and graceful shutdown near `cmd/` or bootstrap packages.
- Keep middleware, API error mapping, validation helpers, and shared clients small and explicit.

Suggested layout when starting from scratch:

```text
cmd/server/main.go
internal/handler/
internal/service/
internal/repository/
internal/middleware/
internal/model/
internal/database/sqlc/
sql/schema/
sql/queries/
test/
```

## Go conventions

- Use short, concrete, lowercase package names.
- Use `PascalCase` for exported identifiers and `camelCase` for local variables.
- Keep initialisms consistent: `ID`, `HTTP`, `URL`, `JSON`.
- Avoid `Get` for simple field accessors; use it when the method implies lookup or I/O.
- Use `ErrX` for sentinel errors and `NewX` names for constructors.
- Use an unexported custom type for context keys.

## Interfaces, packages, and dependency flow

- Define interfaces where they are consumed, not where they are implemented.
- Keep interfaces small and behavior-focused.
- Prefer concrete dependencies until a second implementation or real test seam appears.
- Use constructor injection; avoid setter injection and hidden global dependencies.
- Keep packages cohesive; split god packages before adding more helpers to them.

## Errors and observability

- Never ignore errors without explicit justification.
- Wrap errors with `%w` and inspect them with `errors.Is` and `errors.As`.
- Keep transport error mapping in handlers, not in services or repositories.
- Use `slog` structured fields and always log operational errors with an `err` field.
- Include request-scoped keys such as `request_id`, `user_id`, and `trace_id` when available.
- Do not use `fmt.Println` for operational logs.

## Context and concurrency

- `context.Context` is the first parameter and should be named `ctx`.
- Never store context in a struct.
- Propagate context through DB, cache, queue, and HTTP client calls.
- Every goroutine needs an owner, cancellation path, and shutdown behavior.
- Use `errgroup.WithContext` for related concurrent work that should fail or cancel together.
- Avoid unbounded goroutine creation; use worker pools or backpressure for fan-out.
- Run `go test -race ./...` for non-trivial concurrent code.

## HTTP, database, and security

- Use `http.Status...` constants, not numeric literals.
- Set server and client timeouts explicitly.
- Limit request body size for JSON and upload endpoints.
- Keep response and error envelopes consistent within an API surface.
- Service layer owns transaction boundaries.
- Keep SQL in queries or repository code, not in handlers.
- Treat `sqlc` output as generated code: regenerate it, do not hand-edit it.
- Prefer SQL migrations with reversible `Up`/`Down` steps when possible.
- Use Argon2id for passwords and avoid logging secrets or raw tokens.

## JSON and API contracts

- Use `encoding/json` unless the repository standardizes on another encoder.
- Keep request and response DTOs at transport boundaries; avoid making domain models depend on JSON tags.
- Treat JSON tags, omitted fields, defaults, unknown-field handling, and time formats as API contract decisions.
- Use `json.Decoder` with `DisallowUnknownFields` only when rejecting unknown input is intentional.
- Avoid `map[string]any` for structured payloads unless the schema is genuinely dynamic.

## Testing and verification

- Prefer table-driven tests when a behavior has multiple cases.
- Use `t.Run`, `t.Helper()`, `t.Cleanup()`, and `t.Parallel()` where they improve clarity and speed.
- Add integration tests with real dependencies when mocks would hide important behavior.
- Use fuzz tests, benchmarks, or golden tests when the problem shape justifies them.
- Run `gofmt`/`goimports` on touched files, `go test ./...`, `go vet ./...`, and `staticcheck ./...` for substantial changes.
- Run `go mod tidy` when dependencies are added, removed, or changed.
- Run `govulncheck ./...` when dependency or exposure changes matter.

## Guardrails

- Do not let handlers accumulate business logic.
- Do not let services silently reach into transport concerns.
- Do not introduce interface-heavy architecture without evidence it helps.
- Do not start background goroutines without ownership and shutdown.
- Do not widen package scope when a smaller focused change will solve the problem.

## Response expectations

When using this skill:

1. State the architecture impact of the change in plain language.
2. Call out trade-offs when choosing libraries, concurrency patterns, or package boundaries.
3. Prefer concrete file-level recommendations over broad Go advice.
4. End with the most relevant verification commands or follow-up checks.
