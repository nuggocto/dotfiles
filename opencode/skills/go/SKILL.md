---
name: go
description: >
  Production-grade Go guidance focused on idiomatic code, clear architecture
  boundaries, reliability, and testability. Use when working with Go code, .go
  files, go.mod modules, libraries, CLIs, services, APIs, or workers.
license: MIT
metadata:
  author: opencode
  version: "2.3.1"
---

# Go

Use this skill for production-grade Go applications, libraries, services, APIs, workers, and tooling. Apply the backend stack options only when creating or extending a backend service. Prefer the repository's existing patterns over generic defaults.

Resolve the mandatory minimum and language semantics from the `go` directive. When present in the main module or workspace, also resolve the optional `toolchain` preference, `GOTOOLCHAIN` policy, dependency versions, build tags, CI matrix, module checksums, and deployment configuration from `go.mod`, `go.work`, `go.sum`, and automation before consulting APIs. Use Go 1.27.2 for new projects (latest stable verified 2026-10-09); confirm that CI, release builds, and production use the latest patch release of a supported Go line. Patch releases carry security and correctness fixes, and the `go` directive alone does not keep the building toolchain current. Use documentation matching those versions; pkg.go.dev hosting does not make a recommendation official Go-project policy. For toolchain upgrades, read `references/toolchain-upgrades.md`.

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

For new backend stack selection or changes to HTTP, persistence, migrations,
logging, startup, or shutdown, read
[references/backend-stack.md](references/backend-stack.md).

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
- Gate syntax on the module's `go` directive and supported toolchains: `new(expression)` and self-referential generic constraints require Go 1.26+, and generic methods require Go 1.27+. Interface methods cannot declare type parameters or be implemented by generic methods.

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

## Security boundaries

- Load the `security` skill when a change creates or alters an authentication, authorization, cryptography, upload, command, parser, outbound-URL, filesystem-path, or other trust boundary. Treat outbound URLs as SSRF boundaries and filesystem paths as traversal boundaries; bound request, response, decompression, and collection sizes.
- For cryptographic code or tests, read the cryptographic compatibility guidance
  in [references/toolchain-upgrades.md](references/toolchain-upgrades.md#http-tls-and-cryptographic-compatibility).

## JSON and API contracts

- Preserve the repository's JSON encoder and wire behavior. In Go 1.27, `encoding/json` uses the v2 implementation with v1-compatible semantics, though error text may change; choose `encoding/json/v2` for new contracts only when its stricter defaults fit.
- Use boundary-owned request and response types when the transport contract differs from the internal representation; do not duplicate identical structs merely to avoid JSON tags.
- Treat JSON tags, omitted fields, defaults, unknown-field handling, and time formats as API contract decisions.
- Reject unknown input only when intentional: use `json.Decoder.DisallowUnknownFields` with v1 or `json.RejectUnknownMembers(true)` with v2. Verify duplicate-name, invalid-UTF-8, and field-matching behavior when changing encoders.
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
