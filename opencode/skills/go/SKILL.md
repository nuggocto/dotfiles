---
name: go
description: >
  Production-grade Go guidance focused on idiomatic code, clear architecture
  boundaries, reliability, and testability. Use when working with Go code, .go
  files, go.mod modules, libraries, CLIs, services, APIs, or workers.
license: MIT
metadata:
  author: opencode
  version: "2.3.0"
---

# Go

Use this skill for production-grade Go applications, libraries, services, APIs, workers, and tooling. Apply the backend stack options only when creating or extending a backend service. Prefer the repository's existing patterns over generic defaults.

Resolve the mandatory minimum and language semantics from the `go` directive. When present in the main module or workspace, also resolve the optional `toolchain` preference, `GOTOOLCHAIN` policy, dependency versions, build tags, CI matrix, module checksums, and deployment configuration from `go.mod`, `go.work`, `go.sum`, and automation before consulting APIs. Confirm that CI, release builds, and production use the latest patch release of a supported Go line. Patch releases carry security and correctness fixes, and the `go` directive alone does not keep the building toolchain current. Use documentation matching those versions; pkg.go.dev hosting does not make a recommendation official Go-project policy. For toolchain upgrades, read `references/toolchain-upgrades.md`.

## Workflow

1. Identify the program shape and constraints: application or library, entrypoint, transport, storage, concurrency model, latency target, and deployment model.
2. Start with manifests, entrypoints, configuration, implementation, tests, migrations, and CI. Follow imports, callers, interface implementations, generated-code inputs, build tags, and deployment configuration until the behavior and compatibility contracts are understood.
3. Preserve established framework and package choices unless they are unsafe, broken, or clearly fighting the request.
4. Make the smallest change that keeps package boundaries, error flow, and ownership easy to follow.
5. Before editing generated code, identify its source and pinned generator, modify the input or template, and review regenerated output for unrelated churn.
6. Verify with the narrowest useful commands first; expand to affected toolchains, build tags, platforms, race tests, fmt/lint/test/build checks, and CI-equivalent analyzers. For latency-, allocation-, GC-, memory-, or cgo-sensitive code, rerun representative benchmarks and profiles after changing the Go toolchain.

## Default posture

- Prefer the standard library and small dependencies.
- Prefer concrete types first; introduce interfaces only for real seams.
- Prefer explicit dependencies, per-call context propagation, and structured service logging.
- Prefer simple package layouts over layered ceremony.
- Do not add abstractions, frameworks, or concurrency machinery before they are needed.

## Opinionated starter options

Use these only for a new backend application when its requirements fit. Third-party entries are reasonable choices, not language-wide defaults.

| Area | Option | Notes |
| --- | --- | --- |
| Toolchain | Mandatory minimum `go` directive; optional preferred `toolchain` directive | Account for `GOTOOLCHAIN` and automatic switching; do not rewrite directives incidentally |
| Formatting | `gofmt`; optionally `goimports` | `goimports` also applies Go formatting while organizing imports |
| HTTP | `net/http`; Chi when its routing features help | Keep handlers and middleware compatible with standard `http.Handler` |
| PostgreSQL | `pgx`; add `pgxpool` or `sqlc` when useful | Match connection and query tooling to the service's needs |
| Migrations | Existing deployment-owned system; Goose SQL is one option | Keep migrations versioned, ordered, reviewed, and deployment-owned |
| JSON | `encoding/json` | Use explicit request/response DTOs and stable tags |
| Logging | `log/slog` | Use structured service logs unless the repository has an established API |
| Validation | Explicit validation; optionally `go-playground/validator` | Add declarative validation when contract complexity justifies it |
| Password hashing | Argon2id | If the service stores passwords |
| IDs | Domain-specific; UUIDv7 when time ordering and locality help | IDs are identifiers, not authorization secrets |
| Date/time | `time` (stdlib) | Keep time zones explicit and consistent |
| Integration tests | Real isolated dependencies; optionally `testcontainers-go` | Use containers when realism justifies requiring a container runtime |
| Static analysis | `go vet`; optionally `staticcheck` | Run repository-configured analyzers |
| Vulnerability review | `govulncheck` | Run regularly and after dependency or toolchain changes |

If the repository already uses Echo, Gin, Fiber, GORM, Bun, or another established stack, stay consistent unless the user explicitly asks for a migration.

When Chi, pgx, sqlc, Goose, or `log/slog` is in scope, read
`references/backend-stack.md` before changing routing, generated database code,
migrations, logging, startup, or shutdown.

## Architecture defaults

- Start with the fewest cohesive packages that fit the program. Add transport, application, or storage adapters only when they create a useful boundary.
- Keep handlers focused on transport when separating that concern improves clarity; small programs may keep closely related behavior together.
- Let the code coordinating an atomic use case own its transaction boundary.
- Keep SQL, persistence details, and generated query code in focused packages when exposing them would leak implementation details.
- Keep startup, wiring, config, and graceful shutdown near `cmd/` or bootstrap packages.
- Organize internal packages around domains or capabilities rather than mechanically creating handler/service/repository layers.

Suggested layout when starting from scratch:

```text
cmd/server/main.go
internal/account/
internal/httpapi/        # when a separate transport adapter is useful
internal/postgres/       # when a separate storage adapter is useful
sql/queries/
```

Keep tests beside the code as `*_test.go` by default.

## Go conventions

- Use short, concrete, lowercase package names.
- Use Go's `MixedCaps` or `mixedCaps`; exported identifiers begin with an uppercase letter.
- Keep initialisms consistent: `ID`, `HTTP`, `URL`, `JSON`.
- Avoid `Get` for simple field accessors; use it when the method implies lookup or I/O.
- Use `ErrX` for sentinel errors. Name constructors `New` when the package already supplies the type context, `NewX` when it distinguishes among exported types, or use a descriptive factory name when construction semantics matter.
- Use an unexported custom type for context keys.
- Give exported declarations useful doc comments beginning with the declared name. Error strings normally start lowercase and omit terminal punctuation because callers compose them.
- Use `new(expression)` and self-referential generic constraints only when the module's `go` directive and supported toolchains permit them.

## Interfaces, packages, and dependency flow

- Interfaces generally belong where they are consumed. A provider package may own one when the interface itself is a deliberate public contract rather than a wrapper around one implementation.
- Keep interfaces small and behavior-focused.
- Start concrete. Define a small interface in the consuming package when callers need substitutability or a genuine narrow seam; a test alone does not justify a broad interface.
- Make dependencies explicit through parameters or fields. Use constructors when they establish invariants or wire required long-lived dependencies, while preserving useful zero values where practical.
- Keep packages cohesive; split god packages before adding more helpers to them.

## Errors and observability

- Never ignore errors without explicit justification.
- Add context to errors. Wrap with `%w` only when callers should inspect the underlying error; otherwise use `%v` or translate it to a package-owned error. Use `errors.Is` and `errors.As` for documented error chains.
- Keep transport error mapping in handlers, not in services or repositories.
- Log an operational failure once, at the boundary that handles or terminates it; otherwise return it. Follow the repository's stable structured attribute names.
- Include request-scoped keys such as `request_id`, `user_id`, and `trace_id` when available.
- Do not use `fmt.Println` for operational logs.

## Context and concurrency

- In newly designed APIs that accept `context.Context`, make it the first parameter and name it `ctx`. Preserve required interface, callback, generated, or compatibility-constrained signatures.
- Do not store contexts in structs in new APIs; pass a per-call context as the first parameter. A documented exception may be justified when preserving API compatibility, as with request-like values.
- Propagate context through DB, cache, queue, and HTTP client calls.
- For every goroutine, make its owner and termination condition clear. Add cancellation when work can outlive its caller or become unnecessary, propagate errors when they matter, and wait during shutdown when correctness requires completion.
- Use `errgroup.WithContext` when tasks belong to one operation, ensure workers observe the derived context, call `Wait`, and bound fan-out. The derived context is cancelled on the first error and when `Wait` returns; do not return or use it after the group completes.
- Avoid unbounded goroutine creation; use worker pools or backpressure for fan-out.
- Run `go test -race ./...` for non-trivial concurrent code.

## HTTP, database, and security

- In application HTTP code, use `http.Status...` constants rather than numeric literals. Protocol tables and parser fixtures may use numbers when that is clearer.
- Configure `http.Server.ReadHeaderTimeout` and `IdleTimeout`, then choose `ReadTimeout` and `WriteTimeout` only after accounting for request bodies and streaming behavior.
- Reuse `http.Client` and its `Transport`; choose an end-to-end client timeout, per-request context deadlines, or both according to the operation.
- Regression-test TLS interoperability after toolchain upgrades. Prefer fixing incompatible peers over retaining temporary compatibility settings.
- After a successful `Client.Do`, close `resp.Body` on every path. Consume it as required by the protocol and connection-reuse policy, and bound reads from untrusted peers.
- Shut servers down with `http.Server.Shutdown` and a bounded context, treat `http.ErrServerClosed` as expected, stop accepting work, and wait for owned work that must complete.
- Bound request bodies before decoding with `http.MaxBytesReader` or `http.MaxBytesHandler`, using endpoint-specific limits for JSON and uploads.
- Configure `httputil.ReverseProxy` with `Rewrite`, not the deprecated and insecure `Director`; explicitly decide whether and how to add trusted forwarding headers.
- Preserve standard-library limits on cookies and query parameters, handle parser failures explicitly, and do not relax compatibility controls for those limits or strict URL host parsing without a reviewed requirement.
- Regression-test `ServeMux` redirects, request methods and bodies, virtual hosts, cookies, proxies, and URL rejection after a toolchain upgrade when those behaviors are public contracts.
- Keep response and error envelopes consistent within an API surface.
- The code coordinating an atomic use case owns the transaction boundary.
- Keep SQL in queries or repository code, not in handlers.
- Treat `sqlc` output as generated code: regenerate it, do not hand-edit it.
- Before schema or performance-sensitive query changes, load the matching database skill. Account for table size, lock behavior, deployment order, and overlapping application versions; prefer expand-and-contract changes and separate bounded backfills from deploy-time migrations.
- Use Argon2id only for human-chosen passwords. Generate opaque bearer tokens with `crypto/rand` or use a vetted token format, and avoid logging secrets or raw tokens.
- Read the selected toolchain's release notes before changing cryptographic code or tests. Do not assume caller-supplied randomness hooks or deterministic-test techniques behave the same across Go releases.
- Do not introduce RSA PKCS #1 v1.5 encryption. Use OAEP for RSA encryption, and retain v1.5 decryption only for reviewed legacy protocol compatibility.
- Load the `security` skill when a change creates or alters an authentication, authorization, cryptography, upload, command, parser, outbound-URL, filesystem-path, or other trust boundary. Treat outbound URLs as SSRF boundaries and filesystem paths as traversal boundaries; bound request, response, decompression, and collection sizes.

## JSON and API contracts

- Use `encoding/json` unless the repository standardizes on another encoder.
- Use boundary-owned request and response types when the transport contract differs from the internal representation; do not duplicate identical structs merely to avoid JSON tags.
- Treat JSON tags, omitted fields, defaults, unknown-field handling, and time formats as API contract decisions.
- Use `json.Decoder` with `DisallowUnknownFields` only when rejecting unknown input is intentional.
- Avoid `map[string]any` for structured payloads unless the schema is genuinely dynamic.

## Testing and verification

- Load the `test-quality` skill when writing or reviewing tests. Prefer table-driven tests when a behavior has multiple cases.
- Use `t.Run`, `t.Helper()`, `t.Cleanup()`, and `t.Parallel()` where they improve clarity and speed.
- Use `t.Log` and assertion messages for ordinary diagnostics. When the selected Go version supports test artifact directories, use them for files such as traces, profiles, images, or generated fixtures that CI should preserve.
- Add integration tests with real dependencies when mocks would hide important behavior.
- Use fuzz tests, benchmarks, or golden tests when the problem shape justifies them.
- When the minimum Go version permits, write new benchmarks with `for b.Loop()`. Collect repeated before and after samples with allocation reporting and compare them with `benchstat` rather than relying on a single run.
- Load the `benchmark` skill for performance claims. Benchmark the shipped binary or library with production-equivalent data, workload, and deployment topology.
- Load the `qa` skill when the change needs validation of the shipped binary, server, or library integration as a real consumer; unit tests and `go test ./...` do not verify packaging, startup, migration, or deployment behavior.
- Run `gofmt` or configured `goimports` on touched files, `go test ./...`, and `go vet ./...` for substantial changes. Run Staticcheck only through the repository's pinned or CI-equivalent invocation.
- After a toolchain upgrade, inspect the selected version's `go fix` capabilities. Review proposed modernizations before applying them, inspect the resulting diff, and rerun tests. Do not mix optional modernization into an unrelated change.
- Treat a `go` directive generated by `go mod init` as a tool default, not an intentionally selected support floor. Decide compatibility explicitly and change it with the repository-selected toolchain when needed.
- Run `go mod tidy` with the repository-selected toolchain when the import graph changes, then inspect `go.mod` and `go.sum` for incidental directive or dependency changes.
- Run `govulncheck ./...` in the repository's regular CI or release security workflow and after dependency or toolchain changes.

## Guardrails

- Do not create generic technical layers without evidence that their boundaries help.
- Do not let transport concerns dictate domain policy.
- Do not introduce interface-heavy architecture without evidence it helps.
- Do not start background goroutines without ownership and shutdown.
- Do not widen package scope when a smaller focused change will solve the problem.

## Primary references

- Go release history and support policy: `https://go.dev/doc/devel/release`
- Release notes for the selected Go line: substitute `N` in `https://go.dev/doc/go1.N`
- Go toolchain selection: `https://go.dev/doc/toolchain`
- Go modules reference: `https://go.dev/ref/mod`
- Go standard library: `https://pkg.go.dev/std`

## Response expectations

For substantial changes using this skill, unless the user requests another format:

1. State the architecture impact of the change in plain language.
2. Call out trade-offs when choosing libraries, concurrency patterns, or package boundaries.
3. Prefer concrete file-level recommendations over broad Go advice.
4. Point to official Go docs or the package's versioned docs and upstream repository when specifics matter.
5. End with the most relevant verification commands or follow-up checks.
